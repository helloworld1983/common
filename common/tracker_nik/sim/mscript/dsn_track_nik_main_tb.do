## NOTE:  Do not edit this file.
## Autogenerated by ProjNav (creatfdo.tcl) on Mon Jan 26 12:17:18 ���������� ����� (����) 2009
##
vlib work

vcom "../../../../../lib_vicg/vicg_common_pkg.vhd"
vcom "../../vsobel_main.vhd"
vcom "../../core_gen/vsobel_fifo.vhd"
vcom "../../core_gen/vsobel_bram.vhd"
vcom "../../core_gen/vsobel_subsigned.vhd"
vcom "../Testbanch/vsobel_main_tb.vhd"
vsim -t 1ps   -lib work vsobel_main_tb
do vsobel_main_tb_wave.do
view wave
view structure
view signals
run 1000ns

