--------------------------------------------------------------------------------
-- Engineer: Golovachenko V. (vicg@hotmail.ru)
-- Create Date: 10.02.2005
-- Design Name: TVS.vhd
-- Component Name: TVS
-- Revision: ver.03
--  change ver.03 - ���� ������� ���������� ������ ������� ���������������� ����� TV (TVADJUST)
--                - ������� ���-�� ����� � ���� TV. ������ � ���� 288 �����. ������ ���� 287
--------------------------------------------------------------------------------
--
--                      ____________________________________________
--             ________|                                            |_______
--    |       |                                                             |
--    |       |                                                             |
--    |_______|                                                             |
--
--    |<-CC�->|<------>|<------------------------------------------>|<------>
--     4.7���   5.8���                   52���                       1.53���
--                     |<--->|                                |<--->|
--                     ���������� (var1)                       ���������� (var2)

--  Notes: � �� ������� � ����� ���� 288 �����, � �� ������ 287!!!!!
--         � ���� ������ ������� �� 0.5 ����� 1 � 2  �����.
--         ����� ���������� 288+0.5+287+0.5=576 ����� � �����.
--
--  ������� ���� ��������� ��� ����� ������ ����������� ������ ���-�� �������� ����� ��� � 1-�� ���� ��� � 2-��!!!!!
--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity TVS is
generic
(
----�������� �������
--  N_ROW  : integer:=65;--���-�� ����� � �����. (312.5 ����� � ����� ����)
--  N_H2   : integer:=32;--�.�. 64us/2=32us (�������� ������� �����)
--  W2_32us: integer:=5; --�.�. 2.32 us
--  W4_7us : integer:=10; --�.�. 4.7 us
--  W1_53us: integer:=2; --�.�. 1.53 us
--  W5_8us : integer:=11; --�.�. 5.8 us
--  var1   : integer:=2;  --�����������
--  var2   : integer:=2   --�����������

----��� �������� ������������ clk=12.5MHz (�������� �����/������ - 577/640)
----��������� �� Starter Kit SPARTAN-3.
--  N_ROW  : integer:=625;--���-�� ����� � �����. (312.5 ����� � ����� ����)
--  N_H2   : integer:=400;--�.�. 64us/2=32us (�������� ������� �����)
--  W2_32us: integer:=29;--�.�. 2.32 us
--  W4_7us : integer:=59;--�.�. 4.7 us
--  W1_53us: integer:=19; --�.�. 1.53 us
--  W5_8us : integer:=73; --�.�. 5.8 us
--  var1   : integer:=4;  --�����������
--  var2   : integer:=5   --�����������

--��� �������� ������������ clk=15MHz (�������� �����/������ - 574/768)
--��������� �� Starter Kit SPARTAN-3.
N_ROW  : integer:=625;--���-�� ����� � �����. (312.5 ����� � ����� ����)
N_H2   : integer:=480;--�.�. 64us/2=32us (�������� ������� �����)
W2_32us: integer:=35; --�.�. 2.32 us
W4_7us : integer:=71; --�.�. 4.7 us
W1_53us: integer:=23; --�.�. 1.53 us
W5_8us : integer:=87; --�.�. 5.8 us
var1   : integer:=6;   --�����������
var2   : integer:=6    --�����������
);
port(
--EN_ADJUST  : out std_logic;
--LOAD_ADJUST: out std_logic;

--    KGI   : out std_logic;
p_out_tv_kci   : out std_logic;
p_out_tv_ssi   : out std_logic;--�����������. ����������� TV ������
p_out_tv_field : out std_logic;--���� TV ������� (������/�������� ������)
p_out_den      : out std_logic;--�������� ����� ������.(���������� ������ ������)

p_in_clk_en: in std_logic;
p_in_clk   : in std_logic;
p_in_rst   : in std_logic;
);
end TVS;

architecture behavior of TVS is

