## NOTE:  Do not edit this file.
## Autogenerated by ProjNav (creatfdo.tcl) on Mon Jan 26 12:17:18 ���������� ����� (����) 2009
##
vlib work


vcom -93 "../../../lib/vicg/vicg_common_pkg.vhd"
vcom -93 "../testbanch/prj_cfg_sim.vhd"

vcom "../../../../../../ml505/ise/src/core_gen//host_vbuf.vhd"

vcom -93 "../../src/eth_phypin_pkg.vhd"
vcom -93 "../../src/eth_pkg.vhd"
vcom -93 "../../src/eth_ip.vhd"

vcom -93 "../testbanch/eth_ip_tb.vhd"


vsim -t 1ps   -lib work eth_ip_tb
do eth_ip_wave.do
view wave
view structure
view signals
run 1000ns

