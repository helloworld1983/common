-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 03/02/2010
-- Module Name : vereskm_main
--
-- ����������/�������� :
--
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

library unisim;
use unisim.vcomponents.all;

library work;
use work.vicg_common_pkg.all;
use work.prj_cfg.all;
use work.prj_def.all;
use work.memif.all;
use work.vereskm_pkg.all;
use work.cfgdev_pkg.all;
use work.mem_ctrl_pkg.all;
use work.mem_wr_pkg.all;
use work.sata_testgen_pkg.all;
--use work.sata_glob_pkg.all;
--use work.dsn_hdd_pkg.all;
use work.dsn_ethg_pkg.all;
use work.dsn_video_ctrl_pkg.all;
use work.pcie_pkg.all;

entity vereskm_main is
generic(
G_SIM_HOST : string:="OFF";
G_SIM_PCIE : std_logic:='0';
G_DBG_PCIE : string:="OFF";
G_SIM      : string:="OFF"
);
port(
--------------------------------------------------
--��������������� ����
--------------------------------------------------
pin_out_led       : out   std_logic_vector(7 downto 0);
pin_out_led_C     : out   std_logic;
pin_out_led_E     : out   std_logic;
pin_out_led_N     : out   std_logic;
pin_out_led_S     : out   std_logic;
pin_out_led_W     : out   std_logic;

pin_out_TP        : out   std_logic_vector(7 downto 0);

pin_in_btn_C      : in    std_logic;
pin_in_btn_E      : in    std_logic;
pin_in_btn_N      : in    std_logic;
pin_in_btn_S      : in    std_logic;
pin_in_btn_W      : in    std_logic;

pin_out_ddr2_cke1 : out   std_logic;
pin_out_ddr2_cs1  : out   std_logic;
pin_out_ddr2_odt1 : out   std_logic;

--------------------------------------------------
--Memory banks
--------------------------------------------------
ra0               : out   std_logic_vector(C_MEM_BANK0.ra_width - 1 downto 0);
rc0               : inout std_logic_vector(C_MEM_BANK0.rc_width - 1 downto 0);
rd0               : inout std_logic_vector(C_MEM_BANK0.rd_width - 1 downto 0);
--ra1               : out   std_logic_vector(C_MEM_BANK1.ra_width - 1 downto 0);
--rc1               : inout std_logic_vector(C_MEM_BANK1.rc_width - 1 downto 0);
--rd1               : inout std_logic_vector(C_MEM_BANK1.rd_width - 1 downto 0);

--------------------------------------------------
--Ethernet
--------------------------------------------------
pin_out_sfp_tx_dis    : out  std_logic;                      --//SFP - TX DISABLE
pin_in_sfp_sd         : in   std_logic;                      --//SFP - SD signal detect

pin_out_eth_txp       : out   std_logic_vector(1 downto 0);
pin_out_eth_txn       : out   std_logic_vector(1 downto 0);
pin_in_eth_rxp        : in    std_logic_vector(1 downto 0);
pin_in_eth_rxn        : in    std_logic_vector(1 downto 0);
pin_in_eth_clk_p      : in    std_logic;
pin_in_eth_clk_n      : in    std_logic;

pin_out_gt_X0Y6_txp   : out  std_logic_vector(1 downto 0);
pin_out_gt_X0Y6_txn   : out  std_logic_vector(1 downto 0);
pin_in_gt_X0Y6_rxp    : in   std_logic_vector(1 downto 0);
pin_in_gt_X0Y6_rxn    : in   std_logic_vector(1 downto 0);
pin_in_gt_X0Y6_clk_p  : in   std_logic;
pin_in_gt_X0Y6_clk_n  : in   std_logic;

--------------------------------------------------
--PCI-EXPRESS
--------------------------------------------------
pin_out_pciexp_txp    : out   std_logic_vector(C_PCGF_PCIE_LINK_WIDTH-1 downto 0);
pin_out_pciexp_txn    : out   std_logic_vector(C_PCGF_PCIE_LINK_WIDTH-1 downto 0);
pin_in_pciexp_rxp     : in    std_logic_vector(C_PCGF_PCIE_LINK_WIDTH-1 downto 0);
pin_in_pciexp_rxn     : in    std_logic_vector(C_PCGF_PCIE_LINK_WIDTH-1 downto 0);
pin_in_pciexp_clk_p   : in    std_logic;
pin_in_pciexp_clk_n   : in    std_logic;

----------------------------------------------------
----SATA
----------------------------------------------------
--pin_out_sata_txn      : out   std_logic_vector((C_SH_GTCH_COUNT_MAX*C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1))-1 downto 0);
--pin_out_sata_txp      : out   std_logic_vector((C_SH_GTCH_COUNT_MAX*C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1))-1 downto 0);
--pin_in_sata_rxn       : in    std_logic_vector((C_SH_GTCH_COUNT_MAX*C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1))-1 downto 0);
--pin_in_sata_rxp       : in    std_logic_vector((C_SH_GTCH_COUNT_MAX*C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1))-1 downto 0);
--pin_in_sata_clk_n     : in    std_logic_vector(C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1)-1 downto 0);
--pin_in_sata_clk_p     : in    std_logic_vector(C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1)-1 downto 0);

--------------------------------------------------
-- Local bus
--------------------------------------------------
lreset_l              : in    std_logic;
lclk                  : in    std_logic;
lwrite                : in    std_logic;
lads_l                : in    std_logic;
lblast_l              : in    std_logic;
lbe_l                 : in    std_logic_vector(32/8-1 downto 0);
lad                   : inout std_logic_vector(32-1 downto 0);
lbterm_l              : inout std_logic;
lready_l              : inout std_logic;
fholda                : in    std_logic;
finto_l               : out   std_logic;

--------------------------------------------------
-- Reference clock 200MHz
--------------------------------------------------
pin_in_refclk200M_n   : in    std_logic;
pin_in_refclk200M_p   : in    std_logic
);
end entity;

architecture struct of vereskm_main is

----component ROC generic (WIDTH : Time := 500 ns); port (O : out std_ulogic := '1'); end component;
--component IBUFDS            port(I : in  std_logic; IB : in  std_logic; O  : out std_logic);end component;
--component IBUFGDS_LVPECL_25 port(I : in  std_logic; IB : in  std_logic; O  : out std_logic);end component;
--component BUFG              port(I : in  std_logic; O  : out std_logic);end component;

component fpga_test_01
generic(
G_BLINK_T05   : integer:=10#125#; -- 1/2 ������� ������� ����������.(����� � ms)
G_CLK_T05us   : integer:=10#1000# -- ���-�� �������� ������� ����� p_in_clk
                                  -- �������������_ � 1/2 ������� 1us
);
port(
p_out_test_led : out   std_logic;--//������� ����������
p_out_test_done: out   std_logic;--//������ �������� � '1' ����� 3 ���.

p_out_1us      : out   std_logic;
p_out_1ms      : out   std_logic;
-------------------------------
--System
-------------------------------
p_in_clk       : in    std_logic;
p_in_rst       : in    std_logic
);
end component;

component gtp_prog_clkmux
generic(
G_CLKIN_CHANGE     : std_logic := '0';
G_CLKSOUTH_CHANGE  : std_logic := '0';
G_CLKNORTH_CHANGE  : std_logic := '0';

G_CLKIN_MUX_VAL    : std_logic_vector(2 downto 0):="011";
G_CLKSOUTH_MUX_VAL : std_logic := '0';
G_CLKNORTH_MUX_VAL : std_logic := '0'
);
port(
p_in_drp_rst    : in    std_logic;
p_in_drp_clk    : in    std_logic;

p_out_txp       : out   std_logic_vector(1 downto 0);
p_out_txn       : out   std_logic_vector(1 downto 0);
p_in_rxp        : in    std_logic_vector(1 downto 0);
p_in_rxn        : in    std_logic_vector(1 downto 0);

p_in_clkin      : in    std_logic;
p_out_refclkout : out   std_logic
);
end component;

component lbus_dcm
generic(
G_CLKFX_DIV  : integer:=1;
G_CLKFX_MULT : integer:=2
);
port(
p_out_gclkin : out   std_logic;
p_out_clk0   : out   std_logic;
p_out_clkfx  : out   std_logic;
--p_out_clkdiv : out   std_logic;
--p_out_clk2x  : out   std_logic;
p_out_locked : out   std_logic;

p_in_clk     : in    std_logic;
p_in_rst     : in    std_logic
);
end component;

component mem_pll
port(
mclk      : in  std_logic;
rst       : in  std_logic;
refclk200 : in  std_logic;

clk0      : out std_logic;
clk45     : out std_logic;
clk2x0    : out std_logic;
clk2x90   : out std_logic;
locked    : out std_logic_vector(1 downto 0);
memrst    : out std_logic
);
end component;

signal i_usr_rst                        : std_logic;

signal i_refclk200MHz                   : std_logic;
signal g_refclk200MHz                   : std_logic;

signal i_gt_X0Y6_rst                    : std_logic;
signal i_gt_X0Y6_clkin                  : std_logic;

signal i_dcm_rst_cnt                    : std_logic_vector(5 downto 0);
signal i_dcm_rst                        : std_logic;

signal g_lbus_clkin                     : std_logic;
--signal g_lbus_clkdiv                    : std_logic;
--signal g_lbus_clk2x                     : std_logic;
signal g_lbus_clkfx                     : std_logic;
signal g_lbus_clk                       : std_logic;
signal lclk_dcm_lock                    : std_logic;

signal g_usr_highclk                    : std_logic;

signal i_memctrl_pllclk0                : std_logic;
signal i_memctrl_pllclk45               : std_logic;
signal i_memctrl_pllclk2x0              : std_logic;
signal i_memctrl_pllclk2x90             : std_logic;
signal i_memctrl_pll_rst_out            : std_logic;

signal i_pciexp_gt_refclk               : std_logic;
signal g_pciexp_gt_refclkout            : std_logic;

signal i_host_rdy                       : std_logic;
signal i_host_rst_n                     : std_logic;
signal g_host_clk                       : std_logic;
signal i_host_gctrl                     : std_logic_vector(C_HREG_CTRL_LAST_BIT downto 0);
signal i_host_dev_ctrl                  : std_logic_vector(C_HREG_DEV_CTRL_LAST_BIT downto 0);
signal i_host_dev_txd                   : std_logic_vector(C_HDEV_DWIDTH-1 downto 0);
signal i_host_dev_rxd                   : std_logic_vector(C_HDEV_DWIDTH-1 downto 0);
signal i_host_dev_wr                    : std_logic;
signal i_host_dev_rd                    : std_logic;
signal i_host_dev_status                : std_logic_vector(C_HREG_DEV_STATUS_LAST_BIT downto 0);
signal i_host_dev_irq                   : std_logic_vector(C_HIRQ_COUNT-1 downto 0);
signal i_host_dev_opt_in                : std_logic_vector(C_HDEV_OPTIN_LAST_BIT downto 0);
signal i_host_dev_opt_out               : std_logic_vector(C_HDEV_OPTOUT_LAST_BIT downto 0);

