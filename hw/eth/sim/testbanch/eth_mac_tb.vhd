-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 31.03.2011 19:15:18
-- Module Name : eth_mac_tb
--
-- Description : ������������� ������ ������ dsn_hdd.vhd
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

use ieee.std_logic_textio.all;
use std.textio.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.vicg_common_pkg.all;
use work.eth_pkg.all;
use work.prj_cfg.all;

entity eth_mac_tb is
generic(
G_USR_DBUS: integer:=32;
G_ETH_CORE_DBUS: integer:=16;
G_ETH_CORE_DBUS_SWP: integer:=1; --1/0 ���� Length/Type ������ ��./��. ���� (0 - �� ���������!!! 1 - ��� � ������� ������)
G_DBG : string:="ON";
G_SIM : string:="ON"
);
port(
--p_out_txll_data      : out   std_logic_vector(G_ETH_CORE_DBUS-1 downto 0);
--p_out_txll_sof_n     : out   std_logic;
--p_out_txll_eof_n     : out   std_logic;
--p_out_txll_src_rdy_n : out   std_logic;
----p_in_txll_dst_rdy_n  : in    std_logic;
--p_out_txll_rem       : out   std_logic_vector(0 downto 0)

p_out_rxbuf_din       : out   std_logic_vector(G_USR_DBUS-1 downto 0);
p_out_rxbuf_wr        : out   std_logic;
--p_in_rxbuf_full       : in    std_logic;
p_out_rxd_sof         : out   std_logic;
p_out_rxd_eof         : out   std_logic
);
end eth_mac_tb;

architecture behavior of eth_mac_tb is

constant C_ETH_GT_REFCLK_PERIOD : TIME := 6.6 ns; --150MHz
constant C_ETH_GT_DRPCLK_PERIOD : TIME := 6.6*8 ns;
constant C_CFG_PERIOD           : TIME := 6.6*5 ns;

component host_vbuf
  PORT (
    rst : IN STD_LOGIC;
    wr_clk : IN STD_LOGIC;
    rd_clk : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC;
    prog_full : OUT STD_LOGIC
  );
END component;

component eth_mac_rx
generic(
G_ETH : TEthGeneric;
G_DBG : string:="OFF";
G_SIM : string:="OFF"
);
port(
--------------------------------------
--����������
--------------------------------------
p_in_cfg              : in    TEthCfg;

--------------------------------------
--����� � ���������������� RXBUF
--------------------------------------
p_out_rxbuf_din       : out   std_logic_vector(G_ETH.usrbuf_dwidth-1 downto 0);
p_out_rxbuf_wr        : out   std_logic;
p_in_rxbuf_full       : in    std_logic;
p_out_rxd_sof         : out   std_logic;
p_out_rxd_eof         : out   std_logic;

--------------------------------------
--����� � Local link RxFIFO
--------------------------------------
p_in_rxll_data        : in    std_logic_vector(G_ETH.phy_dwidth-1 downto 0);
p_in_rxll_sof_n       : in    std_logic;
p_in_rxll_eof_n       : in    std_logic;
p_in_rxll_src_rdy_n   : in    std_logic;
p_out_rxll_dst_rdy_n  : out   std_logic;
p_in_rxll_fifo_status : in    std_logic_vector(3 downto 0);
p_in_rxll_rem         : in    std_logic_vector(0 downto 0);

--------------------------------------
--���������� ��������� PAUSE Control Frame
--(����� �������� ��. ug194.pdf/Flow Control Block/Flow Control Implementation Example)
--------------------------------------
p_out_pause_req       : out   std_logic;
p_out_pause_val       : out   std_logic_vector(15 downto 0);

--------------------------------------------------
--��������������� �������
--------------------------------------------------
p_in_tst              : in    std_logic_vector(31 downto 0);
p_out_tst             : out   std_logic_vector(31 downto 0);

--//------------------------------------
--//SYSTEM
--//------------------------------------
p_in_clk              : in    std_logic;
p_in_rst              : in    std_logic
);
end component;


