-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 05.03.2011 13:10:01
-- Module Name : sata_host
--
-- ���������� :
--   ���������� SATA HOST.
--   ���������� ��������� ������ ���������� PHY/Link/Transport/Application Layer
--
-- Revision:
-- Revision 0.01 - 25.11.2008 - ������ ������ ��� �������� SATA
-- Revision 1.00 - ������ ��������� �������
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

library unisim;
use unisim.vcomponents.all;

use work.vicg_common_pkg.all;
use work.sata_unit_pkg.all;
use work.sata_pkg.all;
use work.sata_sim_lite_pkg.all;

entity sata_host is
generic
(
G_SATA_MODULE_MAXCOUNT : integer := 1;    --//���-�� ������ sata_host � �������� ������ sata_dsn.vhd / (�������: 1...3)
G_SATA_MODULE_IDX      : integer := 0;    --//������ ������ sata_host � �������� ������ sata_dsn.vhd / (�������: 0...G_SATA_MODULE_MAXCOUNT-1)
G_SATA_MODULE_CH_COUNT : integer := 1;    --//���-�� ������ SATA ������������ � ������ sata_host.vhd / (�������: 1...2)
G_GTP_DBUS             : integer := 16;   --//
G_DBG                  : string  := "OFF";--//� ������ ������� ����������� ������ ���� "OFF" - ������� ����� ChipScoupe
G_SIM                  : string  := "OFF" --//� ������ ������� ����������� ������ ���� "OFF" - �������������
);
port
(
---------------------------------------------------------------------------
--Sata Driver
---------------------------------------------------------------------------
p_out_sata_txn              : out   std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);
p_out_sata_txp              : out   std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);
p_in_sata_rxn               : in    std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);
p_in_sata_rxp               : in    std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);

--------------------------------------------------
--����� � USERAPP Layer
--------------------------------------------------
p_in_al_ctrl                : in    TALCtrl_GtpCh;
p_out_al_status             : out   TALStatus_GtpCh;
p_out_al_clkout             : out   std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);

--//����� � CMDFIFO
p_in_cmdfifo_dout           : in    TBus16_GtpCh;                                   --//
p_in_cmdfifo_eof_n          : in    std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);
p_in_cmdfifo_src_rdy_n      : in    std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);
p_out_cmdfifo_dst_rdy_n     : out   std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);

--//����� � TXFIFO
p_in_txbuf_dout             : in    TBus32_GtpCh;                                   --//
p_out_txbuf_rd              : out   std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);
p_in_txbuf_status           : in    TTxBufStatus_GtpCh;

--//����� � RXFIFO
p_out_rxbuf_din             : out   TBus32_GtpCh;                                   --//
p_out_rxbuf_wd              : out   std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);
p_in_rxbuf_status           : in    TRxBufStatus_GtpCh;

---------------------------------------------------------------------------
--��������������� �������
---------------------------------------------------------------------------
p_in_tst                    : in    std_logic_vector(31 downto 0);
p_out_tst                   : out   std_logic_vector(31 downto 0);

---------------------------------------------------------------------------
--�������������/������� - � ������� ������� �� ������������
---------------------------------------------------------------------------
--//�������������
p_out_sim_gtp_txdata        : out   TBus16_GtpCh;
p_out_sim_gtp_txcharisk     : out   TBus02_GtpCh;
p_in_sim_gtp_rxdata         : in    TBus16_GtpCh;
p_in_sim_gtp_rxcharisk      : in    TBus02_GtpCh;
p_in_sim_gtp_rxstatus       : in    TBus03_GtpCh;
p_in_sim_gtp_rxelecidle     : in    std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);
p_out_sim_rst               : out   std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);
p_out_sim_clk               : out   std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);

---------------------------------------------------------------------------
--System
---------------------------------------------------------------------------
p_in_sys_dcm_gclk0          : in    std_logic;
p_in_sys_dcm_gclk2x         : in    std_logic;
p_in_sys_dcm_lock           : in    std_logic;
p_out_sys_dcm_rst           : out   std_logic;

p_out_gtp_refclk            : out   std_logic;--//����� ����� REFCLKOUT ������ GTP_DUAL/sata_rocketio.vhdl
p_in_g_gtp_refclk           : in    std_logic;--//������� p_out_gtp_refclk ����������� ����� ���������� �����
p_in_clk                    : in    std_logic;--//CLKIN ��� ������ RocketIO(GTP)
p_in_rst                    : in    std_logic
);
end sata_host;

