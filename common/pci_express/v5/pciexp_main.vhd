-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 31.01.2011 9:54:18
-- Module Name : pciexp_main.vhd
--
-- Description : ����� ����� ���������� Endpoint PCI-Express � ����� PCI-Express.
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

library work;
use work.prj_cfg.all;

entity pciexp_main is
--generic(
--);
port
(
--//-------------------------------------------------------
--// User Port
--//-------------------------------------------------------
p_out_usr_tst              : out   std_logic_vector(127 downto 0);
p_in_usr_tst               : in    std_logic_vector(127 downto 0);

p_out_host_clk_out         : out   std_logic;
p_out_glob_ctrl            : out   std_logic_vector(31 downto 0);

p_out_dev_ctrl             : out   std_logic_vector(31 downto 0);
p_out_dev_din              : out   std_logic_vector(31 downto 0);
p_in_dev_dout              : in    std_logic_vector(31 downto 0);
p_out_dev_wd               : out   std_logic;
p_out_dev_rd               : out   std_logic;
p_in_dev_fifoflag          : in    std_logic_vector(7 downto 0);
p_in_dev_status            : in    std_logic_vector(31 downto 0);
p_in_dev_irq               : in    std_logic_vector(31 downto 0);
p_in_dev_option            : in    std_logic_vector(127 downto 0);

p_out_mem_ctl_reg          : out   std_logic_vector(0 downto 0);
p_out_mem_mode_reg         : out   std_logic_vector(511 downto 0);
p_in_mem_locked            : in    std_logic_vector(7 downto 0);
p_in_mem_trained           : in    std_logic_vector(15 downto 0);

p_out_mem_bank1h           : out   std_logic_vector(15 downto 0);
p_out_mem_adr              : out   std_logic_vector(34 downto 0);
p_out_mem_ce               : out   std_logic;
p_out_mem_cw               : out   std_logic;
p_out_mem_rd               : out   std_logic;
p_out_mem_wr               : out   std_logic;
p_out_mem_be               : out   std_logic_vector(7 downto 0);
p_out_mem_term             : out   std_logic;
p_out_mem_din              : out   std_logic_vector(31 downto 0);
p_in_mem_dout              : in    std_logic_vector(31 downto 0);

p_in_mem_wf                : in    std_logic;
p_in_mem_wpf               : in    std_logic;
p_in_mem_re                : in    std_logic;
p_in_mem_rpe               : in    std_logic;

--//-------------------------------------------------------
--// System Port
--//-------------------------------------------------------
p_in_fast_simulation       : in    std_logic;

p_out_pciexp_txp           : out   std_logic_vector(C_PCIEXPRESS_LINK_WIDTH-1 downto 0);
p_out_pciexp_txn           : out   std_logic_vector(C_PCIEXPRESS_LINK_WIDTH-1 downto 0);
p_in_pciexp_rxp            : in    std_logic_vector(C_PCIEXPRESS_LINK_WIDTH-1 downto 0);
p_in_pciexp_rxn            : in    std_logic_vector(C_PCIEXPRESS_LINK_WIDTH-1 downto 0);

p_in_pciexp_rst            : in    std_logic;

p_out_module_rdy           : out   std_logic;
p_in_gtp_refclkin          : in    std_logic;
p_out_gtp_refclkout        : out   std_logic
);
end pciexp_main;

architecture behavioral of pciexp_main is

constant GI_PCI_EXP_TRN_DATA_WIDTH       : integer:= 64;
constant GI_PCI_EXP_TRN_REM_WIDTH        : integer:= 8;
constant GI_PCI_EXP_TRN_BUF_AV_WIDTH     : integer:= 4;
constant GI_PCI_EXP_BAR_HIT_WIDTH        : integer:= 7;
constant GI_PCI_EXP_FC_HDR_WIDTH         : integer:= 8;
constant GI_PCI_EXP_FC_DATA_WIDTH        : integer:= 12;
constant GI_PCI_EXP_CFG_DATA_WIDTH       : integer:= 32;
constant GI_PCI_EXP_CFG_ADDR_WIDTH       : integer:= 10;
constant GI_PCI_EXP_CFG_CPLHDR_WIDTH     : integer:= 48;
constant GI_PCI_EXP_CFG_BUSNUM_WIDTH     : integer:= 8;
constant GI_PCI_EXP_CFG_DEVNUM_WIDTH     : integer:= 5;
constant GI_PCI_EXP_CFG_FUNNUM_WIDTH     : integer:= 3;
constant GI_PCI_EXP_CFG_CAP_WIDTH        : integer:= 16;

