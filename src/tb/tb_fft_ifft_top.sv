`timescale 1ns/1ps

module tb_fft_ifft_top;
    localparam int N = 128;

    reg clk;
    reg rst_n;
    reg mode;
    reg [15:0] data_in_re;
    reg [15:0] data_in_im;
    reg data_in_valid;

    wire [15:0] data_out_re;
    wire [15:0] data_out_im;
    wire data_out_valid;

    reg [15:0] input_fft_re [0:N-1];
    reg [15:0] input_fft_im [0:N-1];
    reg [15:0] expected_fft_re [0:N-1];
    reg [15:0] expected_fft_im [0:N-1];
    reg [15:0] input_ifft_re [0:N-1];
    reg [15:0] input_ifft_im [0:N-1];
    reg [15:0] expected_ifft_re [0:N-1];
    reg [15:0] expected_ifft_im [0:N-1];

    string data_dir;
    int errors;

    fft_ifft_top dut (
        .clk(clk),
        .rst_n(rst_n),
        .mode(mode),
        .data_in_re(data_in_re),
        .data_in_im(data_in_im),
        .data_in_valid(data_in_valid),
        .data_out_re(data_out_re),
        .data_out_im(data_out_im),
        .data_out_valid(data_out_valid)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        if (!$value$plusargs("DATA_DIR=%s", data_dir)) begin
            data_dir = "src/data";
        end

        $readmemh({data_dir, "/input_fft_re.mem"}, input_fft_re);
        $readmemh({data_dir, "/input_fft_im.mem"}, input_fft_im);
        $readmemh({data_dir, "/expected_fft_re.mem"}, expected_fft_re);
        $readmemh({data_dir, "/expected_fft_im.mem"}, expected_fft_im);
        $readmemh({data_dir, "/input_ifft_re.mem"}, input_ifft_re);
        $readmemh({data_dir, "/input_ifft_im.mem"}, input_ifft_im);
        $readmemh({data_dir, "/expected_ifft_re.mem"}, expected_ifft_re);
        $readmemh({data_dir, "/expected_ifft_im.mem"}, expected_ifft_im);

        errors = 0;
        rst_n = 1'b0;
        mode = 1'b0;
        data_in_re = 16'd0;
        data_in_im = 16'd0;
        data_in_valid = 1'b0;
        repeat (5) @(posedge clk);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);

        run_case(1'b0, "FFT", input_fft_re, input_fft_im, expected_fft_re, expected_fft_im);
        repeat (16) @(posedge clk);
        run_case(1'b1, "IFFT", input_ifft_re, input_ifft_im, expected_ifft_re, expected_ifft_im);

        if (errors == 0) begin
            $display("PASS: FFT/IFFT RTL matches MATLAB fixed-point vectors.");
        end else begin
            $display("FAIL: total mismatches = %0d", errors);
        end
        $finish;
    end

    task automatic run_case(
        input bit case_mode,
        input string case_name,
        input reg [15:0] in_re [0:N-1],
        input reg [15:0] in_im [0:N-1],
        input reg [15:0] exp_re [0:N-1],
        input reg [15:0] exp_im [0:N-1]
    );
        int i;
        int out_idx;
        int timeout;
        begin
            $display("Running %s case...", case_name);
            mode = case_mode;

            for (i = 0; i < N; i = i + 1) begin
                @(posedge clk);
                data_in_valid <= 1'b1;
                data_in_re <= in_re[i];
                data_in_im <= in_im[i];
            end
            @(posedge clk);
            data_in_valid <= 1'b0;
            data_in_re <= 16'd0;
            data_in_im <= 16'd0;

            out_idx = 0;
            timeout = 0;
            while (out_idx < N && timeout < 2000) begin
                @(posedge clk);
                timeout = timeout + 1;
                if (data_out_valid) begin
                    if (abs_diff16(data_out_re, exp_re[out_idx]) > 1 ||
                        abs_diff16(data_out_im, exp_im[out_idx]) > 1) begin
                        $display(
                            "Mismatch %s[%0d]: got (%0d,%0d), expected (%0d,%0d)",
                            case_name,
                            out_idx,
                            $signed(data_out_re),
                            $signed(data_out_im),
                            $signed(exp_re[out_idx]),
                            $signed(exp_im[out_idx])
                        );
                        errors = errors + 1;
                    end
                    out_idx = out_idx + 1;
                end
            end

            if (out_idx != N) begin
                $display("Timeout waiting for %s outputs: got %0d samples", case_name, out_idx);
                errors = errors + 1;
            end else begin
                $display("%s case completed.", case_name);
            end
        end
    endtask

    function automatic int abs_diff16(input [15:0] a, input [15:0] b);
        int diff;
        begin
            diff = $signed(a) - $signed(b);
            if (diff < 0) begin
                abs_diff16 = -diff;
            end else begin
                abs_diff16 = diff;
            end
        end
    endfunction
endmodule
