module fft_ifft_top
#(
    parameter N     = 128,
    parameter RE_W  = 16,
    parameter IM_W  = 16,
    parameter FRAC_BITS = 12,
    parameter INTERNAL_W = 20
)
(
    input wire              clk,
    input wire              rst_n,
    input wire              mode,
    input wire [RE_W-1:0]   data_in_re,
    input wire [IM_W-1:0]   data_in_im,
    input wire              data_in_valid,
    output reg [RE_W-1:0]   data_out_re,
    output reg [IM_W-1:0]   data_out_im,
    output reg              data_out_valid
);

localparam ST_IDLE = 2'd0;
localparam ST_LOAD = 2'd1;
localparam ST_CALC = 2'd2;
localparam ST_OUT  = 2'd3;

reg [1:0] state;
reg mode_r;
reg calc_phase;
reg [6:0] load_cnt;
reg [6:0] out_cnt;
reg [2:0] stage_idx;
reg [2:0] step_idx;

reg signed [INTERNAL_W-1:0] mem_re [0:N-1];
reg signed [INTERNAL_W-1:0] mem_im [0:N-1];

reg [6:0] lane_a_idx [0:7];
reg [6:0] lane_b_idx [0:7];
reg signed [INTERNAL_W-1:0] lane_ar [0:7];
reg signed [INTERNAL_W-1:0] lane_ai [0:7];
reg signed [INTERNAL_W-1:0] lane_tr [0:7];
reg signed [INTERNAL_W-1:0] lane_ti [0:7];