component core_pciexp_ep_blk_plus
port
(
--// PCI Express Fabric Interface
pci_exp_txp                   : out   std_logic_vector(C_PCIEXPRESS_LINK_WIDTH-1 downto 0);
pci_exp_txn                   : out   std_logic_vector(C_PCIEXPRESS_LINK_WIDTH-1 downto 0);
pci_exp_rxp                   : in    std_logic_vector(C_PCIEXPRESS_LINK_WIDTH-1 downto 0);
pci_exp_rxn                   : in    std_logic_vector(C_PCIEXPRESS_LINK_WIDTH-1 downto 0);


--// Transaction (TRN) Interface
trn_clk                       : out   std_logic;
trn_reset_n                   : out   std_logic;
trn_lnk_up_n                  : out   std_logic;

--// Tx
trn_td                        : in    std_logic_vector(GI_PCI_EXP_TRN_DATA_WIDTH-1 downto 0);
trn_trem_n                    : in    std_logic_vector(GI_PCI_EXP_TRN_REM_WIDTH-1 downto 0);
trn_tsof_n                    : in    std_logic;
trn_teof_n                    : in    std_logic;
trn_tsrc_rdy_n                : in    std_logic;
trn_tdst_rdy_n                : out   std_logic;
trn_tdst_dsc_n                : out   std_logic;
trn_tsrc_dsc_n                : in    std_logic;
trn_terrfwd_n                 : in    std_logic;
trn_tbuf_av                   : out   std_logic_vector(GI_PCI_EXP_TRN_BUF_AV_WIDTH-1 downto 0);


--// Rx
trn_rd                        : out   std_logic_vector(GI_PCI_EXP_TRN_DATA_WIDTH-1 downto 0);
trn_rrem_n                    : out   std_logic_vector(GI_PCI_EXP_TRN_REM_WIDTH-1 downto 0);
trn_rsof_n                    : out   std_logic;
trn_reof_n                    : out   std_logic;
trn_rsrc_rdy_n                : out   std_logic;
trn_rsrc_dsc_n                : out   std_logic;
trn_rdst_rdy_n                : in    std_logic;
trn_rerrfwd_n                 : out   std_logic;
trn_rnp_ok_n                  : in    std_logic;
trn_rbar_hit_n                : out   std_logic_vector(GI_PCI_EXP_BAR_HIT_WIDTH-1 downto 0);
trn_rfc_nph_av                : out   std_logic_vector(GI_PCI_EXP_FC_HDR_WIDTH-1 downto 0);
trn_rfc_npd_av                : out   std_logic_vector(GI_PCI_EXP_FC_DATA_WIDTH-1 downto 0);
trn_rfc_ph_av                 : out   std_logic_vector(GI_PCI_EXP_FC_HDR_WIDTH-1 downto 0);
trn_rfc_pd_av                 : out   std_logic_vector(GI_PCI_EXP_FC_DATA_WIDTH-1 downto 0);
trn_rcpl_streaming_n          : in    std_logic;


--// Host (CFG) Interface
cfg_do                        : out   std_logic_vector(GI_PCI_EXP_CFG_DATA_WIDTH-1 downto 0);
cfg_rd_wr_done_n              : out   std_logic;
cfg_di                        : in    std_logic_vector(GI_PCI_EXP_CFG_DATA_WIDTH-1 downto 0);
cfg_byte_en_n                 : in    std_logic_vector(GI_PCI_EXP_CFG_DATA_WIDTH/8-1 downto 0);
cfg_dwaddr                    : in    std_logic_vector(GI_PCI_EXP_CFG_ADDR_WIDTH-1 downto 0);
cfg_wr_en_n                   : in    std_logic;
cfg_rd_en_n                   : in    std_logic;
cfg_err_cor_n                 : in    std_logic;
cfg_err_ur_n                  : in    std_logic;
cfg_err_ecrc_n                : in    std_logic;
cfg_err_cpl_timeout_n         : in    std_logic;
cfg_err_cpl_abort_n           : in    std_logic;
cfg_err_cpl_unexpect_n        : in    std_logic;
cfg_err_posted_n              : in    std_logic;
cfg_err_tlp_cpl_header        : in    std_logic_vector(GI_PCI_EXP_CFG_CPLHDR_WIDTH-1 downto 0);

cfg_err_cpl_rdy_n             : out   std_logic;
cfg_err_locked_n              : in    std_logic;
cfg_interrupt_n               : in    std_logic;
cfg_interrupt_rdy_n           : out   std_logic;
cfg_interrupt_assert_n        : in    std_logic;
cfg_interrupt_di              : in    std_logic_vector(7 downto 0);
cfg_interrupt_do              : out   std_logic_vector(7 downto 0);
cfg_interrupt_mmenable        : out   std_logic_vector(2 downto 0);
cfg_interrupt_msienable       : out   std_logic;
cfg_to_turnoff_n              : out   std_logic;
cfg_pm_wake_n                 : in    std_logic;
cfg_pcie_link_state_n         : out   std_logic_vector(2 downto 0);
cfg_trn_pending_n             : in    std_logic;
cfg_bus_number                : out   std_logic_vector(GI_PCI_EXP_CFG_BUSNUM_WIDTH-1 downto 0);
cfg_device_number             : out   std_logic_vector(GI_PCI_EXP_CFG_DEVNUM_WIDTH-1 downto 0);
cfg_function_number           : out   std_logic_vector(GI_PCI_EXP_CFG_FUNNUM_WIDTH-1 downto 0);
cfg_dsn                       : in    std_logic_vector(63 downto 0);
cfg_status                    : out   std_logic_vector(GI_PCI_EXP_CFG_CAP_WIDTH-1 downto 0);
cfg_command                   : out   std_logic_vector(GI_PCI_EXP_CFG_CAP_WIDTH-1 downto 0);
cfg_dstatus                   : out   std_logic_vector(GI_PCI_EXP_CFG_CAP_WIDTH-1 downto 0);
cfg_dcommand                  : out   std_logic_vector(GI_PCI_EXP_CFG_CAP_WIDTH-1 downto 0);
cfg_lstatus                   : out   std_logic_vector(GI_PCI_EXP_CFG_CAP_WIDTH-1 downto 0);
cfg_lcommand                  : out   std_logic_vector(GI_PCI_EXP_CFG_CAP_WIDTH-1 downto 0);
fast_train_simulation_only    : in    std_logic;

--// System (SYS) Interface
sys_clk                       : in    std_logic;
--//sys_clk_n                     : in  std_logic;
refclkout                     : out   std_logic;
sys_reset_n                   : in    std_logic
);
end component;


