module fft_ifft_top
#(
    parameter N     = 128,
    parameter RE_W  = 16,   // real part data width
    parameter IM_W  = 16    // imaginary part data width
)
(
    input wire              clk,
    input wire              rst_n,
	input wire				mode,  			  // input select fft/ifft mode, 0-fft, 1-ifft

    input wire [RE_W-1:0]   data_in_re,       // input data's real part, input over N cycles
    input wire [IM_W-1:0]   data_in_im,       // input data's imaginary part
    input wire              data_in_valid,    // input data valid signal
    
    output reg [RE_W-1:0]   data_out_re,      // output data's real part, output over N cycles
    output reg [IM_W-1:0]   data_out_im,      // output data's imaginary part
    output reg              data_out_valid    // output data valid signal
);

localparam ST_IDLE = 3'd0;
localparam ST_LOAD = 3'd1;
localparam ST_CALC = 3'd2;
localparam ST_OUT  = 3'd3;

reg [2:0] state;
reg       mode_r;

reg [6:0] load_cnt;
reg [6:0] out_cnt;
reg [7:0] group_base;
reg [6:0] j_idx;
reg [7:0] stage_half;
reg [8:0] stage_m;
reg [7:0] tw_step;

reg signed [31:0] mem_re [0:N-1];
reg signed [31:0] mem_im [0:N-1];

reg signed [31:0] a_re;
reg signed [31:0] a_im;
reg signed [31:0] b_re;
reg signed [31:0] b_im;
reg signed [15:0] w_re;
reg signed [15:0] w_im;
reg signed [63:0] prod_re;
reg signed [63:0] prod_im;
reg signed [31:0] t_re;
reg signed [31:0] t_im;