signal cnt_2H  : std_logic_vector(8 downto 0);--integer range 0 to 511;--������� ��������� ������
signal cnt_N2H : std_logic_vector(9 downto 0);--integer range 0 to 1023;--������� ���-�� �������� �����
signal cnt_N2H5: std_logic_vector(6 downto 0);--integer range 0 to 127;--���-�� 5��� ��������� �����
signal cnt_2H5 : std_logic_vector(2 downto 0);--integer range 0 to 7;
signal H2,H2SHT1,H2SHT2,H2SHT3,H2SHT4,H2SHT5: std_logic;

signal EUR: std_logic;
--  signal EAR: std_logic;
signal KCI_int: std_logic;
--  signal KGI: std_logic;
signal SelH: std_logic;
signal Fiald_int: std_logic;

--  ��� ������������ ���-�� ����� � ����� � ������ � ������!!!!!!
--  signal test_pix: integer:=0;--  �������� �������. ��������� ���-�� ������ � ������
--  signal test_row: integer:=0;--  �������� �������. ��������� ���-�� ����� � �����
--  signal APRT: std_logic;

--  MAIN
begin

p_out_tv_field<=Fiald_int;
p_out_tv_kci<=KCI_int;

process(p_in_rst,clk)
variable a : std_logic;
variable b : std_logic;
begin
  if p_in_rst='1' then
    cnt_2H<=(others=>'0');--0;
    cnt_N2H<=CONV_STD_LOGIC_VECTOR((N_ROW-2), 10);
    cnt_2H5<=CONV_STD_LOGIC_VECTOR(3, 3);
    cnt_N2H5<=CONV_STD_LOGIC_VECTOR(((N_ROW/5)-1), 7);
    H2SHT3<='0';
    H2SHT2<='0';
    H2SHT1<='0';
    H2<='0';

    a:='0';
    SelH<='0';

    Fiald_int<='0';
    b:='0';

    EUR<='0';
--      EAR<='0';
    KCI_int<='0';
--      KGI<='0';

  elsif clk'event and clk='1' then
  if p_in_clk_en='1' then
    if cnt_2H=CONV_STD_LOGIC_VECTOR(N_H2-1, 9) then
      --��������� ������ ��������� ������� �����
      H2<='1';
      cnt_2H<=(others=>'0');--0;

      a:= not a;
      SelH<=a;

      --������������ 5 ��������� ��������� ������� �����
      if cnt_2H5=CONV_STD_LOGIC_VECTOR(4, 3) then
        cnt_2H5<=(others=>'0');--0;

        --������������ ���-�� ��� �� 5 ��������� ��������� ������� �����
        if cnt_N2H5=CONV_STD_LOGIC_VECTOR(((N_ROW/5)-1), 7) then
          cnt_N2H5<=(others=>'0');--0;
          KCI_int<='0';
          --��������� ���������� ��� ������������ ������������ ���������
          EUR<='1';
          --��������� ���������� ��� ������������ ��������� �������� ��������
--            KGI<='1';

        elsif cnt_N2H5="0000000" then
          --��������� ������ ����
          b:=not b;
          Fiald_int<=b;

          --��������� ������� ������ �������
          KCI_int<='1';
          cnt_N2H5<=cnt_N2H5+1;

        elsif cnt_N2H5=CONV_STD_LOGIC_VECTOR(1, 7) then
          --��������� ������� ������ �������
          KCI_int<='0';
          cnt_N2H5<=cnt_N2H5+1;

        elsif cnt_N2H5=CONV_STD_LOGIC_VECTOR(2, 7) then
          --��������� ���������� ��� ������������ ������������ ���������
          EUR<='0';

          cnt_N2H5<=cnt_N2H5+1;

--          elsif cnt_N2H5=CONV_STD_LOGIC_VECTOR(9, 7) then
--            --��������� ���������� ��� ������������ ��������� �������� ��������
--            KGI<='0';
--            cnt_N2H5<=cnt_N2H5+1;

        else
          cnt_N2H5<=cnt_N2H5+1;

        end if;

      else
        cnt_2H5<=cnt_2H5+1;

      end if;

      --����������� ���-�� ��������� �����
      if cnt_N2H=CONV_STD_LOGIC_VECTOR((N_ROW-1), 10) then
        cnt_N2H<=(others=>'0');--0;

      else
        cnt_N2H<=cnt_N2H+1;

      end if;