component pciexp_ep_cntrl
port
(
--//------------------------------------
--// Port Declarations
--//------------------------------------
--//���������������� ����
p_out_host_clk_out                 : out   std_logic;

p_out_usr_tst                      : out   std_logic_vector(127 downto 0);
p_in_usr_tst                       : in    std_logic_vector(127 downto 0);

p_out_glob_ctrl                    : out   std_logic_vector(31 downto 0);
p_out_dev_ctrl                     : out   std_logic_vector(31 downto 0);
p_out_dev_din                      : out   std_logic_vector(31 downto 0);
p_in_dev_dout                      : in    std_logic_vector(31 downto 0);
p_out_dev_wd                       : out   std_logic;
p_out_dev_rd                       : out   std_logic;
p_in_dev_fifoflag                  : in    std_logic_vector(7 downto 0);
p_in_dev_status                    : in    std_logic_vector(31 downto 0);
p_in_dev_irq                       : in    std_logic_vector(31 downto 0);
p_in_dev_option                    : in    std_logic_vector(127 downto 0);

p_out_mem_ctl_reg                  : out   std_logic_vector(0 downto 0);
p_out_mem_mode_reg                 : out   std_logic_vector(511 downto 0);
p_in_mem_locked                    : in    std_logic_vector(7 downto 0);
p_in_mem_trained                   : in    std_logic_vector(15 downto 0);

p_out_mem_bank1h                   : out   std_logic_vector(15 downto 0);
p_out_mem_adr                      : out   std_logic_vector(34 downto 0);
p_out_mem_ce                       : out   std_logic;
p_out_mem_cw                       : out   std_logic;
p_out_mem_rd                       : out   std_logic;
p_out_mem_wr                       : out   std_logic;
p_out_mem_be                       : out   std_logic_vector(7 downto 0);
p_out_mem_term                     : out   std_logic;
p_out_mem_din                      : out   std_logic_vector(31 downto 0);
p_in_mem_dout                      : in    std_logic_vector(31 downto 0);

p_in_mem_wf                        : in    std_logic;
p_in_mem_wpf                       : in    std_logic;
p_in_mem_re                        : in    std_logic;
p_in_mem_rpe                       : in    std_logic;


init_rst_o                         : out   std_logic;


--// LocalLink Tx
trn_td_o                           : out   std_logic_vector(63 downto 0);
trn_trem_n_o                       : out   std_logic_vector(7 downto 0);
trn_tsof_n_o                       : out   std_logic;
trn_teof_n_o                       : out   std_logic;
trn_tsrc_rdy_n_o                   : out   std_logic;
trn_tdst_rdy_n_i                   : in    std_logic;
trn_tsrc_dsc_n_o                   : out   std_logic;
trn_tdst_dsc_n_i                   : in    std_logic;
trn_terrfwd_n_o                    : out   std_logic;
trn_tbuf_av_i                      : in    std_logic_vector(5 downto 0);

--// LocalLink Rx
trn_rd_i                           : in    std_logic_vector(63 downto 0);
trn_rrem_n_i                       : in    std_logic_vector(7 downto 0);
trn_rsof_n_i                       : in    std_logic;
trn_reof_n_i                       : in    std_logic;
trn_rsrc_rdy_n_i                   : in    std_logic;
trn_rsrc_dsc_n_i                   : in    std_logic;
trn_rdst_rdy_n_o                   : out   std_logic;
trn_rerrfwd_n_i                    : in    std_logic;
trn_rnp_ok_n_o                     : out   std_logic;

trn_rbar_hit_n_i                   : in    std_logic_vector(6 downto 0);
trn_rfc_nph_av_i                   : in    std_logic_vector(7 downto 0);
trn_rfc_npd_av_i                   : in    std_logic_vector(11 downto 0);
trn_rfc_ph_av_i                    : in    std_logic_vector(7 downto 0);
trn_rfc_pd_av_i                    : in    std_logic_vector(11 downto 0);
--//trn_rfc_cplh_av_i                : in    std_logic_vector((`PCI_EXP_TRN_FC_HDR_WIDTH - 1) downto 0);
--//trn_rfc_cpld_av_i                : in    std_logic_vector((`PCI_EXP_TRN_FC_DATA_WIDTH - 1) downto 0);
trn_rcpl_streaming_n_o             : out   std_logic;

--// Transaction ( TRN ) Interface
trn_lnk_up_n_i                     : in    std_logic;
trn_reset_n_i                      : in    std_logic;
trn_clk_i                          : in    std_logic;

--// Host ( CFG ) Interface
cfg_turnoff_ok_n_o                 : out   std_logic;
cfg_to_turnoff_n_i                 : in    std_logic;

cfg_interrupt_n_o                  : out   std_logic;
cfg_interrupt_rdy_n_i              : in    std_logic;
cfg_interrupt_assert_n_o           : out   std_logic;
cfg_interrupt_di_o                 : out   std_logic_vector(7 downto 0);
cfg_interrupt_do_i                 : in    std_logic_vector(7 downto 0);
cfg_interrupt_msienable_i          : in    std_logic;
cfg_interrupt_mmenable_i           : in    std_logic_vector(2 downto 0);

cfg_do_i                           : in    std_logic_vector(31 downto 0);
cfg_di_o                           : out   std_logic_vector(31 downto 0);
cfg_dwaddr_o                       : out   std_logic_vector(9 downto 0);
cfg_byte_en_n_o                    : out   std_logic_vector(3 downto 0);
cfg_wr_en_n_o                      : out   std_logic;
cfg_rd_en_n_o                      : out   std_logic;
cfg_rd_wr_done_n_i                 : in    std_logic;

cfg_err_tlp_cpl_header_o           : out   std_logic_vector(47 downto 0);
cfg_err_ecrc_n_o                   : out   std_logic;
cfg_err_ur_n_o                     : out   std_logic;
cfg_err_cpl_timeout_n_o            : out   std_logic;
cfg_err_cpl_unexpect_n_o           : out   std_logic;
cfg_err_cpl_abort_n_o              : out   std_logic;
cfg_err_posted_n_o                 : out   std_logic;
cfg_err_cor_n_o                    : out   std_logic;

cfg_pm_wake_n_o                    : out   std_logic;
cfg_trn_pending_n_o                : out   std_logic;
cfg_dsn_o                          : out   std_logic_vector(63 downto 0);
cfg_pcie_link_state_n_i            : in    std_logic_vector(2 downto 0);
cfg_bus_number_i                   : in    std_logic_vector(7 downto 0);
cfg_device_number_i                : in    std_logic_vector(4 downto 0);
cfg_function_number_i              : in    std_logic_vector(2 downto 0);
cfg_status_i                       : in    std_logic_vector(15 downto 0);
cfg_command_i                      : in    std_logic_vector(15 downto 0);
cfg_dstatus_i                      : in    std_logic_vector(15 downto 0);
cfg_dcommand_i                     : in    std_logic_vector(15 downto 0);
cfg_lstatus_i                      : in    std_logic_vector(15 downto 0);
cfg_lcommand_i                     : in    std_logic_vector(15 downto 0)
);
end component;