wire [7:0] addr_a = group_base + {1'b0, j_idx};
wire [8:0] addr_b_w = group_base + {1'b0, j_idx} + stage_half;
wire [6:0] addr_b = addr_b_w[6:0];
wire [13:0] tw_idx_w = j_idx * tw_step[6:0];
wire [6:0] tw_idx = tw_idx_w[6:0];

integer i;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= ST_IDLE;
        mode_r <= 1'b0;
        load_cnt <= 7'd0;
        out_cnt <= 7'd0;
        group_base <= 8'd0;
        j_idx <= 7'd0;
        stage_half <= 8'd1;
        stage_m <= 9'd2;
        tw_step <= 8'd64;
        data_out_re <= {RE_W{1'b0}};
        data_out_im <= {IM_W{1'b0}};
        data_out_valid <= 1'b0;
        for (i = 0; i < N; i = i + 1) begin
            mem_re[i] <= 32'sd0;
            mem_im[i] <= 32'sd0;
        end
    end else begin
        data_out_valid <= 1'b0;

        case (state)
            ST_IDLE: begin
                load_cnt <= 7'd0;
                if (data_in_valid) begin
                    mode_r <= mode;
                    mem_re[bit_reverse7(7'd0)] <= {{16{data_in_re[RE_W-1]}}, data_in_re};
                    mem_im[bit_reverse7(7'd0)] <= {{16{data_in_im[IM_W-1]}}, data_in_im};
                    load_cnt <= 7'd1;
                    state <= ST_LOAD;
                end
            end

            ST_LOAD: begin
                if (data_in_valid) begin
                    mem_re[bit_reverse7(load_cnt)] <= {{16{data_in_re[RE_W-1]}}, data_in_re};
                    mem_im[bit_reverse7(load_cnt)] <= {{16{data_in_im[IM_W-1]}}, data_in_im};

                    if (load_cnt == 7'd127) begin
                        group_base <= 8'd0;
                        j_idx <= 7'd0;
                        stage_half <= 8'd1;
                        stage_m <= 9'd2;
                        tw_step <= 8'd64;
                        state <= ST_CALC;
                    end else begin
                        load_cnt <= load_cnt + 7'd1;
                    end
                end
            end

            ST_CALC: begin
                a_re = mem_re[addr_a[6:0]];
                a_im = mem_im[addr_a[6:0]];
                b_re = mem_re[addr_b];
                b_im = mem_im[addr_b];
                w_re = twiddle_re(tw_idx);
                w_im = twiddle_im(tw_idx, mode_r);

                prod_re = b_re * w_re - b_im * w_im;
                prod_im = b_re * w_im + b_im * w_re;
                t_re = prod_re >>> 15;
                t_im = prod_im >>> 15;

                mem_re[addr_a[6:0]] <= (a_re + t_re) >>> 1;
                mem_im[addr_a[6:0]] <= (a_im + t_im) >>> 1;
                mem_re[addr_b] <= (a_re - t_re) >>> 1;
                mem_im[addr_b] <= (a_im - t_im) >>> 1;

                if (j_idx == stage_half[6:0] - 7'd1) begin
                    j_idx <= 7'd0;
                    if ((group_base + stage_m) >= N) begin
                        if (stage_half == 8'd64) begin
                            out_cnt <= 7'd0;
                            state <= ST_OUT;
                        end else begin
                            group_base <= 8'd0;
                            stage_half <= stage_half << 1;
                            stage_m <= stage_m << 1;
                            tw_step <= tw_step >> 1;
                        end
                    end else begin
                        group_base <= group_base + stage_m[7:0];
                    end
                end else begin
                    j_idx <= j_idx + 7'd1;
                end
            end

            ST_OUT: begin
                data_out_re <= sat16(mem_re[out_cnt]);
                data_out_im <= sat16(mem_im[out_cnt]);
                data_out_valid <= 1'b1;
                if (out_cnt == 7'd127) begin
                    state <= ST_IDLE;
                end else begin
                    out_cnt <= out_cnt + 7'd1;
                end
            end

            default: begin
                state <= ST_IDLE;
            end
        endcase
    end
end

function [6:0] bit_reverse7;
    input [6:0] x;
    begin
        bit_reverse7 = {x[0], x[1], x[2], x[3], x[4], x[5], x[6]};
    end
endfunction

function signed [15:0] sat16;
    input signed [31:0] x;
    begin
        if (x > 32'sd32767)
            sat16 = 16'sh7fff;
        else if (x < -32'sd32768)
            sat16 = 16'sh8000;
        else
            sat16 = x[15:0];
    end
endfunction

function signed [15:0] sin_quarter_q15;
    input [5:0] idx;
    begin
        case (idx)
            6'd0:  sin_quarter_q15 = 16'sd0;
            6'd1:  sin_quarter_q15 = 16'sd1608;
            6'd2:  sin_quarter_q15 = 16'sd3212;
            6'd3:  sin_quarter_q15 = 16'sd4808;
            6'd4:  sin_quarter_q15 = 16'sd6393;
            6'd5:  sin_quarter_q15 = 16'sd7962;
            6'd6:  sin_quarter_q15 = 16'sd9512;
            6'd7:  sin_quarter_q15 = 16'sd11039;
            6'd8:  sin_quarter_q15 = 16'sd12540;
            6'd9:  sin_quarter_q15 = 16'sd14010;
            6'd10: sin_quarter_q15 = 16'sd15447;
            6'd11: sin_quarter_q15 = 16'sd16846;
            6'd12: sin_quarter_q15 = 16'sd18205;
            6'd13: sin_quarter_q15 = 16'sd19520;
            6'd14: sin_quarter_q15 = 16'sd20788;
            6'd15: sin_quarter_q15 = 16'sd22006;
            6'd16: sin_quarter_q15 = 16'sd23170;
            6'd17: sin_quarter_q15 = 16'sd24279;
            6'd18: sin_quarter_q15 = 16'sd25330;
            6'd19: sin_quarter_q15 = 16'sd26320;
            6'd20: sin_quarter_q15 = 16'sd27246;
            6'd21: sin_quarter_q15 = 16'sd28106;
            6'd22: sin_quarter_q15 = 16'sd28899;
            6'd23: sin_quarter_q15 = 16'sd29622;
            6'd24: sin_quarter_q15 = 16'sd30274;
            6'd25: sin_quarter_q15 = 16'sd30853;
            6'd26: sin_quarter_q15 = 16'sd31357;
            6'd27: sin_quarter_q15 = 16'sd31786;
            6'd28: sin_quarter_q15 = 16'sd32138;
            6'd29: sin_quarter_q15 = 16'sd32413;
            6'd30: sin_quarter_q15 = 16'sd32610;
            6'd31: sin_quarter_q15 = 16'sd32729;
            default: sin_quarter_q15 = 16'sd32767;
        endcase
    end
endfunction

function signed [15:0] sin_q15_0_to_63;
    input [6:0] idx;
    reg [6:0] mirror;
    begin
        if (idx <= 7'd32)
            sin_q15_0_to_63 = sin_quarter_q15(idx[5:0]);
        else begin
            mirror = 7'd64 - idx;
            sin_q15_0_to_63 = sin_quarter_q15(mirror[5:0]);
        end
    end
endfunction

function signed [15:0] cos_q15_0_to_63;
    input [6:0] idx;
    reg [6:0] mirror;
    begin
        if (idx <= 7'd32) begin
            mirror = 7'd32 - idx;
            cos_q15_0_to_63 = sin_quarter_q15(mirror[5:0]);
        end else begin
            mirror = idx - 7'd32;
            cos_q15_0_to_63 = -sin_quarter_q15(mirror[5:0]);
        end
    end
endfunction

function signed [15:0] twiddle_re;
    input [6:0] idx;
    begin
        twiddle_re = cos_q15_0_to_63(idx);
    end
endfunction

function signed [15:0] twiddle_im;
    input [6:0] idx;
    input       ifft_mode;
    reg signed [15:0] s;
    begin
        s = sin_q15_0_to_63(idx);
        if (ifft_mode)
            twiddle_im = s;
        else
            twiddle_im = -s;
    end
endfunction

endmodule