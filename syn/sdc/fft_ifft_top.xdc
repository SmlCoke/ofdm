create_clock -name clk -period 10.000 [get_ports clk]

set_input_delay  2.000 -clock clk [get_ports {mode data_in_re[*] data_in_im[*] data_in_valid}]
set_output_delay 2.000 -clock clk [get_ports {data_out_re[*] data_out_im[*] data_out_valid}]

set_false_path -from [get_ports rst_n]