component pciexp_ctrl_rst
port
(
pciexp_refclk_i    : in    std_logic;
trn_lnk_up_n_i     : in    std_logic;
sys_reset_n_o      : out   std_logic;
module_rdy_o       : out   std_logic
);
end component;



signal from_ctrl_rst_n                     : std_logic;

signal refclkout                           : std_logic;

signal sys_reset_n                         : std_logic;
signal trn_clk                             : std_logic;-- //synthesis attribute max_fanout of trn_clk is "100000"
signal trn_reset_n                         : std_logic;
signal trn_lnk_up_n                        : std_logic;

signal trn_tsof_n                          : std_logic;
signal trn_teof_n                          : std_logic;
signal trn_tsrc_rdy_n                      : std_logic;
signal trn_tdst_rdy_n                      : std_logic;
signal trn_tsrc_dsc_n                      : std_logic;
signal trn_terrfwd_n                       : std_logic;
signal trn_tdst_dsc_n                      : std_logic;
signal trn_td                              : std_logic_vector(GI_PCI_EXP_TRN_DATA_WIDTH-1 downto 0);--(63 downto 0);
signal trn_trem_n                          : std_logic_vector(GI_PCI_EXP_TRN_REM_WIDTH-1 downto 0);--(7 downto 0);
signal trn_tbuf_av                         : std_logic_vector(GI_PCI_EXP_TRN_BUF_AV_WIDTH-1 downto 0);--(3 downto 0);