architecture behavioral of sata_host is

signal i_dcm_lock                  : std_logic;
signal g_dcm_clk0                  : std_logic;
signal g_dcm_clk2x                 : std_logic;

signal i_ctrl_sata_modules_rst     : std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);
signal i_ctrl_sata_rst             : std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);

signal i_spctrl_link_establish     : std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);
signal i_spctrl_gtp_ch_rst         : std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);
signal i_spctrl_gtp_rst            : std_logic;
signal i_spctrl_spd                : std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);

signal i_reg_dma                   : TRegDMA_GtpCh;
signal i_reg_shadow                : TRegShadow_GtpCh;
signal i_reg_hold                  : TRegHold_GtpCh;
signal i_reg_update                : TRegShadowUpdate_GtpCh;

signal i_tr_ctrl                   : TTLCtrl_GtpCh;
signal i_tr_status                 : TTLStat_GtpCh;

signal i_link_ctrl                 : TLLCtrl_GtpCh;
signal i_link_status               : TLLStat_GtpCh;
signal i_link_txd_close            : std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);
signal i_link_txd                  : TBus32_GtpCh;
signal i_link_txd_rd               : std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);
signal i_link_txd_status           : TTxBufStatus_GtpCh;
signal i_link_rxd                  : TBus32_GtpCh;
signal i_link_rxd_wr               : std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);
signal i_link_rxd_status           : TRxBufStatus_GtpCh;

signal i_phy_rxtype                : TBus21_GtpCh;
signal i_phy_txreq                 : TBus08_GtpCh;
signal i_phy_txrdy_n               : std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);
signal i_phy_sync                  : std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);
signal i_phy_txd                   : TBus32_GtpCh;
signal i_phy_rxd                   : TBus32_GtpCh;
signal i_phy_rxd_en                : TBus03_GtpCh;

signal i_phy_ctrl                  : TPLCtrl_GtpCh;
signal i_phy_status                : TPLStat_GtpCh;
signal i_phy_gtp_txreset           : std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0):="00";

signal i_gtp_PLLLKDET              : std_logic;
signal i_gtp_refclk_out            : std_logic;
signal i_in_g_gtp_refclk           : std_logic;
signal i_gtp_reset                 : std_logic;

signal i_gtp_drpclk                : std_logic;
signal i_gtp_drpaddr               : std_logic_vector(6 downto 0);
signal i_gtp_drpen                 : std_logic;
signal i_gtp_drpwe                 : std_logic;
signal i_gtp_drpdi                 : std_logic_vector(15 downto 0);
signal i_gtp_drpdo                 : std_logic_vector(15 downto 0);
signal i_gtp_drprdy                : std_logic;

signal i_gtp_usrclk                : std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);
signal g_gtp_usrclk                : std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);
signal g_gtp_usrclk2               : std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);

signal i_gtp_datawidth             : std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0):="00";

signal i_gtp_txreset               : std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0):="00";
signal i_gtp_rxreset               : std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0):="00";
signal i_gtp_rxbufreset            : std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0):="00";

signal i_gtp_rxdata                : TBus16_GtpCh;
signal i_gtp_rxcharisk             : TBus02_GtpCh;
signal i_gtp_rxbufstatus           : TBus03_GtpCh;
signal i_gtp_rxstatus              : TBus03_GtpCh;
signal i_gtp_rxelecidle            : std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0):="00";
signal i_gtp_rxbyteisaligned       : std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0):="00";
signal i_gtp_rxbyterealigned       : std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0):="00";
signal i_gtp_rxdisperr             : TBus02_GtpCh;
signal i_gtp_rxnotintable          : TBus02_GtpCh;

signal i_gtp_txdata                : TBus16_GtpCh;
signal i_gtp_txbufstatus           : TBus02_GtpCh;
signal i_gtp_txcharisk             : TBus02_GtpCh;
signal i_gtp_txcomstart            : std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0):="00";
signal i_gtp_txcomtype             : std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0):="00";
signal i_gtp_txelecidle            : std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0):="00";