signal i_host_devadr                    : std_logic_vector(C_HREG_DEV_CTRL_ADR_M_BIT-C_HREG_DEV_CTRL_ADR_L_BIT downto 0);
signal i_host_vchsel                    : std_logic_vector(3 downto 0);

Type THostDCtrl is array (0 to C_HDEV_COUNT-1) of std_logic;
Type THostDWR is array (0 to C_HDEV_COUNT-1) of std_logic_vector(i_host_dev_txd'range);
signal i_host_wr                        : THostDCtrl;
signal i_host_rd                        : THostDCtrl;
signal i_host_txd                       : THostDWR;
signal i_host_rxd                       : THostDWR;
signal i_host_rxrdy                     : THostDCtrl;
signal i_host_txrdy                     : THostDCtrl;
signal i_host_rxbuf_empty               : THostDCtrl;
signal i_host_txbuf_full                : THostDCtrl;
signal i_host_irq                       : THostDCtrl;

signal i_host_rst_all                   : std_logic;
signal i_host_rst_eth                   : std_logic;
signal i_host_rst_mem                   : std_logic;
signal i_host_rddone_vctrl              : std_logic;
signal i_host_rddone_trcnik             : std_logic;

Type THDevWidthCnt is array (0 to C_HDEV_COUNT-1) of std_logic_vector(2 downto 0);
signal i_hdev_dma_start                 : std_logic_vector(C_HDEV_COUNT-1 downto 0);
signal hclk_hdev_dma_start              : std_logic_vector(C_HDEV_COUNT-1 downto 0);
signal hclk_hdev_dma_start_cnt          : THDevWidthCnt;

signal i_host_tst_in                    : std_logic_vector(127 downto 0);
signal i_host_tst_out                   : std_logic_vector(127 downto 0);
signal i_host_tst2_out                  : std_logic_vector(255 downto 0);

signal i_cfg_rst                        : std_logic;
signal i_cfg_rdy                        : std_logic;
signal i_cfg_dadr                       : std_logic_vector(C_CFGPKT_DADR_M_BIT-C_CFGPKT_DADR_L_BIT downto 0);
signal i_cfg_radr                       : std_logic_vector(C_CFGPKT_RADR_M_BIT-C_CFGPKT_RADR_L_BIT downto 0);
signal i_cfg_radr_ld                    : std_logic;
signal i_cfg_radr_fifo                  : std_logic;
signal i_cfg_wr                         : std_logic;
signal i_cfg_rd                         : std_logic;
signal i_cfg_txd                        : std_logic_vector(15 downto 0);
signal i_cfg_rxd                        : std_logic_vector(15 downto 0);
Type TCfgRxD is array (0 to C_CFGDEV_COUNT-1) of std_logic_vector(i_cfg_rxd'range);
signal i_cfg_rxd_dev                    : TCfgRxD;
signal i_cfg_done                       : std_logic;
signal i_cfg_wr_dev                     : std_logic_vector(C_CFGDEV_COUNT-1 downto 0);
signal i_cfg_rd_dev                     : std_logic_vector(C_CFGDEV_COUNT-1 downto 0);
signal i_cfg_done_dev                   : std_logic_vector(C_CFGDEV_COUNT-1 downto 0);
signal i_cfg_tst_out                    : std_logic_vector(31 downto 0);

signal i_swt_rst                        : std_logic;
signal i_swt_tst_out                    : std_logic_vector(31 downto 0);

signal i_eth_gt_refclk125               : std_logic;
signal g_eth_gt_refclkout               : std_logic;
signal i_eth_rst                        : std_logic;
signal i_eth_rdy                        : std_logic;
signal i_eth_carier                     : std_logic;
signal i_eth_module_gt_plllkdet         : std_logic;
signal i_eth_rxd_sof                    : std_logic;
signal i_eth_rxd_eof                    : std_logic;
signal i_eth_rxbuf_din                  : std_logic_vector(31 downto 0);
signal i_eth_rxbuf_wr                   : std_logic;
signal i_eth_rxbuf_full                 : std_logic;
signal i_eth_txbuf_dout                 : std_logic_vector(31 downto 0);
signal i_eth_txbuf_rd                   : std_logic;
signal i_eth_txbuf_empty                : std_logic;
signal i_eth_tst_out                    : std_logic_vector(31 downto 0);

signal i_tmr_rst                        : std_logic;
signal i_tmr_hirq                       : std_logic_vector(C_TMR_COUNT-1 downto 0);

signal i_vctrl_rst                      : std_logic;
signal hclk_hrddone_vctrl_cnt           : std_logic_vector(2 downto 0);
signal hclk_hrddone_vctrl               : std_logic;
--signal i_vctrl_module_rdy               : std_logic;
--signal i_vctrl_module_error             : std_logic;
signal i_vctrl_vbufin_rdy               : std_logic;
signal i_vctrl_vbufin_dout              : std_logic_vector(31 downto 0);
signal i_vctrl_vbufin_rd                : std_logic;
signal i_vctrl_vbufin_empty             : std_logic;
signal i_vctrl_vbufin_pfull             : std_logic;
signal i_vctrl_vbufin_full              : std_logic;
signal i_vctrl_vbufout_din              : std_logic_vector(31 downto 0);
signal i_vctrl_vbufout_wd               : std_logic;
signal i_vctrl_vbufout_empty            : std_logic;
signal i_vctrl_vbufout_full             : std_logic;

signal i_vctrl_hrd_start                : std_logic;
signal i_vctrl_hrd_done                 : std_logic;
signal i_vctrl_hrd_done_dly             : std_logic_vector(1 downto 0);
signal g_vctrl_swt_bufclk               : std_logic;
signal i_vctrl_hirq                     : std_logic_vector(C_VCTRL_VCH_COUNT-1 downto 0);
signal i_vctrl_hrdy                     : std_logic_vector(C_VCTRL_VCH_COUNT-1 downto 0);
signal i_vctrl_hirq_out                 : std_logic_vector(C_VCTRL_VCH_COUNT_MAX-1 downto 0);
signal i_vctrl_hrdy_out                 : std_logic_vector(C_VCTRL_VCH_COUNT_MAX-1 downto 0);
signal i_vctrl_hfrmrk                   : std_logic_vector(31 downto 0);
signal i_vctrl_vrd_done                 : std_logic;
signal i_vctrl_tst_out                  : std_logic_vector(31 downto 0);
signal i_vctrl_vrdprms                  : TReaderVCHParams;
signal i_vctrl_vfrdy                    : std_logic_vector(C_VCTRL_VCH_COUNT-1 downto 0);
signal i_vctrl_vrowmrk                  : TVMrks;
signal i_vctrlwr_memin                  : TMemIN;
signal i_vctrlwr_memout                 : TMemOUT;
signal i_vctrlrd_memin                  : TMemIN;
signal i_vctrlrd_memout                 : TMemOUT;

signal i_trc_rst                        : std_logic;
signal hclk_hrddone_trcnik_cnt          : std_logic_vector(2 downto 0);
signal hclk_hrddone_trcnik              : std_logic;
signal i_trcnik_hrd_done_dly            : std_logic_vector(1 downto 0);
signal i_trcnik_hrd_done                : std_logic;
signal i_trcnik_hdrdy                   : std_logic:='0';
signal i_trcnik_hfrmrk                  : std_logic_vector(31 downto 0):=(others=>'0');
signal i_trc_tst_out                    : std_logic_vector(31 downto 0);
signal i_trc_vbufs                      : TVfrBufs;
signal i_trc_busy                       : std_logic_vector(C_VCTRL_VCH_COUNT-1 downto 0);
signal i_trc_memin                      : TMemIN;
signal i_trc_memout                     : TMemOUT;

signal i_host_mem_ctrl                  : TPce2Mem_Ctrl;
signal i_host_mem_status                : TPce2Mem_Status;
signal i_host_memin                     : TMemIN;
signal i_host_memout                    : TMemOUT;
signal i_host_mem_tst_out               : std_logic_vector(31 downto 0);

signal i_memctrl_rst                    : std_logic;
signal i_memctrl_locked                 : std_logic_vector(7 downto 0);
signal i_memctrl_trained                : std_logic_vector(max_num_bank - 1 downto 0);
signal i_memctrl_ready                  : std_logic;

signal i_memin_ch                       : TMemINCh;
signal i_memout_ch                      : TMemOUTCh;

signal i_arb_mem_rst                    : std_logic;
signal i_arb_memin                      : TMemIN;
signal i_arb_memout                     : TMemOUT;
signal i_arb_mem_tst_out                : std_logic_vector(31 downto 0);

signal i_swt_hdd_tstgen_cfg             : THDDTstGen;
--signal i_hdd_rst                        : std_logic;
--signal i_hdd_gt_refclk150               : std_logic_vector(C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1)-1 downto 0);
--signal g_hdd_gt_refclkout               : std_logic;
--signal i_hdd_gt_plldet                  : std_logic;
--signal i_hdd_dcm_lock                   : std_logic;
--signal i_hdd_module_rdy                 : std_logic;
--signal i_hdd_module_error               : std_logic;
--signal i_hdd_busy                       : std_logic;
----signal i_hdd_hirq                       : std_logic;
--signal i_hdd_done                       : std_logic;
--signal i_hdd_rxdata                     : std_logic_vector(31 downto 0);
--signal i_hdd_rxdata_rd                  : std_logic;
--signal i_hdd_rxbuf_empty                : std_logic;
--signal i_hdd_rxbuf_pempty               : std_logic;
--signal i_hdd_txdata                     : std_logic_vector(31 downto 0);
--signal i_hdd_txdata_wd                  : std_logic;
--signal i_hdd_txbuf_empty                : std_logic;
--signal i_hdd_txbuf_pfull                : std_logic;
--signal i_hdd_txbuf_full                 : std_logic;
--signal i_hdd_vbuf_dout                  : std_logic_vector(31 downto 0);
--signal i_hdd_vbuf_rd                    : std_logic;
--signal i_hdd_vbuf_empty                 : std_logic;
--signal i_hdd_vbuf_full                  : std_logic;
--signal i_hdd_vbuf_pfull                 : std_logic;
--signal i_hdd_vbuf_wrcnt                 : std_logic_vector(3 downto 0);
--signal i_hdd_rbuf_cfg                   : THDDRBufCfg;
--signal i_hdd_rbuf_status                : THDDRBufStatus;
--signal i_hdd_rbuf_tst_out               : std_logic_vector(31 downto 0);
--signal i_hdd_dbgled                     : THDDLed_SHCountMax;
--signal i_hdd_tst_in                     : std_logic_vector(31 downto 0);
--signal i_hdd_tst_out                    : std_logic_vector(31 downto 0);
--signal i_hdd_dbgcs                      : TSH_dbgcs_exp;
--signal i_hddrambuf_dbgcs                : TSH_ila;
--signal i_hdd_rambuf_dbgcs               : TSH_ila;
----signal i_hdd_sim_gt_txdata              : TBus32_SHCountMax;--
----signal i_hdd_sim_gt_txcharisk           : TBus04_SHCountMax;--
----signal i_hdd_sim_gt_txcomstart          : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);--
--signal i_hdd_sim_gt_rxdata              : TBus32_SHCountMax;
--signal i_hdd_sim_gt_rxcharisk           : TBus04_SHCountMax;
--signal i_hdd_sim_gt_rxstatus            : TBus03_SHCountMax;
--signal i_hdd_sim_gt_rxelecidle          : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
--signal i_hdd_sim_gt_rxdisperr           : TBus04_SHCountMax;
--signal i_hdd_sim_gt_rxnotintable        : TBus04_SHCountMax;
--signal i_hdd_sim_gt_rxbyteisaligned     : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
----signal i_hdd_sim_gt_sim_rst             : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);--
----signal i_hdd_sim_gt_sim_clk             : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);--
--
--signal i_hdd_memin                      : TMemIN;
--signal i_hdd_memout                     : TMemOUT;
--
--signal i_dsntst_rst                     : std_logic;
--signal i_dsntst_txdata_rdy              : std_logic;
--signal i_dsntst_txdata_dout             : std_logic_vector(31 downto 0);
--signal i_dsntst_txdata_wd               : std_logic;
--signal i_dsntst_txbuf_empty             : std_logic;
--signal i_dsntst_txbuf_full              : std_logic;
--signal i_dsntst_bufclk                  : std_logic;
--signal i_dsntst_tst_out                 : std_logic_vector(31 downto 0);


