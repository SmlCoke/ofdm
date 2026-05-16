# Vivado batch synthesis script for the 128-point FFT/IFFT RTL.
# Usage:
#   vivado -mode batch -source syn/scripts/run_vivado_synth.tcl

set script_dir [file dirname [file normalize [info script]]]
set repo_root [file normalize [file join $script_dir ../..]]
set report_dir [file join $repo_root syn reports]
file mkdir $report_dir

set part_name xcku040-ffva1156-2-e
set top_name fft_ifft_top

read_verilog [file join $repo_root src rtl fft_ifft_top.v]
read_xdc [file join $repo_root syn sdc fft_ifft_top.xdc]

synth_design -top $top_name -part $part_name
opt_design
place_design
route_design

report_timing_summary -delay_type max -max_paths 10 -file [file join $report_dir timing_summary.rpt]
report_utilization -file [file join $report_dir utilization.rpt]
report_power -file [file join $report_dir power.rpt]
report_clock_utilization -file [file join $report_dir clock_utilization.rpt]

set timing_paths [get_timing_paths -max_paths 1 -delay_type max]
set wns [get_property SLACK [lindex $timing_paths 0]]
set delay [get_property DATAPATH_DELAY [lindex $timing_paths 0]]

proc extract_util {report_text label} {
    set pattern "\\|[ ]*$label[ ]*\\|[ ]*([0-9]+)[ ]*\\|"
    if {[regexp $pattern $report_text -> value]} {
        return $value
    }
    return 0
}

set util_text [report_utilization -return_string]
set util_luts [extract_util $util_text "Slice LUTs"]
set util_ffs  [extract_util $util_text "Slice Registers"]
set util_dsp  [extract_util $util_text "DSPs"]

set clk_period_ns 10.0
if {$wns ne ""} {
    set fmax_mhz [expr {1000.0 / ($clk_period_ns - $wns)}]
} else {
    set fmax_mhz [expr {1000.0 / $clk_period_ns}]
}

# Current RTL latency model:
# load 128 cycles + 448 butterfly cycles + output 128 cycles = 704 cycles.
set process_cycles 704
set output_bits [expr {128 * 32}]
set throughput_mbps [expr {$output_bits * $fmax_mhz / $process_cycles}]
set efficiency [expr {$throughput_mbps / double($util_luts + $util_ffs + $util_dsp * 280)}]

set fp [open [file join $report_dir summary.txt] w]
puts $fp "FFT/IFFT Vivado Synthesis Summary"
puts $fp "Part: $part_name (KCU105 compatible Kintex UltraScale)"
puts $fp "Clock period constraint: ${clk_period_ns} ns"
puts $fp "WNS: $wns ns"
puts $fp "Critical datapath delay: $delay ns"
puts $fp "Estimated Fmax: $fmax_mhz MHz"
puts $fp "Process cycles per 128-point transform: $process_cycles"
puts $fp "Latency at constrained 100 MHz: [expr {$process_cycles * $clk_period_ns / 1000.0}] us"
puts $fp "Throughput: $throughput_mbps Mbps"
puts $fp "LUTs: $util_luts"
puts $fp "FFs: $util_ffs"
puts $fp "DSPs: $util_dsp"
puts $fp "Hardware efficiency: $efficiency Mbps/resource_unit"
close $fp

write_checkpoint -force [file join $report_dir fft_ifft_top_routed.dcp]