signal tst_alayer_out              : TBus32_GtpCh;
signal tst_tlayer_out              : TBus32_GtpCh;
signal tst_llayer_out              : TBus32_GtpCh;
signal tst_player_out              : TBus32_GtpCh;
signal tst_spctrl_out              : std_logic_vector(31 downto 0);
signal tst_out                     : std_logic;


attribute keep : string;
attribute keep of i_gtp_usrclk : signal is "true";



--MAIN
begin

--//----------------------------------
--//��������������� �������
--//----------------------------------
gen_dbg_off : if strcmp(G_DBG,"OFF") generate
p_out_tst(31 downto 0)<=(others=>'0');
end generate gen_dbg_off;

gen_dbg_on : if strcmp(G_DBG,"ON") generate
tstout:process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    tst_out<='0';
  elsif p_in_clk'event and p_in_clk='1' then
    tst_out<=OR_reduce(tst_spctrl_out) or
             OR_reduce(tst_player_out(0)) or
             OR_reduce(tst_llayer_out(0)) or
             OR_reduce(tst_tlayer_out(0)) or
             OR_reduce(tst_alayer_out(0));

  end if;
end process tstout;

p_out_tst(0)<=tst_out;
p_out_tst(1)<=i_link_txd_close(0);
p_out_tst(31 downto 2)<=(others=>'0');

end generate gen_dbg_on;



--//-----------------------------
--//�������������
--//-----------------------------
p_out_gtp_refclk<=i_gtp_refclk_out;
p_out_sys_dcm_rst<=not i_gtp_PLLLKDET;

i_gtp_reset      <= p_in_rst or i_spctrl_gtp_rst;

i_dcm_lock       <=not p_in_sys_dcm_lock;
g_dcm_clk0       <=p_in_sys_dcm_gclk0;
g_dcm_clk2x      <=p_in_sys_dcm_gclk2x;
i_in_g_gtp_refclk<=p_in_g_gtp_refclk;


m_speed_ctrl : sata_speed_ctrl
generic map
(
--  G_SPEED_SATA               => "ALL",--G_SPEED_SATA,--"SATA1",--"SATA2",
G_SATA_MODULE_MAXCOUNT => G_SATA_MODULE_MAXCOUNT,
G_SATA_MODULE_IDX      => G_SATA_MODULE_IDX,
G_GTP_CH_COUNT         => G_SATA_MODULE_CH_COUNT,
G_DBG                  => G_DBG,
G_SIM                  => G_SIM
)
port map
(
--------------------------------------------------
--
--------------------------------------------------
p_in_cfg_sata_version   => "00",--p_in_cfg_sata_version,
--------------------------------------------------
--
--------------------------------------------------
p_out_sata_version      => i_spctrl_spd,
p_in_link_establish     => i_spctrl_link_establish,

p_out_gtp_ch_rst        => i_spctrl_gtp_ch_rst,
p_out_gtp_rst           => i_spctrl_gtp_rst,

p_in_usr_dcm_lock       => i_dcm_lock,

--------------------------------------------------
--RocketIO
--------------------------------------------------
p_in_gtp_pll_lock       => i_gtp_PLLLKDET,

p_out_gtp_drpclk        => i_gtp_drpclk,
p_out_gtp_drpaddr       => i_gtp_drpaddr,
p_out_gtp_drpen         => i_gtp_drpen,
p_out_gtp_drpwe         => i_gtp_drpwe,
p_out_gtp_drpdi         => i_gtp_drpdi,
p_in_gtp_drpdo          => i_gtp_drpdo,
p_in_gtp_drprdy         => i_gtp_drprdy,

--------------------------------------------------
--��������������� �������
--------------------------------------------------
p_in_tst                => p_in_tst,
p_out_tst               => tst_spctrl_out,

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk                => i_in_g_gtp_refclk, --//(150MHz)
p_in_rst                => p_in_rst
);

--//������� ������ ����� ������������� ���� �������� G_SATA_MODULE_CH_COUNT=1
gen_ch_count1 : if G_SATA_MODULE_CH_COUNT=1 generate

p_out_al_clkout(1)<='0';

p_out_al_status(1).ATAStatus<=(others=>'0');
p_out_al_status(1).ATAError<=(others=>'0');
p_out_al_status(1).SStatus<=(others=>'0');
p_out_al_status(1).SError<=(others=>'0');
p_out_al_status(1).Usr<=(others=>'0');

