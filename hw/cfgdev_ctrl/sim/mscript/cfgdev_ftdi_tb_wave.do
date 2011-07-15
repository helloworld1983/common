onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider sim
add wave -noupdate /cfgdev_ftdi_tb/p_in_rst
add wave -noupdate /cfgdev_ftdi_tb/p_in_clk
add wave -noupdate -radix hexadecimal /cfgdev_ftdi_tb/i_pkts
add wave -noupdate -radix hexadecimal /cfgdev_ftdi_tb/i_ftdi_d
add wave -noupdate /cfgdev_ftdi_tb/i_ftdi_rxf_n
add wave -noupdate /cfgdev_ftdi_tb/i_ftdi_rd_n
add wave -noupdate /cfgdev_ftdi_tb/i_ftdi_txe_n
add wave -noupdate /cfgdev_ftdi_tb/i_ftdi_wr_n
add wave -noupdate -divider m_devcfg
add wave -noupdate -color {Cornflower Blue} -itemcolor Gold /cfgdev_ftdi_tb/m_devcfg/fsm_state_cs
add wave -noupdate /cfgdev_ftdi_tb/m_devcfg/i_dv_oe
add wave -noupdate -radix hexadecimal /cfgdev_ftdi_tb/m_devcfg/i_dv_tmr
add wave -noupdate /cfgdev_ftdi_tb/m_devcfg/i_dv_tmr_en
add wave -noupdate /cfgdev_ftdi_tb/m_devcfg/i_dv_rxrdy
add wave -noupdate /cfgdev_ftdi_tb/m_devcfg/i_dv_txrdy
add wave -noupdate /cfgdev_ftdi_tb/m_devcfg/i_dv_rd
add wave -noupdate /cfgdev_ftdi_tb/m_devcfg/i_dv_wr
add wave -noupdate -radix unsigned /cfgdev_ftdi_tb/m_devcfg/i_cfg_dbyte
add wave -noupdate -radix hexadecimal /cfgdev_ftdi_tb/m_devcfg/i_cfg_d
add wave -noupdate -radix hexadecimal -expand -subitemconfig {/cfgdev_ftdi_tb/m_devcfg/i_pkt_dheader(0) {-height 15 -radix hexadecimal} /cfgdev_ftdi_tb/m_devcfg/i_pkt_dheader(1) {-height 15 -radix hexadecimal}} /cfgdev_ftdi_tb/m_devcfg/i_pkt_dheader
add wave -noupdate -radix hexadecimal /cfgdev_ftdi_tb/m_devcfg/i_cntd_pkt
add wave -noupdate /cfgdev_ftdi_tb/m_devcfg/i_flag_pktdata
add wave -noupdate -divider sim
add wave -noupdate -radix hexadecimal /cfgdev_ftdi_tb/i_cfg_adr
add wave -noupdate -radix hexadecimal /cfgdev_ftdi_tb/i_cfg_adr_cnt
add wave -noupdate -radix hexadecimal /cfgdev_ftdi_tb/i_cfg_adr_fifo
add wave -noupdate -radix hexadecimal /cfgdev_ftdi_tb/i_cfg_adr_ld
add wave -noupdate -radix hexadecimal /cfgdev_ftdi_tb/i_cfg_wd
add wave -noupdate -radix hexadecimal /cfgdev_ftdi_tb/i_cfg_rd
add wave -noupdate -radix hexadecimal /cfgdev_ftdi_tb/i_cfg_txdata
add wave -noupdate -radix hexadecimal /cfgdev_ftdi_tb/i_cfg_rxdata
add wave -noupdate -radix hexadecimal /cfgdev_ftdi_tb/i_reg0
add wave -noupdate -radix hexadecimal /cfgdev_ftdi_tb/i_reg1
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {15750 ns}
