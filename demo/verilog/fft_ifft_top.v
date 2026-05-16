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

endmodule