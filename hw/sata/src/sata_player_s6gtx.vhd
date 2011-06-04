-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 03.04.2011 11:49:15
-- Module Name : sata_player_gt
--
-- ����������/�������� :
--   1. ����� ���������� GTX(gig tx/rx) c sata_host.vhd
--
-- Revision:
-- Revision 0.01 - File Created
--
--------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.vicg_common_pkg.all;
use work.sata_pkg.all;

entity sata_player_gt is
generic
(
G_GT_CH_COUNT: integer := 2;
G_GT_DBUS    : integer := 16;
G_SIM        : string  := "OFF"
);
port
(
---------------------------------------------------------------------------
--Usr Cfg
---------------------------------------------------------------------------
p_in_spd               : in    TSpdCtrl_GTCH;
p_in_sys_dcm_gclk2div  : in    std_logic;--//dcm_clk0 /2
p_in_sys_dcm_gclk      : in    std_logic;--//dcm_clk0
p_in_sys_dcm_gclk2x    : in    std_logic;--//dcm_clk0 x 2

p_out_usrclk2          : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0); --//������������ ������� sata_host.vhd
p_out_resetdone        : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);

---------------------------------------------------------------------------
--Driver(������� ���������� �� ������)
---------------------------------------------------------------------------
p_out_txn              : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_out_txp              : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_in_rxn               : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_in_rxp               : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);

---------------------------------------------------------------------------
--Tranceiver
---------------------------------------------------------------------------
p_in_txelecidle        : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0); --//���������� �������� OOB ��������
p_in_txcomstart        : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0); --//������ �������� OOB �������
p_in_txcomtype         : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0); --//����� ���� OOB �������
p_in_txdata            : in    TBus32_GTCH;                                   --//����� ������ ��� ����������� DUAL_GTP
p_in_txcharisk         : in    TBus04_GTCH;                                   --//������� ������� ���.�������� �� ����� txdata

p_in_txreset           : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0); --//����� �����������
p_out_txbufstatus      : out   TBus02_GTCH;

---------------------------------------------------------------------------
--Receiver
---------------------------------------------------------------------------
p_in_rxcdrreset        : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0); --//����� GT RxPCS + PMA
p_in_rxreset           : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0); --//����� GT RxPCS
p_out_rxelecidle       : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0); --//����������� ���������� OOB �������
p_out_rxstatus         : out   TBus03_GTCH;                                    --//��� ������������� OOB �������
p_out_rxdata           : out   TBus32_GTCH;                                    --//����� ������ �� ��������� DUAL_GTP
p_out_rxcharisk        : out   TBus04_GTCH;                                    --//������� ������� ���.�������� � rxdata
p_out_rxdisperr        : out   TBus04_GTCH;                                    --//������ �������� � �������� ������
p_out_rxnotintable     : out   TBus04_GTCH;                                    --//
p_out_rxbyteisaligned  : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);  --//������ ��������� �� ������

p_in_rxbufreset        : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_out_rxbufstatus      : out   TBus03_GTCH;

----------------------------------------------------------------------------
--System
----------------------------------------------------------------------------
--���� ������������� ���������������� DUAL_GTP
p_in_drpclk            : in    std_logic;
p_in_drpaddr           : in    std_logic_vector(7 downto 0);
p_in_drpen             : in    std_logic;
p_in_drpwe             : in    std_logic;
p_in_drpdi             : in    std_logic_vector(15 downto 0);
p_out_drpdo            : out   std_logic_vector(15 downto 0);
p_out_drprdy           : out   std_logic;

p_out_plllock          : out   std_logic;--//������ ������� PLL DUAL_GTP
p_out_refclkout        : out   std_logic;--//���������� ������������ p_in_refclkin. ��. ���.68. ug196.pdf

p_in_refclkin          : in    std_logic;--//������� ������ ��� ������ DUAL_GTP
p_in_rst               : in    std_logic
);
end sata_player_gt;

architecture behavioral of sata_player_gt is

--//1 - ������ ��� ������ G_GT_DBUS=8
--//2 - ��� ���� ������ �������. ������������� �� ������ �������. �� Figure 7-15: Comma Alignment Boundaries ,
--      ug196_Virtex-5 FPGA RocketIO GTP Transceiver User Guide.pdf
constant C_GTP_ALIGN_COMMA_WORD    : integer := selval(1, 2, cmpval(G_GT_DBUS, 8));
constant C_GTP_DATAWIDTH           : std_logic_vector(1 downto 0):=CONV_STD_LOGIC_VECTOR(selval(0, selval(1, 2, cmpval(G_GT_DBUS, 16)), cmpval(G_GT_DBUS, 8)), C_GTP_DATAWIDTH'length);

signal i_refclkin                  : std_logic_vector(1 downto 0);
signal i_txcomsas                  : std_logic;
signal i_txcominit                 : std_logic;
signal i_txcomwake                 : std_logic;
signal i_txcom_finish              : std_logic;
signal i_rxcominit                 : std_logic;
signal i_rxcomwake                 : std_logic;

signal i_plllkdet                  : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal i_resetdone                 : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);

signal i_rxelecidle                : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);

signal i_spdclk_sel                : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal g_gtp_usrclk                : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal g_gtp_usrclk2               : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);


signal i_txelecidle_in             : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal i_txcomstart_in             : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal i_txcomtype_in              : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal i_txdata_in                 : TBus32_GTCH;
signal i_txcharisk_in              : TBus04_GTCH;

signal i_txreset_in                : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal i_txbufstatus_out           : TBus02_GTCH;

signal i_rxcdrreset_in             : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal i_rxreset_in                : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);

signal i_rxstatus_out              : TBus03_GTCH;
signal i_rxdata_out                : TBus32_GTCH;
signal i_rxcharisk_out             : TBus04_GTCH;
signal i_rxdisperr_out             : TBus04_GTCH;
signal i_rxnotintable_out          : TBus04_GTCH;
signal i_rxbyteisaligned_out       : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);

signal i_rxbufreset_in             : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal i_rxbufstatus_out           : TBus03_GTCH;

signal i_refclkout                 : std_logic_vector(1 downto 0);
signal i_refclkout_o               : std_logic_vector(1 downto 0);
signal i_gtpclkfbwest              : std_logic_vector(1 downto 0);
signal i_gtpclkfbwest_out          : std_logic_vector(1 downto 0);

