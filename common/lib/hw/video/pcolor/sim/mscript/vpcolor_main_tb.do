## NOTE:  Do not edit this file.
## Autogenerated by ProjNav (creatfdo.tcl) on Mon Jan 26 12:17:18 ���������� ����� (����) 2009
##
vlib work

vcom "../../../../lib/vicg/vicg_common_pkg.vhd"

vcom "../../core_gen/vpcolor_bbram.vhd"
vcom "../../core_gen/vpcolor_gbram.vhd"
vcom "../../core_gen/vpcolor_rbram.vhd"
vcom "../../core_gen/vpcolor_fifo.vhd"
vcom "../../vpcolor_main.vhd"

vcom "../testbanch/vpcolor_main_tb.vhd"
vsim -t 1ps   -lib work vpcolor_main_tb
do vpcolor_main_tb_wave.do
view wave
view structure
view signals
run 1000ns

