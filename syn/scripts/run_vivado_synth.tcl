# Vivado batch synthesis script for the 128-point FFT/IFFT RTL.
# Post-synthesis reports only (no place/route) for reasonable runtime on
# large inferred register memories.
#
# Usage:
#   vivado -mode batch -notrace -source syn/scripts/run_vivado_synth.tcl

set script_dir [file dirname [file normalize [info script]]]
set repo_root [file normalize [file join $script_dir ../..]]
set report_dir [file join $repo_root syn reports]
file mkdir $report_dir

set part_name xcku040-ffva1156-2-e
set top_name fft_ifft_top

read_verilog [file join $repo_root src rtl fft_ifft_top.v]
read_xdc [file join $repo_root syn sdc fft_ifft_top.xdc]

synth_design -top $top_name -part $part_name -flatten_hierarchy rebuilt -directive RuntimeOptimized

report_timing_summary -delay_type max -max_paths 10 -file [file join $report_dir timing_summary.rpt]
report_utilization -file [file join $report_dir utilization.rpt]
report_power -file [file join $report_dir power.rpt]
report_timing -max_paths 10 -file [file join $report_dir critical_paths.rpt]

set wns ""
set delay ""
set logic_levels ""
set timing_paths [get_timing_paths -max_paths 1 -nworst 1 -setup]
if {[llength $timing_paths] > 0} {
    set wns [get_property SLACK [lindex $timing_paths 0]]
    set delay [get_property DATAPATH_DELAY [lindex $timing_paths 0]]
    catch { set logic_levels [get_property LOGIC_LEVELS [lindex $timing_paths 0]] }
}

set util_text [report_utilization -return_string]
set util_luts 0
set util_ffs 0
set util_dsp 0
regexp {\|[ ]*CLB LUTs\*?[ ]*\|[ ]*([0-9]+)[ ]*\|} $util_text -> util_luts
regexp {\|[ ]*CLB Registers[ ]*\|[ ]*([0-9]+)[ ]*\|} $util_text -> util_ffs
regexp {\|[ ]*DSPs[ ]*\|[ ]*([0-9]+)[ ]*\|} $util_text -> util_dsp

set clk_period_ns 10.0
if {$wns ne "" && $wns ne "INF"} {
    set fmax_mhz [expr {1000.0 / ($clk_period_ns - $wns)}]
} else {
    set fmax_mhz [expr {1000.0 / $clk_period_ns}]
}

# RTL latency: 128 load + 112 calc (fixed 8-lane MDC, 2 cycles/substep) + 128 output = 368 cycles
set process_cycles 368
set output_bits [expr {128 * 32}]
set throughput_mbps [expr {$output_bits * $fmax_mhz / $process_cycles}]
set efficiency [expr {$throughput_mbps / double($util_luts + $util_ffs + $util_dsp * 280)}]
set latency_us_at_100m [expr {$process_cycles * $clk_period_ns / 1000.0}]
set latency_us_at_fmax [expr {$process_cycles / $fmax_mhz}]
set meets_80211n [expr {$latency_us_at_fmax <= 3.2}]

set fp [open [file join $report_dir summary.txt] w]
puts $fp "FFT/IFFT Vivado Synthesis Summary (post-synthesis estimates)"
puts $fp "Part: $part_name (KCU105 compatible Kintex UltraScale)"
puts $fp "Flow: synth_design only (no place/route)"
puts $fp "Clock period constraint: ${clk_period_ns} ns"
puts $fp "WNS (estimated): $wns ns"
puts $fp "Critical datapath delay (estimated): $delay ns"
puts $fp "Critical path logic levels (estimated): $logic_levels"
puts $fp "Estimated Fmax: $fmax_mhz MHz"
puts $fp "Process cycles per 128-point transform: $process_cycles"
puts $fp "Latency at 100 MHz: $latency_us_at_100m us"
puts $fp "Latency at estimated Fmax: $latency_us_at_fmax us"
puts $fp "Meets 3.2us requirement at estimated Fmax: $meets_80211n"
puts $fp "Throughput: $throughput_mbps Mbps"
puts $fp "LUTs: $util_luts"
puts $fp "FFs: $util_ffs"
puts $fp "DSPs: $util_dsp"
puts $fp "Hardware efficiency: $efficiency Mbps/resource_unit"
close $fp

write_checkpoint -force [file join $report_dir fft_ifft_top_synth.dcp]
