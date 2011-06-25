-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 10.02.2011 17:26:14
-- Module Name : sata_player
--
-- ����������/�������� :
--   PHY Layer:
--   ����������� ��������� �������:
--   1.sata_player_oob
--   2.sata_player_rx
--   3.sata_player_tx
--   +
--   4.���������� ��������� ������������� i_cnt_sync
--     (��� ����������� ��������� ALIGN ������������ ���������� i_cnt_sync)
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
use work.sata_unit_pkg.all;
use work.sata_pkg.all;
use work.sata_sim_lite_pkg.all;

entity sata_player is
generic
(
G_GT_DBUS : integer:=16;
G_DBG     : string :="OFF";
G_SIM     : string :="OFF"
);
port
(
--------------------------------------------------
--���������� (�������� ������ ��. sata_player_oob_cntrl.vhd)
--------------------------------------------------
p_in_ctrl               : in    std_logic_vector(C_PLCTRL_LAST_BIT downto 0);--//��������� ��. sata_pkg.vhd/���� - PHY Layer/����������/Map:
p_out_status            : out   std_logic_vector(C_PLSTAT_LAST_BIT downto 0);--//��������� ��. sata_pkg.vhd/���� - PHY Layer/�������/Map

--------------------------------------------------
--����� � Link Layer
--------------------------------------------------
p_in_phy_txd            : in    std_logic_vector(31 downto 0);
p_in_phy_txreq          : in    std_logic_vector(7 downto 0);
p_out_phy_txrdy_n       : out   std_logic;

p_out_phy_rxtype        : out   std_logic_vector(C_TDATA_EN downto C_TALIGN);
p_out_phy_rxdata        : out   std_logic_vector(31 downto 0);

p_out_phy_sync          : out   std_logic;

--------------------------------------------------
--����� � RocketIO (�������� ������ ��. sata_player_gt.vhd)
--------------------------------------------------
p_out_gt_rst            : out   std_logic;

--RocketIO Tranceiver
p_out_gt_txelecidle     : out   std_logic;
p_out_gt_txcomstart     : out   std_logic;
p_out_gt_txcomtype      : out   std_logic;
p_out_gt_txdata         : out   std_logic_vector(31 downto 0);
p_out_gt_txcharisk      : out   std_logic_vector(3 downto 0);

p_out_gt_txreset        : out   std_logic;
p_in_gt_txbufstatus     : in    std_logic_vector(1 downto 0);

--RocketIO Receiver
p_in_gt_rxelecidle      : in    std_logic;
p_in_gt_rxstatus        : in    std_logic_vector(2 downto 0);
p_in_gt_rxdata          : in    std_logic_vector(31 downto 0);
p_in_gt_rxcharisk       : in    std_logic_vector(3 downto 0);
p_in_gt_rxdisperr       : in    std_logic_vector(3 downto 0);
p_in_gt_rxnotintable    : in    std_logic_vector(3 downto 0);
p_in_gt_rxbyteisaligned : in    std_logic;

p_in_gt_rxbufstatus     : in    std_logic_vector(2 downto 0);
p_out_gt_rxbufreset     : out   std_logic;

--------------------------------------------------
--��������������� �������
--------------------------------------------------
p_in_tst                : in    std_logic_vector(31 downto 0);
p_out_tst               : out   std_logic_vector(31 downto 0);
p_out_dbg               : out   TPL_dbgport;

--------------------------------------------------
--System
--------------------------------------------------
p_in_tmrclk            : in    std_logic;
p_in_clk               : in    std_logic;
p_in_rst               : in    std_logic
);
end sata_player;

architecture behavioral of sata_player is

signal i_oob_status             : std_logic_vector(C_PLSTAT_LAST_BIT downto 0);

signal i_rxerr                  : std_logic_vector(C_PRxSTAT_LAST_BIT downto 0);
signal i_rxtype                 : std_logic_vector(C_TDATA_EN downto C_TALIGN);
signal i_d10_2_senddis          : std_logic;

