-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 2010.08
-- Module Name : vsobel_main
--
-- ����������/�������� :
--  ������ ��������� ���������� ��������� ������.
--
--  ����������� ��������� �������� dX, dY , �������� �������
--  ��� ��������� ������ � ���� p_out_dwnp_data �������� ���� ������� ������
--
--  Upstream Port(��. ������)
--  Downstream Port(���. ������)
--
--  ������� ������: ������ 2-� ������� � ������ + ������ 2-� ������
--  �������� ������
--
--  �������� ������ ������:
--  1. ������� ����� ������ ������. ���� p_in_cfg_bypass - 0/1:
--     Upstream Port -> Downstream Port ������������/�� ������������
--  2. ��������� ������ �������� ����� ����� p_in_cfg_pix_count/p_in_cfg_row_count
--
--
-- Revision:
-- Revision 0.01 - File Created
-- Revision 0.02 - add 2010.10.07 �������� Bag (������ ��������� �� 2)
-- Revision 0.03 - add 2010.11.06 ������� ���������� ���� ���������� p_in_cfg_ctrl
-- Revision 0.04 - add 2010.11.10 ������� ������ ���������� �� ���� p_out_dwnp_data ��� p_in_cfg_bypass='0'
-- Revision 0.05 - add 2010.11.10 ��������
--                 ���� tmp_grad_out(0)(9 downto 0) - � ���� ������ ���� ������������
--                 ����� tmp_grad_out(0)(10 downto 0) - ���������� ��������
-- Revision 0.06 - add 2010.11.13 ������������� ���������� ������ ������� ������.
--                 �������� ������ �������� �������, ������� ��� ��������� ���� ���������� �������.
--                 � ���������� ���������� ����� ���� ������� :)
-- Revision 1.00 - add 2010.11.19
--                 ������� generic - G_DOUT_WIDTH + � ��������������� ��������� � ����� � ����
-- Revision 2.00 - add 2010.11.26
--                 ������� ���������� �������� ����� � ������ ������������ ����� ����������.
--                 ������ ������� �� ������� �� Xilix s3esk_video_line_stores.pdf (��. ������� ..\Sobel\doc)
--
-- Revision 2.01 - add 06.12.2010 12:27:08
--                 ������������ ���� p_out_dwnp_dx,p_out_dwnp_dy � p_out_dwnp_dxm,p_out_dwnp_dym (m - �������� ������)
--                 ������� ����� p_out_dwnp_dxs,p_out_dwnp_dys (s - �������� ��������.
--                 ��������� �������� i_sum_x1(i) - i_sum_x2(i), i_sum_y1(i) - i_sum_y2(i).
--                 ������� ������������ � ������� ..\Sobel\doc
-- Revision 2.02 - add 10.12.2010 11:47:08
--                 ������������� ��������� �������� �������� dX,dY
--                 ��� ������������ � ��������� ����������.
-- Revision 2.03 - add 20.01.2011 18:59:43
--                 ������� ������ �������� ������� �������� ��� ���������� ���������.
-- Revision 2.04 - add 22.01.2011 17:28:27
--                 � ����������� ������� ������� �������� ���������� ������ � ������� �� 2
-- Revision 2.05 - add 25.01.2011 17:37:18
--                 �������� ������� �� 2(������ �� ������), � � ����� � ���
--                 �������� ������� ������� ������� �������� ���������� ������ � ������� �� 2
-- Revision 2.06 - add 26.01.2011 16:40:07
--                 ��������� ��� ����������� ������� �������� � ������� ����� ������ ����� p_in_upp_data
--                 ���� ������� ��� ����� ������ ������� ��� p_in_upp_data=32bit, ��� � � p_in_upp_data=8bit
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
--use work.prj_def.all;

entity vsobel_main is
generic(
G_DOUT_WIDTH : integer:=32;  --//��������� �������� 32, 8

                             --//���� 32, ��
                             --//����� : �� 1clk �� �������� ����� �������� ����� 4-� ���������� ������, ���
                             --//p_out_dwnp_grad(7...0)   = i_grad_out(0);
                             --//p_out_dwnp_grad(15...8)  = i_grad_out(1);
                             --//p_out_dwnp_grad(23...16) = i_grad_out(2);
                             --//p_out_dwnp_grad(31...24) = i_grad_out(3);
                             --//������: ��� ���������� ��������� ������ �������� FPGA

                             --//���� 8, ��
                             --//����� : ����� ���������� ���������� �� ��������� � G_DOUT_WIDTH=32
                             --//������:�� 1clk �� �������� ����� ������� 1 ���������� �����, ���
                             --//p_out_dwnp_grad(7...0)   = i_grad_out(0);
                             --//p_out_dwnp_grad(15...8)  = 0;
                             --//p_out_dwnp_grad(23...16) = 0;
                             --//p_out_dwnp_grad(31...24) = 0;

G_SIM         : string:="OFF"
);
port
(
-------------------------------
-- ����������
-------------------------------
p_in_cfg_bypass            : in    std_logic;                    --//0/1 - Upstream Port -> Downstream Port ������������/�� ������������
p_in_cfg_pix_count         : in    std_logic_vector(15 downto 0);--//���-�� ������/4 �.� p_in_upp_data=32bit
p_in_cfg_row_count         : in    std_logic_vector(15 downto 0);--//���-�� ����� (�����������)
p_in_cfg_ctrl              : in    std_logic_vector(1 downto 0); --//���0 - 1/0 - ������ ������ ������������ ������� (dx^2 + dy^2)^0.5
                                                                 --//���1 - 1/0 - (1 - dx,dy ������� �� 2. ������ ��� ����������),(0 - ��� �������)
p_in_cfg_init              : in    std_logic;                    --//�������������. ����� �������� ������ BRAM

--//--------------------------
--//Upstream Port (������� ������)
--//--------------------------
--p_in_upp_clk               : in    std_logic;
p_in_upp_data              : in    std_logic_vector(31 downto 0);
p_in_upp_wd                : in    std_logic;                    --//������ ������ � ������ vsobel_main.vhd
p_out_upp_rdy_n            : out   std_logic;                    --//0 - ������ vsobel_main.vhd ����� � ������ ������

--//--------------------------
--//Downstream Port (���������)
--//--------------------------
--p_in_dwnp_clk              : in    std_logic;
p_in_dwnp_rdy_n            : in    std_logic;                    --//0 - ���� ��������� ����� � ������ ������
p_out_dwnp_wd              : out   std_logic;                    --//������ ������ � ��������
p_out_dwnp_data            : out   std_logic_vector(31 downto 0);

p_out_dwnp_grad            : out   std_logic_vector(31 downto 0);--//�������� �������

p_out_dwnp_dxm             : out   std_logic_vector((8*4)-1 downto 0); --//dX - ������
p_out_dwnp_dym             : out   std_logic_vector((8*4)-1 downto 0); --//dY - ������

p_out_dwnp_dxs             : out   std_logic_vector((11*4)-1 downto 0);--//dX - �������� ��������(��� 10)
p_out_dwnp_dys             : out   std_logic_vector((11*4)-1 downto 0);--//dY - �������� ��������(��� 10)

-------------------------------
--���������������
-------------------------------
p_in_tst_ctrl              : in    std_logic_vector(31 downto 0);
p_out_tst                  : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk            : in    std_logic;
p_in_rst            : in    std_logic
);
end vsobel_main;

architecture behavioral of vsobel_main is

constant dly : time := 1 ps;

component vsobel_sub
port (
a   : in  std_logic_vector(10 downto 0);
b   : in  std_logic_vector(10 downto 0);
s   : out std_logic_vector(10 downto 0)
);
end component;

component vsobel_bram
port
(
--//WRITE FIRST
addra: IN  std_logic_VECTOR(9 downto 0);
dina : IN  std_logic_VECTOR(31 downto 0);
douta: OUT std_logic_VECTOR(31 downto 0);
ena  : IN  std_logic;
wea  : IN  std_logic_VECTOR(0 downto 0);
clka : IN  std_logic;
rsta : IN  std_logic;

--//READ FIRST
addrb: IN  std_logic_VECTOR(9 downto 0);
dinb : IN  std_logic_VECTOR(31 downto 0);
doutb: OUT std_logic_VECTOR(31 downto 0);
enb  : IN  std_logic;
web  : IN  std_logic_VECTOR(0 downto 0);
clkb : IN  std_logic;
rstb : IN  std_logic
);
end component;

signal b_ctrl_div                        : std_logic;
signal b_ctrl_grad                       : std_logic;

signal i_upp_data                        : std_logic_vector(p_in_upp_data'range);
signal i_upp_wd                          : std_logic;
signal i_upp_rdy_n_out                   : std_logic;

signal i_lbufs_adra                      : std_logic_vector(9 downto 0);
signal tmp_lbufs_awrite                  : std_logic_vector(i_lbufs_adra'range);
type TArryLBufByte is array (0 to 2) of std_logic_vector(31 downto 0);
signal i_lbufs_dout                      : TArryLBufByte;
signal i_lbufs_dout_dly                  : TArryLBufByte;
signal i_lbuf_ena                        : std_logic_vector(0 downto 0);

signal i_byte_cnt_init                   : std_logic_vector(1 downto 0);
signal i_byte_cnt                        : std_logic_vector(1 downto 0);
--signal i_pix_cnt                         : std_logic_vector(p_in_cfg_pix_count'length-1 downto 0);
--signal i_row_cnt                         : std_logic_vector(p_in_cfg_row_count'length-1 downto 0);

signal sr_result_en_fst                  : std_logic_vector(0 to 3);
signal sr_result_en                      : std_logic_vector(0 to 7);

signal sr_byteline_ld                    : std_logic_vector(0 to 0);
signal sr_byteline_en                    : std_logic_vector(0 to 0);
type TSrByte is array (3 downto 0) of std_logic_vector(7 downto 0);
type TSrLine is array (0 to 2) of TSrByte;
signal sr_byteline                       : TSrLine;

type TSrByteDly is array (0 to 1) of std_logic_vector(7 downto 0);
type TSrLineDly is array (0 to 2) of TSrByteDly;
signal sr_byteline_dly                   : TSrLineDly;

type TArrayPixs is array (0 to 2) of std_logic_vector(7 downto 0);
type TMatrix is array (0 to 2) of TArrayPixs;
type TMatrixs is array (0 to G_DOUT_WIDTH/8-1) of TMatrix;
signal i_matrix                          : TMatrixs;

type TSrPixOut is array (0 to 5) of std_logic_vector(7 downto 0);
type TSrPixOuts is array (0 to G_DOUT_WIDTH/8-1) of TSrPixOut;
signal sr_pix                            : TSrPixOuts;

type TCalc0 is array (0 to 3) of std_logic_vector(8 downto 0);
signal i_sum_pix02_line0                 : TCalc0;
signal i_sum_pix02_line2                 : TCalc0;
signal i_sum_pix0_line02                 : TCalc0;
signal i_sum_pix2_line02                 : TCalc0;

signal i_sum_pix1_line0_x2               : TCalc0;
signal i_sum_pix1_line2_x2               : TCalc0;
signal i_sum_pix0_line1_x2               : TCalc0;
signal i_sum_pix2_line1_x2               : TCalc0;

type TCalc1 is array (0 to G_DOUT_WIDTH/8-1) of std_logic_vector(9 downto 0);
signal i_sum_x1                          : TCalc1;
signal i_sum_x2                          : TCalc1;
signal i_sum_y1                          : TCalc1;
signal i_sum_y2                          : TCalc1;

signal tmp_delt_xm                       : TCalc1;
signal i_delt_xm                         : TCalc1;
signal i_delt_xm_dly0                    : TCalc1;
signal i_delt_xm_dly1                    : TCalc1;

signal tmp_delt_ym                       : TCalc1;
signal i_delt_ym                         : TCalc1;
signal i_delt_ym_dly0                    : TCalc1;
signal i_delt_ym_dly1                    : TCalc1;

signal tmp_delt_xs_div                   : TCalc1;
signal tmp_delt_ys_div                   : TCalc1;

type TCalc2 is array (0 to G_DOUT_WIDTH/8-1) of std_logic_vector((2*i_delt_xm(0)'length)-1 downto 0);
signal i_mult_01                         : TCalc2;
signal i_mult_01_div                     : TCalc2;
--signal i_mult_01_div_rem                 : TCalc201;
signal i_mult_02                         : TCalc2;
signal i_mult_02_div                     : TCalc2;
--signal i_mult_02_div_rem                 : TCalc202;
--signal i_mult_div_rem_result             : TCalc203;


type TCalc3 is array (0 to G_DOUT_WIDTH/8-1) of std_logic_vector(10 downto 0);--//add 2010.11.10
--signal tmp_grad_out                      : TCalc3;
signal tmp_grad_out                      : TCalc2;

signal i_sum_x1s                         : TCalc3;--//std_logic_vector(10 downto 0);--
signal i_sum_x2s                         : TCalc3;
signal i_sum_y1s                         : TCalc3;
signal i_sum_y2s                         : TCalc3;
signal i_sub_x12s                        : TCalc3;
signal i_sub_y12s                        : TCalc3;

signal tmp_delt_xs                       : TCalc3;
signal tmp_delt_ys                       : TCalc3;
signal i_delt_xs                         : TCalc3;
signal i_delt_xs_dly0                    : TCalc3;
signal i_delt_xs_dly1                    : TCalc3;

signal i_delt_ys                         : TCalc3;
signal i_delt_ys_dly0                    : TCalc3;
signal i_delt_ys_dly1                    : TCalc3;

signal i_delt_xs_out                     : TCalc3;
signal i_delt_ys_out                     : TCalc3;

type TCalc4 is array (0 to G_DOUT_WIDTH/8-1) of std_logic_vector(7 downto 0);
signal i_grad_out                        : TCalc4;
signal i_delt_xm_out                     : TCalc4;
signal i_delt_ym_out                     : TCalc4;

signal i_result_out                      : TCalc4;
signal i_result_en_out                   : std_logic;


--MAIN
begin

--//----------------------------------
--//��������������� �������
--//----------------------------------
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    p_out_tst(7 downto 0)<=(others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then
--    for i in 0 to G_DOUT_WIDTH/8-1 loop
--      p_out_tst(1)<=OR_reduce(i_mult_01_div_rem(i)) or i_mult_div_rem_result(i)(7);
--      p_out_tst(2)<=OR_reduce(i_mult_02_div_rem(i));
--    end loop;

    p_out_tst(0)<=OR_reduce(i_byte_cnt);
  end if;
end process;
--p_out_tst(7 downto 0)<=(others=>'0');


--//-----------------------------
--//�������������
--//-----------------------------

--//add 2010.11.06
b_ctrl_div <=p_in_cfg_ctrl(1);
b_ctrl_grad<=p_in_cfg_ctrl(0);



--//------------------------------------------------------
--//RAM ����� ����� ����������
--//------------------------------------------------------
--//������ ������ � ������(BRAM) �����
i_lbufs_adra<=tmp_lbufs_awrite;

i_lbuf_ena(0) <=i_upp_wd and not p_in_dwnp_rdy_n;

--//������ �����:
--//lineN : ������� ������
i_lbufs_dout(0)<=i_upp_data;

--//lineN-1 : ���������� ������
m_buf0 : vsobel_bram
port map
(
--//READ FIRST
addra=> i_lbufs_adra,
dina => i_upp_data,
douta=> i_lbufs_dout(1),
ena  => i_lbuf_ena(0),
wea  => i_lbuf_ena,
clka => p_in_clk,
rsta => p_in_rst,

--//WRITE FIRST
addrb=> "0000000000",
dinb => "00000000000000000000000000000000",
doutb=> open,
enb  => '0',
web  => "0",
clkb => p_in_clk,
rstb => p_in_rst
);

--//lineN-2 : ���������� ������
m_buf1 : vsobel_bram
port map
(
--//READ FIRST
addra=> i_lbufs_adra,
dina => i_lbufs_dout(1),
douta=> i_lbufs_dout(2),
ena  => i_lbuf_ena(0),
wea  => i_lbuf_ena,
clka => p_in_clk,
rsta => p_in_rst,

--//WRITE FIRST
addrb=> "0000000000",
dinb => "00000000000000000000000000000000",
doutb=> open,
enb  => '0',
web  => "0",
clkb => p_in_clk,
rstb => p_in_rst
);


--//XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
--//���������� �������� + ������������ ������� ����������
--//��� ������ 1clk=4-� �������� sample
--//XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
gen_w32 : if G_DOUT_WIDTH=32 generate
begin

--//------------------------------------------------------
--//
--//------------------------------------------------------
--//add 26.01.2011 16:40:07
i_upp_data<=p_in_upp_data;
i_upp_wd<=p_in_upp_wd;


--//-----------------------------
--//�������������
--//-----------------------------
--i_byte_cnt_init<="10";

--//----------------------------------------------
--//����� � Upstream Port
--//----------------------------------------------
p_out_upp_rdy_n <= p_in_dwnp_rdy_n;-- when p_in_cfg_bypass='0' else p_in_dwnp_rdy_n;
--p_out_upp_rdy_n <=i_upp_rdy_n_out or p_in_dwnp_rdy_n when p_in_cfg_bypass='0' else p_in_dwnp_rdy_n;

--//-----------------------------
--//����� ����������
--//-----------------------------
p_out_dwnp_wd <= i_result_en_out when p_in_cfg_bypass='0' else p_in_upp_wd;

gen0_w32byte : for i in 0 to 3 generate
p_out_dwnp_data(8*(i + 1) - 1 downto 8*i) <= i_result_out(i) when p_in_cfg_bypass='0' else p_in_upp_data(8*(i + 1) - 1 downto 8*i);
p_out_dwnp_grad(8*(i + 1) - 1 downto 8*i)<= i_grad_out(i);

p_out_dwnp_dxm(8*(i + 1) - 1 downto 8*i) <= i_delt_xm_out(i);
p_out_dwnp_dym(8*(i + 1) - 1 downto 8*i) <= i_delt_ym_out(i);

p_out_dwnp_dxs(11*(i + 1) - 1 downto 11*i) <= i_delt_xs_out(i);
p_out_dwnp_dys(11*(i + 1) - 1 downto 11*i) <= i_delt_ys_out(i);
end generate gen0_w32byte;

--//----------------------------------------------
--//���������� ������� ������ � Upstream Port
--//----------------------------------------------
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
--    i_upp_rdy_n_out<='0';

    tmp_lbufs_awrite<=(others=>'0');
--    i_row_cnt<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then

    if p_in_cfg_bypass='1' or p_in_cfg_init='1' then
      tmp_lbufs_awrite<=(others=>'0');
    else
      --//��������� ����� ���.
        if p_in_dwnp_rdy_n='0' then

            if i_upp_wd='1' then
              if tmp_lbufs_awrite=p_in_cfg_pix_count(tmp_lbufs_awrite'range)-2 then
                tmp_lbufs_awrite<=(others=>'0');
              else
                tmp_lbufs_awrite<=tmp_lbufs_awrite+1;
              end if;
            end if;

        end if;--//if p_in_dwnp_rdy_n='0' then
    end if;

  end if;
end process;


--//------------------------------------------------------
--//����� ��������
--//------------------------------------------------------
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then

    sr_result_en<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then
  if p_in_dwnp_rdy_n='0' then

      --//���-�� ������ �������� = ���-�� �������� ����������:
      --//� ����� ������ ����� �������� � ����������� �� ���-�� �������� ����������
--      sr_result_en<=(i_upp_wd or OR_reduce(i_byte_cnt)) & sr_result_en(0 to 6);
      sr_result_en<=i_upp_wd & sr_result_en(0 to 6);

  end if;--//if p_in_dwnp_rdy_n='0' then
  end if;
end process;

--//------------------------------------------------------
--//������������ ������� ����������
--//------------------------------------------------------
sr_byteline_ld(0)<=i_upp_wd;

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    for y in 0 to 2 loop
      for i in 0 to 3 loop
        sr_byteline(y)(i)<=(others=>'0');
      end loop;

      for i in 0 to 1 loop
        sr_byteline_dly(y)(i)<=(others=>'0');
      end loop;
    end loop;
  elsif p_in_clk'event and p_in_clk='1' then
  if p_in_dwnp_rdy_n='0' then

      if sr_byteline_ld(0)='1'then
          for y in 0 to 2 loop
            for i in 0 to 3 loop
              sr_byteline(y)(i)<=i_lbufs_dout(y)(8*(i+1)-1 downto 8*i);
            end loop;

            for i in 0 to 1 loop
              sr_byteline_dly(y)(i)<=sr_byteline(y)(i+2);
            end loop;
          end loop;
      end if;

  end if;--//if p_in_dwnp_rdy_n='0'
  end if;
end process;

--//������� ����������
--//��� - i_matrix(������ ��������� ������)(������ ������)(������ �������)
gen_matrix0 : for i in 0 to 2 generate
begin
--//��� - i_matrix(0)(������ ������)(������ �������)
i_matrix(0)(2-i)(2)<=sr_byteline(i)(0);
i_matrix(0)(2-i)(1)<=sr_byteline_dly(i)(1);
i_matrix(0)(2-i)(0)<=sr_byteline_dly(i)(0);
end generate gen_matrix0;

gen_matrix1 : for i in 0 to 2 generate
begin
--//��� - i_matrix(0)(������ ������)(������ �������)
i_matrix(1)(2-i)(2)<=sr_byteline(i)(1);
i_matrix(1)(2-i)(1)<=sr_byteline(i)(0);
i_matrix(1)(2-i)(0)<=sr_byteline_dly(i)(1);
end generate gen_matrix1;

gen_matrix2 : for i in 0 to 2 generate
begin
--//��� - i_matrix(0)(������ ������)(������ �������)
i_matrix(2)(2-i)(2)<=sr_byteline(i)(2);
i_matrix(2)(2-i)(1)<=sr_byteline(i)(1);
i_matrix(2)(2-i)(0)<=sr_byteline(i)(0);
end generate gen_matrix2;

gen_matrix3 : for i in 0 to 2 generate
begin
--//��� - i_matrix(0)(������ ������)(������ �������)
i_matrix(3)(2-i)(2)<=sr_byteline(i)(3);
i_matrix(3)(2-i)(1)<=sr_byteline(i)(2);
i_matrix(3)(2-i)(0)<=sr_byteline(i)(1);
end generate gen_matrix3;

end generate gen_w32;




--//XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
--//���������� �������� + ������������ ������� ����������
--//��� ������ 1clk=1�������� sample
--//XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
gen_w8 : if G_DOUT_WIDTH=8 generate
begin

--//------------------------------------------------------
--//
--//------------------------------------------------------
--//add 26.01.2011 16:40:07
i_upp_data<=p_in_upp_data;
i_upp_wd<=p_in_upp_wd;


--//-----------------------------
--//�������������
--//-----------------------------
i_byte_cnt_init<="11";

--//----------------------------------------------
--//����� � Upstream Port
--//----------------------------------------------
p_out_upp_rdy_n <=i_upp_rdy_n_out or p_in_dwnp_rdy_n when p_in_cfg_bypass='0' else p_in_dwnp_rdy_n;

--//-----------------------------
--//����� ����������
--//-----------------------------
--add 2010.11.10
p_out_dwnp_wd <= i_result_en_out when p_in_cfg_bypass='0' else p_in_upp_wd;
p_out_dwnp_data <= EXT(i_result_out(0), p_out_dwnp_data'length) when p_in_cfg_bypass='0' else p_in_upp_data;

p_out_dwnp_grad <= EXT(i_grad_out(0), p_out_dwnp_grad'length);

p_out_dwnp_dxm  <= EXT(i_delt_xm_out(0), p_out_dwnp_dxm'length);
p_out_dwnp_dym  <= EXT(i_delt_ym_out(0), p_out_dwnp_dym'length);

p_out_dwnp_dxs  <= EXT(i_delt_xs_out(0), p_out_dwnp_dxs'length);
p_out_dwnp_dys  <= EXT(i_delt_ys_out(0), p_out_dwnp_dys'length);




--//----------------------------------------------
--//���������� ������� ������ � Upstream Port
--//----------------------------------------------
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_upp_rdy_n_out<='0';

    i_byte_cnt<=(others=>'0');
    tmp_lbufs_awrite<=(others=>'0');
--    i_row_cnt<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then

    if p_in_cfg_bypass='1' or p_in_cfg_init='1' then
      tmp_lbufs_awrite<=(others=>'0');
      i_byte_cnt<=(others=>'0');
      i_upp_rdy_n_out<='0';

    else
      --//��������� ����� ���.
        if p_in_dwnp_rdy_n='0' then

            if i_upp_wd='1' then
              --//����� ������ �������� DWORD
              i_upp_rdy_n_out<='1';--//��������� ������ ������� ������ � ����� ������ ��
                                   --//����� ��������� ���� ���� �������� DWORD

              i_byte_cnt<=i_byte_cnt+1;--//����� ������� ���� �������� DWORD

            else
              if i_upp_rdy_n_out='1' then
              --//��������� ���� �������� DWORD
                if i_byte_cnt=i_byte_cnt_init then
                  i_byte_cnt<=(others=>'0');
                  i_upp_rdy_n_out<='0';

                  if tmp_lbufs_awrite=p_in_cfg_pix_count(tmp_lbufs_awrite'range)-2 then
                    tmp_lbufs_awrite<=(others=>'0');
                  else
                    tmp_lbufs_awrite<=tmp_lbufs_awrite+1;
                  end if;

                else
                  i_byte_cnt<=i_byte_cnt+1;--//����� ������� ���� �������� DWORD
                end if;
              end if;
            end if;
        end if;--//if p_in_dwnp_rdy_n='0' then

    end if;

  end if;
end process;

--//------------------------------------------------------
--//����� ��������
--//------------------------------------------------------
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then

    sr_result_en<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then
  if p_in_dwnp_rdy_n='0' then

      --//���-�� ������ �������� = ���-�� �������� ����������:
      --//� ����� ������ ����� �������� � ����������� �� ���-�� �������� ����������
      sr_result_en<=(i_upp_wd or OR_reduce(i_byte_cnt)) & sr_result_en(0 to 6);

  end if;--//if p_in_dwnp_rdy_n='0' then
  end if;
end process;


--//------------------------------------------------------
--//������������ ������� ����������
--//------------------------------------------------------
sr_byteline_en(0)<=OR_reduce(i_byte_cnt);
sr_byteline_ld(0)<=i_upp_wd;

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
      for y in 0 to 2 loop
        for i in 0 to 3 loop
          sr_byteline(y)(i)<=(others=>'0');
        end loop;
      end loop;
      for y in 0 to 2 loop
        for i in 0 to 1 loop
          sr_byteline_dly(y)(i)<=(others=>'0');
        end loop;
      end loop;
  elsif p_in_clk'event and p_in_clk='1' then
  if p_in_dwnp_rdy_n='0' then
      if sr_byteline_ld(0)='1'then
      --//�������� ������ 2DW ��� ������� ����������
        for y in 0 to 2 loop
          for i in 0 to 3 loop
            sr_byteline(y)(i)<=i_lbufs_dout(y)(8*(i+1)-1 downto 8*i);
          end loop;
        end loop;
      else
        if sr_byteline_en(0)='1'then
          --//������� ���� � ������� ���������� (����� ���� 2DW ��� 3-�� �����)
          for y in 0 to 2 loop
            sr_byteline(y)<="00000000"&sr_byteline(y)(3 downto 1);
          end loop;
        end if;
      end if;

      --//��������� ������� �� 2-� ����� ��� 3-�� �����
      --//��������� ��� ������������ ������� ����������
      for y in 0 to 2 loop
        if (sr_byteline_ld(0)='1' or sr_byteline_en(0)='1') then
          sr_byteline_dly(y)(0)<=sr_byteline(y)(0);
          sr_byteline_dly(y)(1)<=sr_byteline_dly(y)(0);
        end if;
      end loop;
  end if;--//if p_in_dwnp_rdy_n='0'
  end if;
end process;

--//������� ����������
gen_matrix0 : for i in 0 to 2 generate
begin
--//��� - i_matrix(0)(������ ������)(������ �������)
i_matrix(0)(2-i)(2)<=sr_byteline(i)(0);
i_matrix(0)(2-i)(1)<=sr_byteline_dly(i)(0);
i_matrix(0)(2-i)(0)<=sr_byteline_dly(i)(1);
end generate gen_matrix0;

end generate gen_w8;



--//------------------------------------------------------
--//����������
--//------------------------------------------------------
gen_mcalc : for i in 0 to G_DOUT_WIDTH/8-1 generate

--//add 06.12.2010
--//���(10) - ����!!!(0/1 - +/-)
i_sum_x1s(i)<=EXT(i_sum_x1(i), i_sum_x1s(i)'length);
i_sum_x2s(i)<=EXT(i_sum_x2(i), i_sum_x2s(i)'length);
i_sum_y1s(i)<=EXT(i_sum_y1(i), i_sum_y1s(i)'length);
i_sum_y2s(i)<=EXT(i_sum_y2(i), i_sum_y2s(i)'length);

--//���������� ��������
m_subx : vsobel_sub
port map(
a   => i_sum_x1s(i), --//a
b   => i_sum_x2s(i), --//b
s   => i_sub_x12s(i) --//s=a-b
);
m_suby : vsobel_sub
port map(
a   => i_sum_y2s(i), --i_sum_y1s(i), --//add 10.12.2010 11:47:08
b   => i_sum_y1s(i), --i_sum_y2s(i),
s   => i_sub_y12s(i)
);


--//������� �� 128
i_mult_01_div(i)<="0000000"&i_mult_01(i)(19 downto 7);--//���������
--i_mult_01_div_rem(i)<=i_mult_01(i)(6 downto 0);       --//�������

--//������� �� 32
i_mult_02_div(i)<="00000"&i_mult_02(i)(19 downto 5);--//���������
--i_mult_02_div_rem(i)<=i_mult_02(i)(4 downto 0);     --//�������

--//������� �� 2, �������� �������� tmp_delt_xs � tmp_delt_ys.
--//����� ������� ��������� ������ ����� �����!!!, ������� �����������
--//                                                                                                 | ����                                 |     | ������� ����� |
tmp_delt_xs_div(i)(i_delt_xs(i)'length-2 downto 0)<=tmp_delt_xs(i)(i_delt_xs(i)'length-1 downto 1) + (tmp_delt_xs(i)(tmp_delt_xs(i)'length-1) and tmp_delt_xs(i)(0));
tmp_delt_ys_div(i)(i_delt_xs(i)'length-2 downto 0)<=tmp_delt_ys(i)(i_delt_ys(i)'length-1 downto 1) + (tmp_delt_ys(i)(tmp_delt_ys(i)'length-1) and tmp_delt_ys(i)(0));

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then

    i_sum_pix02_line0(i)<=(others=>'0');
    i_sum_pix02_line2(i)<=(others=>'0');
    i_sum_pix0_line02(i)<=(others=>'0');
    i_sum_pix2_line02(i)<=(others=>'0');

    i_sum_pix1_line0_x2(i)<=(others=>'0');
    i_sum_pix1_line2_x2(i)<=(others=>'0');
    i_sum_pix0_line1_x2(i)<=(others=>'0');
    i_sum_pix2_line1_x2(i)<=(others=>'0');

    i_sum_x1(i)<=(others=>'0');
    i_sum_x2(i)<=(others=>'0');
    i_sum_y1(i)<=(others=>'0');
    i_sum_y2(i)<=(others=>'0');

    tmp_delt_xm(i)<=(others=>'0');
    tmp_delt_ym(i)<=(others=>'0');
    tmp_delt_xs(i)<=(others=>'0');
    tmp_delt_ys(i)<=(others=>'0');

    i_delt_xm(i)<=(others=>'0');
    i_delt_xm_dly0(i)<=(others=>'0');
    i_delt_xm_dly1(i)<=(others=>'0');
    i_delt_ym(i)<=(others=>'0');
    i_delt_ym_dly0(i)<=(others=>'0');
    i_delt_ym_dly1(i)<=(others=>'0');

    i_delt_xs(i)<=(others=>'0');
    i_delt_xs_dly0(i)<=(others=>'0');
    i_delt_xs_dly1(i)<=(others=>'0');
    i_delt_ys(i)<=(others=>'0');
    i_delt_ys_dly0(i)<=(others=>'0');
    i_delt_ys_dly1(i)<=(others=>'0');

    i_mult_01(i)<=(others=>'0');
    i_mult_02(i)<=(others=>'0');

    tmp_grad_out(i)<=(others=>'0');

    sr_pix(i)(0)<=(others=>'0');
    sr_pix(i)(1)<=(others=>'0');
    sr_pix(i)(2)<=(others=>'0');
    sr_pix(i)(3)<=(others=>'0');
    sr_pix(i)(4)<=(others=>'0');
    sr_pix(i)(5)<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then
  if p_in_dwnp_rdy_n='0' then
    --//------------------------------------------
    --//������
    --//------------------------------------------
    --//1 ����� ������� ������ ������� ����������
    i_sum_pix02_line0(i)<=EXT(i_matrix(i)(0)(0), i_sum_pix02_line0(i)'length) + EXT(i_matrix(i)(0)(2), i_sum_pix02_line0(i)'length);
    i_sum_pix02_line2(i)<=EXT(i_matrix(i)(2)(0), i_sum_pix02_line2(i)'length) + EXT(i_matrix(i)(2)(2), i_sum_pix02_line2(i)'length);

    i_sum_pix0_line02(i)<=EXT(i_matrix(i)(0)(0), i_sum_pix0_line02(i)'length) + EXT(i_matrix(i)(2)(0), i_sum_pix0_line02(i)'length);
    i_sum_pix2_line02(i)<=EXT(i_matrix(i)(0)(2), i_sum_pix2_line02(i)'length) + EXT(i_matrix(i)(2)(2), i_sum_pix2_line02(i)'length);

    --//add 2010.10.07
    i_sum_pix1_line0_x2(i)<=i_matrix(i)(0)(1)&'0'; --//��������� �� 2 ����� ������� ���������� ������� ����������
    i_sum_pix1_line2_x2(i)<=i_matrix(i)(2)(1)&'0'; --//����� 2-� ��������
    i_sum_pix0_line1_x2(i)<=i_matrix(i)(1)(0)&'0';
    i_sum_pix2_line1_x2(i)<=i_matrix(i)(1)(2)&'0';

--    sr_pix(i)(0)<=i_matrix(i)(2)(2);
    sr_pix(i)(0)<=i_matrix(i)(1)(1);--//add 20.01.2011 18:59:43
                                    --//������ �� �������� ���� �������� ������ � ��������� �������� �
                                    --//��� �������� �������

    --//2 �������������� ����� �� X,Y
    i_sum_x1(i)<=EXT(i_sum_pix02_line0(i), i_sum_x1(i)'length) + EXT(i_sum_pix1_line0_x2(i), i_sum_x1(i)'length);
    i_sum_x2(i)<=EXT(i_sum_pix02_line2(i), i_sum_x2(i)'length) + EXT(i_sum_pix1_line2_x2(i), i_sum_x2(i)'length);

    i_sum_y1(i)<=EXT(i_sum_pix0_line02(i), i_sum_y1(i)'length) + EXT(i_sum_pix0_line1_x2(i), i_sum_y1(i)'length);
    i_sum_y2(i)<=EXT(i_sum_pix2_line02(i), i_sum_y2(i)'length) + EXT(i_sum_pix2_line1_x2(i), i_sum_y2(i)'length);

    sr_pix(i)(1)<=sr_pix(i)(0);

    --//------------------------------------------
    --//���������� ������ +
    --//�������(���������)
    --//------------------------------------------
    if i_sum_x1(i) > i_sum_x2(i) then
      tmp_delt_xm(i)<=i_sum_x1(i) - i_sum_x2(i);
    else
      tmp_delt_xm(i)<=i_sum_x2(i) - i_sum_x1(i);
    end if;

    if i_sum_y1(i) > i_sum_y2(i) then
      tmp_delt_ym(i)<=i_sum_y1(i) - i_sum_y2(i);
    else
      tmp_delt_ym(i)<=i_sum_y2(i) - i_sum_y1(i);
    end if;

    tmp_delt_xs(i)<=i_sub_x12s(i);
    tmp_delt_ys(i)<=i_sub_y12s(i);

    sr_pix(i)(2)<=sr_pix(i)(1);

    --//------------------------------------------
    --//������� �� 2 (����������� ��� ����������)
    --//------------------------------------------
    if b_ctrl_div='1' then
      i_delt_xm(i)<='0'&tmp_delt_xm(i)(tmp_delt_xm(i)'length-1 downto 1);
      i_delt_ym(i)<='0'&tmp_delt_ym(i)(tmp_delt_ym(i)'length-1 downto 1);

      i_delt_xs(i)(i_delt_xs(i)'length-1)<=tmp_delt_xs(i)(i_delt_xs(i)'length-1);--//����
      i_delt_xs(i)(i_delt_xs(i)'length-2 downto 0)<=tmp_delt_xs_div(i);

      i_delt_ys(i)(i_delt_ys(i)'length-1)<=tmp_delt_ys(i)(i_delt_ys(i)'length-1);--//����
      i_delt_ys(i)(i_delt_ys(i)'length-2 downto 0)<=tmp_delt_ys_div(i);

    else
      i_delt_xm(i)<=tmp_delt_xm(i);
      i_delt_ym(i)<=tmp_delt_ym(i);

      i_delt_xs(i)<=tmp_delt_xs(i);
      i_delt_ys(i)<=tmp_delt_ys(i);
    end if;

    sr_pix(i)(3)<=sr_pix(i)(2);

    --//------------------------------------------
    --//���������� � ���������� ���������
    --//------------------------------------------
    if i_delt_xm(i) > i_delt_ym(i) then
      i_mult_01(i)<=i_delt_xm(i) * CONV_STD_LOGIC_VECTOR(10#123#, i_delt_xm(i)'length);
      i_mult_02(i)<=i_delt_ym(i) * CONV_STD_LOGIC_VECTOR(10#13#, i_delt_ym(i)'length);
    else
      i_mult_01(i)<=i_delt_ym(i) * CONV_STD_LOGIC_VECTOR(10#123#, i_delt_ym(i)'length);
      i_mult_02(i)<=i_delt_xm(i) * CONV_STD_LOGIC_VECTOR(10#13#, i_delt_xm(i)'length);
    end if;

    i_delt_xm_dly0(i)<=i_delt_xm(i);
    i_delt_ym_dly0(i)<=i_delt_ym(i);

    --//����� ��� �� �� ���������� -1024
    if i_delt_xs(i)(i_delt_xs(i)'length-2 downto 0)=CONV_STD_LOGIC_VECTOR(10#00#, i_delt_xs(i)'length-1) then
      i_delt_xs_dly0(i)(i_delt_xs(i)'length-1)<='0';
    else
      i_delt_xs_dly0(i)(i_delt_xs(i)'length-1)<=i_delt_xs(i)(i_delt_xs(i)'length-1);
    end if;
      i_delt_xs_dly0(i)(i_delt_xs(i)'length-2 downto 0)<=i_delt_xs(i)(i_delt_xs(i)'length-2 downto 0);

    if i_delt_ys(i)(i_delt_xs(i)'length-2 downto 0)=CONV_STD_LOGIC_VECTOR(10#00#, i_delt_ys(i)'length-1) then
      i_delt_ys_dly0(i)(i_delt_ys(i)'length-1)<='0';
    else
      i_delt_ys_dly0(i)(i_delt_ys(i)'length-1)<=i_delt_ys(i)(i_delt_ys(i)'length-1);
    end if;
      i_delt_ys_dly0(i)(i_delt_ys(i)'length-2 downto 0)<=i_delt_ys(i)(i_delt_ys(i)'length-2 downto 0);

--    i_delt_xs_dly0(i)<=i_delt_xs(i);
--    i_delt_ys_dly0(i)<=i_delt_ys(i);

    sr_pix(i)(4)<=sr_pix(i)(3);


    --//------------------------------------------
    --//���������� ��������� �������
    --//------------------------------------------
    if b_ctrl_grad='1' then
      --//������ ������������ ������� ���������� ��������� (dx^2 + dy^2)^0.5
      --//i_mult_01/128  +  i_mult_02/32
      tmp_grad_out(i)<=i_mult_01_div(i) + i_mult_02_div(i);
--      i_mult_div_rem_result(i)<=('0'&i_mult_01_div_rem(i)) + ('0'&i_mult_02_div_rem(i)&"00");
    else
      --//������ ������������ ������� ���������� ��������� (dx^2 + dy^2)^0.5
      tmp_grad_out(i)<=EXT(i_delt_xm_dly0(i), tmp_grad_out(i)'length) + EXT(i_delt_ym_dly0(i), tmp_grad_out(i)'length);--//add 2010.11.10
    end if;

    i_delt_xm_dly1(i)<=i_delt_xm_dly0(i);
    i_delt_ym_dly1(i)<=i_delt_ym_dly0(i);

    i_delt_xs_dly1(i)<=i_delt_xs_dly0(i);
    i_delt_ys_dly1(i)<=i_delt_ys_dly0(i);

    sr_pix(i)(5)<=sr_pix(i)(4);

  end if;--//if p_in_dwnp_rdy_n='0' then
  end if;
end process;


--//------------------------------------------------------
--//������ ��������� � Downstream Port
--//------------------------------------------------------
--i_result_en_out<=sr_result_en(7) and not p_in_dwnp_rdy_n;

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_result_out(i)<=(others=>'0');

    i_grad_out(i)<=(others=>'0');
    i_delt_xm_out(i)<=(others=>'0');
    i_delt_ym_out(i)<=(others=>'0');

    i_delt_xs_out(i)<=(others=>'0');
    i_delt_ys_out(i)<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then
  if p_in_dwnp_rdy_n='0' then

    i_delt_xs_out(i)<=i_delt_xs_dly1(i);
    i_delt_ys_out(i)<=i_delt_ys_dly1(i);

    --//������������ ����������:
    if i_delt_xm_dly1(i)>=CONV_STD_LOGIC_VECTOR(10#255#, i_delt_xm_dly1(i)'length) then
      i_delt_xm_out(i)<=(others=>'1');
    else
      i_delt_xm_out(i)(7 downto 0)<=i_delt_xm_dly1(i)(7 downto 0);
    end if;

    if i_delt_ym_dly1(i)>=CONV_STD_LOGIC_VECTOR(10#255#, i_delt_ym_dly1(i)'length) then
      i_delt_ym_out(i)<=(others=>'1');
    else
      i_delt_ym_out(i)(7 downto 0)<=i_delt_ym_dly1(i)(7 downto 0);
    end if;

    if tmp_grad_out(i)>=CONV_STD_LOGIC_VECTOR(10#255#, tmp_grad_out(i)'length) then
      i_grad_out(i)<=(others=>'1');
    else
      i_grad_out(i)(7 downto 0)<=tmp_grad_out(i)(i_grad_out(i)'high downto 0);
    end if;

    i_result_out(i)(7 downto 0)<=sr_pix(i)(5);
----    i_result_out(0)(15 downto 8)<=sr_pix(0)(5);
----    i_result_out(0)(23 downto 16)<=sr_pix(0)(5);
----    i_result_out(0)(31 downto 24)<=sr_pix(0)(5);

  end if;--//if p_in_dwnp_rdy_n='0' then
  end if;
end process;
end generate gen_mcalc;

i_result_en_out<=sr_result_en(7) and not p_in_dwnp_rdy_n;





--END MAIN
end behavioral;