signal  tied_to_ground_i           : std_logic;
signal  tied_to_ground_vec_i       : std_logic_vector(63 downto 0);
signal  tied_to_vcc_i              : std_logic;
signal  tied_to_vcc_vec_i          : std_logic_vector(63 downto 0);

attribute keep : string;
attribute keep of g_gtp_usrclk : signal is "true";


--MAIN
begin


gen_null : for i in 0 to C_GTCH_COUNT_MAX-1 generate
m_BUFIO2FB : BUFIO2FB
generic map(
DIVIDE_BYPASS =>TRUE--Bypassdivider(TRUE/FALSE)
)
port map(O =>i_gtpclkfbwest_out(i), I =>i_gtpclkfbwest(i));

m_BUFIO2 : BUFIO2
generic map(
DIVIDE        => 1,
DIVIDE_BYPASS => TRUE,
I_INVERT      => FALSE,
USE_DOUBLER   => FALSE
)
port map(
I            => i_refclkout(i),  --1-bitinput:Clockinput(connecttoIBUFG)
DIVCLK       => open,            --1-bitoutput:Dividedclockoutput
IOCLK        => i_refclkout_o(i),--1-bitoutput:I/Ooutputclock
SERDESSTROBE => open,            --1-bitoutput:OutputSERDESstrobe(connecttoISERDES2/OSERDES2)
);

end generate gen_null;


gen_gt_ch1 : if G_GT_CH_COUNT=1 generate
i_txelecidle_in(1)      <='0';
i_txcomstart_in(1)      <='0';
i_txcomtype_in(1)       <='0';
i_txdata_in(1)(15 downto 0)  <=(others=>'0');
i_txcharisk_in(1)(1 downto 0)<=(others=>'0');

i_txreset_in(1)         <='0';
p_out_txbufstatus(1)    <=(others=>'0');

i_rxcdrreset_in(1)      <='0';
i_rxreset_in(1)         <='0';
p_out_rxelecidle(1)     <='0';
p_out_rxstatus(1)       <=(others=>'0');
p_out_rxdata(1)(15 downto 0)     <=(others=>'0');
p_out_rxcharisk(1)(1 downto 0)   <=(others=>'0');
p_out_rxdisperr(1)(1 downto 0)   <=(others=>'0');
p_out_rxnotintable(1)(1 downto 0)<=(others=>'0');
p_out_rxbyteisaligned(1)<='0';

i_rxbufreset_in(1)      <='0';
p_out_rxbufstatus(1)    <=(others=>'0');


g_gtp_usrclk(1) <=g_gtp_usrclk(0);
g_gtp_usrclk2(1)<=g_gtp_usrclk2(0);

p_out_usrclk2(1)<=g_gtp_usrclk2(0);
p_out_resetdone(1)<=i_resetdone(0);

end generate gen_gt_ch1;

--#########################################
--//����� �������� ������ ��� ������ SATA
--#########################################
gen_ch : for i in 0 to G_GT_CH_COUNT-1 generate

