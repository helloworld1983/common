-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 14.07.2011 11:49:04
-- Module Name : cfgdev_host_tb
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

use work.cfgdev_pkg.all;

entity cfgdev_host_tb is
port(
p_out_tst : out std_logic
);
end cfgdev_host_tb;

architecture behavior of cfgdev_host_tb is

constant CI_OPT : integer := 1;

constant C_HOSTCLK_PERIOD : TIME := 6.6 ns; --150MHz
constant C_USRCLK_PERIOD  : TIME := 10 ns;

-- Small delay for simulation purposes.
constant dly : time := 1 ps;--50 ns;

signal p_in_clk                 : std_logic;
signal p_in_rst                 : std_logic;

signal i_ftdi_d                 : std_logic_vector(7 downto 0);
signal i_ftdi_dout              : std_logic_vector(7 downto 0);
signal i_ftdi_din               : std_logic_vector(7 downto 0);
signal i_ftd_rcv                : std_logic;
signal i_ftdi_rd_n              : std_logic;
signal i_ftdi_wr_n              : std_logic;
signal i_ftdi_txe_n             : std_logic;
signal i_ftdi_rxf_n             : std_logic;
signal i_ftdi_pwren_n           : std_logic;

signal i_dev_adr                : std_logic_vector(C_CFGPKT_DADR_M_BIT-C_CFGPKT_DADR_L_BIT downto 0);
signal i_cfg_adr                : std_logic_vector(C_CFGPKT_RADR_M_BIT-C_CFGPKT_RADR_L_BIT downto 0);
signal i_cfg_adr_ld             : std_logic;
signal i_cfg_adr_fifo           : std_logic;
signal i_cfg_wd                 : std_logic;
signal i_cfg_rd                 : std_logic;
signal i_cfg_txd                : std_logic_vector(15 downto 0);
signal i_cfg_rxd                : std_logic_vector(15 downto 0);
signal i_cfg_done               : std_logic;