--//����� � CMDFIFO
p_out_cmdfifo_dst_rdy_n(1)<='1';

--//����� � TXFIFO
p_out_txbuf_rd(1)<='0';

--//����� � RXFIFO
p_out_rxbuf_din(1)<=(others=>'0');
p_out_rxbuf_wd(1)<='0';

i_spctrl_link_establish(1)<='0';

--//����� � DUAL_GTP
g_gtp_usrclk(1)    <=g_gtp_usrclk(0);
g_gtp_usrclk2(1)   <=g_gtp_usrclk2(0);
i_gtp_datawidth(1) <='0';
i_gtp_txelecidle(1)<='0';
i_gtp_txcomstart(1)<='0';
i_gtp_txcomtype(1) <='0';
i_gtp_txdata(1)    <=i_gtp_txdata(0);
i_gtp_txcharisk(1) <=i_gtp_txcharisk(0);
i_gtp_txreset(1)   <=i_gtp_txreset(0);
i_gtp_rxreset(1)   <=i_gtp_rxreset(0);
i_gtp_rxbufreset(1)<=i_gtp_rxbufreset(0);

gen_sim_on: if strcmp(G_SIM,"ON") generate

p_out_sim_gtp_txdata(1) <= (others=>'0');
p_out_sim_gtp_txcharisk(1) <= (others=>'0');

p_out_sim_rst(1) <= i_ctrl_sata_modules_rst(1);
p_out_sim_clk(1) <= '0';

end generate gen_sim_on;

end generate gen_ch_count1;


--//"�����������" ������� ���������� SATA ���������������� ������ DUAL_GTP (RocketIO)
gen_ch: for i in 0 to G_SATA_MODULE_CH_COUNT-1 generate

-- �������������
p_out_sim_rst(i) <= i_ctrl_sata_modules_rst(i);

gen_sim_on: if strcmp(G_SIM,"ON") generate

p_out_sim_clk(i) <= g_gtp_usrclk2(i);

p_out_sim_gtp_txdata(i)     <= i_gtp_txdata(i);
p_out_sim_gtp_txcharisk(i)  <= i_gtp_txcharisk(i);

i_gtp_rxdata(i)             <= p_in_sim_gtp_rxdata(i);
i_gtp_rxcharisk(i)          <= p_in_sim_gtp_rxcharisk(i);

i_gtp_rxelecidle(i)         <= p_in_sim_gtp_rxelecidle(i);
i_gtp_rxstatus(i)           <= p_in_sim_gtp_rxstatus(i);

i_gtp_rxbufstatus(0)        <= (others=>'0');
i_gtp_rxdisperr(0)          <= (others=>'0');
i_gtp_rxnotintable(0)       <= (others=>'0');
i_gtp_rxbyteisaligned(0)    <= '0';
i_gtp_rxbyterealigned(0)    <= '0';

i_gtp_rxbufstatus(1)        <= (others=>'0');
i_gtp_rxdisperr(1)          <= (others=>'0');
i_gtp_rxnotintable(1)       <= (others=>'0');
i_gtp_rxbyteisaligned(1)    <= '0';
i_gtp_rxbyterealigned(1)    <= '0';

end generate gen_sim_on;



i_spctrl_link_establish(i)<=i_phy_status(i)(C_PSTAT_DET_ESTABLISH_ON_BIT);

i_phy_ctrl(i)(C_PCTRL_SPD_BIT_L)<=i_spctrl_spd(i);
i_phy_ctrl(i)(C_PCTRL_SPD_BIT_M)<='0';

--//����� �� ������ sata_player_transmiter.vhd - ��� ������������� ������ txbuf ������ DUAL_GTP
--//���
--//����� �� ������ sata_speed_ctrl.vhd - ��� ����� �������� ����������
i_gtp_txreset(i)<=i_phy_gtp_txreset(i) or i_spctrl_gtp_ch_rst(i);

--//����� �� ������ sata_speed_ctrl.vhd - ��� ����� �������� ����������
i_gtp_rxreset(i)<=i_spctrl_gtp_ch_rst(i);

--//����� ���� ������� ���������� ����
--//������ sata_speed_ctrl.vhd - ����� �������� ���������� ���
--//������� DCM ����������� ��� ������������ (i_dcm_lock)
i_ctrl_sata_modules_rst(i) <= i_spctrl_gtp_ch_rst(i) or i_dcm_lock;