signal i_synch                  : std_logic;
signal i_cnt_sync               : std_logic_vector(selval(1, 0, cmpval(G_GT_DBUS, 8)) downto 0);--(1 downto 0);


signal i_dbg                    : TPL_dbgport;
signal tst_player_oob_out       : std_logic_vector(31 downto 0);
signal tst_player_rcv_out       : std_logic_vector(31 downto 0);
signal tst_player_tsf_out       : std_logic_vector(31 downto 0);
--signal tst_rcv_aperiod          : std_logic_vector(15 downto 0);



--MAIN
begin

--//----------------------------------
--//��������������� �������
--//----------------------------------
gen_dbg_off : if strcmp(G_DBG,"OFF") generate
p_out_tst(31 downto 0)<=(others=>'0');
end generate gen_dbg_off;

gen_dbg_on : if strcmp(G_DBG,"ON") generate

--p_out_tst(31 downto 0)<=(others=>'0');
ltstout:process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
--    tst_rcv_aperiod<=(others=>'0');
    p_out_tst<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then

    p_out_tst(0)<=tst_player_oob_out(0) or tst_player_rcv_out(0);-- or OR_reduce(tst_rcv_aperiod);

--    if i_rxtype(C_TALIGN)='1' then
--      tst_rcv_aperiod<=(others=>'0');
--    else
--      if tst_rcv_aperiod=(tst_rcv_aperiod'range =>'1') then
--        tst_rcv_aperiod<=(others=>'1');
--      else
--        tst_rcv_aperiod<=tst_rcv_aperiod + 1;
--      end if;
--    end if;

  end if;
end process ltstout;

end generate gen_dbg_on;


--//----------------------------------
--//������ ����������
--//----------------------------------
gen_dbus8 : if G_GT_DBUS=8 generate
i_synch<=AND_reduce(i_cnt_sync);
end generate gen_dbus8;

gen_dbus16 : if G_GT_DBUS=16 generate
i_synch<=i_cnt_sync(0);
end generate gen_dbus16;

gen_dbus32 : if G_GT_DBUS=32 generate
i_synch<='1';
end generate gen_dbus32;

p_out_phy_sync<=i_synch;
p_out_phy_rxtype(C_TDATA_EN downto C_TALIGN)<=i_rxtype(C_TDATA_EN downto C_TALIGN);

p_out_status(C_PRxSTAT_LAST_BIT downto C_PRxSTAT_ERR_DISP_BIT)<=i_rxerr;
p_out_status(C_PLSTAT_LAST_BIT downto C_PSTAT_DET_DEV_ON_BIT)<=i_oob_status(C_PLSTAT_LAST_BIT downto C_PSTAT_DET_DEV_ON_BIT);

--//----------------------------------
--//�������������
--//----------------------------------
lsync_cnt:process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_cnt_sync<=(others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then
    --//���������� �������������:
    if i_rxtype(C_TALIGN)='1' then
      i_cnt_sync<=(others=>'0');
    else
      i_cnt_sync<=i_cnt_sync + 1;
    end if;
  end if;
end process lsync_cnt;



--//----------------------------------
--//������ ��������� ����������
--//----------------------------------
m_phy_oob : sata_player_oob
generic map
(
G_GT_DBUS  => G_GT_DBUS,
G_DBG      => G_DBG,
G_SIM      => G_SIM
)
port map
(
--------------------------------------------------
--
--------------------------------------------------
p_in_ctrl           => p_in_ctrl,
p_out_status        => i_oob_status,

p_in_primitive_det  => i_rxtype(C_TPMNAK downto C_TALIGN),
p_out_d10_2_senddis => i_d10_2_senddis,

--------------------------------------------------
--RocketIO Receiver
--------------------------------------------------
p_out_gt_rst        => p_out_gt_rst,

p_out_gt_txelecidle => p_out_gt_txelecidle,
p_out_gt_txcomstart => p_out_gt_txcomstart,
p_out_gt_txcomtype  => p_out_gt_txcomtype,

p_in_gt_rxelecidle  => p_in_gt_rxelecidle,
p_in_gt_rxstatus    => p_in_gt_rxstatus,

--------------------------------------------------
--��������������� �������
--------------------------------------------------
p_in_tst            => p_in_tst,
p_out_tst           => tst_player_oob_out,
p_out_dbg           => i_dbg.oob,

--------------------------------------------------
--System
--------------------------------------------------
p_in_tmrclk         => p_in_tmrclk,
p_in_clk            => p_in_clk,
p_in_rst            => p_in_rst
);


--//----------------------------------
--//���������� ������
--//----------------------------------
m_phy_tx : sata_player_tx
generic map
(
G_GT_DBUS  => G_GT_DBUS,
G_DBG      => G_DBG,
G_SIM      => G_SIM
)
port map
(
--------------------------------------------------
--
--------------------------------------------------
p_in_rxalign        => '0',--i_rxtype(C_TALIGN),
p_in_linkup         => i_oob_status(C_PSTAT_DET_ESTABLISH_ON_BIT),
p_in_dev_detect     => i_oob_status(C_PSTAT_DET_DEV_ON_BIT),
p_in_d10_2_send_dis => i_d10_2_senddis,
p_in_sync           => i_synch,
p_in_txreq          => p_in_phy_txreq,
p_in_txd            => p_in_phy_txd,
p_out_rdy_n         => p_out_phy_txrdy_n,

--------------------------------------------------
--RocketIO Transmiter
--------------------------------------------------
p_out_gt_txdata     => p_out_gt_txdata,
p_out_gt_txcharisk  => p_out_gt_txcharisk,

p_out_gt_txreset    => p_out_gt_txreset,
p_in_gt_txbufstatus => p_in_gt_txbufstatus,

--------------------------------------------------
--��������������� �������
--------------------------------------------------
p_in_tst            => p_in_tst,
p_out_tst           => tst_player_tsf_out,
p_out_dbg           => i_dbg.tx,

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk            => p_in_clk,
p_in_rst            => p_in_rst
);


--//----------------------------------
--//�������� ������
--//----------------------------------
m_phy_rx : sata_player_rx
generic map
(
G_GT_DBUS  => G_GT_DBUS,
G_DBG      => G_DBG,
G_SIM      => G_SIM
)
port map
(
--------------------------------------------------
--
--------------------------------------------------
p_in_dev_detect         => i_oob_status(C_PSTAT_DET_DEV_ON_BIT),
p_out_rxd               => p_out_phy_rxdata,
p_out_rxtype            => i_rxtype,
p_out_rxerr             => i_rxerr,

--------------------------------------------------
--RocketIO Receiver
--------------------------------------------------
p_in_gt_rxdata          => p_in_gt_rxdata,
p_in_gt_rxcharisk       => p_in_gt_rxcharisk,
p_in_gt_rxdisperr       => p_in_gt_rxdisperr,
p_in_gt_rxnotintable    => p_in_gt_rxnotintable,
p_in_gt_rxbyteisaligned => p_in_gt_rxbyteisaligned,

p_in_gt_rxbufstatus     => p_in_gt_rxbufstatus,
p_out_gt_rxbufreset     => p_out_gt_rxbufreset,

--------------------------------------------------
--��������������� �������
--------------------------------------------------
p_in_tst                => p_in_tst,
p_out_tst               => tst_player_rcv_out,
p_out_dbg               => i_dbg.rx,

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk                => p_in_clk,
p_in_rst                => p_in_rst
);


--//-----------------------------------
--//Debug/Sim
--//-----------------------------------
--gen_sim_on : if strcmp(G_SIM,"ON") generate

p_out_dbg<=i_dbg;

--end generate gen_sim_on;

--END MAIN
end behavioral;
