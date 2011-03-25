-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 10.02.2011 17:19:48
-- Module Name : sata_player_rx
--
-- ����������/�������� :
--   1. ����������� � ������ �� ��������� RocketIO ���������� SATA � ���������������� ������,
--      ������ ���������������� ����� �� ����� p_out_rxtype
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

use work.vicg_common_pkg.all;
use work.sata_pkg.all;
use work.sata_sim_lite_pkg.all;

entity sata_player_rx is
generic
(
G_GTP_DBUS : integer := 16;
G_DBG      : string  := "OFF";
G_SIM      : string  := "OFF"
);
port
(
--------------------------------------------------
--
--------------------------------------------------
p_out_rxd                  : out   std_logic_vector(31 downto 0);               --//�������� ������
p_out_rxtype               : out   std_logic_vector(C_TDATA_EN downto C_TALIGN);--//��� ������

--------------------------------------------------
--RocketIO Receiver (�������� ������ ��. sata_rocketio.vhd)
--------------------------------------------------
--p_in_gtp_pll_lock          : in    std_logic;
p_out_gtp_rxbufreset       : out   std_logic;
p_in_gtp_rxdata            : in    std_logic_vector(15 downto 0);
p_in_gtp_rxcharisk         : in    std_logic_vector(1 downto 0);
p_in_gtp_rxbufstatus       : in    std_logic_vector(2 downto 0);
p_in_gtp_rxelecidle        : in    std_logic;
p_in_gtp_rxdisperr         : in    std_logic_vector(1 downto 0);
p_in_gtp_rxnotintable      : in    std_logic_vector(1 downto 0);
p_in_gtp_rxbyteisaligned   : in    std_logic;
p_in_gtp_rxbyterealigned   : in    std_logic;

--------------------------------------------------
--��������������� �������
--------------------------------------------------
p_in_tst                   : in    std_logic_vector(31 downto 0);
p_out_tst                  : out   std_logic_vector(31 downto 0);

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk               : in    std_logic;
p_in_rst               : in    std_logic
);
end sata_player_rx;

architecture behavioral of sata_player_rx is

signal i_rxdata                  : std_logic_vector(31 downto 0);
signal i_rxdtype                 : std_logic_vector(3 downto 0);

type TSrDataW8 is array (0 to 2) of std_logic_vector(7 downto 0);
signal sr_rxdata                 : TSrDataW8;

type TSrDtypeW8 is array (0 to 2) of std_logic;
signal sr_rxdtype                : TSrDtypeW8;

signal dbgrcv_type               : string(1 to 7);
signal tst_val                   : std_logic;

--MAIN
begin

--//----------------------------------
--//��������������� �������
--//----------------------------------
gen_dbg_off : if strcmp(G_DBG,"OFF") generate
p_out_tst(0)<=tst_val;
p_out_tst(31 downto 1)<=(others=>'0');
end generate gen_dbg_off;

gen_dbg_on : if strcmp(G_DBG,"ON") generate
--ltstout:process(p_in_rst,p_in_clk)
--begin
--  if p_in_rst='1' then
--    p_out_tst(31 downto 2)<=(others=>'0');
--  elsif p_in_clk'event and p_in_clk='1' then
--
--    for i in 0 to C_VSACL_MATRIX_COUNT-1 loop
--    p_out_tst(0)<=OR_reduce(dbg_sr_pix(i)(6));
--    end loop;
--
--    p_out_tst(1)<=tst_synch;
--
--  end if;
--end process ltstout;
p_out_tst(0)<=tst_val;
p_out_tst(31 downto 1)<=(others=>'0');
end generate gen_dbg_on;