signal trn_rsof_n                          : std_logic;
signal trn_reof_n                          : std_logic;
signal trn_rsrc_rdy_n                      : std_logic;
signal trn_rsrc_dsc_n                      : std_logic;
signal trn_rdst_rdy_n                      : std_logic;
signal trn_rerrfwd_n                       : std_logic;
signal trn_rnp_ok_n                        : std_logic;
signal trn_rd                              : std_logic_vector(GI_PCI_EXP_TRN_DATA_WIDTH-1 downto 0);--(63 downto 0);
signal trn_rrem_n                          : std_logic_vector(GI_PCI_EXP_TRN_REM_WIDTH-1 downto 0);--(7 downto 0);
signal trn_rbar_hit_n                      : std_logic_vector(GI_PCI_EXP_BAR_HIT_WIDTH-1 downto 0);--(6 downto 0);
signal trn_rfc_nph_av                      : std_logic_vector(GI_PCI_EXP_FC_HDR_WIDTH-1 downto 0);--(7 downto 0);
signal trn_rfc_npd_av                      : std_logic_vector(GI_PCI_EXP_FC_DATA_WIDTH-1 downto 0);--(11 downto 0);
signal trn_rfc_ph_av                       : std_logic_vector(GI_PCI_EXP_FC_HDR_WIDTH-1 downto 0);--(7 downto 0);
signal trn_rfc_pd_av                       : std_logic_vector(GI_PCI_EXP_FC_DATA_WIDTH-1 downto 0);--(11 downto 0);
signal trn_rcpl_streaming_n                : std_logic;

signal cfg_do                              : std_logic_vector(GI_PCI_EXP_CFG_DATA_WIDTH-1 downto 0);--(31 downto 0);
signal cfg_di                              : std_logic_vector(GI_PCI_EXP_CFG_DATA_WIDTH-1 downto 0);--(31 downto 0);
signal cfg_dwaddr                          : std_logic_vector(GI_PCI_EXP_CFG_ADDR_WIDTH-1 downto 0);--(9 downto 0);
signal cfg_byte_en_n                       : std_logic_vector(GI_PCI_EXP_CFG_DATA_WIDTH/8-1 downto 0);--(3 downto 0);
signal cfg_wr_en_n                         : std_logic;
signal cfg_rd_en_n                         : std_logic;
signal cfg_rd_wr_done_n                    : std_logic;

signal cfg_err_tlp_cpl_header              : std_logic_vector(GI_PCI_EXP_CFG_CPLHDR_WIDTH-1 downto 0);--47 downto 0);
signal cfg_err_cor_n                       : std_logic;
signal cfg_err_ur_n                        : std_logic;
signal cfg_err_cpl_rdy_n                   : std_logic;
signal cfg_err_ecrc_n                      : std_logic;
signal cfg_err_cpl_timeout_n               : std_logic;
signal cfg_err_cpl_abort_n                 : std_logic;
signal cfg_err_cpl_unexpect_n              : std_logic;
signal cfg_err_posted_n                    : std_logic;
signal cfg_err_locked_n                    : std_logic;

signal cfg_interrupt_n                     : std_logic;
signal cfg_interrupt_rdy_n                 : std_logic;
signal cfg_interrupt_assert_n              : std_logic;
signal cfg_interrupt_di                    : std_logic_vector(7 downto 0);
signal cfg_interrupt_do                    : std_logic_vector(7 downto 0);
signal cfg_interrupt_mmenable              : std_logic_vector(2 downto 0);
signal cfg_interrupt_msienable             : std_logic;

--//signal cfg_turnoff_ok_n                    : std_logic;
signal cfg_to_turnoff_n                    : std_logic;
signal cfg_pm_wake_n                       : std_logic;
signal cfg_trn_pending_n                   : std_logic;
signal cfg_dsn                             : std_logic_vector(63 downto 0);

