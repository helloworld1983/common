## NOTE:  Do not edit this file.
## Autogenerated by ProjNav (creatfdo.tcl) on Mon Jan 26 12:17:18 Московское время (зима) 2009
##
vlib work

vcom "../../../../lib/vicg/vicg_common_pkg.vhd"

vcom "../../core_gen/vgamma_bram_gray.vhd"
vcom "../../core_gen/vgamma_bram_rcol.vhd"
vcom "../../core_gen/vgamma_bram_gcol.vhd"
vcom "../../core_gen/vgamma_bram_bcol.vhd"
vcom "../../vgamma_main.vhd"

vcom "../testbanch/vgamma_main_tb.vhd"

vsim -t 1ps   -lib work vgamma_main_tb
do vgamma_main_tb_wave.do
view wave
view structure
view signals
run 1000ns