--
-- If the synthesizer replicates an asynchronous reset signal due high fanout,
-- this can prevent flip-flops being mapped into IOBs. We set the maximum
-- fanout for such nets to a high enough value that replication never occurs.
--
attribute MAX_FANOUT : string;
attribute MAX_FANOUT of i_memctrl_rst : signal is "100000";

attribute keep : string;
attribute keep of g_host_clk : signal is "true";

signal i_test01_led     : std_logic;
signal tst_clr          : std_logic;


--//MAIN
begin


--***********************************************************
--//RESET �������
--***********************************************************
i_host_rst_n <=lreset_l;

i_gt_X0Y6_rst<=not i_host_rdy;
i_tmr_rst    <=not i_host_rst_n or i_host_rst_all;
i_cfg_rst    <=not i_host_rst_n or i_host_rst_all;
i_eth_rst    <=not i_host_rst_n or i_host_rst_all or i_host_rst_eth;
i_vctrl_rst  <=not i_host_rst_n or i_host_rst_all;
i_trc_rst    <=not i_host_rst_n or i_host_rst_all;
i_swt_rst    <=not i_host_rst_n or i_host_rst_all;
i_memctrl_rst<=not i_host_rst_n or i_host_rst_all or i_host_rst_mem;
--i_dsntst_rst <=not i_host_rst_n or i_host_rst_all;
--i_hdd_rst    <=not i_host_rst_n or i_host_rst_all or i_usr_rst;
i_arb_mem_rst<=i_memctrl_rst;