i_spdclk_sel(i)<='0' when p_in_spd(i).sata_ver=CONV_STD_LOGIC_VECTOR(C_FSATA_GEN2, p_in_spd(i).sata_ver'length) else '1';

--//------------------------------
--//GT: ���� �����=8bit
--//------------------------------
gen_gtp_w8 : if G_GT_DBUS=8 generate
m_bufg_usrclk2 : BUFGMUX_CTRL
port map
(
S  => i_spdclk_sel(i),
I0 => p_in_sys_dcm_gclk2x,  --//S=0 - SATA Generation 2 (3Gb/s)
I1 => p_in_sys_dcm_gclk,    --//S=1 - SATA Generation 1 (1.5Gb/s)
O  => g_gtp_usrclk2(i)
);
g_gtp_usrclk(i)<=g_gtp_usrclk2(i);
end generate gen_gtp_w8;

--//------------------------------
--//GT: ���� �����=16bit
--//------------------------------
gen_gtp_w16 : if G_GT_DBUS=16 generate
m_bufg_usrclk2 : BUFGMUX_CTRL
port map
(
S  => i_spdclk_sel(i),
I0 => p_in_sys_dcm_gclk,    --//S=0 - SATA Generation 2 (3Gb/s)
I1 => p_in_sys_dcm_gclk2div,--//S=1 - SATA Generation 1 (1.5Gb/s)
O  => g_gtp_usrclk2(i)
);
m_bufg_usrclk : BUFGMUX_CTRL
port map
(
S  => i_spdclk_sel(i),
I0 => p_in_sys_dcm_gclk2x,  --//S=0 - SATA Generation 2 (3Gb/s)
I1 => p_in_sys_dcm_gclk,    --//S=1 - SATA Generation 1 (1.5Gb/s)
O  => g_gtp_usrclk(i)
);
end generate gen_gtp_w16;

--//------------------------------
--//GT: ���� �����=32bit
--//------------------------------
gen_gtp_w32 : if G_GT_DBUS=32 generate
m_bufg_usrclk2 : BUFGMUX_CTRL
port map
(
S  => i_spdclk_sel(i),
I0 => p_in_sys_dcm_gclk,    --//S=0 - SATA Generation 2 (3Gb/s)
I1 => p_in_sys_dcm_gclk2div,--//S=1 - SATA Generation 1 (1.5Gb/s)
O  => g_gtp_usrclk2(i)
);
m_bufg_usrclk : BUFGMUX_CTRL
port map
(
S  => i_spdclk_sel(i),
I0 => p_in_sys_dcm_gclk2x,  --//S=0 - SATA Generation 2 (3Gb/s)
I1 => p_in_sys_dcm_gclk,    --//S=1 - SATA Generation 1 (1.5Gb/s)
O  => g_gtp_usrclk(i)
);
end generate gen_gtp_w32;

p_out_usrclk2(i)<=g_gtp_usrclk2(i);


process(g_gtp_usrclk2(i))
begin
  if g_gtp_usrclk2(i)'event and g_gtp_usrclk2(i)='1' then
      p_out_resetdone(i)      <=i_resetdone(i);

      i_txelecidle_in(i)      <=p_in_txelecidle(i);
      i_txcomstart_in(i)      <=p_in_txcomstart(i);
      i_txcomtype_in(i)       <=p_in_txcomtype(i);
      i_txdata_in(i)(31 downto 0)  <=p_in_txdata(i)(31 downto 0);
      i_txcharisk_in(i)(3 downto 0)<=p_in_txcharisk(i)(3 downto 0);

      i_txreset_in(i)         <=p_in_txreset(i);
      p_out_txbufstatus(i)    <=i_txbufstatus_out(i);

      i_rxcdrreset_in(i)      <=p_in_rxcdrreset(i);
      i_rxreset_in(i)         <=p_in_rxreset(i);
      p_out_rxelecidle(i)     <=i_rxelecidle(i);
--      p_out_rxstatus(i)       <=i_rxstatus_out(i);
      p_out_rxstatus(i)(2)<=i_rxcominit;
      p_out_rxstatus(i)(1)<=i_rxcomwake;
      p_out_rxstatus(i)(0)<=i_txcom_finish;

      p_out_rxdata(i)(31 downto 0)     <=i_rxdata_out(i)(31 downto 0);
      p_out_rxcharisk(i)(3 downto 0)   <=i_rxcharisk_out(i)(3 downto 0);
      p_out_rxdisperr(i)(3 downto 0)   <=i_rxdisperr_out(i)(3 downto 0);
      p_out_rxnotintable(i)(3 downto 0)<=i_rxnotintable_out(i)(3 downto 0);
      p_out_rxbyteisaligned(i)         <=i_rxbyteisaligned_out(i);

      i_rxbufreset_in(i)      <=p_in_rxbufreset(i);
      p_out_rxbufstatus(i)    <=i_rxbufstatus_out(i);
  end if;
end process;

end generate gen_ch;



--//###########################
--//Gig Tx/Rx
--//###########################
tied_to_ground_i     <= '0';
tied_to_ground_vec_i <= (others => '0');
tied_to_vcc_i        <= '1';
tied_to_vcc_vec_i    <= (others => '1');

p_out_plllock<=AND_reduce(i_plllkdet(G_GT_CH_COUNT-1 downto 0));
p_out_refclkout<=i_refclkout_o(0);



m_gt : GTPA1_DUAL
generic map
(

--_______________________ Simulation-Only Attributes ___________________

SIM_RECEIVER_DETECT_PASS    =>      (TRUE),
SIM_TX_ELEC_IDLE_LEVEL      =>      ("Z"),
SIM_VERSION                 =>      ("2.0"),

SIM_REFCLK0_SOURCE          =>      ("000"),
SIM_REFCLK1_SOURCE          =>      ("000"),

SIM_GTPRESET_SPEEDUP        =>      1,--(TILE_SIM_GTPRESET_SPEEDUP),  --//############################### add vicg
CLK25_DIVIDER_0             =>      6, --����� ��� ��� V5             --//############################### add vicg
CLK25_DIVIDER_1             =>      6, --����� ��� ��� V5             --//############################### add vicg
PLL_DIVSEL_FB_0             =>      2, --����� ��� ��� V5             --//############################### add vicg
PLL_DIVSEL_FB_1             =>      2, --����� ��� ��� V5             --//############################### add vicg
PLL_DIVSEL_REF_0            =>      1, --����� ��� ��� V5             --//############################### add vicg
PLL_DIVSEL_REF_1            =>      1, --����� ��� ��� V5             --//############################### add vicg


--PLL Attributes
CLKINDC_B_0                             =>     (TRUE),
CLKRCV_TRST_0                           =>     (TRUE),
OOB_CLK_DIVIDER_0                       =>     (6),
PLL_COM_CFG_0                           =>     (x"21680a"),
PLL_CP_CFG_0                            =>     (x"00"),
PLL_RXDIVSEL_OUT_0                      =>     (1),
PLL_SATA_0                              =>     (FALSE),
PLL_SOURCE_0                            =>     (TILE_PLL_SOURCE_0),
PLL_TXDIVSEL_OUT_0                      =>     (1),
PLLLKDET_CFG_0                          =>     ("111"),

--
CLKINDC_B_1                             =>     (TRUE),
CLKRCV_TRST_1                           =>     (TRUE),
OOB_CLK_DIVIDER_1                       =>     (6),
PLL_COM_CFG_1                           =>     (x"21680a"),
PLL_CP_CFG_1                            =>     (x"00"),
PLL_RXDIVSEL_OUT_1                      =>     (1),
PLL_SATA_1                              =>     (FALSE),
PLL_SOURCE_1                            =>     (TILE_PLL_SOURCE_1),
PLL_TXDIVSEL_OUT_1                      =>     (1),
PLLLKDET_CFG_1                          =>     ("111"),
PMA_COM_CFG_EAST                        =>     (x"000008000"),
PMA_COM_CFG_WEST                        =>     (x"00000a000"),
TST_ATTR_0                              =>     (x"00000000"),
TST_ATTR_1                              =>     (x"00000000"),

--TX Interface Attributes
CLK_OUT_GTP_SEL_0                       =>     ("REFCLKPLL0"),--("TXOUTCLK0"),  --//############################### add vicg
TX_TDCC_CFG_0                           =>     ("11"),
CLK_OUT_GTP_SEL_1                       =>     ("REFCLKPLL0"),--("TXOUTCLK1"),  --//############################### add vicg
TX_TDCC_CFG_1                           =>     ("11"),

--TX Buffer and Phase Alignment Attributes
PMA_TX_CFG_0                            =>     (x"00082"),
TX_BUFFER_USE_0                         =>     (TRUE),
TX_XCLK_SEL_0                           =>     ("TXOUT"),
TXRX_INVERT_0                           =>     ("011"),
PMA_TX_CFG_1                            =>     (x"00082"),
TX_BUFFER_USE_1                         =>     (TRUE),
TX_XCLK_SEL_1                           =>     ("TXOUT"),
TXRX_INVERT_1                           =>     ("011"),

--TX Driver and OOB signalling Attributes
CM_TRIM_0                               =>     ("00"),
TX_IDLE_DELAY_0                         =>     ("011"),
CM_TRIM_1                               =>     ("00"),
TX_IDLE_DELAY_1                         =>     ("011"),

--TX PIPE/SATA Attributes
COM_BURST_VAL_0                         =>     ("1111"),
COM_BURST_VAL_1                         =>     ("1111"),

--RX Driver,OOB signalling,Coupling and Eq,CDR Attributes
AC_CAP_DIS_0                            =>     (FALSE),
OOBDETECT_THRESHOLD_0                   =>     ("110"),
PMA_CDR_SCAN_0                          =>     (x"6404040"),
PMA_RX_CFG_0                            =>     (x"05ce089"),
PMA_RXSYNC_CFG_0                        =>     (x"00"),
RCV_TERM_GND_0                          =>     (FALSE),
RCV_TERM_VTTRX_0                        =>     (TRUE),
RXEQ_CFG_0                              =>     ("01111011"),
TERMINATION_CTRL_0                      =>     ("10100"),
TERMINATION_OVRD_0                      =>     (FALSE),
TX_DETECT_RX_CFG_0                      =>     (x"1832"),
AC_CAP_DIS_1                            =>     (FALSE),
OOBDETECT_THRESHOLD_1                   =>     ("110"),
PMA_CDR_SCAN_1                          =>     (x"6404040"),
PMA_RX_CFG_1                            =>     (x"05ce089"),
PMA_RXSYNC_CFG_1                        =>     (x"00"),
RCV_TERM_GND_1                          =>     (FALSE),
RCV_TERM_VTTRX_1                        =>     (TRUE),
RXEQ_CFG_1                              =>     ("01111011"),
TERMINATION_CTRL_1                      =>     ("10100"),
TERMINATION_OVRD_1                      =>     (FALSE),
TX_DETECT_RX_CFG_1                      =>     (x"1832"),

--PRBS Detection Attributes
RXPRBSERR_LOOPBACK_0                    =>     ('0'),
RXPRBSERR_LOOPBACK_1                    =>     ('0'),

--Comma Detection and Alignment Attributes
ALIGN_COMMA_WORD_0                      =>     C_GTP_ALIGN_COMMA_WORD,
COMMA_10B_ENABLE_0                      =>     ("1111111111"),
DEC_MCOMMA_DETECT_0                     =>     (TRUE),
DEC_PCOMMA_DETECT_0                     =>     (TRUE),
DEC_VALID_COMMA_ONLY_0                  =>     (FALSE),
MCOMMA_10B_VALUE_0                      =>     ("1010000011"),
MCOMMA_DETECT_0                         =>     (TRUE),
PCOMMA_10B_VALUE_0                      =>     ("0101111100"),
PCOMMA_DETECT_0                         =>     (TRUE),
RX_SLIDE_MODE_0                         =>     ("PCS"),
ALIGN_COMMA_WORD_1                      =>     C_GTP_ALIGN_COMMA_WORD,
COMMA_10B_ENABLE_1                      =>     ("1111111111"),
DEC_MCOMMA_DETECT_1                     =>     (TRUE),
DEC_PCOMMA_DETECT_1                     =>     (TRUE),
DEC_VALID_COMMA_ONLY_1                  =>     (FALSE),
MCOMMA_10B_VALUE_1                      =>     ("1010000011"),
MCOMMA_DETECT_1                         =>     (TRUE),
PCOMMA_10B_VALUE_1                      =>     ("0101111100"),
PCOMMA_DETECT_1                         =>     (TRUE),
RX_SLIDE_MODE_1                         =>     ("PCS"),

--RX Loss-of-sync State Machine Attributes
RX_LOS_INVALID_INCR_0                   =>     (8),
RX_LOS_THRESHOLD_0                      =>     (128),
RX_LOSS_OF_SYNC_FSM_0                   =>     (FALSE),
RX_LOS_INVALID_INCR_1                   =>     (8),
RX_LOS_THRESHOLD_1                      =>     (128),
RX_LOSS_OF_SYNC_FSM_1                   =>     (FALSE),

--RX Elastic Buffer and Phase alignment Attributes
RX_BUFFER_USE_0                         =>     (TRUE),
RX_EN_IDLE_RESET_BUF_0                  =>     (TRUE),
RX_IDLE_HI_CNT_0                        =>     ("1000"),
RX_IDLE_LO_CNT_0                        =>     ("0000"),
RX_XCLK_SEL_0                           =>     ("RXREC"),
RX_BUFFER_USE_1                         =>     (TRUE),
RX_EN_IDLE_RESET_BUF_1                  =>     (TRUE),
RX_IDLE_HI_CNT_1                        =>     ("1000"),
RX_IDLE_LO_CNT_1                        =>     ("0000"),
RX_XCLK_SEL_1                           =>     ("RXREC"),

--Clock Correction Attributes
CLK_COR_ADJ_LEN_0                       =>     (4),
CLK_COR_DET_LEN_0                       =>     (4),
CLK_COR_INSERT_IDLE_FLAG_0              =>     (FALSE),
CLK_COR_KEEP_IDLE_0                     =>     (FALSE),
CLK_COR_MAX_LAT_0                       =>     (18),
CLK_COR_MIN_LAT_0                       =>     (16),
CLK_COR_PRECEDENCE_0                    =>     (TRUE),
CLK_COR_REPEAT_WAIT_0                   =>     (0),
CLK_COR_SEQ_1_1_0                       =>     ("0110111100"),
CLK_COR_SEQ_1_2_0                       =>     ("0001001010"),
CLK_COR_SEQ_1_3_0                       =>     ("0001001010"),
CLK_COR_SEQ_1_4_0                       =>     ("0001111011"),
CLK_COR_SEQ_1_ENABLE_0                  =>     ("1111"),
CLK_COR_SEQ_2_1_0                       =>     ("0100000000"),
CLK_COR_SEQ_2_2_0                       =>     ("0000000000"),
CLK_COR_SEQ_2_3_0                       =>     ("0000000000"),
CLK_COR_SEQ_2_4_0                       =>     ("0000000000"),
CLK_COR_SEQ_2_ENABLE_0                  =>     ("0000"),
CLK_COR_SEQ_2_USE_0                     =>     (FALSE),
CLK_CORRECT_USE_0                       =>     (TRUE),
RX_DECODE_SEQ_MATCH_0                   =>     (TRUE),
CLK_COR_ADJ_LEN_1                       =>     (4),
CLK_COR_DET_LEN_1                       =>     (4),
CLK_COR_INSERT_IDLE_FLAG_1              =>     (FALSE),
CLK_COR_KEEP_IDLE_1                     =>     (FALSE),
CLK_COR_MAX_LAT_1                       =>     (18),
CLK_COR_MIN_LAT_1                       =>     (16),
CLK_COR_PRECEDENCE_1                    =>     (TRUE),
CLK_COR_REPEAT_WAIT_1                   =>     (0),
CLK_COR_SEQ_1_1_1                       =>     ("0110111100"),
CLK_COR_SEQ_1_2_1                       =>     ("0001001010"),
CLK_COR_SEQ_1_3_1                       =>     ("0001001010"),
CLK_COR_SEQ_1_4_1                       =>     ("0001111011"),
CLK_COR_SEQ_1_ENABLE_1                  =>     ("1111"),
CLK_COR_SEQ_2_1_1                       =>     ("0100000000"),
CLK_COR_SEQ_2_2_1                       =>     ("0000000000"),
CLK_COR_SEQ_2_3_1                       =>     ("0000000000"),
CLK_COR_SEQ_2_4_1                       =>     ("0000000000"),
CLK_COR_SEQ_2_ENABLE_1                  =>     ("0000"),
CLK_COR_SEQ_2_USE_1                     =>     (FALSE),
CLK_CORRECT_USE_1                       =>     (TRUE),
RX_DECODE_SEQ_MATCH_1                   =>     (TRUE),

--Channel Bonding Attributes
CHAN_BOND_1_MAX_SKEW_0                  =>     (1),
CHAN_BOND_2_MAX_SKEW_0                  =>     (1),
CHAN_BOND_KEEP_ALIGN_0                  =>     (FALSE),
CHAN_BOND_SEQ_1_1_0                     =>     ("0000000000"),
CHAN_BOND_SEQ_1_2_0                     =>     ("0000000000"),
CHAN_BOND_SEQ_1_3_0                     =>     ("0000000000"),
CHAN_BOND_SEQ_1_4_0                     =>     ("0000000000"),
CHAN_BOND_SEQ_1_ENABLE_0                =>     ("0000"),
CHAN_BOND_SEQ_2_1_0                     =>     ("0000000000"),
CHAN_BOND_SEQ_2_2_0                     =>     ("0000000000"),
CHAN_BOND_SEQ_2_3_0                     =>     ("0000000000"),
CHAN_BOND_SEQ_2_4_0                     =>     ("0000000000"),
CHAN_BOND_SEQ_2_ENABLE_0                =>     ("0000"),
CHAN_BOND_SEQ_2_USE_0                   =>     (FALSE),
CHAN_BOND_SEQ_LEN_0                     =>     (1),
RX_EN_MODE_RESET_BUF_0                  =>     (TRUE),
CHAN_BOND_1_MAX_SKEW_1                  =>     (1),
CHAN_BOND_2_MAX_SKEW_1                  =>     (1),
CHAN_BOND_KEEP_ALIGN_1                  =>     (FALSE),
CHAN_BOND_SEQ_1_1_1                     =>     ("0000000000"),
CHAN_BOND_SEQ_1_2_1                     =>     ("0000000000"),
CHAN_BOND_SEQ_1_3_1                     =>     ("0000000000"),
CHAN_BOND_SEQ_1_4_1                     =>     ("0000000000"),
CHAN_BOND_SEQ_1_ENABLE_1                =>     ("0000"),
CHAN_BOND_SEQ_2_1_1                     =>     ("0000000000"),
CHAN_BOND_SEQ_2_2_1                     =>     ("0000000000"),
CHAN_BOND_SEQ_2_3_1                     =>     ("0000000000"),
CHAN_BOND_SEQ_2_4_1                     =>     ("0000000000"),
CHAN_BOND_SEQ_2_ENABLE_1                =>     ("0000"),
CHAN_BOND_SEQ_2_USE_1                   =>     (FALSE),
CHAN_BOND_SEQ_LEN_1                     =>     (1),
RX_EN_MODE_RESET_BUF_1                  =>     (TRUE),

--RX PCI Express Attributes
CB2_INH_CC_PERIOD_0                     =>     (8),
CDR_PH_ADJ_TIME_0                       =>     ("01010"),
PCI_EXPRESS_MODE_0                      =>     (FALSE),
RX_EN_IDLE_HOLD_CDR_0                   =>     (FALSE),
RX_EN_IDLE_RESET_FR_0                   =>     (TRUE),
RX_EN_IDLE_RESET_PH_0                   =>     (TRUE),
RX_STATUS_FMT_0                         =>     ("SATA"),
TRANS_TIME_FROM_P2_0                    =>     (x"03c"),
TRANS_TIME_NON_P2_0                     =>     (x"19"),
TRANS_TIME_TO_P2_0                      =>     (x"064"),
CB2_INH_CC_PERIOD_1                     =>     (8),
CDR_PH_ADJ_TIME_1                       =>     ("01010"),
PCI_EXPRESS_MODE_1                      =>     (FALSE),
RX_EN_IDLE_HOLD_CDR_1                   =>     (FALSE),
RX_EN_IDLE_RESET_FR_1                   =>     (TRUE),
RX_EN_IDLE_RESET_PH_1                   =>     (TRUE),
RX_STATUS_FMT_1                         =>     ("SATA"),
TRANS_TIME_FROM_P2_1                    =>     (x"03c"),
TRANS_TIME_NON_P2_1                     =>     (x"19"),
TRANS_TIME_TO_P2_1                      =>     (x"064"),

--RX SATA Attributes
SATA_BURST_VAL_0                        =>     ("100"),
SATA_IDLE_VAL_0                         =>     ("100"),
SATA_MAX_BURST_0                        =>     (7),
SATA_MAX_INIT_0                         =>     (22),
SATA_MAX_WAKE_0                         =>     (7),
SATA_MIN_BURST_0                        =>     (4),
SATA_MIN_INIT_0                         =>     (12),
SATA_MIN_WAKE_0                         =>     (4),
SATA_BURST_VAL_1                        =>     ("100"),
SATA_IDLE_VAL_1                         =>     ("100"),
SATA_MAX_BURST_1                        =>     (7),
SATA_MAX_INIT_1                         =>     (22),
SATA_MAX_WAKE_1                         =>     (7),
SATA_MIN_BURST_1                        =>     (4),
SATA_MIN_INIT_1                         =>     (12),
SATA_MIN_WAKE_1                         =>     (4)


)
port map
(
------------------------ Loopback and Powerdown Ports ----------------------
LOOPBACK0                       =>      tied_to_ground_vec_i(2 downto 0),
LOOPBACK1                       =>      tied_to_ground_vec_i(2 downto 0),
RXPOWERDOWN0                    =>      tied_to_ground_vec_i(1 downto 0),
RXPOWERDOWN1                    =>      tied_to_ground_vec_i(1 downto 0),
TXPOWERDOWN0                    =>      tied_to_ground_vec_i(1 downto 0),
TXPOWERDOWN1                    =>      tied_to_ground_vec_i(1 downto 0),
--------------------------------- PLL Ports --------------------------------
CLK00                           =>      CLK00_IN,
CLK01                           =>      CLK01_IN,
CLK10                           =>      tied_to_ground_i,
CLK11                           =>      tied_to_ground_i,
CLKINEAST0                      =>      tied_to_ground_i,
CLKINEAST1                      =>      tied_to_ground_i,
CLKINWEST0                      =>      tied_to_ground_i,
CLKINWEST1                      =>      tied_to_ground_i,
GCLK00                          =>      tied_to_ground_i,
GCLK01                          =>      tied_to_ground_i,
GCLK10                          =>      tied_to_ground_i,
GCLK11                          =>      tied_to_ground_i,
GTPRESET0                       =>      p_in_rst,                           --//############################### add vicg
GTPRESET1                       =>      p_in_rst,                           --//############################### add vicg
GTPTEST0                        =>      "00010000",
GTPTEST1                        =>      "00010000",
INTDATAWIDTH0                   =>      tied_to_vcc_i,
INTDATAWIDTH1                   =>      tied_to_vcc_i,
PLLCLK00                        =>      tied_to_ground_i,
PLLCLK01                        =>      tied_to_ground_i,
PLLCLK10                        =>      tied_to_ground_i,
PLLCLK11                        =>      tied_to_ground_i,
PLLLKDET0                       =>      i_plllkdet(0),                      --//############################### add vicg
PLLLKDET1                       =>      i_plllkdet(1),                      --//############################### add vicg
PLLLKDETEN0                     =>      tied_to_vcc_i,
PLLLKDETEN1                     =>      tied_to_vcc_i,
PLLPOWERDOWN0                   =>      tied_to_ground_i,
PLLPOWERDOWN1                   =>      tied_to_ground_i,
REFCLKOUT0                      =>      open,
REFCLKOUT1                      =>      open,
REFCLKPLL0                      =>      open,
REFCLKPLL1                      =>      open,
REFCLKPWRDNB0                   =>      tied_to_vcc_i,
REFCLKPWRDNB1                   =>      tied_to_vcc_i,
REFSELDYPLL0                    =>      tied_to_ground_vec_i(2 downto 0),
REFSELDYPLL1                    =>      tied_to_ground_vec_i(2 downto 0),
RESETDONE0                      =>      i_resetdone(0),                     --//############################### add vicg
RESETDONE1                      =>      i_resetdone(1),                     --//############################### add vicg
TSTCLK0                         =>      tied_to_ground_i,
TSTCLK1                         =>      tied_to_ground_i,
TSTIN0                          =>      tied_to_ground_vec_i(11 downto 0),
TSTIN1                          =>      tied_to_ground_vec_i(11 downto 0),
TSTOUT0                         =>      open,
TSTOUT1                         =>      open,
----------------------- Receive Ports - 8b10b Decoder ----------------------
RXCHARISCOMMA0(3 downto 2)      =>      open,                               --//############################### add vicg
RXCHARISCOMMA0(1 downto 0)      =>      open,                               --//############################### add vicg
RXCHARISCOMMA1(3 downto 2)      =>      open,                               --//############################### add vicg
RXCHARISCOMMA1(1 downto 0)      =>      open,                               --//############################### add vicg
RXCHARISK0(3 downto 2)          =>      i_rxcharisk_out(0)(3 downto 2),     --//############################### add vicg
RXCHARISK0(1 downto 0)          =>      i_rxcharisk_out(0)(1 downto 0),     --//############################### add vicg
RXCHARISK1(3 downto 2)          =>      i_rxcharisk_out(1)(3 downto 2),     --//############################### add vicg
RXCHARISK1(1 downto 0)          =>      i_rxcharisk_out(1)(1 downto 0),     --//############################### add vicg
RXDEC8B10BUSE0                  =>      tied_to_vcc_i,
RXDEC8B10BUSE1                  =>      tied_to_vcc_i,
RXDISPERR0(3 downto 2)          =>      i_rxdisperr_out(0)(3 downto 2),     --//############################### add vicg
RXDISPERR0(1 downto 0)          =>      i_rxdisperr_out(0)(1 downto 0),     --//############################### add vicg
RXDISPERR1(3 downto 2)          =>      i_rxdisperr_out(1)(3 downto 2),     --//############################### add vicg
RXDISPERR1(1 downto 0)          =>      i_rxdisperr_out(1)(1 downto 0),     --//############################### add vicg
RXNOTINTABLE0(3 downto 2)       =>      i_rxnotintable_out(0)(3 downto 2),  --//############################### add vicg
RXNOTINTABLE0(1 downto 0)       =>      i_rxnotintable_out(0)(1 downto 0),  --//############################### add vicg
RXNOTINTABLE1(3 downto 2)       =>      i_rxnotintable_out(1)(3 downto 2),  --//############################### add vicg
RXNOTINTABLE1(1 downto 0)       =>      i_rxnotintable_out(1)(1 downto 0),  --//############################### add vicg
RXRUNDISP0                      =>      open,
RXRUNDISP1                      =>      open,
USRCODEERR0                     =>      tied_to_ground_i,
USRCODEERR1                     =>      tied_to_ground_i,
---------------------- Receive Ports - Channel Bonding ---------------------
RXCHANBONDSEQ0                  =>      open,
RXCHANBONDSEQ1                  =>      open,
RXCHANISALIGNED0                =>      open,
RXCHANISALIGNED1                =>      open,
RXCHANREALIGN0                  =>      open,
RXCHANREALIGN1                  =>      open,
RXCHBONDI                       =>      tied_to_ground_vec_i(2 downto 0),
RXCHBONDMASTER0                 =>      tied_to_ground_i,
RXCHBONDMASTER1                 =>      tied_to_ground_i,
RXCHBONDO                       =>      open,
RXCHBONDSLAVE0                  =>      tied_to_ground_i,
RXCHBONDSLAVE1                  =>      tied_to_ground_i,
RXENCHANSYNC0                   =>      tied_to_ground_i,
RXENCHANSYNC1                   =>      tied_to_ground_i,
---------------------- Receive Ports - Clock Correction --------------------
RXCLKCORCNT0                    =>      open,                           --//############################### add vicg
RXCLKCORCNT1                    =>      open,                           --//############################### add vicg
--------------- Receive Ports - Comma Detection and Alignment --------------
RXBYTEISALIGNED0                =>      i_rxbyteisaligned_out(0),       --//############################### add vicg
RXBYTEISALIGNED1                =>      i_rxbyteisaligned_out(1),       --//############################### add vicg
RXBYTEREALIGN0                  =>      open,
RXBYTEREALIGN1                  =>      open,
RXCOMMADET0                     =>      open,
RXCOMMADET1                     =>      open,
RXCOMMADETUSE0                  =>      '1',--��� ��� V5                --//############################### add vicg
RXCOMMADETUSE1                  =>      '1',--��� ��� V5                --//############################### add vicg
RXENMCOMMAALIGN0                =>      '1',--��� ��� V5                --//############################### add vicg
RXENMCOMMAALIGN1                =>      '1',--��� ��� V5                --//############################### add vicg
RXENPCOMMAALIGN0                =>      '1',--��� ��� V5                --//############################### add vicg
RXENPCOMMAALIGN1                =>      '1',--��� ��� V5                --//############################### add vicg
RXSLIDE0                        =>      tied_to_ground_i,
RXSLIDE1                        =>      tied_to_ground_i,
----------------------- Receive Ports - PRBS Detection ---------------------
PRBSCNTRESET0                   =>      tied_to_ground_i,
PRBSCNTRESET1                   =>      tied_to_ground_i,
RXENPRBSTST0                    =>      tied_to_ground_vec_i(2 downto 0),
RXENPRBSTST1                    =>      tied_to_ground_vec_i(2 downto 0),
RXPRBSERR0                      =>      open,
RXPRBSERR1                      =>      open,
------------------- Receive Ports - RX Data Path interface -----------------
RXDATA0                         =>      i_rxdata_out(0),                --//############################### add vicg
RXDATA1                         =>      i_rxdata_out(1),                --//############################### add vicg
RXDATAWIDTH0                    =>      C_GTP_DATAWIDTH,                --//############################### add vicg
RXDATAWIDTH1                    =>      C_GTP_DATAWIDTH,                --//############################### add vicg
RXRECCLK0                       =>      open,                           --//############################### add vicg
RXRECCLK1                       =>      open,                           --//############################### add vicg
RXRESET0                        =>      i_rxreset_in(0),                --//############################### add vicg
RXRESET1                        =>      i_rxreset_in(1),                --//############################### add vicg
RXUSRCLK0                       =>      g_gtp_usrclk(0),                --//############################### add vicg
RXUSRCLK1                       =>      g_gtp_usrclk(1),                --//############################### add vicg
RXUSRCLK20                      =>      g_gtp_usrclk2(0),               --//############################### add vicg
RXUSRCLK21                      =>      g_gtp_usrclk2(1),               --//############################### add vicg
------- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
GATERXELECIDLE0                 =>      '0',                            --//############################### add vicg
GATERXELECIDLE1                 =>      '0',                            --//############################### add vicg
IGNORESIGDET0                   =>      '0',                            --//############################### add vicg
IGNORESIGDET1                   =>      '0',                            --//############################### add vicg
RCALINEAST                      =>      tied_to_ground_vec_i(4 downto 0),
RCALINWEST                      =>      tied_to_ground_vec_i(4 downto 0),
RCALOUTEAST                     =>      open,
RCALOUTWEST                     =>      open,
RXCDRRESET0                     =>      i_rxcdrreset_in(0),             --//############################### add vicg
RXCDRRESET1                     =>      i_rxcdrreset_in(1),             --//############################### add vicg
RXELECIDLE0                     =>      i_rxelecidle(0),                --//############################### add vicg
RXELECIDLE1                     =>      i_rxelecidle(1),                --//############################### add vicg
RXEQMIX0                        =>      "00",                           --//############################### add vicg
RXEQMIX1                        =>      "00",                           --//############################### add vicg
RXN0                            =>      p_in_rxn(0),
RXN1                            =>      p_in_rxn(1),
RXP0                            =>      p_in_rxp(0),
RXP1                            =>      p_in_rxp(1),
----------- Receive Ports - RX Elastic Buffer and Phase Alignment ----------
RXBUFRESET0                     =>      i_rxbufreset_in(0),             --//############################### add vicg
RXBUFRESET1                     =>      i_rxbufreset_in(1),             --//############################### add vicg
RXBUFSTATUS0                    =>      i_rxbufstatus_out(0),           --//############################### add vicg
RXBUFSTATUS1                    =>      i_rxbufstatus_out(1),           --//############################### add vicg
RXENPMAPHASEALIGN0              =>      tied_to_ground_i,
RXENPMAPHASEALIGN1              =>      tied_to_ground_i,
RXPMASETPHASE0                  =>      tied_to_ground_i,
RXPMASETPHASE1                  =>      tied_to_ground_i,
RXSTATUS0                       =>      i_rxstatus_out(0),              --//############################### add vicg
RXSTATUS1                       =>      i_rxstatus_out(1),              --//############################### add vicg
--------------- Receive Ports - RX Loss-of-sync State Machine --------------
RXLOSSOFSYNC0                   =>      open,
RXLOSSOFSYNC1                   =>      open,
-------------- Receive Ports - RX Pipe Control for PCI Express -------------
PHYSTATUS0                      =>      open,
PHYSTATUS1                      =>      open,
RXVALID0                        =>      open,
RXVALID1                        =>      open,
-------------------- Receive Ports - RX Polarity Control -------------------
RXPOLARITY0                     =>      tied_to_ground_i,
RXPOLARITY1                     =>      tied_to_ground_i,
------------- Shared Ports - Dynamic Reconfiguration Port (DRP) ------------
DADDR                           =>      p_in_drpaddr(7 downto 0),       --//############################### add vicg
DCLK                            =>      p_in_drpclk,                    --//############################### add vicg
DEN                             =>      p_in_drpen,                     --//############################### add vicg
DI                              =>      p_in_drpdi,                     --//############################### add vicg
DRDY                            =>      p_out_drprdy,                   --//############################### add vicg
DRPDO                           =>      p_out_drpdo,                    --//############################### add vicg
DWE                             =>      p_in_drpwe,                     --//############################### add vicg
---------------------------- TX/RX Datapath Ports --------------------------
GTPCLKFBEAST                    =>      open,
GTPCLKFBSEL0EAST                =>      "10",
GTPCLKFBSEL0WEST                =>      "00",
GTPCLKFBSEL1EAST                =>      "11",
GTPCLKFBSEL1WEST                =>      "01",
GTPCLKFBWEST                    =>      i_gtpclkfbwest,                 --//############################### add vicg
GTPCLKOUT0                      =>      i_refclkout(0),                 --//############################### add vicg
GTPCLKOUT1                      =>      i_refclkout(1),                 --//############################### add vicg
------------------- Transmit Ports - 8b10b Encoder Control -----------------
TXBYPASS8B10B0                  =>      tied_to_ground_vec_i(3 downto 0),
TXBYPASS8B10B1                  =>      tied_to_ground_vec_i(3 downto 0),
TXCHARDISPMODE0                 =>      tied_to_ground_vec_i(3 downto 0),
TXCHARDISPMODE1                 =>      tied_to_ground_vec_i(3 downto 0),
TXCHARDISPVAL0                  =>      tied_to_ground_vec_i(3 downto 0),
TXCHARDISPVAL1                  =>      tied_to_ground_vec_i(3 downto 0),
TXCHARISK0(3 downto 2)          =>      i_txcharisk_in(0)(3 downto 2),  --//############################### add vicg
TXCHARISK0(1 downto 0)          =>      i_txcharisk_in(0)(1 downto 0),  --//############################### add vicg
TXCHARISK1(3 downto 2)          =>      i_txcharisk_in(1)(3 downto 2),  --//############################### add vicg
TXCHARISK1(1 downto 0)          =>      i_txcharisk_in(1)(1 downto 0),  --//############################### add vicg
TXENC8B10BUSE0                  =>      tied_to_vcc_i,
TXENC8B10BUSE1                  =>      tied_to_vcc_i,
TXKERR0                         =>      open,
TXKERR1                         =>      open,
TXRUNDISP0                      =>      open,
TXRUNDISP1                      =>      open,
--------------- Transmit Ports - TX Buffer and Phase Alignment -------------
TXBUFSTATUS0                    =>      open,
TXBUFSTATUS1                    =>      open,
TXENPMAPHASEALIGN0              =>      tied_to_ground_i,
TXENPMAPHASEALIGN1              =>      tied_to_ground_i,
TXPMASETPHASE0                  =>      tied_to_ground_i,
TXPMASETPHASE1                  =>      tied_to_ground_i,
------------------ Transmit Ports - TX Data Path interface -----------------
TXDATA0                         =>      i_txdata_in(0)(31 downto 0),  --//############################### add vicg
TXDATA1                         =>      i_txdata_in(1)(31 downto 0),  --//############################### add vicg
TXDATAWIDTH0                    =>      C_GTP_DATAWIDTH,              --//############################### add vicg
TXDATAWIDTH1                    =>      C_GTP_DATAWIDTH,              --//############################### add vicg
TXOUTCLK0                       =>      open,                         --//############################### add vicg
TXOUTCLK1                       =>      open,                         --//############################### add vicg
TXRESET0                        =>      i_txreset_in(0),              --//############################### add vicg
TXRESET1                        =>      i_txreset_in(1),              --//############################### add vicg
TXUSRCLK0                       =>      g_gtp_usrclk(0),              --//############################### add vicg
TXUSRCLK1                       =>      g_gtp_usrclk(1),              --//############################### add vicg
TXUSRCLK20                      =>      g_gtp_usrclk2(0),             --//############################### add vicg
TXUSRCLK21                      =>      g_gtp_usrclk2(1),             --//############################### add vicg
--------------- Transmit Ports - TX Driver and OOB signalling --------------
TXBUFDIFFCTRL0                  =>      "101",
TXBUFDIFFCTRL1                  =>      "101",
TXDIFFCTRL0                     =>      "0111",--TXDIFFCTRL0_IN,--//############################### add vicg
TXDIFFCTRL1                     =>      "0111",--TXDIFFCTRL1_IN,--//############################### add vicg
TXINHIBIT0                      =>      tied_to_ground_i,
TXINHIBIT1                      =>      tied_to_ground_i,
TXN0                            =>      p_out_txn(0),
TXN1                            =>      p_out_txn(1),
TXP0                            =>      p_out_txp(0),
TXP1                            =>      p_out_txp(1),
TXPREEMPHASIS0                  =>      "010",
TXPREEMPHASIS1                  =>      "010",
--------------------- Transmit Ports - TX PRBS Generator -------------------
TXENPRBSTST0                    =>      tied_to_ground_vec_i(2 downto 0),
TXENPRBSTST1                    =>      tied_to_ground_vec_i(2 downto 0),
TXPRBSFORCEERR0                 =>      tied_to_ground_i,
TXPRBSFORCEERR1                 =>      tied_to_ground_i,
-------------------- Transmit Ports - TX Polarity Control ------------------
TXPOLARITY0                     =>      tied_to_ground_i,
TXPOLARITY1                     =>      tied_to_ground_i,
----------------- Transmit Ports - TX Ports for PCI Express ----------------
TXDETECTRX0                     =>      tied_to_ground_i,
TXDETECTRX1                     =>      tied_to_ground_i,
TXELECIDLE0                     =>      i_txelecidle_in(0),          --//############################### add vicg
TXELECIDLE1                     =>      i_txelecidle_in(1),          --//############################### add vicg
TXPDOWNASYNCH0                  =>      tied_to_ground_i,
TXPDOWNASYNCH1                  =>      tied_to_ground_i,
--------------------- Transmit Ports - TX Ports for SATA -------------------
TXCOMSTART0                     =>      i_txcomstart_in(0),          --//############################### add vicg
TXCOMSTART1                     =>      i_txcomstart_in(1),          --//############################### add vicg
TXCOMTYPE0                      =>      i_txcomtype_in(0),           --//############################### add vicg
TXCOMTYPE1                      =>      i_txcomtype_in(1)            --//############################### add vicg

);


--END MAIN
end behavioral;