signal cfg_pcie_link_state_n               : std_logic_vector(2 downto 0);
signal cfg_bus_number                      : std_logic_vector(GI_PCI_EXP_CFG_BUSNUM_WIDTH-1 downto 0);--(7 downto 0);
signal cfg_device_number                   : std_logic_vector(GI_PCI_EXP_CFG_DEVNUM_WIDTH-1 downto 0);--(4 downto 0);
signal cfg_function_number                 : std_logic_vector(GI_PCI_EXP_CFG_FUNNUM_WIDTH-1 downto 0);--(2 downto 0);
signal cfg_status                          : std_logic_vector(GI_PCI_EXP_CFG_CAP_WIDTH-1 downto 0);--(15 downto 0);
signal cfg_command                         : std_logic_vector(GI_PCI_EXP_CFG_CAP_WIDTH-1 downto 0);--(15 downto 0);
signal cfg_dstatus                         : std_logic_vector(GI_PCI_EXP_CFG_CAP_WIDTH-1 downto 0);--(15 downto 0);
signal cfg_dcommand                        : std_logic_vector(GI_PCI_EXP_CFG_CAP_WIDTH-1 downto 0);--(15 downto 0);
signal cfg_lstatus                         : std_logic_vector(GI_PCI_EXP_CFG_CAP_WIDTH-1 downto 0);--(15 downto 0);
signal cfg_lcommand                        : std_logic_vector(GI_PCI_EXP_CFG_CAP_WIDTH-1 downto 0);--(15 downto 0);

signal user_trn_tbuf_av                    : std_logic_vector(5 downto 0);--(15 downto 0);

--//MAIN
begin


--//----------------------------------------------------------------------
--//������ ���� PCI-Express
--//----------------------------------------------------------------------
m_core_pciexp : core_pciexp_ep_blk_plus
port map
(
--// PCI Express Fabric Interface
pci_exp_txp                   => p_out_pciexp_txp,
pci_exp_txn                   => p_out_pciexp_txn,
pci_exp_rxp                   => p_in_pciexp_rxp,
pci_exp_rxn                   => p_in_pciexp_rxn,


--// Transaction (TRN) Interface
trn_clk                       => trn_clk,
trn_reset_n                   => trn_reset_n,
trn_lnk_up_n                  => trn_lnk_up_n,

--// Tx
trn_td                        => trn_td,
trn_trem_n                    => trn_trem_n,
trn_tsof_n                    => trn_tsof_n,
trn_teof_n                    => trn_teof_n,
trn_tsrc_rdy_n                => trn_tsrc_rdy_n,
trn_tdst_rdy_n                => trn_tdst_rdy_n,
trn_tdst_dsc_n                => trn_tdst_dsc_n,
trn_tsrc_dsc_n                => trn_tsrc_dsc_n,
trn_terrfwd_n                 => trn_terrfwd_n,
trn_tbuf_av                   => trn_tbuf_av,


--// Rx
trn_rd                        => trn_rd,
trn_rrem_n                    => trn_rrem_n,
trn_rsof_n                    => trn_rsof_n,
trn_reof_n                    => trn_reof_n,
trn_rsrc_rdy_n                => trn_rsrc_rdy_n,
trn_rsrc_dsc_n                => trn_rsrc_dsc_n,
trn_rdst_rdy_n                => trn_rdst_rdy_n,
trn_rerrfwd_n                 => trn_rerrfwd_n,
trn_rnp_ok_n                  => trn_rnp_ok_n,
trn_rbar_hit_n                => trn_rbar_hit_n,
trn_rfc_nph_av                => trn_rfc_nph_av,
trn_rfc_npd_av                => trn_rfc_npd_av,
trn_rfc_ph_av                 => trn_rfc_ph_av,
trn_rfc_pd_av                 => trn_rfc_pd_av,
trn_rcpl_streaming_n          => trn_rcpl_streaming_n,


--// Host (CFG) Interface
cfg_do                        => cfg_do,
cfg_rd_wr_done_n              => cfg_rd_wr_done_n,
cfg_di                        => cfg_di,
cfg_byte_en_n                 => cfg_byte_en_n,
cfg_dwaddr                    => cfg_dwaddr,
cfg_wr_en_n                   => cfg_wr_en_n,
cfg_rd_en_n                   => cfg_rd_en_n,
cfg_err_cor_n                 => cfg_err_cor_n,
cfg_err_ur_n                  => cfg_err_ur_n,
cfg_err_ecrc_n                => cfg_err_ecrc_n,
cfg_err_cpl_timeout_n         => cfg_err_cpl_timeout_n,
cfg_err_cpl_abort_n           => cfg_err_cpl_abort_n,
cfg_err_cpl_unexpect_n        => cfg_err_cpl_unexpect_n,
cfg_err_posted_n              => cfg_err_posted_n,
cfg_err_tlp_cpl_header        => cfg_err_tlp_cpl_header,

cfg_err_cpl_rdy_n             => cfg_err_cpl_rdy_n,
cfg_err_locked_n              => '1',--cfg_err_locked_n,
cfg_interrupt_n               => cfg_interrupt_n,
cfg_interrupt_rdy_n           => cfg_interrupt_rdy_n,
cfg_interrupt_assert_n        => cfg_interrupt_assert_n,
cfg_interrupt_di              => cfg_interrupt_di,
cfg_interrupt_do              => cfg_interrupt_do,
cfg_interrupt_mmenable        => cfg_interrupt_mmenable,
cfg_interrupt_msienable       => cfg_interrupt_msienable,
cfg_to_turnoff_n              => cfg_to_turnoff_n,
cfg_pm_wake_n                 => cfg_pm_wake_n,
cfg_pcie_link_state_n         => cfg_pcie_link_state_n,
cfg_trn_pending_n             => cfg_trn_pending_n,
cfg_bus_number                => cfg_bus_number,
cfg_device_number             => cfg_device_number,
cfg_function_number           => cfg_function_number,
cfg_dsn                       => cfg_dsn,
cfg_status                    => cfg_status,
cfg_command                   => cfg_command,
cfg_dstatus                   => cfg_dstatus,
cfg_dcommand                  => cfg_dcommand,
cfg_lstatus                   => cfg_lstatus,
cfg_lcommand                  => cfg_lcommand,
fast_train_simulation_only    => p_in_fast_simulation,--fast_train_simulation_only,

--// System (SYS) Interface
--//sys_clk_n                     : in  std_logic;
sys_clk                       => p_in_gtp_refclkin,
refclkout                     => refclkout,
sys_reset_n                   => sys_reset_n
);