component eth_mac_tx
generic(
G_ETH : TEthGeneric;
G_DBG : string:="OFF";
G_SIM : string:="OFF"
);
port(
--------------------------------------
--����������
--------------------------------------
p_in_cfg             : in    TEthCfg;

--------------------------------------
--����� � ���������������� TXBUF
--------------------------------------
p_in_txbuf_dout      : in    std_logic_vector(G_ETH.usrbuf_dwidth-1 downto 0);
p_out_txbuf_rd       : out   std_logic;
p_in_txbuf_empty     : in    std_logic;
--p_in_txd_rdy         : in    std_logic;

--------------------------------------
--����� � Local link TxFIFO
--------------------------------------
p_out_txll_data      : out   std_logic_vector(G_ETH.phy_dwidth-1 downto 0);
p_out_txll_sof_n     : out   std_logic;
p_out_txll_eof_n     : out   std_logic;
p_out_txll_src_rdy_n : out   std_logic;
p_in_txll_dst_rdy_n  : in    std_logic;
p_out_txll_rem       : out   std_logic_vector(0 downto 0);

--------------------------------------------------
--��������������� �������
--------------------------------------------------
p_in_tst             : in    std_logic_vector(31 downto 0);
p_out_tst            : out   std_logic_vector(31 downto 0);

--------------------------------------
--SYSTEM
--------------------------------------
p_in_clk             : in    std_logic;
p_in_rst             : in    std_logic
);
end component;

signal i_clk                      : std_logic;
signal i_rst                      : std_logic;

signal i_eth_tx_cfg               : TEthCfg;
signal i_eth_rx_cfg               : TEthCfg;

signal i_txbuf_dout               : std_logic_vector(G_USR_DBUS-1 downto 0);
signal i_txbuf_rd                 : std_logic;
signal i_txbuf_empty              : std_logic;

signal i_data                     : std_logic_vector(G_USR_DBUS-1 downto 0);
signal i_data_wr                  : std_logic;

signal p_out_txll_data            : std_logic_vector(G_ETH_CORE_DBUS-1 downto 0);
signal p_out_txll_sof_n           : std_logic;
signal p_out_txll_eof_n           : std_logic;
signal p_out_txll_src_rdy_n       : std_logic;
signal p_in_txll_dst_rdy_n        : std_logic;
signal p_out_txll_rem             : std_logic_vector(0 downto 0);

signal p_in_rxbuf_full            :  std_logic;

--MAIN
begin


--
--pin_in_eth_gtp_rxn<=(others=>'0');
--pin_in_eth_gtp_rxp<=(others=>'1');



m_rx : eth_mac_rx
generic map(
G_ETH.gtch_count_max  => C_PCFG_ETH_GTCH_COUNT_MAX,
G_ETH.usrbuf_dwidth   => G_USR_DBUS,
G_ETH.phy_dwidth      => G_ETH_CORE_DBUS,
G_ETH.phy_select      => C_ETH_PHY_FIBER,
G_ETH.mac_length_swap => G_ETH_CORE_DBUS_SWP, --1/0 ���� Length/Type ������ ��./��. ���� (0 - �� ���������!!! 1 - ��� � ������� ������)
G_DBG => G_DBG,
G_SIM => G_SIM
)
port map(
--------------------------------------
--����������
--------------------------------------
p_in_cfg             => i_eth_rx_cfg,

--------------------------------------
--����� � ���������������� RXBUF
--------------------------------------
p_out_rxbuf_din       => p_out_rxbuf_din,
p_out_rxbuf_wr        => p_out_rxbuf_wr ,
p_in_rxbuf_full       => p_in_rxbuf_full,
p_out_rxd_sof         => p_out_rxd_sof  ,
p_out_rxd_eof         => p_out_rxd_eof  ,

--------------------------------------
--����� � Local link RxFIFO
--------------------------------------
p_in_rxll_data        => p_out_txll_data     ,
p_in_rxll_sof_n       => p_out_txll_sof_n    ,
p_in_rxll_eof_n       => p_out_txll_eof_n    ,
p_in_rxll_src_rdy_n   => p_out_txll_src_rdy_n,
p_out_rxll_dst_rdy_n  => p_in_txll_dst_rdy_n ,
p_in_rxll_fifo_status => (others=>'0')       ,
p_in_rxll_rem         => p_out_txll_rem      ,

--------------------------------------
--���������� ��������� PAUSE Control Frame
--(����� �������� ��. ug194.pdf/Flow Control Block/Flow Control Implementation Example)
--------------------------------------
p_out_pause_req       => open,
p_out_pause_val       => open,

--------------------------------------------------
--��������������� �������
--------------------------------------------------
p_in_tst             => (others=>'0'),
p_out_tst            => open,

--------------------------------------
--SYSTEM
--------------------------------------
p_in_clk             => i_clk,
p_in_rst             => i_rst
);