process(i_host_rst_n, g_refclk200MHz)
begin
  if i_host_rst_n = '0' then
    i_dcm_rst_cnt <= (others => '0');
  elsif g_refclk200MHz'event and g_refclk200MHz = '1' then
    if i_dcm_rst_cnt(i_dcm_rst_cnt'high) = '0' then
      i_dcm_rst_cnt <= i_dcm_rst_cnt + 1;
    end if;
  end if;
end process;

i_dcm_rst <= i_dcm_rst_cnt(i_dcm_rst_cnt'high - 1) or i_host_rst_all;


--***********************************************************
--��������� ������ �������:
--***********************************************************
--//Input 200MHz reference clock for IDELAY / ODELAY elements
ibufg_refclk : IBUFGDS_LVPECL_25 port map(I  => pin_in_refclk200M_p, IB => pin_in_refclk200M_n, O  => i_refclk200MHz);
bufg_refclk  : BUFG              port map(I  => i_refclk200MHz, O  => g_refclk200MHz);

--//Input 100MHz reference clock for PCI-EXPRESS
ibuf_pciexp_gt_refclk : IBUFDS port map (I=>pin_in_pciexp_clk_p, IB=> pin_in_pciexp_clk_n, O=>i_pciexp_gt_refclk );

----//Input 150MHz reference clock for SATA
--gen_sata_gt : for i in 0 to C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1)-1 generate
--ibufds_hdd_gt_refclk : IBUFDS port map(I  => pin_in_sata_clk_p(i), IB => pin_in_sata_clk_n(i), O  => i_hdd_gt_refclk150(i));
--end generate gen_sata_gt;

--//Input 125MHz reference clock for Eth
ibufds_X0Y6_gt_refclk : IBUFDS port map(I => pin_in_gt_X0Y6_clk_p, IB => pin_in_gt_X0Y6_clk_n, O => i_gt_X0Y6_clkin);

--//������������ ��������� ������� ������� GTP_X0Y6
--//�.� � ������ ������� ������� ������� ��� GTP_X0Y7 ����� ������� �� � ���. ����� pin_in_eth_clk_n/p, �
--//� ����� CLKINNORTH (����� �������� ��. xilinx manual ug196.pdf/Appendix F)
m_gt_refclkout : gtp_prog_clkmux
generic map(
G_CLKIN_CHANGE      => '0',   --//����������/������ ��������� ��������� �������������� CLKIN    - '1'/'0'
G_CLKSOUTH_CHANGE   => '0',   --//����������/������ ��������� ��������� �������������� CLKSOUTH - '1'/'0'
G_CLKNORTH_CHANGE   => '1',   --//����������/������ ��������� ��������� �������������� CLKNORTH - '1'/'0'

G_CLKIN_MUX_VAL     => "011", --//�������� ��� �������������� CLKIN
G_CLKSOUTH_MUX_VAL  => '1',   --//�������� ��� �������������� CLKSOUTH
G_CLKNORTH_MUX_VAL  => '1'    --//�������� ��� �������������� CLKNORTH
)
port map(
p_in_drp_rst    => i_gt_X0Y6_rst,
p_in_drp_clk    => g_pciexp_gt_refclkout,

p_out_txp       => pin_out_gt_X0Y6_txp,
p_out_txn       => pin_out_gt_X0Y6_txn,
p_in_rxp        => pin_in_gt_X0Y6_rxp,
p_in_rxn        => pin_in_gt_X0Y6_rxn,

p_in_clkin      => i_gt_X0Y6_clkin,
p_out_refclkout => open
);

--//Input 125MHz reference clock for GTP_X0Y7 Eth_MAC0
--//� ������ ������� ������� ������� ��� GTP_X0Y7 ����� ������� �� � ���. ����� pin_in_eth_clk_n/p, �
--//� ����� CLKINNORTH (����� �������� ��. xilinx manual ug196.pdf/Appendix F)
ibufds_gt_eth_refclk : IBUFDS port map(I  => pin_in_eth_clk_p, IB => pin_in_eth_clk_n, O  => i_eth_gt_refclk125);

--//DCM Local Bus
m_dcm_lbus : lbus_dcm
generic map(
G_CLKFX_DIV  => 1,
G_CLKFX_MULT => C_PCFG_LBUSDCM_CLKFX_M
)
port map(
p_out_gclkin => g_lbus_clkin,
p_out_clk0   => g_lbus_clk,
p_out_clkfx  => g_lbus_clkfx,
--p_out_clkdiv => g_lbus_clkdiv,
--p_out_clk2x  => g_lbus_clk2x,
p_out_locked => lclk_dcm_lock,

p_in_clk     => lclk,
p_in_rst     => i_dcm_rst
);

--//PLL ����������� ������
m_pll_mem_ctrl : mem_pll
port map(
mclk      => g_refclk200MHz,
rst       => i_memctrl_rst,
refclk200 => g_refclk200MHz,

clk0      => i_memctrl_pllclk0,
clk45     => i_memctrl_pllclk45,
clk2x0    => i_memctrl_pllclk2x0,
clk2x90   => i_memctrl_pllclk2x90,
locked    => i_memctrl_locked(1 downto 0),
memrst    => i_memctrl_pll_rst_out
);

g_usr_highclk<=i_memctrl_pllclk2x0;


--***********************************************************
--������ ���������������� ����-�
--***********************************************************
m_cfg : cfgdev_host
port map(
-------------------------------
--����� � ������
-------------------------------
p_out_host_rxrdy     => i_host_rxrdy(C_HDEV_CFG_DBUF),
p_out_host_rxd       => i_host_rxd(C_HDEV_CFG_DBUF),
p_in_host_rd         => i_host_rd(C_HDEV_CFG_DBUF),

p_out_host_txrdy     => i_host_txrdy(C_HDEV_CFG_DBUF),
p_in_host_txd        => i_host_txd(C_HDEV_CFG_DBUF),
p_in_host_wr         => i_host_wr(C_HDEV_CFG_DBUF),

p_out_host_irq       => i_host_irq(C_HIRQ_CFG_RX),
p_in_host_clk        => g_host_clk,

-------------------------------
--
-------------------------------
p_out_module_rdy     => i_cfg_rdy,
p_out_module_error   => open,

-------------------------------
--������/������ ���������������� ���������� ���-��
-------------------------------
p_out_cfg_dadr       => i_cfg_dadr,
p_out_cfg_radr       => i_cfg_radr,
p_out_cfg_radr_ld    => i_cfg_radr_ld,
p_out_cfg_radr_fifo  => i_cfg_radr_fifo,
p_out_cfg_wr         => i_cfg_wr,
p_out_cfg_rd         => i_cfg_rd,
p_out_cfg_txdata     => i_cfg_txd,
p_in_cfg_rxdata      => i_cfg_rxd,
p_in_cfg_txrdy       => '1',
p_in_cfg_rxrdy       => '1',

p_out_cfg_done       => i_cfg_done,
p_in_cfg_clk         => g_host_clk,

-------------------------------
--���������������
-------------------------------
p_in_tst             => (others=>'0'),
p_out_tst            => i_cfg_tst_out,

-------------------------------
--System
-------------------------------
p_in_rst => i_cfg_rst
);

--//������������ ���������� �� ����� ����� �����������(cfgdev.vhd) ��� �����. ������ �������:
i_cfg_rxd<=i_cfg_rxd_dev(C_CFGDEV_ETH)     when i_cfg_dadr(3 downto 0)=CONV_STD_LOGIC_VECTOR(C_CFGDEV_ETH, 4)     else
           i_cfg_rxd_dev(C_CFGDEV_VCTRL)   when i_cfg_dadr(3 downto 0)=CONV_STD_LOGIC_VECTOR(C_CFGDEV_VCTRL, 4)   else
           i_cfg_rxd_dev(C_CFGDEV_SWT)     when i_cfg_dadr(3 downto 0)=CONV_STD_LOGIC_VECTOR(C_CFGDEV_SWT, 4)     else
           i_cfg_rxd_dev(C_CFGDEV_TMR)     when i_cfg_dadr(3 downto 0)=CONV_STD_LOGIC_VECTOR(C_CFGDEV_TMR, 4)     else
           i_cfg_rxd_dev(C_CFGDEV_HDD)     when i_cfg_dadr(3 downto 0)=CONV_STD_LOGIC_VECTOR(C_CFGDEV_HDD, 4)     else
           i_cfg_rxd_dev(C_CFGDEV_TESTING) when i_cfg_dadr(3 downto 0)=CONV_STD_LOGIC_VECTOR(C_CFGDEV_TESTING, 4) else
           i_cfg_rxd_dev(C_CFGDEV_TRCNIK)  when i_cfg_dadr(3 downto 0)=CONV_STD_LOGIC_VECTOR(C_CFGDEV_TRCNIK, 4)  else
           (others=>'0');

gen_cfg_dev : for i in 0 to C_CFGDEV_COUNT-1 generate
i_cfg_wr_dev(i)   <=i_cfg_wr   when i_cfg_dadr=i else '0';
i_cfg_rd_dev(i)   <=i_cfg_rd   when i_cfg_dadr=i else '0';
i_cfg_done_dev(i) <=i_cfg_done when i_cfg_dadr=i else '0';
end generate gen_cfg_dev;


--***********************************************************
--������ ������ ������
--***********************************************************
m_tmr : dsn_timer
port map(
-------------------------------
-- ���������������� ������ dsn_timer.vhd (host_clk domain)
-------------------------------
p_in_host_clk     => g_host_clk,

p_in_cfg_adr      => i_cfg_radr(7 downto 0),
p_in_cfg_adr_ld   => i_cfg_radr_ld,
p_in_cfg_adr_fifo => i_cfg_radr_fifo,

p_in_cfg_txdata   => i_cfg_txd,
p_in_cfg_wd       => i_cfg_wr_dev(C_CFGDEV_TMR),

p_out_cfg_rxdata  => i_cfg_rxd_dev(C_CFGDEV_TMR),
p_in_cfg_rd       => i_cfg_rd_dev(C_CFGDEV_TMR),

p_in_cfg_done     => i_cfg_wr_dev(C_CFGDEV_TMR),

-------------------------------
-- STATUS ������ dsn_timer.vhd
-------------------------------
p_in_tmr_clk      => g_pciexp_gt_refclkout,
p_out_tmr_rdy     => open,
p_out_tmr_error   => open,

p_out_tmr_irq     => i_tmr_hirq,

-------------------------------
--System
-------------------------------
p_in_rst => i_tmr_rst
);

--***********************************************************
--������ ������ ���������
--***********************************************************
m_swt : dsn_switch
port map(
-------------------------------
-- ���������������� ������ dsn_switch.vhd (p_in_cfg_clk domain)
-------------------------------
p_in_cfg_clk              => g_host_clk,

p_in_cfg_adr              => i_cfg_radr(7 downto 0),
p_in_cfg_adr_ld           => i_cfg_radr_ld,
p_in_cfg_adr_fifo         => i_cfg_radr_fifo,

p_in_cfg_txdata           => i_cfg_txd,
p_in_cfg_wd               => i_cfg_wr_dev(C_CFGDEV_SWT),

p_out_cfg_rxdata          => i_cfg_rxd_dev(C_CFGDEV_SWT),
p_in_cfg_rd               => i_cfg_rd_dev(C_CFGDEV_SWT),

p_in_cfg_done             => i_cfg_done_dev(C_CFGDEV_SWT),

-------------------------------
-- ����� � ������ (host_clk domain)
-------------------------------
p_in_host_clk             => g_host_clk,

-- ����� ���� <-> ETH(dsn_eth.vhd)
p_out_host_eth_rxd_irq    => i_host_irq(C_HIRQ_ETH_RX),
p_out_host_eth_rxd_rdy    => i_host_rxrdy(C_HDEV_ETH_DBUF),
p_out_host_eth_rxd        => i_host_rxd(C_HDEV_ETH_DBUF),
p_in_host_eth_rd          => i_host_rd(C_HDEV_ETH_DBUF),

p_out_host_eth_txbuf_rdy  => i_host_txrdy(C_HDEV_ETH_DBUF),
p_in_host_eth_txd         => i_host_txd(C_HDEV_ETH_DBUF),
p_in_host_eth_wr          => i_host_wr(C_HDEV_ETH_DBUF),

-- ����� ���� <-> VideoBUF
p_out_host_vbuf_dout      => i_host_rxd(C_HDEV_VCH_DBUF),
p_in_host_vbuf_rd         => i_host_rd(C_HDEV_VCH_DBUF),
p_out_host_vbuf_empty     => i_host_rxbuf_empty(C_HDEV_VCH_DBUF),


-------------------------------
-- ����� � HDD(dsn_hdd.vhd)
-------------------------------
p_in_hdd_tstgen           => i_swt_hdd_tstgen_cfg,
p_in_hdd_vbuf_rdclk       => g_usr_highclk,

p_out_hdd_vbuf_dout       => open, --i_hdd_vbuf_dout,
p_in_hdd_vbuf_rd          => '0',  --i_hdd_vbuf_rd,
p_out_hdd_vbuf_empty      => open, --i_hdd_vbuf_empty,
p_out_hdd_vbuf_full       => open, --i_hdd_vbuf_full,
p_out_hdd_vbuf_pfull      => open, --i_hdd_vbuf_pfull,
p_out_hdd_vbuf_wrcnt      => open, --i_hdd_vbuf_wrcnt,

-------------------------------
-- ����� � Eth(dsn_ethg.vhd) (ethg_clk domain)
-------------------------------
p_in_eth_clk              => g_eth_gt_refclkout,

p_in_eth_rxd_sof          => i_eth_rxd_sof,
p_in_eth_rxd_eof          => i_eth_rxd_eof,
p_in_eth_rxbuf_din        => i_eth_rxbuf_din,
p_in_eth_rxbuf_wr         => i_eth_rxbuf_wr,
p_out_eth_rxbuf_empty     => i_host_rxbuf_empty(C_HDEV_ETH_DBUF),
p_out_eth_rxbuf_full      => i_eth_rxbuf_full,

p_out_eth_txbuf_dout      => i_eth_txbuf_dout,
p_in_eth_txbuf_rd         => i_eth_txbuf_rd,
p_out_eth_txbuf_empty     => i_eth_txbuf_empty,
p_out_eth_txbuf_full      => i_host_txbuf_full(C_HDEV_ETH_DBUF),


-------------------------------
-- ����� � VCTRL(dsn_video_ctrl.vhd) (vctrl_clk domain)
-------------------------------
p_in_vctrl_clk            => g_vctrl_swt_bufclk,

p_out_vctrl_vbufin_rdy    => i_vctrl_vbufin_rdy,
p_out_vctrl_vbufin_dout   => i_vctrl_vbufin_dout,
p_in_vctrl_vbufin_rd      => i_vctrl_vbufin_rd,
p_out_vctrl_vbufin_empty  => i_vctrl_vbufin_empty,
p_out_vctrl_vbufin_full   => i_vctrl_vbufin_full,
p_out_vctrl_vbufin_pfull  => i_vctrl_vbufin_pfull,

p_in_vctrl_vbufout_din    => i_vctrl_vbufout_din,
p_in_vctrl_vbufout_wr     => i_vctrl_vbufout_wd,
p_out_vctrl_vbufout_empty => i_vctrl_vbufout_empty,
p_out_vctrl_vbufout_full  => i_vctrl_vbufout_full,


-------------------------------
-- ����� � ������� ������������(dsn_testing.vhd)
-------------------------------
p_out_dsntst_bufclk       => open,         --i_dsntst_bufclk,

p_in_dsntst_txd_rdy       => '0',          --i_dsntst_txdata_rdy,
p_in_dsntst_txbuf_din     => (others=>'0'),--i_dsntst_txdata_dout,
p_in_dsntst_txbuf_wr      => '0',          --i_dsntst_txdata_wd,
p_out_dsntst_txbuf_empty  => open,         --i_dsntst_txbuf_empty,
p_out_dsntst_txbuf_full   => open,         --i_dsntst_txbuf_full,


-------------------------------
--���������������
-------------------------------
p_in_tst                  => (others=>'0'),
p_out_tst                 => i_swt_tst_out,

-------------------------------
--System
-------------------------------
p_in_rst => i_swt_rst
);

--***********************************************************
--������ Ethernet - dsn_ethg.vhd
--***********************************************************
m_eth : dsn_ethg
generic map(
G_MODULE_USE => C_PCFG_ETH_USE,
G_DBG        => C_PCFG_ETH_DBG,
G_SIM        => G_SIM
)
port map(
-------------------------------
-- ���������������� ������ dsn_ethg.vhd (host_clk domain)
-------------------------------
p_in_cfg_clk          => g_host_clk,

p_in_cfg_adr          => i_cfg_radr(7 downto 0),
p_in_cfg_adr_ld       => i_cfg_radr_ld,
p_in_cfg_adr_fifo     => i_cfg_radr_fifo,

p_in_cfg_txdata       => i_cfg_txd,
p_in_cfg_wd           => i_cfg_wr_dev(C_CFGDEV_ETH),

p_out_cfg_rxdata      => i_cfg_rxd_dev(C_CFGDEV_ETH),
p_in_cfg_rd           => i_cfg_rd_dev(C_CFGDEV_ETH),

p_in_cfg_done         => i_cfg_done_dev(C_CFGDEV_ETH),
p_in_cfg_rst          => i_cfg_rst,

-------------------------------
-- STATUS ������ dsn_ethg.vhd
-------------------------------
p_out_eth_rdy          => i_eth_rdy,
p_out_eth_error        => i_eth_carier,
p_out_eth_gt_plllkdet  => i_eth_module_gt_plllkdet,

p_out_sfp_tx_dis       => pin_out_sfp_tx_dis,
p_in_sfp_sd            => pin_in_sfp_sd,

-------------------------------
-- ����� � �������� ������ dsn_switch.vhd
-------------------------------
p_out_eth_rxbuf_din    => i_eth_rxbuf_din,
p_out_eth_rxbuf_wr     => i_eth_rxbuf_wr,
p_in_eth_rxbuf_full    => i_eth_rxbuf_full,
p_out_eth_rxd_sof      => i_eth_rxd_sof,
p_out_eth_rxd_eof      => i_eth_rxd_eof,

p_in_eth_txbuf_dout    => i_eth_txbuf_dout,
p_out_eth_txbuf_rd     => i_eth_txbuf_rd,
p_in_eth_txbuf_empty   => i_eth_txbuf_empty,

--------------------------------------------------
--ETH Driver
--------------------------------------------------
p_out_eth_gt_txp       => pin_out_eth_txp,
p_out_eth_gt_txn       => pin_out_eth_txn,
p_in_eth_gt_rxp        => pin_in_eth_rxp,
p_in_eth_gt_rxn        => pin_in_eth_rxn,

p_in_eth_gt_refclk     => i_eth_gt_refclk125,
p_out_eth_gt_refclkout => g_eth_gt_refclkout,
p_in_eth_gt_drpclk     => g_pciexp_gt_refclkout,

-------------------------------
--���������������
-------------------------------
p_in_tst               => (others=>'0'),
p_out_tst              => i_eth_tst_out,

-------------------------------
--System
-------------------------------
p_in_rst               => i_eth_rst
);


--***********************************************************
--������ ������ ����� ���������� - dsn_video_ctrl.vhd
--***********************************************************
i_vctrl_hirq_out<=EXT(i_vctrl_hirq, i_vctrl_hirq_out'length);
i_vctrl_hrdy_out<=EXT(i_vctrl_hrdy, i_vctrl_hrdy_out'length);

m_vctrl : dsn_video_ctrl
generic map(
G_SIMPLE => C_PCFG_VCTRL_SIMPLE,
G_SIM    => G_SIM,

G_MEM_AWIDTH => C_HREG_MEM_ADR_LAST_BIT,
G_MEM_DWIDTH => C_HDEV_DWIDTH
)
port map(
-------------------------------
-- ���������������� ������ dsn_video_ctrl.vhd (host_clk domain)
-------------------------------
p_in_host_clk        => g_host_clk,

p_in_cfg_adr         => i_cfg_radr(7 downto 0),
p_in_cfg_adr_ld      => i_cfg_radr_ld,
p_in_cfg_adr_fifo    => i_cfg_radr_fifo,

p_in_cfg_txdata      => i_cfg_txd,
p_in_cfg_wd          => i_cfg_wr_dev(C_CFGDEV_VCTRL),

p_out_cfg_rxdata     => i_cfg_rxd_dev(C_CFGDEV_VCTRL),
p_in_cfg_rd          => i_cfg_rd_dev(C_CFGDEV_VCTRL),

p_in_cfg_done        => i_cfg_done_dev(C_CFGDEV_VCTRL),

-------------------------------
-- ����� � ����
-------------------------------
p_in_vctrl_hrdchsel  => i_host_vchsel,
p_in_vctrl_hrdstart  => i_vctrl_hrd_start,
p_in_vctrl_hrddone   => i_vctrl_hrd_done,
p_out_vctrl_hirq     => i_vctrl_hirq,
p_out_vctrl_hdrdy    => i_vctrl_hrdy,
p_out_vctrl_hfrmrk   => i_vctrl_hfrmrk,

-------------------------------
-- STATUS ������ dsn_video_ctrl.vhd
-------------------------------
p_out_vctrl_modrdy   => open,--i_vctrl_module_rdy,
p_out_vctrl_moderr   => open,--i_vctrl_module_error,
p_out_vctrl_rd_done  => i_vctrl_vrd_done,

p_out_vctrl_vrdprm   => i_vctrl_vrdprms,
p_out_vctrl_vfrrdy   => i_vctrl_vfrdy,
p_out_vctrl_vrowmrk  => i_vctrl_vrowmrk,

-------------------------------
-- ����� � ������� ��������
-------------------------------
p_in_trc_busy        => i_trc_busy,
p_out_trc_vbuf       => i_trc_vbufs,

-------------------------------
-- ����� � �������� ������ dsn_switch.vhd
-------------------------------
p_out_vbuf_clk       => g_vctrl_swt_bufclk,

p_in_vbufin_rdy      => i_vctrl_vbufin_rdy,
p_in_vbufin_dout     => i_vctrl_vbufin_dout,
p_out_vbufin_dout_rd => i_vctrl_vbufin_rd,
p_in_vbufin_empty    => i_vctrl_vbufin_empty,
p_in_vbufin_full     => i_vctrl_vbufin_full,
p_in_vbufin_pfull    => i_vctrl_vbufin_pfull,

p_out_vbufout_din    => i_vctrl_vbufout_din,
p_out_vbufout_din_wd => i_vctrl_vbufout_wd,
p_in_vbufout_empty   => i_vctrl_vbufout_empty,
p_in_vbufout_full    => i_vctrl_vbufout_full,

---------------------------------
-- ����� � mem_ctrl.vhd
---------------------------------
--//CH WRITE
p_out_memwr          => i_vctrlwr_memin,
p_in_memwr           => i_vctrlwr_memout,
--//CH READ
p_out_memrd          => i_vctrlrd_memin,
p_in_memrd           => i_vctrlrd_memout,

-------------------------------
--���������������
-------------------------------
p_out_tst            => i_vctrl_tst_out,

-------------------------------
--System
-------------------------------
p_in_clk => g_usr_highclk,
p_in_rst => i_vctrl_rst
);


--***********************************************************
--������ ������ �������� - dsn_track.vhd
--***********************************************************
m_track : dsn_track_nik
generic map(
G_SIM             => G_SIM,
G_MODULE_USE      => C_PCFG_TRC_USE,

G_MEM_BANK_M_BIT  => C_VCTRL_REG_MEM_ADR_BANK_M_BIT,
G_MEM_BANK_L_BIT  => C_VCTRL_REG_MEM_ADR_BANK_L_BIT,

G_MEM_VCH_M_BIT   => C_VCTRL_MEM_VCH_M_BIT,
G_MEM_VCH_L_BIT   => C_VCTRL_MEM_VCH_L_BIT,
G_MEM_VFR_M_BIT   => C_VCTRL_MEM_VFR_M_BIT,
G_MEM_VFR_L_BIT   => C_VCTRL_MEM_VFR_L_BIT,
G_MEM_VLINE_M_BIT => C_VCTRL_MEM_VLINE_M_BIT,
G_MEM_VLINE_L_BIT => C_VCTRL_MEM_VLINE_L_BIT,

G_MEM_AWIDTH      => C_HREG_MEM_ADR_LAST_BIT,
G_MEM_DWIDTH      => C_HDEV_DWIDTH
)
port map(
-------------------------------
-- ���������� �� �����
-------------------------------
p_in_host_clk        => g_host_clk,

p_in_cfg_adr         => i_cfg_radr(7 downto 0),
p_in_cfg_adr_ld      => i_cfg_radr_ld,
p_in_cfg_adr_fifo    => i_cfg_radr_fifo,

p_in_cfg_txdata      => i_cfg_txd,
p_in_cfg_wd          => i_cfg_wr_dev(C_CFGDEV_TRCNIK),

p_out_cfg_rxdata     => i_cfg_rxd_dev(C_CFGDEV_TRCNIK),
p_in_cfg_rd          => i_cfg_rd_dev(C_CFGDEV_TRCNIK),

p_in_cfg_done        => i_cfg_done_dev(C_CFGDEV_TRCNIK),

-------------------------------
-- ����� � ����
-------------------------------
p_out_trc_hirq       => i_host_irq(C_HIRQ_TRCNIK),
p_out_trc_hdrdy      => i_trcnik_hdrdy,
p_out_trc_hfrmrk     => i_trcnik_hfrmrk,
p_in_trc_hrddone     => i_trcnik_hrd_done,

p_out_trc_bufo_dout  => open,
p_in_trc_bufo_rd     => '0',
p_out_trc_bufo_empty => open,

p_out_trc_busy       => i_trc_busy,

-------------------------------
-- ����� � VCTRL
-------------------------------
p_in_vctrl_vrdprms   => i_vctrl_vrdprms,
p_in_vctrl_vfrrdy    => i_vctrl_vfrdy,
p_in_vctrl_vbuf      => i_trc_vbufs,
p_in_vctrl_vrowmrk   => i_vctrl_vrowmrk,

---------------------------------
-- ����� � mem_ctrl.vhd
---------------------------------
p_out_mem            => i_trc_memin,
p_in_mem             => i_trc_memout,

-------------------------------
--���������������
-------------------------------
p_in_tst             => (others=>'0'),
p_out_tst            => i_trc_tst_out,

-------------------------------
--System
-------------------------------
p_in_clk => g_usr_highclk,
p_in_rst => i_trc_rst
);


----***********************************************************
----������ ���������� - dsn_hdd.vhd
----***********************************************************
--i_swt_hdd_tstgen_cfg<=i_hdd_rbuf_cfg.tstgen;
--
--m_hdd : dsn_hdd
--generic map(
--G_MODULE_USE=> C_PCFG_HDD_USE,
--G_HDD_COUNT => C_PCFG_HDD_COUNT,
--G_GT_DBUS   => C_PCFG_HDD_GT_DBUS,
--G_DBG       => C_PCFG_HDD_DBG,
--G_DBGCS     => C_PCFG_HDD_DBGCS,
--G_SIM       => G_SIM
--)
--port map(
---------------------------------
---- ���������������� ������ dsn_hdd.vhd (p_in_cfg_clk domain)
---------------------------------
--p_in_cfg_if           => C_HDD_CFGIF_PCIEXP,
--p_in_cfg_clk          => g_host_clk,
--
--p_in_cfg_adr          => i_cfg_radr(7 downto 0),
--p_in_cfg_adr_ld       => i_cfg_radr_ld,
--p_in_cfg_adr_fifo     => i_cfg_radr_fifo,
--
--p_in_cfg_txdata       => i_cfg_txd,
--p_in_cfg_wd           => i_cfg_wr_dev(C_CFGDEV_HDD),
--
--p_out_cfg_rxdata      => i_cfg_rxd_dev(C_CFGDEV_HDD),
--p_in_cfg_rd           => i_cfg_rd_dev(C_CFGDEV_HDD),
--
--p_in_cfg_done         => i_cfg_done_dev(C_CFGDEV_HDD),
--p_in_cfg_rst          => i_cfg_rst,
--
---------------------------------
---- STATUS ������ dsn_hdd.vhd
---------------------------------
--p_out_hdd_rdy         => i_hdd_module_rdy,
--p_out_hdd_error       => i_hdd_module_error,
--p_out_hdd_busy        => i_hdd_busy,
--p_out_hdd_irq         => open,--i_hdd_hirq,
--p_out_hdd_done        => i_hdd_done,
--
---------------------------------
---- ����� � �����������/����������� ������ ����������
---------------------------------
--p_out_rbuf_cfg        => i_hdd_rbuf_cfg,
--p_in_rbuf_status      => i_hdd_rbuf_status,
--
--p_in_hdd_txd          => i_hdd_txdata,
--p_in_hdd_txd_wr       => i_hdd_txdata_wd,
--p_out_hdd_txbuf_pfull => i_hdd_txbuf_pfull,
--p_out_hdd_txbuf_full  => i_hdd_txbuf_full,
--p_out_hdd_txbuf_empty => i_hdd_txbuf_empty,
--
--p_out_hdd_rxd         => i_hdd_rxdata,
--p_in_hdd_rxd_rd       => i_hdd_rxdata_rd,
--p_out_hdd_rxbuf_empty => i_hdd_rxbuf_empty,
--p_out_hdd_rxbuf_pempty=> i_hdd_rxbuf_pempty,
--
----------------------------------------------------
----Sata Driver
----------------------------------------------------
--p_out_sata_txn        => pin_out_sata_txn,
--p_out_sata_txp        => pin_out_sata_txp,
--p_in_sata_rxn         => pin_in_sata_rxn,
--p_in_sata_rxp         => pin_in_sata_rxp,
--
--p_in_sata_refclk      => i_hdd_gt_refclk150,
--p_out_sata_refclkout  => g_hdd_gt_refclkout,
--p_out_sata_gt_plldet  => i_hdd_gt_plldet,
--p_out_sata_dcm_lock   => i_hdd_dcm_lock,
--
-----------------------------------------------------------------------------
----��������������� ����
-----------------------------------------------------------------------------
--p_in_tst              => i_hdd_tst_in,
--p_out_tst             => i_hdd_tst_out,
--
----------------------------------------------------
----//Debug/Sim
----------------------------------------------------
--p_out_dbgcs                 => i_hdd_dbgcs,
--p_out_dbgled                => i_hdd_dbgled,
--
--p_out_sim_gt_txdata         => open,--i_hdd_sim_gt_txdata,    --
--p_out_sim_gt_txcharisk      => open,--i_hdd_sim_gt_txcharisk, --
--p_out_sim_gt_txcomstart     => open,--i_hdd_sim_gt_txcomstart,--
--p_in_sim_gt_rxdata          => i_hdd_sim_gt_rxdata,
--p_in_sim_gt_rxcharisk       => i_hdd_sim_gt_rxcharisk,
--p_in_sim_gt_rxstatus        => i_hdd_sim_gt_rxstatus,
--p_in_sim_gt_rxelecidle      => i_hdd_sim_gt_rxelecidle,
--p_in_sim_gt_rxdisperr       => i_hdd_sim_gt_rxdisperr,
--p_in_sim_gt_rxnotintable    => i_hdd_sim_gt_rxnotintable,
--p_in_sim_gt_rxbyteisaligned => i_hdd_sim_gt_rxbyteisaligned,
--p_out_gt_sim_rst            => open,--i_hdd_sim_gt_sim_rst,--
--p_out_gt_sim_clk            => open,--i_hdd_sim_gt_sim_clk,--
--
----------------------------------------------------
----System
----------------------------------------------------
--p_in_clk           => g_usr_highclk,
--p_in_rst           => i_hdd_rst
--);
--
--gen_satah: for i in 0 to C_HDD_COUNT_MAX-1 generate
--i_hdd_sim_gt_rxdata(i)<=(others=>'0');
--i_hdd_sim_gt_rxcharisk(i)<=(others=>'0');
--i_hdd_sim_gt_rxstatus(i)<=(others=>'0');
--i_hdd_sim_gt_rxelecidle(i)<='0';
--i_hdd_sim_gt_rxdisperr(i)<=(others=>'0');
--i_hdd_sim_gt_rxnotintable(i)<=(others=>'0');
--i_hdd_sim_gt_rxbyteisaligned(i)<='0';
--end generate gen_satah;
--
--m_hdd_rambuf : dsn_hdd_rambuf
--generic map(
--G_MODULE_USE  => C_PCFG_HDD_USE,
--G_RAMBUF_SIZE => C_PCFG_HDD_RAMBUF_SIZE,
--G_DBGCS       => C_PCFG_HDD_DBGCS,
--G_SIM         => G_SIM,
--
--G_MEM_AWIDTH  => C_HREG_MEM_ADR_LAST_BIT,
--G_MEM_DWIDTH  => C_HDEV_DWIDTH
--)
--port map(
---------------------------------
---- ����������������
---------------------------------
--p_in_rbuf_cfg       => i_hdd_rbuf_cfg,
--p_out_rbuf_status   => i_hdd_rbuf_status,
--
----//--------------------------
----//Upstream Port(����� � ������� ��������� ������)
----//--------------------------
--p_in_vbuf_dout      => i_hdd_vbuf_dout,
--p_out_vbuf_rd       => i_hdd_vbuf_rd,
--p_in_vbuf_empty     => i_hdd_vbuf_empty,
--p_in_vbuf_full      => i_hdd_vbuf_full,
--p_in_vbuf_pfull     => i_hdd_vbuf_pfull,
--p_in_vbuf_wrcnt     => i_hdd_vbuf_wrcnt,
--
----//--------------------------
----//����� � ������� HDD
----//--------------------------
--p_out_hdd_txd        => i_hdd_txdata,
--p_out_hdd_txd_wr     => i_hdd_txdata_wd,
--p_in_hdd_txbuf_pfull => i_hdd_txbuf_pfull,
--p_in_hdd_txbuf_full  => i_hdd_txbuf_full,
--p_in_hdd_txbuf_empty => i_hdd_txbuf_empty,
--
--p_in_hdd_rxd         => i_hdd_rxdata,
--p_out_hdd_rxd_rd     => i_hdd_rxdata_rd,
--p_in_hdd_rxbuf_empty => i_hdd_rxbuf_empty,
--p_in_hdd_rxbuf_pempty=> i_hdd_rxbuf_pempty,
--
-----------------------------------
---- ����� � mem_ctrl.vhd
-----------------------------------
--p_out_mem            => i_hdd_memin,
--p_in_mem             => i_hdd_memout,
--
---------------------------------
----���������������
---------------------------------
--p_in_tst            => (others=>'0'),
--p_out_tst           => i_hdd_rbuf_tst_out,
--p_out_dbgcs         => i_hdd_rambuf_dbgcs,
--
---------------------------------
----System
---------------------------------
--p_in_clk => g_usr_highclk,
--p_in_rst => i_hdd_rst
--);


----***********************************************************
----������ ������ ������������ - �������� ����� ������
----***********************************************************
--m_testing : vtester_v01
--generic map(
--G_SIM   => G_SIM
--)
--port map(
---------------------------------
---- ���������� �� �����
---------------------------------
--p_in_host_clk         => g_host_clk,
--
--p_in_cfg_adr          => i_cfg_radr(7 downto 0),
--p_in_cfg_adr_ld       => i_cfg_radr_ld,
--p_in_cfg_adr_fifo     => i_cfg_radr_fifo,
--
--p_in_cfg_txdata       => i_cfg_txd,
--p_in_cfg_wd           => i_cfg_wr_dev(C_CFGDEV_TESTING),
--
--p_out_cfg_rxdata      => i_cfg_rxd_dev(C_CFGDEV_TESTING),
--p_in_cfg_rd           => i_cfg_rd_dev(C_CFGDEV_TESTING),
--
--p_in_cfg_done         => i_cfg_done_dev(C_CFGDEV_TESTING),
--
---------------------------------
---- STATUS ������ dsn_testing.VHD
---------------------------------
--p_out_module_rdy      => open,
--p_out_module_error    => open,
--
---------------------------------
----����� � �������� �������
---------------------------------
--p_out_dst_dout_rdy    => i_dsntst_txdata_rdy,
--p_out_dst_dout        => i_dsntst_txdata_dout,
--p_out_dst_dout_wd     => i_dsntst_txdata_wd,
--p_in_dst_rdy          => i_dsntst_txbuf_empty,
----p_in_dst_clk          => i_dsntst_bufclk,
--
---------------------------------
----���������������
---------------------------------
--p_out_tst             => i_dsntst_tst_out,
--
---------------------------------
----System
---------------------------------
--p_in_tmrclk => g_pciexp_gt_refclkout,
--
--p_in_clk    => i_dsntst_bufclk,
--p_in_rst    => i_dsntst_rst
--);


--***********************************************************
--������ ������ ����� - dsn_host.vhd
--***********************************************************
m_host : dsn_host
generic map(
G_PCIE_LINK_WIDTH => C_PCGF_PCIE_LINK_WIDTH,
G_PCIE_RST_SEL    => C_PCGF_PCIE_RST_SEL,
G_DBG      => G_DBG_PCIE,
G_SIM_HOST => G_SIM_HOST,
G_SIM_PCIE => G_SIM_PCIE
)
port map(
--------------------------------------------------
-- ����� � ������ �� Local bus
--------------------------------------------------
lad                => lad,
lbe_l              => lbe_l,
lads_l             => lads_l,
lwrite             => lwrite,
lblast_l           => lblast_l,
lbterm_l           => lbterm_l,
lready_l           => lready_l,
fholda             => fholda,
finto_l            => finto_l,
lclk               => g_lbus_clk,

--------------------------------------------------
-- ����� � ������ �� PCI-EXPRESS
--------------------------------------------------
p_out_pciexp_txp   => pin_out_pciexp_txp,
p_out_pciexp_txn   => pin_out_pciexp_txn,
p_in_pciexp_rxp    => pin_in_pciexp_rxp,
p_in_pciexp_rxn    => pin_in_pciexp_rxn,

p_in_pciexp_gt_clkin   => i_pciexp_gt_refclk,
p_out_pciexp_gt_clkout => g_pciexp_gt_refclkout,

--------------------------------------------------
--����� � ���-���� ������� Veresk-M
--------------------------------------------------
p_out_hclk         => g_host_clk,
p_out_gctrl        => i_host_gctrl,

p_out_dev_ctrl     => i_host_dev_ctrl,
p_out_dev_din      => i_host_dev_txd,
p_in_dev_dout      => i_host_dev_rxd,
p_out_dev_wr       => i_host_dev_wr,
p_out_dev_rd       => i_host_dev_rd,
p_in_dev_status    => i_host_dev_status,
p_in_dev_irq       => i_host_dev_irq,
p_in_dev_opt       => i_host_dev_opt_in,
p_out_dev_opt      => i_host_dev_opt_out,

--------------------------------------------------
--���������������
--------------------------------------------------
p_in_usr_tst       => i_host_tst_in,
p_out_usr_tst      => i_host_tst_out,
p_in_tst           => (others=>'0'),
p_out_tst          => i_host_tst2_out,

--------------------------------------------------
--System
--------------------------------------------------
p_out_module_rdy   => i_host_rdy,
p_in_rst_n         => i_host_rst_n
);

i_host_tst_in(63 downto 0)<=(others=>'0');
i_host_tst_in(71 downto 64)<=(others=>'0');
i_host_tst_in(72)<=i_eth_module_gt_plllkdet;
i_host_tst_in(73)<='0';--lclk_dcm_lock;
i_host_tst_in(74)<='0';--i_hdd_gt_plldet and i_hdd_dcm_lock;
i_host_tst_in(75)<=i_memctrl_ready;
i_host_tst_in(76)<=AND_reduce(i_memctrl_trained(C_PCFG_MEMCTRL_BANK_COUNT downto 0));
i_host_tst_in(126 downto 77)<=(others=>'0');
i_host_tst_in(127)<=i_vctrl_tst_out(0);-- xor i_hdd_tst_out(0);
                    --i_arb_mem_tst_out(0)  i_hdd_rbuf_tst_out(0) or i_swt_tst_out(0);


--//������� ���������
i_host_dev_status(C_HREG_DEV_STATUS_CFG_RDY_BIT)    <=i_cfg_rdy;
i_host_dev_status(C_HREG_DEV_STATUS_CFG_RXRDY_BIT)  <=i_host_rxrdy(C_HDEV_CFG_DBUF);
i_host_dev_status(C_HREG_DEV_STATUS_CFG_TXRDY_BIT)  <=i_host_txrdy(C_HDEV_CFG_DBUF);

i_host_dev_status(C_HREG_DEV_STATUS_ETH_RDY_BIT)    <=i_eth_rdy;
i_host_dev_status(C_HREG_DEV_STATUS_ETH_CARIER_BIT) <=i_eth_carier;
i_host_dev_status(C_HREG_DEV_STATUS_ETH_RXRDY_BIT)  <=i_host_rxrdy(C_HDEV_ETH_DBUF);
i_host_dev_status(C_HREG_DEV_STATUS_ETH_TXRDY_BIT)  <=i_host_txrdy(C_HDEV_ETH_DBUF);

gen_status_vch : for i in 0 to C_VCTRL_VCH_COUNT_MAX-1 generate
i_host_dev_status(C_HREG_DEV_STATUS_VCH0_FRRDY_BIT + i)<=i_vctrl_hrdy_out(i);
end generate gen_status_vch;

i_host_dev_status(C_HREG_DEV_STATUS_MEMCTRL_RDY_BIT)<=i_memctrl_ready;
i_host_dev_status(C_HREG_DEV_STATUS_TRCNIK_DRDY_BIT)<=i_trcnik_hdrdy;


--//������/������ ������ ��������� �����
i_host_wr(C_HDEV_MEM_DBUF) <=i_host_dev_wr when i_host_devadr=CONV_STD_LOGIC_VECTOR(C_HDEV_MEM_DBUF, i_host_devadr'length) else '0';
i_host_rd(C_HDEV_MEM_DBUF) <=i_host_dev_rd when i_host_devadr=CONV_STD_LOGIC_VECTOR(C_HDEV_MEM_DBUF, i_host_devadr'length) else '0';
i_host_txd(C_HDEV_MEM_DBUF)<=i_host_dev_txd;

i_host_wr(C_HDEV_CFG_DBUF) <=i_host_dev_wr when i_host_devadr=CONV_STD_LOGIC_VECTOR(C_HDEV_CFG_DBUF, i_host_devadr'length) else '0';
i_host_rd(C_HDEV_CFG_DBUF) <=i_host_dev_rd when i_host_devadr=CONV_STD_LOGIC_VECTOR(C_HDEV_CFG_DBUF, i_host_devadr'length) else '0';
i_host_txd(C_HDEV_CFG_DBUF)<=i_host_dev_txd;

i_host_wr(C_HDEV_ETH_DBUF) <=i_host_dev_wr when i_host_devadr=CONV_STD_LOGIC_VECTOR(C_HDEV_ETH_DBUF, i_host_devadr'length) else '0';
i_host_rd(C_HDEV_ETH_DBUF) <=i_host_dev_rd when i_host_devadr=CONV_STD_LOGIC_VECTOR(C_HDEV_ETH_DBUF, i_host_devadr'length) else '0';
i_host_txd(C_HDEV_ETH_DBUF)<=i_host_dev_txd;

i_host_rd(C_HDEV_VCH_DBUF) <=i_host_dev_rd when i_host_devadr=CONV_STD_LOGIC_VECTOR(C_HDEV_VCH_DBUF, i_host_devadr'length) else '0';

i_host_dev_rxd<=i_host_rxd(C_HDEV_CFG_DBUF) when i_host_devadr=CONV_STD_LOGIC_VECTOR(C_HDEV_CFG_DBUF, i_host_devadr'length) else
                i_host_rxd(C_HDEV_ETH_DBUF) when i_host_devadr=CONV_STD_LOGIC_VECTOR(C_HDEV_ETH_DBUF, i_host_devadr'length) else
                i_host_rxd(C_HDEV_VCH_DBUF) when i_host_devadr=CONV_STD_LOGIC_VECTOR(C_HDEV_VCH_DBUF, i_host_devadr'length) else
                i_host_rxd(C_HDEV_MEM_DBUF) when i_host_devadr=CONV_STD_LOGIC_VECTOR(C_HDEV_MEM_DBUF, i_host_devadr'length) else
                (others=>'0');


--//����� (Host<-dev)
i_host_dev_opt_in(C_HDEV_OPTIN_TXFIFO_PFULL_BIT)<=i_host_txbuf_full(C_HDEV_ETH_DBUF) when i_host_devadr=CONV_STD_LOGIC_VECTOR(C_HDEV_ETH_DBUF, i_host_devadr'length) else
                                                 i_host_txbuf_full(C_HDEV_MEM_DBUF) when i_host_devadr=CONV_STD_LOGIC_VECTOR(C_HDEV_MEM_DBUF, i_host_devadr'length) else
                                                 '0';

i_host_dev_opt_in(C_HDEV_OPTIN_RXFIFO_EMPTY_BIT)<=i_host_rxbuf_empty(C_HDEV_ETH_DBUF) when i_host_devadr=CONV_STD_LOGIC_VECTOR(C_HDEV_ETH_DBUF, i_host_devadr'length) else
                                                 i_host_rxbuf_empty(C_HDEV_VCH_DBUF) when i_host_devadr=CONV_STD_LOGIC_VECTOR(C_HDEV_VCH_DBUF, i_host_devadr'length) else
                                                 i_host_rxbuf_empty(C_HDEV_MEM_DBUF) when i_host_devadr=CONV_STD_LOGIC_VECTOR(C_HDEV_MEM_DBUF, i_host_devadr'length) else
                                                 '0';

i_host_dev_opt_in(C_HDEV_OPTIN_MEMTRN_DONE_BIT)<=i_host_mem_status.done;
i_host_dev_opt_in(C_HDEV_OPTIN_VCTRL_FRMRK_M_BIT downto C_HDEV_OPTIN_VCTRL_FRMRK_L_BIT)<=i_vctrl_hfrmrk;
i_host_dev_opt_in(C_HDEV_OPTIN_VCTRL_FRSKIP_M_BIT downto C_HDEV_OPTIN_VCTRL_FRSKIP_L_BIT)<=i_vctrl_tst_out(23 downto 16);
i_host_dev_opt_in(C_HDEV_OPTIN_TRC_DSIZE_M_BIT downto C_HDEV_OPTIN_TRC_DSIZE_L_BIT)<=i_trcnik_hfrmrk;


--//����������
i_host_dev_irq(C_HIRQ_TMR0)  <=i_tmr_hirq(0);
i_host_dev_irq(C_HIRQ_CFG_RX)<=i_host_irq(C_HIRQ_CFG_RX);
i_host_dev_irq(C_HIRQ_ETH_RX)<=i_host_irq(C_HIRQ_ETH_RX);
i_host_dev_irq(C_HIRQ_TRCNIK)<=i_host_irq(C_HIRQ_TRCNIK);
gen_irq_vch : for i in 0 to C_VCTRL_VCH_COUNT_MAX-1 generate
i_host_dev_irq(C_HIRQ_VCH0 + i)<=i_vctrl_hirq_out(i);
end generate gen_irq_vch;


--//��������� ����������� �������� �����
i_host_mem_ctrl.dir       <=not i_host_dev_ctrl(C_HREG_DEV_CTRL_DMA_DIR_BIT);
i_host_mem_ctrl.start     <=i_host_dev_ctrl(C_HREG_DEV_CTRL_DMA_START_BIT) when i_host_devadr=CONV_STD_LOGIC_VECTOR(C_HDEV_MEM_DBUF, i_host_devadr'length) else '0';
i_host_mem_ctrl.adr       <=i_host_dev_opt_out(C_HDEV_OPTOUT_MEM_ADR_M_BIT downto C_HDEV_OPTOUT_MEM_ADR_L_BIT);
i_host_mem_ctrl.req_len   <=i_host_dev_opt_out(C_HDEV_OPTOUT_MEM_RQLEN_M_BIT downto C_HDEV_OPTOUT_MEM_RQLEN_L_BIT);
i_host_mem_ctrl.trnwr_len <=i_host_dev_opt_out(C_HDEV_OPTOUT_MEM_TRNWR_LEN_M_BIT downto C_HDEV_OPTOUT_MEM_TRNWR_LEN_L_BIT);
i_host_mem_ctrl.trnrd_len <=i_host_dev_opt_out(C_HDEV_OPTOUT_MEM_TRNRD_LEN_M_BIT downto C_HDEV_OPTOUT_MEM_TRNRD_LEN_L_BIT);

i_host_rst_all<=i_host_gctrl(C_HREG_CTRL_RST_ALL_BIT);
i_host_rst_eth<=i_host_gctrl(C_HREG_CTRL_RST_ETH_BIT);
i_host_rst_mem<=i_host_gctrl(C_HREG_CTRL_RST_MEM_BIT);
i_host_rddone_vctrl<=i_host_gctrl(C_HREG_CTRL_RDDONE_VCTRL_BIT);
i_host_rddone_trcnik<=i_host_gctrl(C_HREG_CTRL_RDDONE_TRCNIK_BIT);

i_host_devadr<=i_host_dev_ctrl(C_HREG_DEV_CTRL_ADR_M_BIT downto C_HREG_DEV_CTRL_ADR_L_BIT);
i_host_vchsel<=EXT(i_host_dev_ctrl(C_HREG_DEV_CTRL_VCH_M_BIT downto C_HREG_DEV_CTRL_VCH_L_BIT), i_host_vchsel'length);

process(i_host_rst_n, g_host_clk)
begin
  if i_host_rst_n='0' then
    for i in 0 to C_HDEV_COUNT-1 loop
      i_hdev_dma_start(i)<='0';
      hclk_hdev_dma_start(i)<='0';
      hclk_hdev_dma_start_cnt(i)<=(others=>'0');
    end loop;

    hclk_hrddone_vctrl<='0';
    hclk_hrddone_vctrl_cnt<=(others=>'0');

    hclk_hrddone_trcnik<='0';
    hclk_hrddone_trcnik_cnt<=(others=>'0');

  elsif g_host_clk'event and g_host_clk='1' then

    for i in 0 to C_HDEV_COUNT-1 loop
      --//������� ������ DMA ����������
      if i_host_devadr=i then
        if i_host_dev_ctrl(C_HREG_DEV_CTRL_DMA_START_BIT)='1' then
          i_hdev_dma_start(i)<='1';
        else
          i_hdev_dma_start(i)<='0';
        end if;
      end if;
    end loop;--//for

    --//����������� ���������:
    for i in 0 to C_HDEV_COUNT-1 loop
      --//����������� ������� ������ DMA ����������
      if i_hdev_dma_start(i)='1' then
        hclk_hdev_dma_start(i)<='1';
      elsif hclk_hdev_dma_start_cnt(i)="100" then
        hclk_hdev_dma_start(i)<='0';
      end if;

      if hclk_hdev_dma_start(i)='0' then
        hclk_hdev_dma_start_cnt(i)<=(others=>'0');
      else
        hclk_hdev_dma_start_cnt(i)<=hclk_hdev_dma_start_cnt(i)+1;
      end if;
    end loop;

    --//����������� ������� i_host_rddone_vctrl
    if i_host_rddone_vctrl='1' then
      hclk_hrddone_vctrl<='1';
    elsif hclk_hrddone_vctrl_cnt="100" then
      hclk_hrddone_vctrl<='0';
    end if;

    if hclk_hrddone_vctrl='0' then
      hclk_hrddone_vctrl_cnt<=(others=>'0');
    else
      hclk_hrddone_vctrl_cnt<=hclk_hrddone_vctrl_cnt+1;
    end if;

    --//����������� ������� i_host_rddone_trcnik
    if i_host_rddone_trcnik='1' then
      hclk_hrddone_trcnik<='1';
    elsif hclk_hrddone_trcnik_cnt="100" then
      hclk_hrddone_trcnik<='0';
    end if;

    if hclk_hrddone_trcnik='0' then
      hclk_hrddone_trcnik_cnt<=(others=>'0');
    else
      hclk_hrddone_trcnik_cnt<=hclk_hrddone_trcnik_cnt+1;
    end if;

  end if;
end process;

--//����������������� ����������� �������� �����
process(i_host_rst_n, g_usr_highclk)
begin
  if i_host_rst_n='0' then
    i_vctrl_hrd_start<='0';

    i_vctrl_hrd_done<='0';
    i_vctrl_hrd_done_dly<=(others=>'0');

    i_trcnik_hrd_done_dly<=(others=>'0');
    i_trcnik_hrd_done<='0';

  elsif g_usr_highclk'event and g_usr_highclk='1' then
    i_vctrl_hrd_start<=hclk_hdev_dma_start(C_HDEV_VCH_DBUF);

    i_vctrl_hrd_done_dly(0)<=hclk_hrddone_vctrl;
    i_vctrl_hrd_done_dly(1)<=i_vctrl_hrd_done_dly(0);
    i_vctrl_hrd_done<=i_vctrl_hrd_done_dly(0) and not i_vctrl_hrd_done_dly(1);

    i_trcnik_hrd_done_dly(0)<=hclk_hrddone_trcnik;
    i_trcnik_hrd_done_dly(1)<=i_trcnik_hrd_done_dly(0);
    i_trcnik_hrd_done<=i_trcnik_hrd_done_dly(0) and not i_trcnik_hrd_done_dly(1);

  end if;
end process;


--***********************************************************
--������ ����������� ������
--***********************************************************
--����� ������ dsn_host c ���
m_host2mem : pcie2mem_ctrl
generic map(
G_MEM_AWIDTH     => C_HREG_MEM_ADR_LAST_BIT,
G_MEM_DWIDTH     => C_HDEV_DWIDTH,
G_MEM_BANK_M_BIT => C_HREG_MEM_ADR_BANK_M_BIT,
G_MEM_BANK_L_BIT => C_HREG_MEM_ADR_BANK_L_BIT,
G_DBG            => G_SIM
)
port map(
-------------------------------
--����������
-------------------------------
p_in_ctrl         => i_host_mem_ctrl,
p_out_status      => i_host_mem_status,

p_in_txd          => i_host_txd(C_HDEV_MEM_DBUF),
p_in_txd_wr       => i_host_wr(C_HDEV_MEM_DBUF),
p_out_txbuf_full  => i_host_txbuf_full(C_HDEV_MEM_DBUF),

p_out_rxd         => i_host_rxd(C_HDEV_MEM_DBUF),
p_in_rxd_rd       => i_host_rd(C_HDEV_MEM_DBUF),
p_out_rxbuf_empty => i_host_rxbuf_empty(C_HDEV_MEM_DBUF),

p_in_hclk         => g_host_clk,

-------------------------------
--����� � mem_ctrl
-------------------------------
p_out_mem         => i_host_memin,
p_in_mem          => i_host_memout,

-------------------------------
--���������������
-------------------------------
p_in_tst          => (others=>'0'),
p_out_tst         => i_host_mem_tst_out,

-------------------------------
--System
-------------------------------
p_in_clk         => g_usr_highclk,
p_in_rst         => i_arb_mem_rst
);

--//���������� ���������� � ������� ���
i_memin_ch(0) <= i_host_memin;
i_host_memout    <= i_memout_ch(0);

i_memin_ch(1) <= i_vctrlwr_memin;
i_vctrlwr_memout <= i_memout_ch(1);

i_memin_ch(2) <= i_vctrlrd_memin;
i_vctrlrd_memout <= i_memout_ch(2);

--gen_ch34sel0 : if (strcmp(C_PCFG_HDD_USE,"ON")  and strcmp(C_PCFG_TRC_USE,"ON")) or
--                (strcmp(C_PCFG_HDD_USE,"OFF") and strcmp(C_PCFG_TRC_USE,"OFF")) or
--                (strcmp(C_PCFG_HDD_USE,"ON")  and strcmp(C_PCFG_TRC_USE,"OFF")) generate
----CH3
--i_memin_ch(3)<= i_hdd_memin;
--i_hdd_memout    <= i_memout_ch(3);
--
----CH4
--i_memin_ch(4)<= i_trc_memin;
--i_trc_memout    <= i_memout_ch(4);
--
--end generate gen_chs34el0;
--
--gen_ch34sel1 : if (strcmp(C_PCFG_HDD_USE,"OFF") and strcmp(C_PCFG_TRC_USE,"ON")) generate
--CH3
i_memin_ch(3) <= i_trc_memin;
i_trc_memout     <= i_memout_ch(3);

----CH4
--i_memin_ch(4)<= i_hdd_memin;
--i_hdd_memout    <= i_memout_ch(4);
--
--end generate gen_ch34sel1;

--//������ ����������� ������
m_mem_arb : mem_arb
generic map(
G_CH_COUNT   => selval(10#04#,10#03#, strcmp(C_PCFG_TRC_USE,"ON")),--selval2(10#05#,10#04#,10#04#,10#03#, strcmp(C_PCFG_HDD_USE,"ON"),strcmp(C_PCFG_TRC_USE,"ON")),
G_MEM_AWIDTH => C_HREG_MEM_ADR_LAST_BIT,
G_MEM_DWIDTH => C_HDEV_DWIDTH
)
port map(
-------------------------------
--����� � �������������� ���
-------------------------------
p_in_memch  => i_memin_ch,
p_out_memch => i_memout_ch,

-------------------------------
--����� � mem_ctrl.vhd
-------------------------------
p_out_mem   => i_arb_memin,
p_in_mem    => i_arb_memout,

-------------------------------
--���������������
-------------------------------
p_in_tst    => (others=>'0'),
p_out_tst   => i_arb_mem_tst_out,

-------------------------------
--System
-------------------------------
p_in_clk    => g_usr_highclk,
p_in_rst    => i_arb_mem_rst
);


m_mem_ctrl : mem_ctrl
generic map(
G_BANK_COUNT => C_PCFG_MEMCTRL_BANK_COUNT,
G_SIM        => G_SIM
)
port map(
-----------------------------
--Memory pins
-----------------------------
ra0        => ra0,
rc0        => rc0,
rd0        => rd0,

-----------------------------
-- User channel 0
-----------------------------
p_in_mem   => i_arb_memin,
p_out_mem  => i_arb_memout,

-----------------------------
--Status
-----------------------------
trained    => i_memctrl_trained,

-----------------------------
--System
-----------------------------
memclk0    => i_memctrl_pllclk0,
memclk45   => i_memctrl_pllclk45,
memclk2x0  => i_memctrl_pllclk2x0,
memclk2x90 => i_memctrl_pllclk2x90,
memrst     => i_memctrl_pll_rst_out,
rst        => i_memctrl_rst
);

i_memctrl_ready<=i_memctrl_locked(0);


--//#########################################
--//DBG
--//#########################################
--//��� ����� ALPHA DATA
gen_alphadata : if strcmp(C_PCFG_BOARD,"ALPHA_DATA") generate
begin

pin_out_led<=(others=>'0');
pin_out_led_C<=pin_in_btn_C;
pin_out_led_E<=pin_in_btn_E;
pin_out_led_N<=pin_in_btn_N;
pin_out_led_S<=pin_in_btn_S;
pin_out_led_W<=pin_in_btn_W;

pin_out_TP(0)<=pin_in_btn_C;
pin_out_TP(1)<=pin_in_btn_E;
pin_out_TP(2)<=pin_in_btn_N;
pin_out_TP(3)<=pin_in_btn_S;
pin_out_TP(4)<=pin_in_btn_W;
pin_out_TP(pin_out_TP'high downto 5)<=(others=>'0');

pin_out_ddr2_cke1<='0';
pin_out_ddr2_cs1<='0';
pin_out_ddr2_odt1<='0';

i_usr_rst<='0';
--i_hdd_tst_in<=(others=>'0');

end generate gen_alphadata;


--//��� ����� ML505
gen_ml505 : if strcmp(C_PCFG_BOARD,"ML505") generate

pin_out_ddr2_cke1<='0';
pin_out_ddr2_cs1<='0';
pin_out_ddr2_odt1<='0';

i_usr_rst<=pin_in_btn_N;
--i_hdd_tst_in(0)<=pin_in_btn_W;
--i_hdd_tst_in(31 downto 1)<=(others=>'0');

--i_trc_busy<=(others=>'0');

--//J5 /pin2
pin_out_TP(0)<=pin_in_btn_E or i_trc_busy(0);

--//J6
pin_out_TP(1)<=pin_in_btn_C;--i_dsntst_tst_out(1);  --//pin6
                            --//pin8
pin_out_TP(2)<='0';         --//pin10
pin_out_TP(3)<='0';
                            --//pin14
pin_out_TP(4)<='0';         --//pin16
                            --//pin18
pin_out_TP(5)<='0';         -- /pin20
                            --//pin22
pin_out_TP(6)<='0';         -- /pin24
pin_out_TP(7)<='0';         -- /pin26

--����������
pin_out_led_E<='0';         --i_hdd_gt_plldet and i_hdd_dcm_lock;
pin_out_led_N<=i_test01_led;--i_test01_ledlclk_dcm_lock when pin_in_btn_S='0' else i_test01_led;
pin_out_led_S<='0';
pin_out_led_W<='0';         --'0' when pin_in_btn_W='0' else i_hdd_dbgled(1).spd(1);
pin_out_led_C<='0';         --not lclk_dcm_lock or i_usr_rst when pin_in_btn_W='0' else i_hdd_dbgled(1).spd(0);

pin_out_led(0)<='0'; --i_hdd_dbgled(1).busy;
pin_out_led(1)<='0'; --i_hdd_dbgled(1).err;
pin_out_led(2)<='0'; --i_hdd_dbgled(1).rdy;
pin_out_led(3)<='0'; --i_hdd_dbgled(1).link;

pin_out_led(4)<='0'; --i_hdd_dbgled(0).busy;
pin_out_led(5)<='0'; --i_hdd_dbgled(0).err;
pin_out_led(6)<='0'; --i_hdd_dbgled(0).rdy;
pin_out_led(7)<='0'; --i_hdd_dbgled(0).link;

m_gt_03_test: fpga_test_01
generic map(
G_BLINK_T05   =>10#250#, -- 1/2 ������� ������� ����������.(����� � ms)
G_CLK_T05us   =>10#75#   -- 05us - 150MHz
)
port map(
p_out_test_led => i_test01_led,
p_out_test_done=> open,

p_out_1us      => open,
p_out_1ms      => open,
-------------------------------
--System
-------------------------------
p_in_clk       => g_host_clk,
p_in_rst       => i_cfg_rst
);

end generate gen_ml505;


end architecture;