--//-----------------------------------
--//������ ������
--//-----------------------------------
--p_out_rxtype(C_TALIGN)   <='1' when i_rxdata=C_PDAT_ALIGN   and i_rxdtype=C_PDAT_TPRM and p_in_gtp_rxbyteisaligned='1' else '0';
p_out_rxtype(C_TALIGN)   <='1' when i_rxdata=C_PDAT_ALIGN   and i_rxdtype=C_PDAT_TPRM else '0';
p_out_rxtype(C_TSOF)     <='1' when i_rxdata=C_PDAT_SOF     and i_rxdtype=C_PDAT_TPRM else '0';
p_out_rxtype(C_TEOF)     <='1' when i_rxdata=C_PDAT_EOF     and i_rxdtype=C_PDAT_TPRM else '0';
p_out_rxtype(C_TDMAT)    <='1' when i_rxdata=C_PDAT_DMAT    and i_rxdtype=C_PDAT_TPRM else '0';
p_out_rxtype(C_TCONT)    <='1' when i_rxdata=C_PDAT_CONT    and i_rxdtype=C_PDAT_TPRM else '0';
p_out_rxtype(C_TSYNC)    <='1' when i_rxdata=C_PDAT_SYNC    and i_rxdtype=C_PDAT_TPRM else '0';
p_out_rxtype(C_THOLD)    <='1' when i_rxdata=C_PDAT_HOLD    and i_rxdtype=C_PDAT_TPRM else '0';
p_out_rxtype(C_THOLDA)   <='1' when i_rxdata=C_PDAT_HOLDA   and i_rxdtype=C_PDAT_TPRM else '0';
p_out_rxtype(C_TX_RDY)   <='1' when i_rxdata=C_PDAT_X_RDY   and i_rxdtype=C_PDAT_TPRM else '0';
p_out_rxtype(C_TR_RDY)   <='1' when i_rxdata=C_PDAT_R_RDY   and i_rxdtype=C_PDAT_TPRM else '0';
p_out_rxtype(C_TR_IP)    <='1' when i_rxdata=C_PDAT_R_IP    and i_rxdtype=C_PDAT_TPRM else '0';
p_out_rxtype(C_TR_OK)    <='1' when i_rxdata=C_PDAT_R_OK    and i_rxdtype=C_PDAT_TPRM else '0';
p_out_rxtype(C_TR_ERR)   <='1' when i_rxdata=C_PDAT_R_ERR   and i_rxdtype=C_PDAT_TPRM else '0';
p_out_rxtype(C_TWTRM)    <='1' when i_rxdata=C_PDAT_WTRM    and i_rxdtype=C_PDAT_TPRM else '0';
p_out_rxtype(C_TPMREQ_P) <='1' when i_rxdata=C_PDAT_PMREQ_P and i_rxdtype=C_PDAT_TPRM else '0';
p_out_rxtype(C_TPMREQ_S) <='1' when i_rxdata=C_PDAT_PMREQ_S and i_rxdtype=C_PDAT_TPRM else '0';
p_out_rxtype(C_TPMACK)   <='1' when i_rxdata=C_PDAT_PMACK   and i_rxdtype=C_PDAT_TPRM else '0';
p_out_rxtype(C_TPMNAK)   <='1' when i_rxdata=C_PDAT_PMNAK   and i_rxdtype=C_PDAT_TPRM else '0';
p_out_rxtype(C_TDATA_EN) <='1' when i_rxdtype=C_PDAT_TDATA else '0';


p_out_rxd<=i_rxdata;



--GTP: ���� �����=8bit
gen_dbus8 : if G_GTP_DBUS=8 generate

i_rxdata<=p_in_gtp_rxdata(7 downto 0) & sr_rxdata(0) & sr_rxdata(1) & sr_rxdata(2);
i_rxdtype<=p_in_gtp_rxcharisk(0) & sr_rxdtype(0) & sr_rxdtype(1) & sr_rxdtype(2);

lsr_rxd:process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    for i in 0 to 2 loop
      sr_rxdata(i)<=(others=>'0');
      sr_rxdtype(i)<='0';
    end loop;

  elsif p_in_clk'event and p_in_clk='1' then

      sr_rxdata<=p_in_gtp_rxdata(7 downto 0) & sr_rxdata(0 to 1);
      sr_rxdtype<=p_in_gtp_rxcharisk(0) & sr_rxdtype(0 to 1);

  end if;
end process lsr_rxd;

end generate gen_dbus8;


--GTP: ���� �����=16bit
gen_dbus16 : if G_GTP_DBUS=16 generate

i_rxdata<=p_in_gtp_rxdata(15 downto 8) & p_in_gtp_rxdata(7 downto 0) & sr_rxdata(1) & sr_rxdata(0);
i_rxdtype<=p_in_gtp_rxcharisk(1) & p_in_gtp_rxcharisk(0) & sr_rxdtype(1) & sr_rxdtype(0);

lsr_rxd:process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    for i in 0 to 2 loop
      sr_rxdata(i)<=(others=>'0');
      sr_rxdtype(i)<='0';
    end loop;

  elsif p_in_clk'event and p_in_clk='1' then

      sr_rxdata(0)<=p_in_gtp_rxdata(7 downto 0);
      sr_rxdata(1)<=p_in_gtp_rxdata(15 downto 8);
      sr_rxdtype(0)<=p_in_gtp_rxcharisk(0);
      sr_rxdtype(1)<=p_in_gtp_rxcharisk(1);

  end if;