--//��� ������ ������ ���������� ��� SATA-1 ��� SATA-2
--m_bufgmux_i : BUFGMUX_CTRL
--port map
--(
--S  => i_spctrl_spd(i), -- Clock select input
--I0 => g_dcm_clk0,                      -- 150MHz - S=0 - SATA Generation 1 (1.5Gb/s)
--I1 => g_dcm_clk2x,                     -- 300MHz - S=1 - SATA Generation 2 (3Gb/s)
--O  => i_gtp_usrclk(i)
--);
--
--g_gtp_usrclk(i)<=i_gtp_usrclk(i);
--g_gtp_usrclk2(i)<=g_gtp_usrclk(i);


gen_gtp_w8 : if G_GTP_DBUS=8 generate
--//C��������t ������ � SATA-2
g_gtp_usrclk(i)<=g_dcm_clk2x;
g_gtp_usrclk2(i)<=g_dcm_clk2x;
end generate gen_gtp_w8;

gen_gtp_w16 : if G_GTP_DBUS=16 generate
--//C��������t ������ � SATA-2
g_gtp_usrclk(i)<=g_dcm_clk2x;
g_gtp_usrclk2(i)<=g_dcm_clk0;
end generate gen_gtp_w16;

p_out_al_clkout(i)<=g_gtp_usrclk2(i);

m_alayer : sata_alayer
generic map
(
G_DBG => G_DBG,
G_SIM => G_SIM
)
port map
(
--------------------------------------------------
--����� � USR APP Layer
--------------------------------------------------
p_in_ctrl                 => p_in_al_ctrl(i),
p_out_status              => p_out_al_status(i),

--//����� � CMDFIFO
p_in_cmdfifo_dout         => p_in_cmdfifo_dout(i),
p_in_cmdfifo_eof_n        => p_in_cmdfifo_eof_n(i),
p_in_cmdfifo_src_rdy_n    => p_in_cmdfifo_src_rdy_n(i),
p_out_cmdfifo_dst_rdy_n   => p_out_cmdfifo_dst_rdy_n(i),


--------------------------------------------------
--����� � Transport/Link/PHY Layer
--------------------------------------------------
p_out_tl_ctrl             => i_tr_ctrl(i),
p_in_tl_status            => i_tr_status(i),
p_in_ll_status            => i_link_status(i),
p_in_pl_status            => i_phy_status(i),

p_out_reg_dma             => i_reg_dma(i),
p_out_reg_shadow          => i_reg_shadow(i),
p_in_reg_hold             => i_reg_hold(i),
p_in_reg_update           => i_reg_update(i),

--------------------------------------------------
--��������������� �������
--------------------------------------------------
p_in_tst                  => p_in_tst,
p_out_tst                 => tst_alayer_out(i),

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk                  => g_gtp_usrclk2(i),
p_in_rst                  => i_ctrl_sata_modules_rst(i)
);

m_tlayer : sata_tlayer
generic map
(
G_DBG => G_DBG,
G_SIM => G_SIM
)
port map
(
--------------------------------------------------
--����� � USERAPP Layer
--------------------------------------------------
--//����� � TXFIFO
p_in_txfifo_dout          => p_in_txbuf_dout(i),
p_out_txfifo_rd           => p_out_txbuf_rd(i),
p_in_txfifo_status        => p_in_txbuf_status(i),

--//����� � RXFIFO
p_out_rxfifo_din          => p_out_rxbuf_din(i),
p_out_rxfifo_wd           => p_out_rxbuf_wd(i),
p_in_rxfifo_status        => p_in_rxbuf_status(i),

--------------------------------------------------
--����� � APP Layer
--------------------------------------------------
p_in_tl_ctrl              => i_tr_ctrl(i),
p_out_tl_status           => i_tr_status(i),

p_in_reg_dma              => i_reg_dma(i),
p_in_reg_shadow           => i_reg_shadow(i),
p_out_reg_hold            => i_reg_hold(i),
p_out_reg_update          => i_reg_update(i),

--------------------------------------------------
--����� � Link Layer
--------------------------------------------------
p_out_ll_ctrl             => i_link_ctrl(i),
p_in_ll_status            => i_link_status(i),

p_out_ll_txd_close        => i_link_txd_close(i),
p_out_ll_txd              => i_link_txd(i),
p_in_ll_txd_rd            => i_link_txd_rd(i),
p_out_ll_txd_status       => i_link_txd_status(i),

p_in_ll_rxd               => i_link_rxd(i),
p_in_ll_rxd_wr            => i_link_rxd_wr(i),
p_out_ll_rxd_status       => i_link_rxd_status(i),

--------------------------------------------------
--����� � PHY Layer
--------------------------------------------------
p_in_pl_status            => i_phy_status(i),

--------------------------------------------------
--��������������� �������
--------------------------------------------------
p_in_tst                  => p_in_tst,
p_out_tst                 => tst_tlayer_out(i),

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk                  => g_gtp_usrclk2(i),
p_in_rst                  => i_ctrl_sata_modules_rst(i)
);