--//---------------------------------------------
--//������ ���������� PCI-Express(��������� ����� PCI-Express+ ���. ���������������� ������)
--//---------------------------------------------
m_pciexp_ep_cntrl : pciexp_ep_cntrl
port map
(
--//------------------------------------
--// Port Declarations
--//------------------------------------
--//���������������� ����
p_out_host_clk_out            => p_out_host_clk_out,

p_out_usr_tst                 => p_out_usr_tst,
p_in_usr_tst                  => p_in_usr_tst,

p_out_glob_ctrl               => p_out_glob_ctrl,
p_out_dev_ctrl                => p_out_dev_ctrl,
p_out_dev_din                 => p_out_dev_din,
p_in_dev_dout                 => p_in_dev_dout,
p_out_dev_wd                  => p_out_dev_wd,
p_out_dev_rd                  => p_out_dev_rd,
p_in_dev_fifoflag             => p_in_dev_fifoflag,
p_in_dev_status               => p_in_dev_status,
p_in_dev_irq                  => p_in_dev_irq,
p_in_dev_option               => p_in_dev_option,

p_out_mem_ctl_reg             => p_out_mem_ctl_reg,
p_out_mem_mode_reg            => p_out_mem_mode_reg,
p_in_mem_locked               => p_in_mem_locked,
p_in_mem_trained              => p_in_mem_trained,

p_out_mem_bank1h              => p_out_mem_bank1h,
p_out_mem_adr                 => p_out_mem_adr,
p_out_mem_ce                  => p_out_mem_ce,
p_out_mem_cw                  => p_out_mem_cw,
p_out_mem_rd                  => p_out_mem_rd,
p_out_mem_wr                  => p_out_mem_wr,
p_out_mem_be                  => p_out_mem_be,
p_out_mem_term                => p_out_mem_term,
p_out_mem_din                 => p_out_mem_din,
p_in_mem_dout                 => p_in_mem_dout,

p_in_mem_wf                   => p_in_mem_wf,
p_in_mem_wpf                  => p_in_mem_wpf,
p_in_mem_re                   => p_in_mem_re,
p_in_mem_rpe                  => p_in_mem_rpe,


init_rst_o                    => open,


--// LocalLink Tx
trn_td_o                      => trn_td,
trn_trem_n_o                  => trn_trem_n,
trn_tsof_n_o                  => trn_tsof_n,
trn_teof_n_o                  => trn_teof_n,
trn_tsrc_rdy_n_o              => trn_tsrc_rdy_n,
trn_tdst_rdy_n_i              => trn_tdst_rdy_n,
trn_tsrc_dsc_n_o              => trn_tsrc_dsc_n,
trn_tdst_dsc_n_i              => trn_tdst_dsc_n,
trn_terrfwd_n_o               => trn_terrfwd_n,
trn_tbuf_av_i                 => user_trn_tbuf_av,

--// LocalLink Rx
trn_rd_i                      => trn_rd,
trn_rrem_n_i                  => trn_rrem_n,
trn_rsof_n_i                  => trn_rsof_n,
trn_reof_n_i                  => trn_reof_n,
trn_rsrc_rdy_n_i              => trn_rsrc_rdy_n,
trn_rsrc_dsc_n_i              => trn_rsrc_dsc_n,
trn_rdst_rdy_n_o              => trn_rdst_rdy_n,
trn_rerrfwd_n_i               => trn_rerrfwd_n,
trn_rnp_ok_n_o                => trn_rnp_ok_n,

trn_rbar_hit_n_i              => trn_rbar_hit_n,
trn_rfc_nph_av_i              => trn_rfc_nph_av,
trn_rfc_npd_av_i              => trn_rfc_npd_av,
trn_rfc_ph_av_i               => trn_rfc_ph_av,
trn_rfc_pd_av_i               => trn_rfc_pd_av,
--//trn_rfc_cplh_av_i           => trn_rfc_cplh_av,
--//trn_rfc_cpld_av_i           => trn_rfc_cpld_av,
trn_rcpl_streaming_n_o        => trn_rcpl_streaming_n,

--// Transaction ( TRN ) Interface
trn_lnk_up_n_i                => trn_lnk_up_n,
trn_reset_n_i                 => trn_reset_n,
trn_clk_i                     => trn_clk,

--// Host ( CFG ) Interface
cfg_turnoff_ok_n_o            => open, --cfg_turnoff_ok_n
cfg_to_turnoff_n_i            => cfg_to_turnoff_n,

cfg_interrupt_n_o             => cfg_interrupt_n,
cfg_interrupt_rdy_n_i         => cfg_interrupt_rdy_n,
cfg_interrupt_assert_n_o      => cfg_interrupt_assert_n,
cfg_interrupt_di_o            => cfg_interrupt_di,
cfg_interrupt_do_i            => cfg_interrupt_do,
cfg_interrupt_msienable_i     => cfg_interrupt_msienable,
cfg_interrupt_mmenable_i      => cfg_interrupt_mmenable,

cfg_do_i                      => cfg_do,
cfg_di_o                      => cfg_di,
cfg_dwaddr_o                  => cfg_dwaddr,
cfg_byte_en_n_o               => cfg_byte_en_n,
cfg_wr_en_n_o                 => cfg_wr_en_n,
cfg_rd_en_n_o                 => cfg_rd_en_n,
cfg_rd_wr_done_n_i            => cfg_rd_wr_done_n,

cfg_err_tlp_cpl_header_o      => cfg_err_tlp_cpl_header,
cfg_err_ecrc_n_o              => cfg_err_ecrc_n,
cfg_err_ur_n_o                => cfg_err_ur_n,
cfg_err_cpl_timeout_n_o       => cfg_err_cpl_timeout_n,
cfg_err_cpl_unexpect_n_o      => cfg_err_cpl_unexpect_n,
cfg_err_cpl_abort_n_o         => cfg_err_cpl_abort_n,
cfg_err_posted_n_o            => cfg_err_posted_n,
cfg_err_cor_n_o               => cfg_err_cor_n,

cfg_pm_wake_n_o               => cfg_pm_wake_n,
cfg_trn_pending_n_o           => cfg_trn_pending_n,
cfg_dsn_o                     => cfg_dsn,
cfg_pcie_link_state_n_i       => cfg_pcie_link_state_n,
cfg_bus_number_i              => cfg_bus_number,
cfg_device_number_i           => cfg_device_number,
cfg_function_number_i         => cfg_function_number,
cfg_status_i                  => cfg_status,
cfg_command_i                 => cfg_command,
cfg_dstatus_i                 => cfg_dstatus,
cfg_dcommand_i                => cfg_dcommand,
cfg_lstatus_i                 => cfg_lstatus,
cfg_lcommand_i                => cfg_lcommand
);


m_pciexp_rst : pciexp_ctrl_rst
port map
(
pciexp_refclk_i    => refclkout,
trn_lnk_up_n_i     => trn_lnk_up_n,
sys_reset_n_o      => from_ctrl_rst_n,
module_rdy_o       => p_out_module_rdy
);


user_trn_tbuf_av<=EXT(trn_tbuf_av, 6);

gen_rst0 : if C_PCIEXPRESS_RST_FROM_SLOT=1 generate
begin
sys_reset_n<=p_in_pciexp_rst;
end generate gen_rst0;

gen_rst1 : if C_PCIEXPRESS_RST_FROM_SLOT=0 generate
begin
sys_reset_n<=from_ctrl_rst_n;
end generate gen_rst1;

p_out_gtp_refclkout<=refclkout;

--END MAIN
end behavioral;

