set board [file dirname [file normalize [info script]]]
set root [file dirname $board]
create_project -name cc07_pmod -dir [file join $board gowin] -pn GW5A-LV25MG121NC1/I0 -device_version A -force
add_file [file join $root top_module.v]
add_file [file join $board src cc07_pmod.v]
add_file [file join $board constraints cc07_pmod.cst]
add_file [file join $board constraints cc07_pmod.sdc]
set_option -top_module cc07_pmod
set_option -verilog_std v2001
set_option -output_base_name cc07_pmod
set_option -gen_text_timing_rpt 1
set_option -use_cpu_as_gpio 1
set_option -use_sspi_as_gpio 1
run all
file mkdir [file join $board bitstream]
file copy -force [file join $board gowin cc07_pmod impl pnr cc07_pmod.fs] [file join $board bitstream cc07_pmod.fs]