m_llayer : sata_llayer
generic map
(
--G_GTP_DBUS => G_GTP_DBUS,
G_DBG      => G_DBG,
G_SIM      => G_SIM
)
port map
(
--------------------------------------------------
--����� � Transport Layer
--------------------------------------------------
p_in_ctrl               => i_link_ctrl(i),
p_out_status            => i_link_status(i),

p_in_txd_close          => i_link_txd_close(i),
p_in_txd                => i_link_txd(i),
p_out_txd_rd            => i_link_txd_rd(i),
p_in_txd_status         => i_link_txd_status(i),

p_out_rxd               => i_link_rxd(i),
p_out_rxd_wr            => i_link_rxd_wr(i),
p_in_rxd_status         => i_link_rxd_status(i),

--------------------------------------------------
--����� � Phy Layer
--------------------------------------------------
p_in_phy_rdy            => i_phy_status(i)(C_PSTAT_DET_ESTABLISH_ON_BIT),
p_in_phy_sync           => i_phy_sync(i),

p_in_phy_rxtype         => i_phy_rxtype(i)(C_TDATA_EN downto C_TSOF),
p_in_phy_rxd            => i_phy_rxd(i),

p_out_phy_txd           => i_phy_txd(i),
p_out_phy_txreq         => i_phy_txreq(i),
p_in_phy_txrdy_n        => i_phy_txrdy_n(i),

--------------------------------------------------
--��������������� �������
--------------------------------------------------
p_in_tst                => p_in_tst,
p_out_tst               => tst_llayer_out(i),

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk                => g_gtp_usrclk2(i),
p_in_rst                => i_ctrl_sata_modules_rst(i)
);

m_player : sata_player
generic map
(
G_GTP_DBUS => G_GTP_DBUS,
G_DBG      => G_DBG,
G_SIM      => G_SIM
)
port map
(
--------------------------------------------------
--����������
--------------------------------------------------
p_in_ctrl                  => i_phy_ctrl(i),
p_out_status               => i_phy_status(i),

--------------------------------------------------
--����� � Link Layer
--------------------------------------------------
p_in_phy_txd               => i_phy_txd(i),
p_in_phy_txreq             => i_phy_txreq(i),
p_out_phy_txrdy_n          => i_phy_txrdy_n(i),

p_out_phy_rxtype           => i_phy_rxtype(i)(C_TDATA_EN downto C_TALIGN),
p_out_phy_rxdata           => i_phy_rxd(i),

p_out_phy_sync             => i_phy_sync(i),

--------------------------------------------------
--����� � RocketIO
--------------------------------------------------
p_in_gtp_pll_lock          => i_gtp_PLLLKDET,

--RocketIO Tranceiver
p_out_gtp_txelecidle       => i_gtp_txelecidle(i),
p_out_gtp_txcomstart       => i_gtp_txcomstart(i),
p_out_gtp_txcomtype        => i_gtp_txcomtype(i),
p_out_gtp_txdata           => i_gtp_txdata(i),
p_out_gtp_txcharisk        => i_gtp_txcharisk(i),
p_out_gtp_txreset          => i_phy_gtp_txreset(i),
p_in_gtp_txbufstatus       => i_gtp_txbufstatus(i),

--RocketIO Receiver
p_out_gtp_rxbufreset       => i_gtp_rxbufreset(i),
p_in_gtp_rxdata            => i_gtp_rxdata(i),
p_in_gtp_rxbufstatus       => i_gtp_rxbufstatus(i),
p_in_gtp_rxstatus          => i_gtp_rxstatus(i),
p_in_gtp_rxelecidle        => i_gtp_rxelecidle(i),
p_in_gtp_rxcharisk         => i_gtp_rxcharisk(i),
p_in_gtp_rxdisperr         => i_gtp_rxdisperr(i),
p_in_gtp_rxnotintable      => i_gtp_rxnotintable(i),
p_in_gtp_rxbyteisaligned   => i_gtp_rxbyteisaligned(i),
p_in_gtp_rxbyterealigned   => i_gtp_rxbyterealigned(i),

p_out_gtp_datawidth        => i_gtp_datawidth(i),

--------------------------------------------------
--��������������� �������
--------------------------------------------------
p_in_tst                   => p_in_tst,
p_out_tst                  => tst_player_out(i),

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk                => g_gtp_usrclk2(i),
p_in_rst                => i_ctrl_sata_modules_rst(i)
);