integer i;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= ST_IDLE;
        mode_r <= 1'b0;
        calc_phase <= 1'b0;
        load_cnt <= 7'd0;
        out_cnt <= 7'd0;
        stage_idx <= 3'd0;
        step_idx <= 3'd0;
        data_out_re <= {RE_W{1'b0}};
        data_out_im <= {IM_W{1'b0}};
        data_out_valid <= 1'b0;
        for (i = 0; i < N; i = i + 1) begin
            mem_re[i] <= {INTERNAL_W{1'b0}};
            mem_im[i] <= {INTERNAL_W{1'b0}};
        end
        for (i = 0; i < 8; i = i + 1) begin
            lane_a_idx[i] <= 7'd0;
            lane_b_idx[i] <= 7'd0;
            lane_ar[i] <= {INTERNAL_W{1'b0}};
            lane_ai[i] <= {INTERNAL_W{1'b0}};
            lane_tr[i] <= {INTERNAL_W{1'b0}};
            lane_ti[i] <= {INTERNAL_W{1'b0}};
        end
    end else begin
        data_out_valid <= 1'b0;
        case (state)
            ST_IDLE: begin
                load_cnt <= 7'd0;
                if (data_in_valid) begin
                    mode_r <= mode;
                    mem_re[bit_reverse7(7'd0)] <= {{(INTERNAL_W-RE_W){data_in_re[RE_W-1]}}, data_in_re};
                    mem_im[bit_reverse7(7'd0)] <= {{(INTERNAL_W-IM_W){data_in_im[IM_W-1]}}, data_in_im};
                    load_cnt <= 7'd1;
                    state <= ST_LOAD;
                end
            end
            ST_LOAD: begin
                if (data_in_valid) begin
                    mem_re[bit_reverse7(load_cnt)] <= {{(INTERNAL_W-RE_W){data_in_re[RE_W-1]}}, data_in_re};
                    mem_im[bit_reverse7(load_cnt)] <= {{(INTERNAL_W-IM_W){data_in_im[IM_W-1]}}, data_in_im};
                    if (load_cnt == 7'd127) begin
                        stage_idx <= 3'd0;
                        step_idx <= 3'd0;
                        calc_phase <= 1'b0;
                        state <= ST_CALC;
                    end else begin
                        load_cnt <= load_cnt + 7'd1;
                    end
                end
            end
            ST_CALC: begin
                if (!calc_phase) begin
                    case ({stage_idx, step_idx})
                        6'd0: begin
                            prep_lane(0, 7'd0, 7'd1, 7'd0);
                            prep_lane(1, 7'd2, 7'd3, 7'd0);
                            prep_lane(2, 7'd4, 7'd5, 7'd0);
                            prep_lane(3, 7'd6, 7'd7, 7'd0);
                            prep_lane(4, 7'd8, 7'd9, 7'd0);
                            prep_lane(5, 7'd10, 7'd11, 7'd0);
                            prep_lane(6, 7'd12, 7'd13, 7'd0);
                            prep_lane(7, 7'd14, 7'd15, 7'd0);
                        end
                        6'd1: begin
                            prep_lane(0, 7'd16, 7'd17, 7'd0);
                            prep_lane(1, 7'd18, 7'd19, 7'd0);
                            prep_lane(2, 7'd20, 7'd21, 7'd0);
                            prep_lane(3, 7'd22, 7'd23, 7'd0);
                            prep_lane(4, 7'd24, 7'd25, 7'd0);
                            prep_lane(5, 7'd26, 7'd27, 7'd0);
                            prep_lane(6, 7'd28, 7'd29, 7'd0);
                            prep_lane(7, 7'd30, 7'd31, 7'd0);
                        end
                        6'd2: begin
                            prep_lane(0, 7'd32, 7'd33, 7'd0);
                            prep_lane(1, 7'd34, 7'd35, 7'd0);
                            prep_lane(2, 7'd36, 7'd37, 7'd0);
                            prep_lane(3, 7'd38, 7'd39, 7'd0);
                            prep_lane(4, 7'd40, 7'd41, 7'd0);
                            prep_lane(5, 7'd42, 7'd43, 7'd0);
                            prep_lane(6, 7'd44, 7'd45, 7'd0);
                            prep_lane(7, 7'd46, 7'd47, 7'd0);
                        end
                        6'd3: begin
                            prep_lane(0, 7'd48, 7'd49, 7'd0);
                            prep_lane(1, 7'd50, 7'd51, 7'd0);
                            prep_lane(2, 7'd52, 7'd53, 7'd0);
                            prep_lane(3, 7'd54, 7'd55, 7'd0);
                            prep_lane(4, 7'd56, 7'd57, 7'd0);
                            prep_lane(5, 7'd58, 7'd59, 7'd0);
                            prep_lane(6, 7'd60, 7'd61, 7'd0);
                            prep_lane(7, 7'd62, 7'd63, 7'd0);
                        end
                        6'd4: begin
                            prep_lane(0, 7'd64, 7'd65, 7'd0);
                            prep_lane(1, 7'd66, 7'd67, 7'd0);
                            prep_lane(2, 7'd68, 7'd69, 7'd0);
                            prep_lane(3, 7'd70, 7'd71, 7'd0);
                            prep_lane(4, 7'd72, 7'd73, 7'd0);
                            prep_lane(5, 7'd74, 7'd75, 7'd0);
                            prep_lane(6, 7'd76, 7'd77, 7'd0);
                            prep_lane(7, 7'd78, 7'd79, 7'd0);
                        end
                        6'd5: begin
                            prep_lane(0, 7'd80, 7'd81, 7'd0);
                            prep_lane(1, 7'd82, 7'd83, 7'd0);
                            prep_lane(2, 7'd84, 7'd85, 7'd0);
                            prep_lane(3, 7'd86, 7'd87, 7'd0);
                            prep_lane(4, 7'd88, 7'd89, 7'd0);
                            prep_lane(5, 7'd90, 7'd91, 7'd0);
                            prep_lane(6, 7'd92, 7'd93, 7'd0);
                            prep_lane(7, 7'd94, 7'd95, 7'd0);
                        end
                        6'd6: begin
                            prep_lane(0, 7'd96, 7'd97, 7'd0);
                            prep_lane(1, 7'd98, 7'd99, 7'd0);
                            prep_lane(2, 7'd100, 7'd101, 7'd0);
                            prep_lane(3, 7'd102, 7'd103, 7'd0);
                            prep_lane(4, 7'd104, 7'd105, 7'd0);
                            prep_lane(5, 7'd106, 7'd107, 7'd0);
                            prep_lane(6, 7'd108, 7'd109, 7'd0);
                            prep_lane(7, 7'd110, 7'd111, 7'd0);
                        end
                        6'd7: begin
                            prep_lane(0, 7'd112, 7'd113, 7'd0);
                            prep_lane(1, 7'd114, 7'd115, 7'd0);
                            prep_lane(2, 7'd116, 7'd117, 7'd0);
                            prep_lane(3, 7'd118, 7'd119, 7'd0);
                            prep_lane(4, 7'd120, 7'd121, 7'd0);
                            prep_lane(5, 7'd122, 7'd123, 7'd0);
                            prep_lane(6, 7'd124, 7'd125, 7'd0);
                            prep_lane(7, 7'd126, 7'd127, 7'd0);
                        end
                        6'd8: begin
                            prep_lane(0, 7'd0, 7'd2, 7'd0);
                            prep_lane(1, 7'd1, 7'd3, 7'd32);
                            prep_lane(2, 7'd4, 7'd6, 7'd0);
                            prep_lane(3, 7'd5, 7'd7, 7'd32);
                            prep_lane(4, 7'd8, 7'd10, 7'd0);
                            prep_lane(5, 7'd9, 7'd11, 7'd32);
                            prep_lane(6, 7'd12, 7'd14, 7'd0);
                            prep_lane(7, 7'd13, 7'd15, 7'd32);
                        end
                        6'd9: begin
                            prep_lane(0, 7'd16, 7'd18, 7'd0);
                            prep_lane(1, 7'd17, 7'd19, 7'd32);
                            prep_lane(2, 7'd20, 7'd22, 7'd0);
                            prep_lane(3, 7'd21, 7'd23, 7'd32);
                            prep_lane(4, 7'd24, 7'd26, 7'd0);
                            prep_lane(5, 7'd25, 7'd27, 7'd32);
                            prep_lane(6, 7'd28, 7'd30, 7'd0);
                            prep_lane(7, 7'd29, 7'd31, 7'd32);
                        end
                        6'd10: begin
                            prep_lane(0, 7'd32, 7'd34, 7'd0);
                            prep_lane(1, 7'd33, 7'd35, 7'd32);
                            prep_lane(2, 7'd36, 7'd38, 7'd0);
                            prep_lane(3, 7'd37, 7'd39, 7'd32);
                            prep_lane(4, 7'd40, 7'd42, 7'd0);
                            prep_lane(5, 7'd41, 7'd43, 7'd32);
                            prep_lane(6, 7'd44, 7'd46, 7'd0);
                            prep_lane(7, 7'd45, 7'd47, 7'd32);
                        end
                        6'd11: begin
                            prep_lane(0, 7'd48, 7'd50, 7'd0);
                            prep_lane(1, 7'd49, 7'd51, 7'd32);
                            prep_lane(2, 7'd52, 7'd54, 7'd0);
                            prep_lane(3, 7'd53, 7'd55, 7'd32);
                            prep_lane(4, 7'd56, 7'd58, 7'd0);
                            prep_lane(5, 7'd57, 7'd59, 7'd32);
                            prep_lane(6, 7'd60, 7'd62, 7'd0);
                            prep_lane(7, 7'd61, 7'd63, 7'd32);
                        end
                        6'd12: begin
                            prep_lane(0, 7'd64, 7'd66, 7'd0);
                            prep_lane(1, 7'd65, 7'd67, 7'd32);
                            prep_lane(2, 7'd68, 7'd70, 7'd0);
                            prep_lane(3, 7'd69, 7'd71, 7'd32);
                            prep_lane(4, 7'd72, 7'd74, 7'd0);
                            prep_lane(5, 7'd73, 7'd75, 7'd32);
                            prep_lane(6, 7'd76, 7'd78, 7'd0);
                            prep_lane(7, 7'd77, 7'd79, 7'd32);
                        end
                        6'd13: begin
                            prep_lane(0, 7'd80, 7'd82, 7'd0);
                            prep_lane(1, 7'd81, 7'd83, 7'd32);
                            prep_lane(2, 7'd84, 7'd86, 7'd0);
                            prep_lane(3, 7'd85, 7'd87, 7'd32);
                            prep_lane(4, 7'd88, 7'd90, 7'd0);
                            prep_lane(5, 7'd89, 7'd91, 7'd32);
                            prep_lane(6, 7'd92, 7'd94, 7'd0);
                            prep_lane(7, 7'd93, 7'd95, 7'd32);
                        end
                        6'd14: begin
                            prep_lane(0, 7'd96, 7'd98, 7'd0);
                            prep_lane(1, 7'd97, 7'd99, 7'd32);
                            prep_lane(2, 7'd100, 7'd102, 7'd0);
                            prep_lane(3, 7'd101, 7'd103, 7'd32);
                            prep_lane(4, 7'd104, 7'd106, 7'd0);
                            prep_lane(5, 7'd105, 7'd107, 7'd32);
                            prep_lane(6, 7'd108, 7'd110, 7'd0);
                            prep_lane(7, 7'd109, 7'd111, 7'd32);
                        end
                        6'd15: begin
                            prep_lane(0, 7'd112, 7'd114, 7'd0);
                            prep_lane(1, 7'd113, 7'd115, 7'd32);
                            prep_lane(2, 7'd116, 7'd118, 7'd0);
                            prep_lane(3, 7'd117, 7'd119, 7'd32);
                            prep_lane(4, 7'd120, 7'd122, 7'd0);
                            prep_lane(5, 7'd121, 7'd123, 7'd32);
                            prep_lane(6, 7'd124, 7'd126, 7'd0);
                            prep_lane(7, 7'd125, 7'd127, 7'd32);
                        end
                        6'd16: begin
                            prep_lane(0, 7'd0, 7'd4, 7'd0);
                            prep_lane(1, 7'd1, 7'd5, 7'd16);
                            prep_lane(2, 7'd2, 7'd6, 7'd32);
                            prep_lane(3, 7'd3, 7'd7, 7'd48);
                            prep_lane(4, 7'd8, 7'd12, 7'd0);
                            prep_lane(5, 7'd9, 7'd13, 7'd16);
                            prep_lane(6, 7'd10, 7'd14, 7'd32);
                            prep_lane(7, 7'd11, 7'd15, 7'd48);
                        end
                        6'd17: begin
                            prep_lane(0, 7'd16, 7'd20, 7'd0);
                            prep_lane(1, 7'd17, 7'd21, 7'd16);
                            prep_lane(2, 7'd18, 7'd22, 7'd32);
                            prep_lane(3, 7'd19, 7'd23, 7'd48);
                            prep_lane(4, 7'd24, 7'd28, 7'd0);
                            prep_lane(5, 7'd25, 7'd29, 7'd16);
                            prep_lane(6, 7'd26, 7'd30, 7'd32);
                            prep_lane(7, 7'd27, 7'd31, 7'd48);
                        end
                        6'd18: begin
                            prep_lane(0, 7'd32, 7'd36, 7'd0);
                            prep_lane(1, 7'd33, 7'd37, 7'd16);
                            prep_lane(2, 7'd34, 7'd38, 7'd32);
                            prep_lane(3, 7'd35, 7'd39, 7'd48);
                            prep_lane(4, 7'd40, 7'd44, 7'd0);
                            prep_lane(5, 7'd41, 7'd45, 7'd16);
                            prep_lane(6, 7'd42, 7'd46, 7'd32);
                            prep_lane(7, 7'd43, 7'd47, 7'd48);
                        end
                        6'd19: begin
                            prep_lane(0, 7'd48, 7'd52, 7'd0);
                            prep_lane(1, 7'd49, 7'd53, 7'd16);
                            prep_lane(2, 7'd50, 7'd54, 7'd32);
                            prep_lane(3, 7'd51, 7'd55, 7'd48);
                            prep_lane(4, 7'd56, 7'd60, 7'd0);
                            prep_lane(5, 7'd57, 7'd61, 7'd16);
                            prep_lane(6, 7'd58, 7'd62, 7'd32);
                            prep_lane(7, 7'd59, 7'd63, 7'd48);
                        end
                        6'd20: begin
                            prep_lane(0, 7'd64, 7'd68, 7'd0);
                            prep_lane(1, 7'd65, 7'd69, 7'd16);
                            prep_lane(2, 7'd66, 7'd70, 7'd32);
                            prep_lane(3, 7'd67, 7'd71, 7'd48);
                            prep_lane(4, 7'd72, 7'd76, 7'd0);
                            prep_lane(5, 7'd73, 7'd77, 7'd16);
                            prep_lane(6, 7'd74, 7'd78, 7'd32);
                            prep_lane(7, 7'd75, 7'd79, 7'd48);
                        end
                        6'd21: begin
                            prep_lane(0, 7'd80, 7'd84, 7'd0);
                            prep_lane(1, 7'd81, 7'd85, 7'd16);
                            prep_lane(2, 7'd82, 7'd86, 7'd32);
                            prep_lane(3, 7'd83, 7'd87, 7'd48);
                            prep_lane(4, 7'd88, 7'd92, 7'd0);
                            prep_lane(5, 7'd89, 7'd93, 7'd16);
                            prep_lane(6, 7'd90, 7'd94, 7'd32);
                            prep_lane(7, 7'd91, 7'd95, 7'd48);
                        end
                        6'd22: begin
                            prep_lane(0, 7'd96, 7'd100, 7'd0);
                            prep_lane(1, 7'd97, 7'd101, 7'd16);
                            prep_lane(2, 7'd98, 7'd102, 7'd32);
                            prep_lane(3, 7'd99, 7'd103, 7'd48);
                            prep_lane(4, 7'd104, 7'd108, 7'd0);
                            prep_lane(5, 7'd105, 7'd109, 7'd16);
                            prep_lane(6, 7'd106, 7'd110, 7'd32);
                            prep_lane(7, 7'd107, 7'd111, 7'd48);
                        end
                        6'd23: begin
                            prep_lane(0, 7'd112, 7'd116, 7'd0);
                            prep_lane(1, 7'd113, 7'd117, 7'd16);
                            prep_lane(2, 7'd114, 7'd118, 7'd32);
                            prep_lane(3, 7'd115, 7'd119, 7'd48);
                            prep_lane(4, 7'd120, 7'd124, 7'd0);
                            prep_lane(5, 7'd121, 7'd125, 7'd16);
                            prep_lane(6, 7'd122, 7'd126, 7'd32);
                            prep_lane(7, 7'd123, 7'd127, 7'd48);
                        end
                        6'd24: begin
                            prep_lane(0, 7'd0, 7'd8, 7'd0);
                            prep_lane(1, 7'd1, 7'd9, 7'd8);
                            prep_lane(2, 7'd2, 7'd10, 7'd16);
                            prep_lane(3, 7'd3, 7'd11, 7'd24);
                            prep_lane(4, 7'd4, 7'd12, 7'd32);
                            prep_lane(5, 7'd5, 7'd13, 7'd40);
                            prep_lane(6, 7'd6, 7'd14, 7'd48);
                            prep_lane(7, 7'd7, 7'd15, 7'd56);
                        end
                        6'd25: begin
                            prep_lane(0, 7'd16, 7'd24, 7'd0);
                            prep_lane(1, 7'd17, 7'd25, 7'd8);
                            prep_lane(2, 7'd18, 7'd26, 7'd16);
                            prep_lane(3, 7'd19, 7'd27, 7'd24);
                            prep_lane(4, 7'd20, 7'd28, 7'd32);
                            prep_lane(5, 7'd21, 7'd29, 7'd40);
                            prep_lane(6, 7'd22, 7'd30, 7'd48);
                            prep_lane(7, 7'd23, 7'd31, 7'd56);
                        end
                        6'd26: begin
                            prep_lane(0, 7'd32, 7'd40, 7'd0);
                            prep_lane(1, 7'd33, 7'd41, 7'd8);
                            prep_lane(2, 7'd34, 7'd42, 7'd16);
                            prep_lane(3, 7'd35, 7'd43, 7'd24);
                            prep_lane(4, 7'd36, 7'd44, 7'd32);
                            prep_lane(5, 7'd37, 7'd45, 7'd40);
                            prep_lane(6, 7'd38, 7'd46, 7'd48);
                            prep_lane(7, 7'd39, 7'd47, 7'd56);
                        end
                        6'd27: begin
                            prep_lane(0, 7'd48, 7'd56, 7'd0);
                            prep_lane(1, 7'd49, 7'd57, 7'd8);
                            prep_lane(2, 7'd50, 7'd58, 7'd16);
                            prep_lane(3, 7'd51, 7'd59, 7'd24);
                            prep_lane(4, 7'd52, 7'd60, 7'd32);
                            prep_lane(5, 7'd53, 7'd61, 7'd40);
                            prep_lane(6, 7'd54, 7'd62, 7'd48);
                            prep_lane(7, 7'd55, 7'd63, 7'd56);
                        end
                        6'd28: begin
                            prep_lane(0, 7'd64, 7'd72, 7'd0);
                            prep_lane(1, 7'd65, 7'd73, 7'd8);
                            prep_lane(2, 7'd66, 7'd74, 7'd16);
                            prep_lane(3, 7'd67, 7'd75, 7'd24);
                            prep_lane(4, 7'd68, 7'd76, 7'd32);
                            prep_lane(5, 7'd69, 7'd77, 7'd40);
                            prep_lane(6, 7'd70, 7'd78, 7'd48);
                            prep_lane(7, 7'd71, 7'd79, 7'd56);
                        end
                        6'd29: begin
                            prep_lane(0, 7'd80, 7'd88, 7'd0);
                            prep_lane(1, 7'd81, 7'd89, 7'd8);
                            prep_lane(2, 7'd82, 7'd90, 7'd16);
                            prep_lane(3, 7'd83, 7'd91, 7'd24);
                            prep_lane(4, 7'd84, 7'd92, 7'd32);
                            prep_lane(5, 7'd85, 7'd93, 7'd40);
                            prep_lane(6, 7'd86, 7'd94, 7'd48);
                            prep_lane(7, 7'd87, 7'd95, 7'd56);
                        end
                        6'd30: begin
                            prep_lane(0, 7'd96, 7'd104, 7'd0);
                            prep_lane(1, 7'd97, 7'd105, 7'd8);
                            prep_lane(2, 7'd98, 7'd106, 7'd16);
                            prep_lane(3, 7'd99, 7'd107, 7'd24);
                            prep_lane(4, 7'd100, 7'd108, 7'd32);
                            prep_lane(5, 7'd101, 7'd109, 7'd40);
                            prep_lane(6, 7'd102, 7'd110, 7'd48);
                            prep_lane(7, 7'd103, 7'd111, 7'd56);
                        end
                        6'd31: begin
                            prep_lane(0, 7'd112, 7'd120, 7'd0);
                            prep_lane(1, 7'd113, 7'd121, 7'd8);
                            prep_lane(2, 7'd114, 7'd122, 7'd16);
                            prep_lane(3, 7'd115, 7'd123, 7'd24);
                            prep_lane(4, 7'd116, 7'd124, 7'd32);
                            prep_lane(5, 7'd117, 7'd125, 7'd40);
                            prep_lane(6, 7'd118, 7'd126, 7'd48);
                            prep_lane(7, 7'd119, 7'd127, 7'd56);
                        end
                        6'd32: begin
                            prep_lane(0, 7'd0, 7'd16, 7'd0);
                            prep_lane(1, 7'd1, 7'd17, 7'd4);
                            prep_lane(2, 7'd2, 7'd18, 7'd8);
                            prep_lane(3, 7'd3, 7'd19, 7'd12);
                            prep_lane(4, 7'd4, 7'd20, 7'd16);
                            prep_lane(5, 7'd5, 7'd21, 7'd20);
                            prep_lane(6, 7'd6, 7'd22, 7'd24);
                            prep_lane(7, 7'd7, 7'd23, 7'd28);
                        end
                        6'd33: begin
                            prep_lane(0, 7'd8, 7'd24, 7'd32);
                            prep_lane(1, 7'd9, 7'd25, 7'd36);
                            prep_lane(2, 7'd10, 7'd26, 7'd40);
                            prep_lane(3, 7'd11, 7'd27, 7'd44);
                            prep_lane(4, 7'd12, 7'd28, 7'd48);
                            prep_lane(5, 7'd13, 7'd29, 7'd52);
                            prep_lane(6, 7'd14, 7'd30, 7'd56);
                            prep_lane(7, 7'd15, 7'd31, 7'd60);
                        end
                        6'd34: begin
                            prep_lane(0, 7'd32, 7'd48, 7'd0);
                            prep_lane(1, 7'd33, 7'd49, 7'd4);
                            prep_lane(2, 7'd34, 7'd50, 7'd8);
                            prep_lane(3, 7'd35, 7'd51, 7'd12);
                            prep_lane(4, 7'd36, 7'd52, 7'd16);
                            prep_lane(5, 7'd37, 7'd53, 7'd20);
                            prep_lane(6, 7'd38, 7'd54, 7'd24);
                            prep_lane(7, 7'd39, 7'd55, 7'd28);
                        end
                        6'd35: begin
                            prep_lane(0, 7'd40, 7'd56, 7'd32);
                            prep_lane(1, 7'd41, 7'd57, 7'd36);
                            prep_lane(2, 7'd42, 7'd58, 7'd40);
                            prep_lane(3, 7'd43, 7'd59, 7'd44);
                            prep_lane(4, 7'd44, 7'd60, 7'd48);
                            prep_lane(5, 7'd45, 7'd61, 7'd52);
                            prep_lane(6, 7'd46, 7'd62, 7'd56);
                            prep_lane(7, 7'd47, 7'd63, 7'd60);
                        end
                        6'd36: begin
                            prep_lane(0, 7'd64, 7'd80, 7'd0);
                            prep_lane(1, 7'd65, 7'd81, 7'd4);
                            prep_lane(2, 7'd66, 7'd82, 7'd8);
                            prep_lane(3, 7'd67, 7'd83, 7'd12);
                            prep_lane(4, 7'd68, 7'd84, 7'd16);
                            prep_lane(5, 7'd69, 7'd85, 7'd20);
                            prep_lane(6, 7'd70, 7'd86, 7'd24);
                            prep_lane(7, 7'd71, 7'd87, 7'd28);
                        end
                        6'd37: begin
                            prep_lane(0, 7'd72, 7'd88, 7'd32);
                            prep_lane(1, 7'd73, 7'd89, 7'd36);
                            prep_lane(2, 7'd74, 7'd90, 7'd40);
                            prep_lane(3, 7'd75, 7'd91, 7'd44);
                            prep_lane(4, 7'd76, 7'd92, 7'd48);
                            prep_lane(5, 7'd77, 7'd93, 7'd52);
                            prep_lane(6, 7'd78, 7'd94, 7'd56);
                            prep_lane(7, 7'd79, 7'd95, 7'd60);
                        end
                        6'd38: begin
                            prep_lane(0, 7'd96, 7'd112, 7'd0);
                            prep_lane(1, 7'd97, 7'd113, 7'd4);
                            prep_lane(2, 7'd98, 7'd114, 7'd8);
                            prep_lane(3, 7'd99, 7'd115, 7'd12);
                            prep_lane(4, 7'd100, 7'd116, 7'd16);
                            prep_lane(5, 7'd101, 7'd117, 7'd20);
                            prep_lane(6, 7'd102, 7'd118, 7'd24);
                            prep_lane(7, 7'd103, 7'd119, 7'd28);
                        end
                        6'd39: begin
                            prep_lane(0, 7'd104, 7'd120, 7'd32);
                            prep_lane(1, 7'd105, 7'd121, 7'd36);
                            prep_lane(2, 7'd106, 7'd122, 7'd40);
                            prep_lane(3, 7'd107, 7'd123, 7'd44);
                            prep_lane(4, 7'd108, 7'd124, 7'd48);
                            prep_lane(5, 7'd109, 7'd125, 7'd52);
                            prep_lane(6, 7'd110, 7'd126, 7'd56);
                            prep_lane(7, 7'd111, 7'd127, 7'd60);
                        end
                        6'd40: begin
                            prep_lane(0, 7'd0, 7'd32, 7'd0);
                            prep_lane(1, 7'd1, 7'd33, 7'd2);
                            prep_lane(2, 7'd2, 7'd34, 7'd4);
                            prep_lane(3, 7'd3, 7'd35, 7'd6);
                            prep_lane(4, 7'd4, 7'd36, 7'd8);
                            prep_lane(5, 7'd5, 7'd37, 7'd10);
                            prep_lane(6, 7'd6, 7'd38, 7'd12);
                            prep_lane(7, 7'd7, 7'd39, 7'd14);
                        end
                        6'd41: begin
                            prep_lane(0, 7'd8, 7'd40, 7'd16);
                            prep_lane(1, 7'd9, 7'd41, 7'd18);
                            prep_lane(2, 7'd10, 7'd42, 7'd20);
                            prep_lane(3, 7'd11, 7'd43, 7'd22);
                            prep_lane(4, 7'd12, 7'd44, 7'd24);
                            prep_lane(5, 7'd13, 7'd45, 7'd26);
                            prep_lane(6, 7'd14, 7'd46, 7'd28);
                            prep_lane(7, 7'd15, 7'd47, 7'd30);
                        end
                        6'd42: begin
                            prep_lane(0, 7'd16, 7'd48, 7'd32);
                            prep_lane(1, 7'd17, 7'd49, 7'd34);
                            prep_lane(2, 7'd18, 7'd50, 7'd36);
                            prep_lane(3, 7'd19, 7'd51, 7'd38);
                            prep_lane(4, 7'd20, 7'd52, 7'd40);
                            prep_lane(5, 7'd21, 7'd53, 7'd42);
                            prep_lane(6, 7'd22, 7'd54, 7'd44);
                            prep_lane(7, 7'd23, 7'd55, 7'd46);
                        end
                        6'd43: begin
                            prep_lane(0, 7'd24, 7'd56, 7'd48);
                            prep_lane(1, 7'd25, 7'd57, 7'd50);
                            prep_lane(2, 7'd26, 7'd58, 7'd52);
                            prep_lane(3, 7'd27, 7'd59, 7'd54);
                            prep_lane(4, 7'd28, 7'd60, 7'd56);
                            prep_lane(5, 7'd29, 7'd61, 7'd58);
                            prep_lane(6, 7'd30, 7'd62, 7'd60);
                            prep_lane(7, 7'd31, 7'd63, 7'd62);
                        end
                        6'd44: begin
                            prep_lane(0, 7'd64, 7'd96, 7'd0);
                            prep_lane(1, 7'd65, 7'd97, 7'd2);
                            prep_lane(2, 7'd66, 7'd98, 7'd4);
                            prep_lane(3, 7'd67, 7'd99, 7'd6);
                            prep_lane(4, 7'd68, 7'd100, 7'd8);
                            prep_lane(5, 7'd69, 7'd101, 7'd10);
                            prep_lane(6, 7'd70, 7'd102, 7'd12);
                            prep_lane(7, 7'd71, 7'd103, 7'd14);
                        end
                        6'd45: begin
                            prep_lane(0, 7'd72, 7'd104, 7'd16);
                            prep_lane(1, 7'd73, 7'd105, 7'd18);
                            prep_lane(2, 7'd74, 7'd106, 7'd20);
                            prep_lane(3, 7'd75, 7'd107, 7'd22);
                            prep_lane(4, 7'd76, 7'd108, 7'd24);
                            prep_lane(5, 7'd77, 7'd109, 7'd26);
                            prep_lane(6, 7'd78, 7'd110, 7'd28);
                            prep_lane(7, 7'd79, 7'd111, 7'd30);
                        end
                        6'd46: begin
                            prep_lane(0, 7'd80, 7'd112, 7'd32);
                            prep_lane(1, 7'd81, 7'd113, 7'd34);
                            prep_lane(2, 7'd82, 7'd114, 7'd36);
                            prep_lane(3, 7'd83, 7'd115, 7'd38);
                            prep_lane(4, 7'd84, 7'd116, 7'd40);
                            prep_lane(5, 7'd85, 7'd117, 7'd42);
                            prep_lane(6, 7'd86, 7'd118, 7'd44);
                            prep_lane(7, 7'd87, 7'd119, 7'd46);
                        end
                        6'd47: begin
                            prep_lane(0, 7'd88, 7'd120, 7'd48);
                            prep_lane(1, 7'd89, 7'd121, 7'd50);
                            prep_lane(2, 7'd90, 7'd122, 7'd52);
                            prep_lane(3, 7'd91, 7'd123, 7'd54);
                            prep_lane(4, 7'd92, 7'd124, 7'd56);
                            prep_lane(5, 7'd93, 7'd125, 7'd58);
                            prep_lane(6, 7'd94, 7'd126, 7'd60);
                            prep_lane(7, 7'd95, 7'd127, 7'd62);
                        end
                        6'd48: begin
                            prep_lane(0, 7'd0, 7'd64, 7'd0);
                            prep_lane(1, 7'd1, 7'd65, 7'd1);
                            prep_lane(2, 7'd2, 7'd66, 7'd2);
                            prep_lane(3, 7'd3, 7'd67, 7'd3);
                            prep_lane(4, 7'd4, 7'd68, 7'd4);
                            prep_lane(5, 7'd5, 7'd69, 7'd5);
                            prep_lane(6, 7'd6, 7'd70, 7'd6);
                            prep_lane(7, 7'd7, 7'd71, 7'd7);
                        end
                        6'd49: begin
                            prep_lane(0, 7'd8, 7'd72, 7'd8);
                            prep_lane(1, 7'd9, 7'd73, 7'd9);
                            prep_lane(2, 7'd10, 7'd74, 7'd10);
                            prep_lane(3, 7'd11, 7'd75, 7'd11);
                            prep_lane(4, 7'd12, 7'd76, 7'd12);
                            prep_lane(5, 7'd13, 7'd77, 7'd13);
                            prep_lane(6, 7'd14, 7'd78, 7'd14);
                            prep_lane(7, 7'd15, 7'd79, 7'd15);
                        end
                        6'd50: begin
                            prep_lane(0, 7'd16, 7'd80, 7'd16);
                            prep_lane(1, 7'd17, 7'd81, 7'd17);
                            prep_lane(2, 7'd18, 7'd82, 7'd18);
                            prep_lane(3, 7'd19, 7'd83, 7'd19);
                            prep_lane(4, 7'd20, 7'd84, 7'd20);
                            prep_lane(5, 7'd21, 7'd85, 7'd21);
                            prep_lane(6, 7'd22, 7'd86, 7'd22);
                            prep_lane(7, 7'd23, 7'd87, 7'd23);
                        end
                        6'd51: begin
                            prep_lane(0, 7'd24, 7'd88, 7'd24);
                            prep_lane(1, 7'd25, 7'd89, 7'd25);
                            prep_lane(2, 7'd26, 7'd90, 7'd26);
                            prep_lane(3, 7'd27, 7'd91, 7'd27);
                            prep_lane(4, 7'd28, 7'd92, 7'd28);
                            prep_lane(5, 7'd29, 7'd93, 7'd29);
                            prep_lane(6, 7'd30, 7'd94, 7'd30);
                            prep_lane(7, 7'd31, 7'd95, 7'd31);
                        end
                        6'd52: begin
                            prep_lane(0, 7'd32, 7'd96, 7'd32);
                            prep_lane(1, 7'd33, 7'd97, 7'd33);
                            prep_lane(2, 7'd34, 7'd98, 7'd34);
                            prep_lane(3, 7'd35, 7'd99, 7'd35);
                            prep_lane(4, 7'd36, 7'd100, 7'd36);
                            prep_lane(5, 7'd37, 7'd101, 7'd37);
                            prep_lane(6, 7'd38, 7'd102, 7'd38);
                            prep_lane(7, 7'd39, 7'd103, 7'd39);
                        end
                        6'd53: begin
                            prep_lane(0, 7'd40, 7'd104, 7'd40);
                            prep_lane(1, 7'd41, 7'd105, 7'd41);
                            prep_lane(2, 7'd42, 7'd106, 7'd42);
                            prep_lane(3, 7'd43, 7'd107, 7'd43);
                            prep_lane(4, 7'd44, 7'd108, 7'd44);
                            prep_lane(5, 7'd45, 7'd109, 7'd45);
                            prep_lane(6, 7'd46, 7'd110, 7'd46);
                            prep_lane(7, 7'd47, 7'd111, 7'd47);
                        end
                        6'd54: begin
                            prep_lane(0, 7'd48, 7'd112, 7'd48);
                            prep_lane(1, 7'd49, 7'd113, 7'd49);
                            prep_lane(2, 7'd50, 7'd114, 7'd50);
                            prep_lane(3, 7'd51, 7'd115, 7'd51);
                            prep_lane(4, 7'd52, 7'd116, 7'd52);
                            prep_lane(5, 7'd53, 7'd117, 7'd53);
                            prep_lane(6, 7'd54, 7'd118, 7'd54);
                            prep_lane(7, 7'd55, 7'd119, 7'd55);
                        end
                        6'd55: begin
                            prep_lane(0, 7'd56, 7'd120, 7'd56);
                            prep_lane(1, 7'd57, 7'd121, 7'd57);
                            prep_lane(2, 7'd58, 7'd122, 7'd58);
                            prep_lane(3, 7'd59, 7'd123, 7'd59);
                            prep_lane(4, 7'd60, 7'd124, 7'd60);
                            prep_lane(5, 7'd61, 7'd125, 7'd61);
                            prep_lane(6, 7'd62, 7'd126, 7'd62);
                            prep_lane(7, 7'd63, 7'd127, 7'd63);
                        end
                        default: begin
                            prep_lane(0, 7'd0, 7'd1, 7'd0);
                            prep_lane(1, 7'd2, 7'd3, 7'd0);
                            prep_lane(2, 7'd4, 7'd5, 7'd0);
                            prep_lane(3, 7'd6, 7'd7, 7'd0);
                            prep_lane(4, 7'd8, 7'd9, 7'd0);
                            prep_lane(5, 7'd10, 7'd11, 7'd0);
                            prep_lane(6, 7'd12, 7'd13, 7'd0);
                            prep_lane(7, 7'd14, 7'd15, 7'd0);
                        end
                    endcase
                    calc_phase <= 1'b1;
                end else begin
                    for (i = 0; i < 8; i = i + 1) begin
                        mem_re[lane_a_idx[i]] <= (lane_ar[i] + lane_tr[i]) >>> 1;
                        mem_im[lane_a_idx[i]] <= (lane_ai[i] + lane_ti[i]) >>> 1;
                        mem_re[lane_b_idx[i]] <= (lane_ar[i] - lane_tr[i]) >>> 1;
                        mem_im[lane_b_idx[i]] <= (lane_ai[i] - lane_ti[i]) >>> 1;
                    end
                    calc_phase <= 1'b0;
                    if (step_idx == 3'd7) begin
                        step_idx <= 3'd0;
                        if (stage_idx == 3'd6) begin
                            out_cnt <= 7'd0;
                            state <= ST_OUT;
                        end else begin
                            stage_idx <= stage_idx + 3'd1;
                        end
                    end else begin
                        step_idx <= step_idx + 3'd1;
                    end
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
            default: state <= ST_IDLE;
        endcase
    end
end

task prep_lane;
    input integer lane;
    input [6:0] a;
    input [6:0] b;
    input [6:0] k;
    reg signed [15:0] wr;
    reg signed [15:0] wi;
    reg signed [63:0] pr;
    reg signed [63:0] pi;
    begin
        wr = twiddle_re(k);
        wi = twiddle_im(k, mode_r);
        pr = mem_re[b] * wr - mem_im[b] * wi;
        pi = mem_re[b] * wi + mem_im[b] * wr;
        lane_a_idx[lane] <= a;
        lane_b_idx[lane] <= b;
        lane_ar[lane] <= mem_re[a];
        lane_ai[lane] <= mem_im[a];
        lane_tr[lane] <= pr >>> FRAC_BITS;
        lane_ti[lane] <= pi >>> FRAC_BITS;
    end
endtask

function [6:0] bit_reverse7;
    input [6:0] x;
    begin
        bit_reverse7 = {x[0], x[1], x[2], x[3], x[4], x[5], x[6]};
    end
endfunction

function signed [15:0] sat16;
    input signed [INTERNAL_W-1:0] x;
    begin
        if (x > 20'sd32767)
            sat16 = 16'sh7fff;
        else if (x < -20'sd32768)
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
            6'd1:  sin_quarter_q15 = 16'sd201;
            6'd2:  sin_quarter_q15 = 16'sd401;
            6'd3:  sin_quarter_q15 = 16'sd601;
            6'd4:  sin_quarter_q15 = 16'sd799;
            6'd5:  sin_quarter_q15 = 16'sd995;
            6'd6:  sin_quarter_q15 = 16'sd1189;
            6'd7:  sin_quarter_q15 = 16'sd1380;
            6'd8:  sin_quarter_q15 = 16'sd1567;
            6'd9:  sin_quarter_q15 = 16'sd1751;
            6'd10: sin_quarter_q15 = 16'sd1931;
            6'd11: sin_quarter_q15 = 16'sd2106;
            6'd12: sin_quarter_q15 = 16'sd2276;
            6'd13: sin_quarter_q15 = 16'sd2440;
            6'd14: sin_quarter_q15 = 16'sd2598;
            6'd15: sin_quarter_q15 = 16'sd2751;
            6'd16: sin_quarter_q15 = 16'sd2896;
            6'd17: sin_quarter_q15 = 16'sd3035;
            6'd18: sin_quarter_q15 = 16'sd3166;
            6'd19: sin_quarter_q15 = 16'sd3290;
            6'd20: sin_quarter_q15 = 16'sd3406;
            6'd21: sin_quarter_q15 = 16'sd3513;
            6'd22: sin_quarter_q15 = 16'sd3612;
            6'd23: sin_quarter_q15 = 16'sd3703;
            6'd24: sin_quarter_q15 = 16'sd3784;
            6'd25: sin_quarter_q15 = 16'sd3857;
            6'd26: sin_quarter_q15 = 16'sd3920;
            6'd27: sin_quarter_q15 = 16'sd3973;
            6'd28: sin_quarter_q15 = 16'sd4017;
            6'd29: sin_quarter_q15 = 16'sd4052;
            6'd30: sin_quarter_q15 = 16'sd4076;
            6'd31: sin_quarter_q15 = 16'sd4091;
            default: sin_quarter_q15 = 16'sd4096;
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
    input ifft_mode;
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