--������������ ��������� ��������� �� ����������� �������� ������������ H2
    elsif cnt_2H=CONV_STD_LOGIC_VECTOR((W2_32us-1), 9) then
      --��������� ��������� ������ ������������ H2
      --�� 0+2,3���
        H2SHT1<='1';
        H2SHT2<='0';
        H2SHT3<='0';
        H2SHT4<='0';
        H2SHT5<='0';
        H2<='0';
        cnt_2H<=cnt_2H+1;

    elsif cnt_2H=CONV_STD_LOGIC_VECTOR((N_H2-(W4_7us-1)), 9) then
      --��������� ��������� ������ ������������ H2
      --�� 0-4,7���
        H2SHT1<='0';
        H2SHT2<='1';
        H2SHT3<='0';
        H2SHT4<='0';
        H2SHT5<='0';
        H2<='0';
        cnt_2H<=cnt_2H+1;

    elsif cnt_2H=CONV_STD_LOGIC_VECTOR((W4_7us-1), 9) then
      --��������� ��������� ������ ������������ H2
      --�� 0+4,7���
        H2SHT1<='0';
        H2SHT2<='0';
        H2SHT3<='1';
        H2SHT4<='0';
        H2SHT5<='0';
        H2<='0';
        cnt_2H<=cnt_2H+1;

    elsif cnt_2H=CONV_STD_LOGIC_VECTOR(((W4_7us-1)+(W5_8us-1)+var1), 9) then
      --��������� ��������� ������ ������������ H2
      --�� 0+4,7���+5,8���+6(clk)
        H2SHT1<='0';
        H2SHT2<='0';
        H2SHT3<='0';
        H2SHT4<='1';
        H2SHT5<='0';
        H2<='0';
        cnt_2H<=cnt_2H+1;

    elsif cnt_2H=CONV_STD_LOGIC_VECTOR((N_H2-W1_53us-1-var2), 9) then
      --��������� ��������� ������ ������������ H2
      --�� 0-1,53���-6(clk)
        H2SHT1<='0';
        H2SHT2<='0';
        H2SHT3<='0';
        H2SHT4<='0';
        H2SHT5<='1';
        H2<='0';
        cnt_2H<=cnt_2H+1;
    else
        H2SHT1<='0';
        H2SHT2<='0';
        H2SHT3<='0';
        H2SHT4<='0';
        H2SHT5<='0';
        H2<='0';
        cnt_2H<=cnt_2H+1;
    end if;
  end if;
  end if;
end process;

--��������� TV ������ (�����������)
process(p_in_rst,clk)
variable a : std_logic;
begin
  if p_in_rst='1' then
    a:= '0';
    p_out_tv_ssi<='0';
  elsif clk'event and clk='1' then
  if p_in_clk_en='1' then
        --��������� ��� � ������
    if ((H2='1' or H2SHT3='1') and SelH='1' and EUR='0')  or
      --��������� ������������ �������� ��� ���
       ((H2='1' or H2SHT1='1') and EUR='1' and KCI_int='0') or
        --��������� ������������ �������� ������ ���
       ((H2='1' or H2SHT2='1') and EUR='1' and KCI_int='1') then
      a:= not a;
      p_out_tv_ssi<=not a;
    end if;
  end if;
  end if;
end process;

--��������� �������� ����� ������
process(p_in_rst,clk)
  variable a : std_logic;
begin
  if p_in_rst='1' then
    a:= '0';
    p_out_den<='0';

  elsif clk'event and clk='1' then
  if p_in_clk_en='1' then
    if ((H2SHT4='1' and SelH='1') or (H2SHT5='1'  and SelH='0')) then
      --�������� ���-�� �������� ����� � 1-�� � 2-�� ����
      --� 1-�� ���� �� ������� 287 �����
--        if (Fiald_int='1' and (cnt_N2H>CONV_STD_LOGIC_VECTOR(50, 10) and cnt_N2H<=CONV_STD_LOGIC_VECTOR(624, 10))) or
--           (Fiald_int='0' and (cnt_N2H>CONV_STD_LOGIC_VECTOR(49, 10) and cnt_N2H<=CONV_STD_LOGIC_VECTOR(623, 10))) then
      --� 1-�� ���� �� ������� 288 �����
      if (Fiald_int='1' and (cnt_N2H>CONV_STD_LOGIC_VECTOR(48, 10) and cnt_N2H<=CONV_STD_LOGIC_VECTOR(624, 10))) or
         (Fiald_int='0' and (cnt_N2H>CONV_STD_LOGIC_VECTOR(47, 10) and cnt_N2H<=CONV_STD_LOGIC_VECTOR(623, 10))) then
      --Test
--        if (Fiald_int='1' and (cnt_N2H>CONV_STD_LOGIC_VECTOR(24, 10) and cnt_N2H<=CONV_STD_LOGIC_VECTOR(64, 10))) or
--           (Fiald_int='0' and (cnt_N2H>CONV_STD_LOGIC_VECTOR(23, 10) and cnt_N2H<=CONV_STD_LOGIC_VECTOR(63, 10))) then
        a:= not a;
        p_out_den<=not a;

        --��� ������������ ���-�� ����� � ����� � ������ � ������!!!!!!
--          APRT<=not a;

      end if;
    end if;
  end if;
  end if;
end process;


----��������� ������� ��� ���������� ������
--process(p_in_rst,clk)
--begin
--  if p_in_rst='1' then
--    LOAD_ADJUST<='0';
--    EN_ADJUST<='0';
--
--  elsif clk'event and clk='1' then
--  if p_in_clk_en='1' then
--
----      if (Fiald_int='1' and cnt_N2H=CONV_STD_LOGIC_VECTOR(51, 10)) or (Fiald_int='0' and cnt_N2H=CONV_STD_LOGIC_VECTOR(50, 10)) then
--    if (Fiald_int='1' and cnt_N2H=CONV_STD_LOGIC_VECTOR(49, 10)) or (Fiald_int='0' and cnt_N2H=CONV_STD_LOGIC_VECTOR(48, 10)) then
--      EN_ADJUST<='1';
--    elsif cnt_N2H=CONV_STD_LOGIC_VECTOR(0, 10) then
--      EN_ADJUST<='0';
--    end if;
--
----      if (Fiald_int='1' and cnt_N2H=CONV_STD_LOGIC_VECTOR(51, 10)) or (Fiald_int='0' and cnt_N2H=CONV_STD_LOGIC_VECTOR(50, 10)) then
--    if (Fiald_int='1' and cnt_N2H=CONV_STD_LOGIC_VECTOR(49, 10)) or (Fiald_int='0' and cnt_N2H=CONV_STD_LOGIC_VECTOR(48, 10)) then
--      LOAD_ADJUST<='1';
--    else
--      LOAD_ADJUST<='0';
--    end if;
--
--  end if;
--  end if;
--end process;


--  *********************************************************************************
--  ************* ��������� ���-�� ����� � ����� � ������ � ������ ******************
--  *********************************************************************************
--  process(p_in_rst,clk)
--  begin
--    if p_in_rst='1' then
--      test_pix<=0;
--    elsif clk'event and clk='1' then
--      if APRT='1' then
--        test_pix<=test_pix+1;
--      else
--        test_pix<=0;
--      end if;
--    end if;
--  end process;

--  process(KCI_int,APRT)
--  begin
--    if KCI_int='1' then
--      test_row<=0;
--    elsif APRT'event and APRT='1' then
--      test_row<=test_row+1;
--    end if;
--  end process;

--  END MAIN
end behavior;