signal i_cfg_adr_cnt            : std_logic_vector(i_cfg_adr'range);
signal i_reg0                   : std_logic_vector(i_cfg_rxd'range);
signal i_reg1                   : std_logic_vector(i_cfg_rxd'range);
signal i_reg2                   : std_logic_vector(i_cfg_rxd'range);
signal i_reg3                   : std_logic_vector(i_cfg_rxd'range);
signal i_reg4                   : std_logic_vector(i_cfg_rxd'range);


--type TUsrPktHeader is array (0 to C_CFGPKT_HEADER_DCOUNT + CI_OPT - 1) of std_logic_vector(15 downto 0);
--type TUsrPktData is array (0 to 5) of std_logic_vector(15 downto 0);
--type TUsrPkt is record
--h : TUsrPktHeader;
--d : TUsrPktData;
--end record;
--
--type TUsrPkts is array (0 to 7) of TUsrPkt;
--signal i_pkts     : TUsrPkts;
constant CI_USRD_COUNT_MAX : integer := 6;
constant CI_CFGPKT_HEADER_DCOUNT : integer := C_CFGPKT_HEADER_DCOUNT + CI_OPT;
type TUsrPkt is array (0 to C_CFGPKT_HEADER_DCOUNT + CI_OPT + CI_USRD_COUNT_MAX - 1) of std_logic_vector(15 downto 0);
type TUsrPkts is array (0 to 7) of TUsrPkt;
signal i_pkts     : TUsrPkts;

signal i_host_rxrdy : std_logic;
signal i_host_rxd   : std_logic_vector(31 downto 0);
signal i_host_rd    : std_logic;

signal i_host_txrdy : std_logic;
signal i_host_txd   : std_logic_vector(31 downto 0);
signal i_host_wr    : std_logic;

signal i_host_clk   : std_logic;


--MAIN
begin

gen_host_clk : process
begin
  i_host_clk<='0';
  wait for C_HOSTCLK_PERIOD/2;
  i_host_clk<='1';
  wait for C_HOSTCLK_PERIOD/2;
end process;

gen_clk_usr : process
begin
  p_in_clk<='0';
  wait for C_USRCLK_PERIOD/2;
  p_in_clk<='1';
  wait for C_USRCLK_PERIOD/2;
end process;

p_in_rst<='1','0' after 1 us;

p_out_tst<=i_cfg_done;

m_devcfg : cfgdev_host
port map
(
-------------------------------
--����� � HOST
-------------------------------
p_out_host_rxrdy     => i_host_rxrdy,
p_out_host_rxd       => i_host_rxd  ,
p_in_host_rd         => i_host_rd   ,

p_out_host_txrdy     => i_host_txrdy,
p_in_host_txd        => i_host_txd  ,
p_in_host_wr         => i_host_wr  ,

p_out_host_irq       => open,
p_in_host_clk        => i_host_clk,

-------------------------------
--
-------------------------------
p_out_module_rdy     => open,
p_out_module_error   => open,

-------------------------------
--������/������ ���������������� ���������� ���-��
-------------------------------
p_out_cfg_dadr       => i_dev_adr,
p_out_cfg_radr       => i_cfg_adr,
p_out_cfg_radr_ld    => i_cfg_adr_ld,
p_out_cfg_radr_fifo  => i_cfg_adr_fifo,
p_out_cfg_wr         => i_cfg_wd,
p_out_cfg_rd         => i_cfg_rd,
p_out_cfg_txdata     => i_cfg_txd,
p_in_cfg_rxdata      => i_cfg_rxd,
p_in_cfg_txrdy       => '1',
p_in_cfg_rxrdy       => '1',

--p_out_cfg_rx_set_irq => open,
p_out_cfg_done       => i_cfg_done,
p_in_cfg_clk         => p_in_clk,

-------------------------------
--���������������
-------------------------------
p_in_tst             => "00000000000000000000000000000000",
p_out_tst            => open,

-------------------------------
--System
-------------------------------
p_in_rst             => p_in_rst
);


--//������� ������ ���������
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_cfg_adr_cnt<=(others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then
    if i_cfg_adr_ld='1' then
      i_cfg_adr_cnt<=i_cfg_adr;
    else
      if i_cfg_adr_fifo='0' and (i_cfg_wd='1' or i_cfg_rd='1') then
        i_cfg_adr_cnt<=i_cfg_adr_cnt+1;
      end if;
    end if;
  end if;
end process;

--//������ ���������
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_reg0<=(others=>'0');
    i_reg1<=(others=>'0');
    i_reg2<=(others=>'0');
    i_reg3<=(others=>'0');
    i_reg4<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then

    if i_cfg_wd='1' then
        if    i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(0, i_cfg_adr_cnt'length) then i_reg0<=i_cfg_txd(i_reg0'high downto 0);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(1, i_cfg_adr_cnt'length) then i_reg1<=i_cfg_txd(i_reg1'high downto 0);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(2, i_cfg_adr_cnt'length) then i_reg2<=i_cfg_txd(i_reg2'high downto 0);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(3, i_cfg_adr_cnt'length) then i_reg3<=i_cfg_txd(i_reg3'high downto 0);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(4, i_cfg_adr_cnt'length) then i_reg4<=i_cfg_txd(i_reg4'high downto 0);

        end if;
    end if;

  end if;
end process;

--//������ ���������
process(p_in_rst,p_in_clk)
  variable rxd : std_logic_vector(i_cfg_rxd'range);
begin
  if p_in_rst='1' then
      rxd:=(others=>'0');
    i_cfg_rxd<=(others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then
    rxd:=(others=>'0');

    if i_cfg_rd='1' then
        if    i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(0, i_cfg_adr_cnt'length) then rxd:=EXT(i_reg0, rxd'length);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(1, i_cfg_adr_cnt'length) then rxd:=EXT(i_reg1, rxd'length);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(2, i_cfg_adr_cnt'length) then rxd:=EXT(i_reg2, rxd'length);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(3, i_cfg_adr_cnt'length) then rxd:=EXT(i_reg3, rxd'length);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(4, i_cfg_adr_cnt'length) then rxd:=EXT(i_reg4, rxd'length);

        end if;

        i_cfg_rxd<=rxd;

    end if;--//if p_in_cfg_rd='1' then
  end if;
end process;





process
--  variable dlen_vec: std_logic_vector(15 downto 0):=(others=>'0');
  variable dlen_int: integer:=0;
  variable pkt_x   : integer:=0;
begin

--//-----------------
--//�������������:
--//-----------------
for i in 0 to i_pkts'length-1 loop
  for x in 0 to i_pkts(i)'length-1 loop
    i_pkts(i)(x) <= (others=>'0');
  end loop;
end loop;

i_host_rd <= '1';
i_host_wr <= '0';
i_host_txd <= (others=>'0');

--//Pkt0
i_pkts(0)(0 + CI_OPT)(C_CFGPKT_DADR_M_BIT downto C_CFGPKT_DADR_L_BIT)<=CONV_STD_LOGIC_VECTOR(16#0A#, C_CFGPKT_DADR_M_BIT-C_CFGPKT_DADR_L_BIT+1);
i_pkts(0)(0 + CI_OPT)(C_CFGPKT_WR_BIT)<=C_CFGPKT_WR;
i_pkts(0)(0 + CI_OPT)(C_CFGPKT_FIFO_BIT)<='0';

i_pkts(0)(1 + CI_OPT)<=CONV_STD_LOGIC_VECTOR(16#01#, i_pkts(0)(1)'length);--//Start Adr
i_pkts(0)(2 + CI_OPT)<=CONV_STD_LOGIC_VECTOR(10#05#, i_pkts(0)(2)'length);--//Len
--if CI_OPT = 1 then
i_pkts(0)(0) <= CONV_STD_LOGIC_VECTOR((C_CFGPKT_HEADER_DCOUNT + 5) * 2, i_pkts(0)(0)'length);

i_pkts(0)(3 + CI_OPT)<=CONV_STD_LOGIC_VECTOR(16#1011#, i_pkts(0)(0)'length);
i_pkts(0)(4 + CI_OPT)<=CONV_STD_LOGIC_VECTOR(16#2012#, i_pkts(0)(0)'length);
i_pkts(0)(5 + CI_OPT)<=CONV_STD_LOGIC_VECTOR(16#3013#, i_pkts(0)(0)'length);
i_pkts(0)(6 + CI_OPT)<=CONV_STD_LOGIC_VECTOR(16#4014#, i_pkts(0)(0)'length);
i_pkts(0)(7 + CI_OPT)<=CONV_STD_LOGIC_VECTOR(16#5015#, i_pkts(0)(0)'length);

--//Pkt1
i_pkts(1)(0 + CI_OPT)(C_CFGPKT_DADR_M_BIT downto C_CFGPKT_DADR_L_BIT)<=CONV_STD_LOGIC_VECTOR(16#00#, C_CFGPKT_DADR_M_BIT-C_CFGPKT_DADR_L_BIT+1);
i_pkts(1)(0 + CI_OPT)(C_CFGPKT_WR_BIT)<=C_CFGPKT_RD;
i_pkts(1)(0 + CI_OPT)(C_CFGPKT_FIFO_BIT)<='0';

i_pkts(1)(1 + CI_OPT)<=CONV_STD_LOGIC_VECTOR(16#01#, i_pkts(0)(1)'length);--//Start Adr
i_pkts(1)(2 + CI_OPT)<=CONV_STD_LOGIC_VECTOR(10#03#, i_pkts(0)(2)'length);--//Len
--if CI_OPT = 1 then
i_pkts(1)(0) <= CONV_STD_LOGIC_VECTOR((C_CFGPKT_HEADER_DCOUNT) * 2, i_pkts(1)(0)'length);

i_pkts(1)(3 + CI_OPT)<=CONV_STD_LOGIC_VECTOR(16#01#, i_pkts(0)(0)'length);
i_pkts(1)(4 + CI_OPT)<=CONV_STD_LOGIC_VECTOR(16#02#, i_pkts(0)(0)'length);
i_pkts(1)(5 + CI_OPT)<=CONV_STD_LOGIC_VECTOR(16#03#, i_pkts(0)(0)'length);
i_pkts(1)(6 + CI_OPT)<=CONV_STD_LOGIC_VECTOR(16#04#, i_pkts(0)(0)'length);
i_pkts(1)(7 + CI_OPT)<=CONV_STD_LOGIC_VECTOR(16#04#, i_pkts(0)(0)'length);

--//Pkt2
i_pkts(2)(0 + CI_OPT)(C_CFGPKT_DADR_M_BIT downto C_CFGPKT_DADR_L_BIT)<=CONV_STD_LOGIC_VECTOR(16#00#, C_CFGPKT_DADR_M_BIT-C_CFGPKT_DADR_L_BIT+1);
i_pkts(2)(0 + CI_OPT)(C_CFGPKT_WR_BIT)<=C_CFGPKT_RD;
i_pkts(2)(0 + CI_OPT)(C_CFGPKT_FIFO_BIT)<='0';

i_pkts(2)(1 + CI_OPT)<=CONV_STD_LOGIC_VECTOR(16#02#, i_pkts(0)(1)'length);--//Start Adr
i_pkts(2)(2 + CI_OPT)<=CONV_STD_LOGIC_VECTOR(10#02#, i_pkts(0)(2)'length);--//Len
--if CI_OPT = 1 then
i_pkts(2)(0) <= CONV_STD_LOGIC_VECTOR((C_CFGPKT_HEADER_DCOUNT) * 2, i_pkts(2)(0)'length);

i_pkts(2)(3 + CI_OPT)<=CONV_STD_LOGIC_VECTOR(16#01#, i_pkts(0)(0)'length);
i_pkts(2)(4 + CI_OPT)<=CONV_STD_LOGIC_VECTOR(16#02#, i_pkts(0)(0)'length);
i_pkts(2)(5 + CI_OPT)<=CONV_STD_LOGIC_VECTOR(16#03#, i_pkts(0)(0)'length);
i_pkts(2)(6 + CI_OPT)<=CONV_STD_LOGIC_VECTOR(16#04#, i_pkts(0)(0)'length);
i_pkts(2)(7 + CI_OPT)<=CONV_STD_LOGIC_VECTOR(16#04#, i_pkts(0)(0)'length);


--//Pkt3
i_pkts(3)(0 + CI_OPT)(C_CFGPKT_DADR_M_BIT downto C_CFGPKT_DADR_L_BIT)<=CONV_STD_LOGIC_VECTOR(16#00#, C_CFGPKT_DADR_M_BIT-C_CFGPKT_DADR_L_BIT+1);
i_pkts(3)(0 + CI_OPT)(C_CFGPKT_WR_BIT)<=C_CFGPKT_WR;
i_pkts(3)(0 + CI_OPT)(C_CFGPKT_FIFO_BIT)<='0';

i_pkts(3)(1 + CI_OPT)<=CONV_STD_LOGIC_VECTOR(16#01#, i_pkts(0)(1)'length);--//Start Adr
i_pkts(3)(2 + CI_OPT)<=CONV_STD_LOGIC_VECTOR(10#02#, i_pkts(0)(2)'length);--//Len
--if CI_OPT = 1 then
i_pkts(3)(0) <= CONV_STD_LOGIC_VECTOR((C_CFGPKT_HEADER_DCOUNT + 2) * 2, i_pkts(3)(0)'length);

i_pkts(3)(3 + CI_OPT)<=CONV_STD_LOGIC_VECTOR(16#1021#, i_pkts(0)(0)'length);
i_pkts(3)(4 + CI_OPT)<=CONV_STD_LOGIC_VECTOR(16#2022#, i_pkts(0)(0)'length);
i_pkts(3)(5 + CI_OPT)<=CONV_STD_LOGIC_VECTOR(16#3023#, i_pkts(0)(0)'length);
i_pkts(3)(6 + CI_OPT)<=CONV_STD_LOGIC_VECTOR(16#4024#, i_pkts(0)(0)'length);
i_pkts(3)(7 + CI_OPT)<=CONV_STD_LOGIC_VECTOR(16#5025#, i_pkts(0)(0)'length);


--//Pkt4
i_pkts(4)(0 + CI_OPT)(C_CFGPKT_DADR_M_BIT downto C_CFGPKT_DADR_L_BIT)<=CONV_STD_LOGIC_VECTOR(16#00#, C_CFGPKT_DADR_M_BIT-C_CFGPKT_DADR_L_BIT+1);
i_pkts(4)(0 + CI_OPT)(C_CFGPKT_WR_BIT)<=C_CFGPKT_WR;
i_pkts(4)(0 + CI_OPT)(C_CFGPKT_FIFO_BIT)<='0';

i_pkts(4)(1 + CI_OPT)<=CONV_STD_LOGIC_VECTOR(16#02#, i_pkts(0)(1)'length);--//Start Adr
i_pkts(4)(2 + CI_OPT)<=CONV_STD_LOGIC_VECTOR(10#03#, i_pkts(0)(2)'length);--//Len
--if CI_OPT = 1 then
i_pkts(4)(0) <= CONV_STD_LOGIC_VECTOR((C_CFGPKT_HEADER_DCOUNT + 3) * 2, i_pkts(4)(0)'length);

i_pkts(4)(3 + CI_OPT)<=CONV_STD_LOGIC_VECTOR(16#1031#, i_pkts(0)(0)'length);
i_pkts(4)(4 + CI_OPT)<=CONV_STD_LOGIC_VECTOR(16#2032#, i_pkts(0)(0)'length);
i_pkts(4)(5 + CI_OPT)<=CONV_STD_LOGIC_VECTOR(16#3033#, i_pkts(0)(0)'length);
i_pkts(4)(6 + CI_OPT)<=CONV_STD_LOGIC_VECTOR(16#4034#, i_pkts(0)(0)'length);
i_pkts(4)(7 + CI_OPT)<=CONV_STD_LOGIC_VECTOR(16#5035#, i_pkts(0)(0)'length);


--//-----------------
--//������:
--//-----------------
wait until p_in_rst='0';
wait for 1 us;


--//PKT(Write)
wait until rising_edge(i_host_clk);
i_host_txd(31 downto 0) <= i_pkts(0)(1) & i_pkts(0)(0);
i_host_wr <= '1';
wait until rising_edge(i_host_clk);
i_host_wr <= '0';

wait until rising_edge(i_host_clk);
i_host_txd(31 downto 0) <= i_pkts(0)(3) & i_pkts(0)(2);
i_host_wr <= '1';
wait until rising_edge(i_host_clk);
i_host_wr <= '0';

wait until rising_edge(i_host_clk);
i_host_txd(31 downto 0) <= i_pkts(0)(5) & i_pkts(0)(4);
i_host_wr <= '1';
wait until rising_edge(i_host_clk);
i_host_wr <= '0';

wait until rising_edge(i_host_clk);
i_host_txd(31 downto 0) <= i_pkts(0)(7) & i_pkts(0)(6);
i_host_wr <= '1';
wait until rising_edge(i_host_clk);
i_host_wr <= '0';

wait until rising_edge(i_host_clk);
i_host_txd(31 downto 0) <= CONV_STD_LOGIC_VECTOR(0, 16) & i_pkts(0)(8);
i_host_wr <= '1';
wait until rising_edge(i_host_clk);
i_host_wr <= '0';



wait until rising_edge(i_host_clk) and i_cfg_done = '1';
wait for 1 us;

wait until rising_edge(i_host_clk);
i_host_txd(31 downto 0) <= i_pkts(1)(1) & i_pkts(1)(0);
i_host_wr <= '1';
wait until rising_edge(i_host_clk);
i_host_wr <= '0';

wait until rising_edge(i_host_clk);
i_host_txd(31 downto 0) <= i_pkts(1)(3) & i_pkts(1)(2);
i_host_wr <= '1';
wait until rising_edge(i_host_clk);
i_host_wr <= '0';


wait;

end process;




--END MAIN
end behavior;