end generate gen_ch;



gen_sim_off : if strcmp(G_SIM,"OFF") generate
begin

m_rocketio : sata_rocketio
generic map
(
G_GTP_DBUS => G_GTP_DBUS,
G_SIM      => G_SIM
)
port map
(
--------------------------------------------------
--Driver
--------------------------------------------------
p_out_txn                        => p_out_sata_txn,
p_out_txp                        => p_out_sata_txp,

p_in_rxn                         => p_in_sata_rxn,
p_in_rxp                         => p_in_sata_rxp,

--------------------------------------------------
--Clocking
--------------------------------------------------
p_in_usrclk                      => g_gtp_usrclk,
p_in_usrclk2                     => g_gtp_usrclk2,

--------------------------------------------------
--Transmitter
--------------------------------------------------
p_in_txelecidle                  => i_gtp_txelecidle,
p_in_txcomstart                  => i_gtp_txcomstart,
p_in_txcomtype                   => i_gtp_txcomtype,
p_in_txdata                      => i_gtp_txdata,
p_in_txcharisk                   => i_gtp_txcharisk,
p_in_txreset                     => i_gtp_txreset,
p_out_txbufstatus                => i_gtp_txbufstatus,

--------------------------------------------------
--Reciever
--------------------------------------------------
p_in_rxreset                     => i_gtp_rxreset,
p_in_rxbufreset                  => i_gtp_rxbufreset,
p_out_rxdata                     => i_gtp_rxdata,
p_out_rxcharisk                  => i_gtp_rxcharisk,
p_out_rxbufstatus                => i_gtp_rxbufstatus,
p_out_rxstatus                   => i_gtp_rxstatus,
p_out_rxelecidle                 => i_gtp_rxelecidle,
p_out_rxdisperr                  => i_gtp_rxdisperr,
p_out_rxnotintable               => i_gtp_rxnotintable,
p_out_rxbyteisaligned            => i_gtp_rxbyteisaligned,
p_out_rxbyterealigned            => i_gtp_rxbyterealigned,

--------------------------------------------------
--
--------------------------------------------------
p_in_datawidth                   => i_gtp_datawidth,

--------------------------------------------------
--System
--------------------------------------------------
p_in_drpclk                      => i_gtp_drpclk,
p_in_drpaddr                     => i_gtp_drpaddr,
p_in_drpen                       => i_gtp_drpen,
p_in_drpwe                       => i_gtp_drpwe,
p_in_drpdi                       => i_gtp_drpdi,
p_out_drpdo                      => i_gtp_drpdo,
p_out_drprdy                     => i_gtp_drprdy,

p_out_plllock                    => i_gtp_PLLLKDET,
p_out_refclkout                  => i_gtp_refclk_out,

p_in_refclkin                    => p_in_clk,
p_in_rst                         => i_gtp_reset

);

end generate gen_sim_off;



---##############################
-- �������������
---##############################
gen_sim_on: if strcmp(G_SIM,"ON") generate

i_gtp_drpdo  <="1000"&"0000"&"0000"&"0100";
i_gtp_drprdy <='1';

i_gtp_PLLLKDET <= not p_in_rst;

i_gtp_refclk_out <=p_in_clk;

end generate gen_sim_on;


--END MAIN
end behavioral;
