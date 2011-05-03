-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 02/04/2010
-- Module Name : eth_rx_pkt_filter
--
-- ����������/�������� :
--        ����� ���������� ������� ������ �� �� ������� ������.
--        ����� ����������:
--        3..0 - ��� ������
--        7..4 - ������ ������
--
-- Revision:
-- Revision 0.01 - File Created
-- Revision 0.02 - add 24.01.2011 14:47:56
--                 ������� ��������������� ����
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

library work;
use work.prj_def.all;
use work.eth_pkg.all;

library unisim;
use unisim.vcomponents.all;

entity eth_rx_pkt_filter is
generic(
G_FMASK_COUNT     : integer := 3
);
port
(
--//------------------------------------
--//����������
--//------------------------------------
p_in_fmask      : in    TEthFmask;

--//------------------------------------
--//Upstream Port
--//------------------------------------
p_in_upp_data   : in    std_logic_vector(31 downto 0);
p_in_upp_wr     : in    std_logic;
p_in_upp_rdy    : in    std_logic;
p_in_upp_sof    : in    std_logic;

--//------------------------------------
--//Downstream Port
--//------------------------------------
p_out_dwnp_data : out   std_logic_vector(31 downto 0);
p_out_dwnp_wr   : out   std_logic;
p_out_dwnp_rdy  : out   std_logic;
p_out_dwnp_sof  : out   std_logic;

-------------------------------
--���������������
-------------------------------
p_out_tst       : out   std_logic_vector(31 downto 0);

--//------------------------------------
--//SYSTEM
--//------------------------------------
p_in_clk        : in    std_logic;
p_in_rst        : in    std_logic
);
end eth_rx_pkt_filter;


architecture behavioral of eth_rx_pkt_filter is

signal upp_data_sr            : std_logic_vector(31 downto 0);
signal upp_sof_sr             : std_logic;
signal upp_wr_sr              : std_logic;
signal upp_rdy_sr             : std_logic;

signal i_pkt_type             : std_logic_vector(3 downto 0);
signal i_pkt_subtype          : std_logic_vector(3 downto 0);
signal i_pkt_en               : std_logic;


--MAIN
begin

--//----------------------------------
--//��������������� �������
--//----------------------------------
--process(p_in_rst,p_in_clk)
--begin
--  if p_in_rst='1' then
--    p_out_tst(0)<='0';
--  elsif p_in_clk'event and p_in_clk='1' then
--    p_out_tst(0) <='0'
--  end if;
--end process;
p_out_tst(31 downto 0)<=(others=>'0');



--//����� ��������
process(p_in_clk)
begin
  if p_in_clk'event and p_in_clk='1' then
    upp_rdy_sr <= p_in_upp_rdy;
    upp_sof_sr <= p_in_upp_sof;
    upp_wr_sr  <= p_in_upp_wr;

    if p_in_upp_wr='1' then
      upp_data_sr <= p_in_upp_data;
    end if;

    p_out_dwnp_sof  <= upp_sof_sr and i_pkt_en;
    p_out_dwnp_rdy  <= upp_rdy_sr and i_pkt_en;
    p_out_dwnp_wr   <= upp_wr_sr  and i_pkt_en;
    p_out_dwnp_data <= upp_data_sr;

  end if;
end process;

--//���������� �������� ������
i_pkt_type(3 downto 0)<=p_in_upp_data(19 downto 16);
i_pkt_subtype(3 downto 0)<=p_in_upp_data(23 downto 20);

process(p_in_rst,p_in_clk)
  variable var_pkt_valid   : std_logic;
begin
  if p_in_rst='1' then
    i_pkt_en<='0';
    var_pkt_valid:='0';

  elsif p_in_clk'event and p_in_clk='1' then

    var_pkt_valid:='0';

    if p_in_upp_sof='1' and p_in_upp_wr='1' then

        --//���� ����������� ����� ��� �������� ������
        for i in 0 to G_FMASK_COUNT-1 loop
          --//����������� ������ �� ������� ����� � ������ �����
          if p_in_fmask(i)/=(p_in_fmask(i)'range => '0') then
            if p_in_fmask(i)=(i_pkt_subtype & i_pkt_type) then
              var_pkt_valid:='1';
            end if;
          end if;
        end loop;

      i_pkt_en<=var_pkt_valid;

    elsif upp_rdy_sr='1' then
      i_pkt_en<='0';
    end if;

  end if;
end process;


--END MAIN
end behavioral;