end process lsr_rxd;

end generate gen_dbus16;


p_out_gtp_rxbufreset<='0';




gen_sim_off : if strcmp(G_SIM,"OFF") generate
tst_val<='0';
end generate gen_sim_off;

--//----------------------------------------
--//������ ��� �������������
--//----------------------------------------
--��� �������� �������  ������ ��� ������������
gen_sim_on : if strcmp(G_SIM,"ON") generate

rcv_name: process(p_in_clk)
--  variable dbgrcv_type : string(1 to 7);
begin
if p_in_clk'event and p_in_clk='1' then
  if    i_rxdata=C_PDAT_ALIGN   and i_rxdtype=C_PDAT_TPRM then dbgrcv_type<=C_PNAME_STR(C_TALIGN);
  elsif i_rxdata=C_PDAT_SOF     and i_rxdtype=C_PDAT_TPRM then dbgrcv_type<=C_PNAME_STR(C_TSOF);
  elsif i_rxdata=C_PDAT_EOF     and i_rxdtype=C_PDAT_TPRM then dbgrcv_type<=C_PNAME_STR(C_TEOF);
  elsif i_rxdata=C_PDAT_DMAT    and i_rxdtype=C_PDAT_TPRM then dbgrcv_type<=C_PNAME_STR(C_TDMAT);
  elsif i_rxdata=C_PDAT_CONT    and i_rxdtype=C_PDAT_TPRM then dbgrcv_type<=C_PNAME_STR(C_TCONT);
  elsif i_rxdata=C_PDAT_SYNC    and i_rxdtype=C_PDAT_TPRM then dbgrcv_type<=C_PNAME_STR(C_TSYNC);
  elsif i_rxdata=C_PDAT_HOLD    and i_rxdtype=C_PDAT_TPRM then dbgrcv_type<=C_PNAME_STR(C_THOLD);
  elsif i_rxdata=C_PDAT_HOLDA   and i_rxdtype=C_PDAT_TPRM then dbgrcv_type<=C_PNAME_STR(C_THOLDA);
  elsif i_rxdata=C_PDAT_X_RDY   and i_rxdtype=C_PDAT_TPRM then dbgrcv_type<=C_PNAME_STR(C_TX_RDY);
  elsif i_rxdata=C_PDAT_R_RDY   and i_rxdtype=C_PDAT_TPRM then dbgrcv_type<=C_PNAME_STR(C_TR_RDY);
  elsif i_rxdata=C_PDAT_R_IP    and i_rxdtype=C_PDAT_TPRM then dbgrcv_type<=C_PNAME_STR(C_TR_IP);
  elsif i_rxdata=C_PDAT_R_OK    and i_rxdtype=C_PDAT_TPRM then dbgrcv_type<=C_PNAME_STR(C_TR_OK);
  elsif i_rxdata=C_PDAT_R_ERR   and i_rxdtype=C_PDAT_TPRM then dbgrcv_type<=C_PNAME_STR(C_TR_ERR);
  elsif i_rxdata=C_PDAT_WTRM    and i_rxdtype=C_PDAT_TPRM then dbgrcv_type<=C_PNAME_STR(C_TWTRM);
  elsif i_rxdata=C_PDAT_PMREQ_P and i_rxdtype=C_PDAT_TPRM then dbgrcv_type<=C_PNAME_STR(C_TPMREQ_P);
  elsif i_rxdata=C_PDAT_PMREQ_S and i_rxdtype=C_PDAT_TPRM then dbgrcv_type<=C_PNAME_STR(C_TPMREQ_S);
  elsif i_rxdata=C_PDAT_PMACK   and i_rxdtype=C_PDAT_TPRM then dbgrcv_type<=C_PNAME_STR(C_TPMACK);
  elsif i_rxdata=C_PDAT_PMNAK   and i_rxdtype=C_PDAT_TPRM then dbgrcv_type<=C_PNAME_STR(C_TPMNAK);
  elsif                              i_rxdtype=C_PDAT_TDATA then dbgrcv_type<=C_PNAME_STR(C_TDATA_EN);
--  else dbgrcv_type<=C_PNAME_STR(C_TNONE);
  end if;

  if dbgrcv_type=C_PNAME_STR(C_TDATA_EN) then
    tst_val<='1';
  else
    tst_val<='0';
  end if;
end if;
end process rcv_name;

end generate gen_sim_on;


--END MAIN
end behavioral;