m_tx : eth_mac_tx
generic map(
G_ETH.gtch_count_max  => C_PCFG_ETH_GTCH_COUNT_MAX,
G_ETH.usrbuf_dwidth   => G_USR_DBUS,
G_ETH.phy_dwidth      => G_ETH_CORE_DBUS,
G_ETH.phy_select      => C_ETH_PHY_FIBER,
G_ETH.mac_length_swap => G_ETH_CORE_DBUS_SWP, --1/0 ���� Length/Type ������ ��./��. ���� (0 - �� ���������!!! 1 - ��� � ������� ������)
G_DBG => G_DBG,
G_SIM => G_SIM
)
port map(
--------------------------------------
--����������
--------------------------------------
p_in_cfg             => i_eth_tx_cfg,

--------------------------------------
--����� � ���������������� TXBUF
--------------------------------------
p_in_txbuf_dout      => i_txbuf_dout ,
p_out_txbuf_rd       => i_txbuf_rd   ,
p_in_txbuf_empty     => i_txbuf_empty,
--p_in_txd_rdy         : in    std_logic;

--------------------------------------
--����� � Local link TxFIFO
--------------------------------------
p_out_txll_data      => p_out_txll_data     ,
p_out_txll_sof_n     => p_out_txll_sof_n    ,
p_out_txll_eof_n     => p_out_txll_eof_n    ,
p_out_txll_src_rdy_n => p_out_txll_src_rdy_n,
p_in_txll_dst_rdy_n  => p_in_txll_dst_rdy_n ,
p_out_txll_rem       => p_out_txll_rem      ,

--------------------------------------------------
--��������������� �������
--------------------------------------------------
p_in_tst             => (others=>'0'),
p_out_tst            => open,

--------------------------------------
--SYSTEM
--------------------------------------
p_in_clk             => i_clk,
p_in_rst             => i_rst
);



gen_clk : process
begin
  i_clk<='0';
  wait for C_CFG_PERIOD/2;
  i_clk<='1';
  wait for C_CFG_PERIOD/2;
end process;

i_rst<='1','0' after 1 us;



--//########################################
--//Main Ctrl
--//########################################
gen_mac_a : for i in 0 to i_eth_tx_cfg.mac.dst'length-1 generate
i_eth_tx_cfg.mac.dst(i)<=CONV_STD_LOGIC_VECTOR(i+10, i_eth_tx_cfg.mac.dst(i)'length) ;
i_eth_tx_cfg.mac.src(i)<=CONV_STD_LOGIC_VECTOR(i+10+i_eth_tx_cfg.mac.dst'length, i_eth_tx_cfg.mac.src(i)'length) ;
end generate gen_mac_a;
i_eth_tx_cfg.mac.lentype<=CONV_STD_LOGIC_VECTOR(9, i_eth_tx_cfg.mac.lentype'length);
i_eth_tx_cfg.usrctrl<=(others=>'0');

i_eth_rx_cfg.mac.dst<=i_eth_tx_cfg.mac.src;
i_eth_rx_cfg.mac.src<=i_eth_tx_cfg.mac.dst;
i_eth_rx_cfg.mac.lentype<=i_eth_tx_cfg.mac.lentype;
i_eth_rx_cfg.usrctrl<=i_eth_tx_cfg.usrctrl;

process
begin
--  p_in_txll_dst_rdy_n<='0';
  p_in_rxbuf_full<='0';
  i_data<=(others=>'0');
  i_data_wr<='0';

  wait for 2 us;

  wait until i_clk'event and i_clk='1';
  i_data_wr<='1';
  i_data<=CONV_STD_LOGIC_VECTOR(16#A1A0#, G_USR_DBUS/2) & i_eth_tx_cfg.mac.lentype;

  wait until i_clk'event and i_clk='1';
  i_data_wr<='1';
  i_data<=CONV_STD_LOGIC_VECTOR(16#A5A4#, G_USR_DBUS/2)&CONV_STD_LOGIC_VECTOR(16#A3A2#, G_USR_DBUS/2);
  wait until i_clk'event and i_clk='1';
  i_data_wr<='1';
  i_data<=CONV_STD_LOGIC_VECTOR(16#A9A8#, G_USR_DBUS/2)&CONV_STD_LOGIC_VECTOR(16#A7A6#, G_USR_DBUS/2);

  wait until i_clk'event and i_clk='1';
  i_data_wr<='0';

  wait;
end process;


m_buf : host_vbuf
port map(
rst => i_rst,
wr_clk => i_clk,
rd_clk => i_clk,
din => i_data,
wr_en => i_data_wr,
rd_en => i_txbuf_rd,
dout => i_txbuf_dout,
full => open,
empty => i_txbuf_empty,
prog_full => open
);

--END MAIN
end;



