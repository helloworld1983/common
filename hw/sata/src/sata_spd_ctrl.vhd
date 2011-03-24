-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 06.02.2011 18:14:26
-- Module Name : sata_speed_ctrl
--
-- ����������/�������� :
--      1. ������� ���� ������������ SATA(Gen1,Gen2) �� ������� ����� ������������� ��������� �����
--      2. ����� ������� ���������� SATA �����. ������ DUAL_GTP ����� �������� ������������ �����.
--
--������ � �������� ��������� PLL ������ GTP
--������� �������� �������� ��� ��������� ���������� �� ��������� 1.5Gb/s ��� 3Gb/s
--Attribute               DRP Address     Value for           Value for
--                                        SATA Gen1           SATA Gen2
--                                        (1.5Gb/s)           (3Gb/s)
--GTP_0
--PLL_RXDIVSEL_OUT_0[0]   0X46[2]          1                    0
--PLL_TXDIVSEL_OUT_0[0]   0X45[15]         1                    0
--GTP_1
--PLL_RXDIVSEL_OUT_1[0]   0X0A[0]          1                    0
--PLL_TXDIVSEL_OUT_1[0]   0X05[4]          1                    0
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

use work.vicg_common_pkg.all;
use work.sata_pkg.all;

entity sata_speed_ctrl is
generic
(
--                                                --//"SATA1"-��������� ������ ����.SATA1;
--                                                --//"SATA2"-��������� ������ ����.SATA2;
--G_SPEED_SATA           : string    :="ALL"; --//"ALL"  -��������� ����.SATA1 � SATA2;
G_SATA_MODULE_MAXCOUNT : integer := 1;    --//�������� ��. generic/sata_host.vhd
G_SATA_MODULE_IDX      : integer := 0;    --//�������� ��. generic/sata_host.vhd
G_GTP_CH_COUNT         : integer := 2;    --//�������� ��. generic/sata_host.vhd
G_DBG                  : string  := "OFF";
G_SIM                  : string  := "OFF" --//�������� ��. generic/sata_host.vhd
);
port
(
--------------------------------------------------
--
--------------------------------------------------
p_in_cfg_sata_version   : in    std_logic_vector(1 downto 0);--//����� ���� SATA: 00-SATA-I/SATA-II, 01-only SATA-I, 10-only SATA-II,

--------------------------------------------------
--
--------------------------------------------------
p_out_sata_version      : out   std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);--//����� ���� SATA: Generation 2 (3Gb/s)/ Generation 1 (1.5Gb/s)
p_in_link_establish     : in    std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);--//���������� � SATA �����������

p_out_gtp_ch_rst        : out   std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);--//����� �����. ������ DUAL_GTP
p_out_gtp_rst           : out   std_logic;                                      --//������ ����� �����. DUAL_GTP.

p_in_usr_dcm_lock       : in    std_logic;                                      --//��������� sata_dcm

--------------------------------------------------
--RocketIO
--------------------------------------------------
p_in_gtp_pll_lock       : in    std_logic;

p_out_gtp_drpclk        : out   std_logic;
p_out_gtp_drpaddr       : out   std_logic_vector(6 downto 0);--Dynamic Reconfiguration Port (DRP)
p_out_gtp_drpen         : out   std_logic;
p_out_gtp_drpwe         : out   std_logic;
p_out_gtp_drpdi         : out   std_logic_vector(15 downto 0);
p_in_gtp_drpdo          : in    std_logic_vector(15 downto 0);
p_in_gtp_drprdy         : in    std_logic;

--------------------------------------------------
--��������������� �������
--------------------------------------------------
p_in_tst               : in    std_logic_vector(31 downto 0);
p_out_tst              : out   std_logic_vector(31 downto 0);

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk                : in    std_logic;--
p_in_rst                : in    std_logic --
);
end sata_speed_ctrl;

architecture behavioral of sata_speed_ctrl is


constant C_TRY_COUNT            : integer := 4;
constant C_TRY_TIME             : integer := (C_FSATA_WAITE_880us_75MHz * 2) * C_TRY_COUNT;--//�� 150MHz

constant C_TIME_OUT             : integer := selval (C_TRY_TIME, 16#00000860#, strcmp(G_SIM,"OFF"));


constant C_SATA_MODULE_MAXCOUNT : integer :=G_SATA_MODULE_MAXCOUNT;
constant C_SATA_MODULE_IDX      : integer :=G_SATA_MODULE_IDX;

type TBus16_Array2 is array (0 to 1) of std_logic_vector(15 downto 0);
type TBus7_Array2 is array (0 to 1) of std_logic_vector(6 downto 0);

--//������ ��������� ����� DRP ���������� DUAL_GTP
--//����� �������� ��.Appendix D/ug196_Virtex-5 FPGA RocketIO GTP Transceiver User Guide.pdf
constant C_ADR_REFCLK_SEL        : std_logic_vector(6 downto 0):=CONV_STD_LOGIC_VECTOR(16#04#, 7);

constant C_ADR_PLL_TXDIVSEL_OUT_0: std_logic_vector(6 downto 0):=CONV_STD_LOGIC_VECTOR(16#45#, 7);--//����� 0
constant C_ADR_PLL_TXDIVSEL_OUT_1: std_logic_vector(6 downto 0):=CONV_STD_LOGIC_VECTOR(16#05#, 7);--//����� 1

constant C_ADR_PLL_RXDIVSEL_OUT_0: std_logic_vector(6 downto 0):=CONV_STD_LOGIC_VECTOR(16#46#, 7);--//����� 0
constant C_ADR_PLL_RXDIVSEL_OUT_1: std_logic_vector(6 downto 0):=CONV_STD_LOGIC_VECTOR(16#0A#, 7);--//����� 1

constant C_ADR_PLL_TXDIVSEL_OUT : TBus7_Array2:=(C_ADR_PLL_TXDIVSEL_OUT_0,C_ADR_PLL_TXDIVSEL_OUT_1);
constant C_ADR_PLL_RXDIVSEL_OUT : TBus7_Array2:=(C_ADR_PLL_RXDIVSEL_OUT_0,C_ADR_PLL_RXDIVSEL_OUT_1);


signal i_timer_en               : std_logic;
signal i_timer                  : std_logic_vector(23 downto 0);

type fsm_state is
(
S_PROG_CLOCK_MUX,

--//-------------------------------------------
--//���������������� CLOCK MUX ���������� DUAL_GTP
--//-------------------------------------------
S_DRP_READ,
S_DRP_READ_DONE,
S_DRP_READ_PAUSE,
S_DRP_WRITE,
S_DRP_WRITE_DONE,
S_DRP_WRITE_PAUSE,
S_GTP_RESET,

--//-------------------------------------------
--//������ �������� ���������� � SATA �����������
--//-------------------------------------------
S_IDLE,

S_READ_CH0,
S_READ_CH0_DONE,
S_PAUSE_R0,
S_READ_CH1,
S_READ_CH1_DONE,
S_PAUSE_R1,
S_WRITE_CH0,
S_WRITE_CH0_DONE,
S_PAUSE_W0,
S_WRITE_CH1,
S_WRITE_CH1_DONE,
S_PAUSE_W1,

S_DRP_PROG_DONE,

S_GTP_CH_RESET,
S_WAIT_CONNECT
);
signal fsm_state_cs: fsm_state;

signal i_sata_version           : std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);
signal i_sata_version_out       : std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);

signal i_gtp_rst                : std_logic;
signal i_gtp_ch_rst             : std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);

signal i_gtp_drpaddr            : std_logic_vector(6 downto 0);
signal i_gtp_drpen              : std_logic;
signal i_gtp_drpwe              : std_logic;
signal i_gtp_drpdi              : std_logic_vector(15 downto 0);
signal i_gtp_drpdo              : std_logic_vector(15 downto 0);
signal i_gtp_drprdy             : std_logic;

--  signal i_gtp_drp_value          : std_logic_vector(15 downto 0);
signal i_gtp_drp_read_val       : TBus16_Array2;

signal i_rst_cnt                : std_logic_vector(4 downto 0);

signal i_link_establish         : std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);
signal i_link_ok                     : std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);
signal i_select_drp_reg              : std_logic;


signal tst_fms_cs                    : std_logic_vector(3 downto 0);
signal tst_fms_cs_dly                : std_logic_vector(tst_fms_cs'range);


--MAIN
begin

--//----------------------------------
--//��������������� �������
--//----------------------------------
gen_dbg_off : if strcmp(G_DBG,"OFF") generate
p_out_tst(31 downto 0)<=(others=>'0');
end generate gen_dbg_off;

gen_dbg_on : if strcmp(G_DBG,"ON") generate
ltstout:process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    tst_fms_cs_dly<=(others=>'0');
    p_out_tst(31 downto 1)<=(others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then

    tst_fms_cs_dly<=tst_fms_cs;

    p_out_tst(0)<=OR_reduce(tst_fms_cs_dly);
  end if;
end process ltstout;

tst_fms_cs<=CONV_STD_LOGIC_VECTOR(16#01#, tst_fms_cs'length) when fsm_state_cs=S_IDLE else
            CONV_STD_LOGIC_VECTOR(16#02#, tst_fms_cs'length) when fsm_state_cs=S_READ_CH0 else
            CONV_STD_LOGIC_VECTOR(16#03#, tst_fms_cs'length) when fsm_state_cs=S_READ_CH1 else
            CONV_STD_LOGIC_VECTOR(16#04#, tst_fms_cs'length) when fsm_state_cs=S_WRITE_CH0 else
            CONV_STD_LOGIC_VECTOR(16#05#, tst_fms_cs'length) when fsm_state_cs=S_WRITE_CH1 else
            CONV_STD_LOGIC_VECTOR(16#06#, tst_fms_cs'length) when fsm_state_cs=S_DRP_PROG_DONE else
            CONV_STD_LOGIC_VECTOR(16#07#, tst_fms_cs'length) when fsm_state_cs=S_GTP_CH_RESET else
            CONV_STD_LOGIC_VECTOR(16#08#, tst_fms_cs'length) when fsm_state_cs=S_WAIT_CONNECT else
            CONV_STD_LOGIC_VECTOR(16#00#, tst_fms_cs'length);

end generate gen_dbg_on;



--//----------------------------------
--//������ ����������
--//----------------------------------
p_out_sata_version(0) <=C_FSATA_GEN2 when i_sata_version_out(0)='0' else C_FSATA_GEN1;
p_out_sata_version(1) <=C_FSATA_GEN2 when i_sata_version_out(1)='0' else C_FSATA_GEN1;


--//���-�� sata ������� � ������ sata_host.vhd = 1
gen_ch_count1 : if G_GTP_CH_COUNT=1 generate
  i_link_establish(0) <= p_in_link_establish(0);
  i_link_establish(1) <= '1';
end generate gen_ch_count1;

--//���-�� sata ������� � ������ sata_host.vhd = 2
gen_ch_count2 : if G_GTP_CH_COUNT=2 generate
  i_link_establish <= p_in_link_establish;
end generate gen_ch_count2;


p_out_gtp_rst     <= i_gtp_rst;
p_out_gtp_ch_rst  <= i_gtp_ch_rst;

p_out_gtp_drpclk  <= p_in_clk;
p_out_gtp_drpaddr <= i_gtp_drpaddr;
p_out_gtp_drpen   <= i_gtp_drpen;
p_out_gtp_drpwe   <= i_gtp_drpwe;
p_out_gtp_drpdi   <= i_gtp_drpdi;
i_gtp_drpdo       <= p_in_gtp_drpdo;
i_gtp_drprdy      <= p_in_gtp_drprdy;

--//Timer: Time-Out
ltimer:process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_timer<=(others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then
    if i_timer_en='1' then
      i_timer<=i_timer+1;
    else
      i_timer<= (others=>'0');
    end if;
  end if;
end process ltimer;

--//--------------------------------------------------
--//������� ���������� ����������������� ��������� ����� DPR DUAL_GTP
--//--------------------------------------------------
lfsm:process(p_in_rst,p_in_clk)
  variable c : std_logic;
begin
  if p_in_rst='1' then

    c:='0';

    i_gtp_drp_read_val(0)<=(others=>'0');
    i_gtp_drp_read_val(1)<=(others=>'0');

    fsm_state_cs <= S_PROG_CLOCK_MUX;

    i_select_drp_reg<='0';

    i_gtp_drpaddr <= (others=>'0');
    i_gtp_drpdi   <= (others=>'0');
    i_gtp_drpen   <= '0';
    i_gtp_drpwe   <= '0';

    i_sata_version_out<= (others=>'0');

    i_rst_cnt <= (others=>'0');
    i_gtp_ch_rst <= (others=>'0');
    i_gtp_rst<='0';

    i_timer_en<='0';

    i_link_ok<="00";

  elsif p_in_clk'event and p_in_clk='1' then
--  if p_in_clk_en='1' then

    case fsm_state_cs is

      when S_PROG_CLOCK_MUX =>

        if C_SATA_MODULE_MAXCOUNT=1 then
        --//������ sata_storage.vhd ���������� ������ ���� ��������� DUAL_GTP,��
        --//�������� ������� REFCLK_SEL �� ����� ������.
        --//��������� � �������� ������������ ����������
          fsm_state_cs <= S_IDLE;
        else
        --//������ sata_storage.vhd ���������� 2-� ���������� DUAL_GTP,
        --//��������� � �������� ��������������� �������� REFCLK_SEL
          if i_rst_cnt = CONV_STD_LOGIC_VECTOR(16#01F#, i_rst_cnt'length) then

            i_rst_cnt<=(others=>'0');
            fsm_state_cs <= S_DRP_READ;

          else
            i_rst_cnt<=i_rst_cnt + 1;
          end if;
        end if;

      --//-------------------------------------------
      --//������������ CLOCK MUX ���������� DUAL_GTP
      --//-------------------------------------------
      when S_DRP_READ =>

        i_gtp_drpaddr<=C_ADR_REFCLK_SEL;
        i_gtp_drpen<='1';
        i_gtp_drpwe<='0';

        fsm_state_cs <= S_DRP_READ_DONE;

      when S_DRP_READ_DONE =>

        if i_gtp_drprdy='1' then
          i_gtp_drpen           <='0';
          i_gtp_drp_read_val(0) <= i_gtp_drpdo;--//�������� ���������� ��������� �������� DRP

          i_timer_en<='1';--//START TIMER
          fsm_state_cs <= S_DRP_READ_PAUSE;
        end if;

      when S_DRP_READ_PAUSE =>

        if i_timer = CONV_STD_LOGIC_VECTOR(16#003#, i_timer'length) then
          i_timer_en<='0';--//CLR TIMER
          fsm_state_cs <= S_DRP_WRITE;
        end if;

      when S_DRP_WRITE =>

        i_gtp_drpaddr<=C_ADR_REFCLK_SEL;

        if C_SATA_MODULE_IDX=0 then
          --//���� ����� ���-�� ������ sata_host.vhd=1,�� �������������������� ����� Clock Muxing
          --//�� ���������

          if   C_SATA_MODULE_MAXCOUNT=3 then
            --//���� ����� ���-�� ������ sata_host.vhd=3,��
            --// ������ sata_host.vhd � �������� 0
            --//����������� ���, ����� ������� ������� ���������� �� DUAL_GTP ������ sata_host.vhd/IDX=0
            --//������������ �� ����� CLKOUTSOUTH � CLKOUTNORTH ����� Clock Muxing
            --//��. ug196_Virtex-5 FPGA RocketIO GTP Transceiver User Guide.pdf/Appendix F/Figure F-1
            i_gtp_drpdi(6 downto 0) <= i_gtp_drp_read_val(0)(6 downto 0);
            i_gtp_drpdi(7)          <= '1';                               --//CLKSOUTH_SEL
            i_gtp_drpdi(8)          <= '1';                               --//CLKNORTH_SEL
            i_gtp_drpdi(15 downto 9)<= i_gtp_drp_read_val(0)(15 downto 9);

          elsif C_SATA_MODULE_MAXCOUNT=2 then
            --//���� ����� ���-�� ������ sata_host.vhd=2,�� ������ sata_host.vhd � �������� 0
            --//����������� ���, ����� ������� ������� ���������� �� DUAL_GTP ������ sata_host.vhd/IDX=0
            --//������������ �� ����� CLKOUTSOUTH ����� Clock Muxing
            --//��. ug196_Virtex-5 FPGA RocketIO GTP Transceiver User Guide.pdf/Appendix F/Figure F-1
            i_gtp_drpdi(6 downto 0) <= i_gtp_drp_read_val(0)(6 downto 0);
            i_gtp_drpdi(7)          <= '1';                               --//CLKSOUTH_SEL
            i_gtp_drpdi(8)          <= i_gtp_drp_read_val(0)(8);          --//CLKNORTH_SEL
            i_gtp_drpdi(15 downto 9)<= i_gtp_drp_read_val(0)(15 downto 9);

          end if;

        elsif C_SATA_MODULE_IDX=1 then
        --//���� ������ sata_host.vhd/IDX=1,��
        --//������������ ���������� DUAL_GTP ����� � ����� CLKINSOUTH ����� Clock Muxing
        --//��. ug196_Virtex-5 FPGA RocketIO GTP Transceiver User Guide.pdf/Appendix F/Figure F-1
          i_gtp_drpdi(3 downto 0) <= i_gtp_drp_read_val(0)(3 downto 0);
          i_gtp_drpdi(6 downto 4) <= "100";
          i_gtp_drpdi(15 downto 7)<= i_gtp_drp_read_val(0)(15 downto 7);

        elsif C_SATA_MODULE_IDX=2 then
        --//���� ������ sata_host.vhd/IDX=2,��
        --//������������ ���������� DUAL_GTP ����� � ����� CLKOUTNORTH ����� Clock Muxing
        --//��. ug196_Virtex-5 FPGA RocketIO GTP Transceiver User Guide.pdf/Appendix F/Figure F-1
          i_gtp_drpdi(3 downto 0) <= i_gtp_drp_read_val(0)(3 downto 0);
          i_gtp_drpdi(6 downto 4) <= "101";
          i_gtp_drpdi(15 downto 7)<= i_gtp_drp_read_val(0)(15 downto 7);

        end if;

        i_gtp_drpen <= '1';
        i_gtp_drpwe <= '1';
        fsm_state_cs <= S_DRP_WRITE_DONE;

      when S_DRP_WRITE_DONE =>

        if i_gtp_drprdy='1' then
          i_gtp_drpen <= '0';
          i_gtp_drpwe <= '0';

          i_timer_en<='1';--//START TIMER
          fsm_state_cs <= S_DRP_WRITE_PAUSE;--S_PAUSE_W0;
        end if;

      when S_DRP_WRITE_PAUSE =>

        if i_timer = CONV_STD_LOGIC_VECTOR(16#003#, i_timer'length) then
          i_timer_en<='0';--//CLR TIMER
          fsm_state_cs <= S_GTP_RESET;
        end if;

      --//-------------------------------------------
      --//����� DUAL_GTP
      --//-------------------------------------------
      when S_GTP_RESET =>

        i_gtp_drpaddr <= (others=>'0');
        i_gtp_drpdi   <= (others=>'0');
        i_gtp_drpen   <= '0';
        i_gtp_drpwe   <= '0';

        --//������ ����� ��� ������ RocketIO GTP � ������ sata_host
        if i_rst_cnt = CONV_STD_LOGIC_VECTOR(16#01F#, i_rst_cnt'length) then

          i_rst_cnt<=(others=>'0');
          i_gtp_rst<='0';--//������ ������ ������

          fsm_state_cs <= S_IDLE;

        elsif i_rst_cnt = CONV_STD_LOGIC_VECTOR(16#0F#, i_rst_cnt'length) then
          fsm_state_cs <= S_GTP_RESET;

          i_rst_cnt<=i_rst_cnt + 1;
          i_gtp_rst<='1';

        else
          fsm_state_cs <= S_GTP_RESET;
          i_rst_cnt<=i_rst_cnt + 1;
        end if;



      --//-------------------------------------------
      --//������ �������� ���������� � SATA �����������
      --//-------------------------------------------
      when S_IDLE =>

        if p_in_gtp_pll_lock='0' or p_in_usr_dcm_lock='1' then
        --//������� ���������� PLL DUAL_GTP �� ������������
          i_link_ok<="00";
          fsm_state_cs <= S_IDLE;
        else
          i_link_ok<=i_link_establish;

          if  i_link_establish="11" then
          --//���� ���������� � ����� �������
            fsm_state_cs <= S_IDLE;

          elsif i_link_establish="00" then
          --//��� ���������� � ����� �������
            fsm_state_cs <= S_READ_CH1;

          elsif i_link_establish(0)='0' then
          --//��� ���������� ������ � 0-�� ������
            fsm_state_cs <= S_READ_CH0;

          else
          --//��� ���������� ������ � 1-�� ������
            fsm_state_cs <= S_READ_CH1;
          end if;
        end if;

      --//-------------------------------------------
      --//����� CH0: ������ �������� DRP
      --//-------------------------------------------
      when S_READ_CH0 =>

        if i_link_ok="00" or i_link_ok(0)='0' then
        --//��� ���������� � ����� �������
        --//���
        --//��� ���������� ������ � 0-�� ������

        --//����� �������� DRP ��������� 0-�� ������.��. ������� � ����� ������ sata_ctrl.vhd
        --GTP_0
          if i_select_drp_reg='0' then
            i_gtp_drpaddr<=C_ADR_PLL_RXDIVSEL_OUT(0);--CONV_STD_LOGIC_VECTOR(16#46#, 7); --PLL_RXDIVSEL_OUT_0[0]   0X46[2]
          else
            i_gtp_drpaddr<=C_ADR_PLL_TXDIVSEL_OUT(0);--CONV_STD_LOGIC_VECTOR(16#45#, 7); --PLL_TXDIVSEL_OUT_0[0]   0X45[15]
          end if;

          i_gtp_drpen<='1';
          i_gtp_drpwe<='0';

          fsm_state_cs <= S_READ_CH0_DONE;
        else
        --//��� ���������� ������ � 1-�� ������
          fsm_state_cs <= S_READ_CH1;
        end if;

      when S_READ_CH0_DONE =>

        if i_gtp_drprdy='1' then
          i_gtp_drpen           <='0';
          i_gtp_drp_read_val(0) <= i_gtp_drpdo;--//�������� ���������� ��������� �������� DRP

          i_timer_en<='1';--//START TIMER
          fsm_state_cs <= S_PAUSE_R0;
        end if;

      when S_PAUSE_R0 =>

        if i_timer = CONV_STD_LOGIC_VECTOR(16#003#, i_timer'length) then
          i_timer_en<='0';--//CLR TIMER

          if i_link_ok="00" then
          --//��� ���������� � ����� �������
            fsm_state_cs <= S_READ_CH1;

          elsif i_link_ok(0)='0' then
          --//��� ���������� ������ 0-�� ������
            fsm_state_cs <= S_WRITE_CH0;
          else
          --//��� ���������� ������ � 1-�� ������
            fsm_state_cs <= S_READ_CH1;
          end if;
        end if;

      --//-------------------------------------------
      --//����� CH1: ������ �������� DRP
      --//-------------------------------------------
      when S_READ_CH1 =>
        --//����� �������� DRP ��������� 1-�� ������.��. ������� � ����� ������ sata_ctrl.vhd
        if i_select_drp_reg='0' then
          i_gtp_drpaddr<=C_ADR_PLL_RXDIVSEL_OUT(1);--CONV_STD_LOGIC_VECTOR(16#0A#, 7);
        else
          i_gtp_drpaddr<=C_ADR_PLL_TXDIVSEL_OUT(1);--CONV_STD_LOGIC_VECTOR(16#05#, 7);
        end if;

        i_gtp_drpen<='1';
        i_gtp_drpwe<='0';

        fsm_state_cs <= S_READ_CH1_DONE;

      when S_READ_CH1_DONE =>

        if i_gtp_drprdy='1' then
          i_gtp_drpen           <='0';
          i_gtp_drp_read_val(1) <= i_gtp_drpdo;--//�������� ���������� ��������� �������� DRP

          i_timer_en<='1';--//START TIMER
          fsm_state_cs <= S_PAUSE_R1;
        end if;

      when S_PAUSE_R1 =>

        if i_timer = CONV_STD_LOGIC_VECTOR(16#003#, i_timer'length) then
          i_timer_en<='0';--//CLR TIMER

          if i_link_ok="00" then
          --//��� ���������� � ����� �������
            fsm_state_cs <= S_WRITE_CH0;

          elsif i_link_ok(0)='0' then
          --//��� ���������� ������ 0-�� ������
            fsm_state_cs <= S_WRITE_CH0;
          else
          --//��� ���������� ������ � 1-�� ������
            fsm_state_cs <= S_WRITE_CH1;
          end if;
        end if;

      --//-------------------------------------------
      --//����� CH0: ������ �������� DRP
      --//-------------------------------------------
      when S_WRITE_CH0 =>

        --//����������� �������� DRP. ��. ������� � ����� ������ sata_ctrl.vhd
        --GTP_0
        if i_select_drp_reg='0' then
          i_gtp_drpaddr<=C_ADR_PLL_RXDIVSEL_OUT(0);--CONV_STD_LOGIC_VECTOR(16#46#, 7); --PLL_RXDIVSEL_OUT_0[0]   0X46[2]

          i_gtp_drpdi(1 downto 0) <= i_gtp_drp_read_val(0)(1 downto 0);
          i_gtp_drpdi(2)          <= i_sata_version(0);
          i_gtp_drpdi(15 downto 3)<= i_gtp_drp_read_val(0)(15 downto 3);

        else
          i_gtp_drpaddr<=C_ADR_PLL_TXDIVSEL_OUT(0);--CONV_STD_LOGIC_VECTOR(16#45#, 7);--PLL_TXDIVSEL_OUT_0[0]   0X45[15]

          i_gtp_drpdi(14 downto 0)<= i_gtp_drp_read_val(0)(14 downto 0);
          i_gtp_drpdi(15)         <= i_sata_version(0);
        end if;

        i_gtp_drpen <= '1';
        i_gtp_drpwe <= '1';

        fsm_state_cs <= S_WRITE_CH0_DONE;

      when S_WRITE_CH0_DONE =>

        if i_gtp_drprdy='1' then
          i_gtp_drpen <= '0';
          i_gtp_drpwe <= '0';

          i_timer_en<='1';--//START TIMER
          fsm_state_cs <= S_PAUSE_W0;
        end if;

      when S_PAUSE_W0 =>

        if i_timer = CONV_STD_LOGIC_VECTOR(16#003#, i_timer'length) then
          i_timer_en<='0';--//CLR TIMER

          if i_link_ok="00" then
          --//��� ���������� � ����� �������
            fsm_state_cs <= S_WRITE_CH1;

          elsif i_link_ok(0)='0' then
          --//��� ���������� ������ 0-�� ������
            fsm_state_cs <= S_DRP_PROG_DONE;
          else
          --//��� ���������� ������ � 1-�� ������
            fsm_state_cs <= S_WRITE_CH1;
          end if;

        end if;

      --//-------------------------------------------
      --//����� CH1: ������ �������� DRP
      --//-------------------------------------------
      when S_WRITE_CH1 =>

        --//����������� �������� DRP. ��. ������� � ����� ������ sata_ctrl.vhd
        if i_select_drp_reg='0' then
          i_gtp_drpaddr <= C_ADR_PLL_RXDIVSEL_OUT(1);--CONV_STD_LOGIC_VECTOR(16#0A#, 7);--GTP_1

          i_gtp_drpdi(0)          <= i_sata_version(1);
          i_gtp_drpdi(15 downto 1)<= i_gtp_drp_read_val(1)(15 downto 1);

        else
          i_gtp_drpaddr<=C_ADR_PLL_TXDIVSEL_OUT(1);--CONV_STD_LOGIC_VECTOR(16#05#, 7);

          i_gtp_drpdi(3 downto 0) <= i_gtp_drp_read_val(1)(3 downto 0);
          i_gtp_drpdi(4)          <= i_sata_version(1);
          i_gtp_drpdi(15 downto 5)<= i_gtp_drp_read_val(1)(15 downto 5);
        end if;

        i_gtp_drpen <= '1';
        i_gtp_drpwe <= '1';

        fsm_state_cs <= S_WRITE_CH1_DONE;

      when S_WRITE_CH1_DONE =>

        if i_gtp_drprdy='1' then
          i_gtp_drpen <= '0';
          i_gtp_drpwe <= '0';

          i_timer_en<='1';--//START TIMER
          fsm_state_cs <= S_PAUSE_W1;
        end if;

      when S_PAUSE_W1 =>

        if i_timer = CONV_STD_LOGIC_VECTOR(16#003#, i_timer'length) then
          i_timer_en<='0';--//CLR TIMER

          fsm_state_cs <= S_DRP_PROG_DONE;

        end if;

      --//-------------------------------------------
      --//�������. �������� �� ��� ������� DRP
      --//-------------------------------------------
      when S_DRP_PROG_DONE =>

        c:=not c;
        i_select_drp_reg<=c;

        if i_select_drp_reg='1' then
        --//��� ������� �����������������. ���������� ����� ������� DUAL_GTP
          fsm_state_cs <= S_GTP_CH_RESET;
        else
          fsm_state_cs <= S_READ_CH0;
        end if;

      --//-------------------------------------------
      --//����� ������� DUAL_GTP
      --//-------------------------------------------
      when S_GTP_CH_RESET =>

        i_gtp_drpaddr <= (others=>'0');
        i_gtp_drpdi   <= (others=>'0');
        i_gtp_drpen   <= '0';
        i_gtp_drpwe   <= '0';

        --//������ ����� ��� ������ RocketIO GTP � ������ sata_host
        if i_rst_cnt = CONV_STD_LOGIC_VECTOR(16#01F#, i_rst_cnt'length) then

          i_rst_cnt<=(others=>'0');
          i_gtp_ch_rst<=(others=>'0');--//������ ������ ������

          i_timer_en<='1';--//START TIMER
          fsm_state_cs <= S_WAIT_CONNECT;

        elsif i_rst_cnt = CONV_STD_LOGIC_VECTOR(16#14#, i_rst_cnt'length) then

          i_rst_cnt<=i_rst_cnt + 1;

          i_sata_version_out(0)<=i_sata_version(0);
          i_sata_version_out(1)<=i_sata_version(1);

        elsif i_rst_cnt = CONV_STD_LOGIC_VECTOR(16#0F#, i_rst_cnt'length) then
          fsm_state_cs <= S_GTP_CH_RESET;

          i_rst_cnt<=i_rst_cnt + 1;

          if i_link_ok(0)='0' then
          --//��� ���������� � 0-�� ������. ���������� �����
            i_gtp_ch_rst(0)<='1';
          end if;

          if i_link_ok(1)='0' then
          --//��� ���������� � 1-�� ������. ���������� �����
            i_gtp_ch_rst(1)<='1';
          end if;

        else
          fsm_state_cs <= S_GTP_CH_RESET;
          i_rst_cnt<=i_rst_cnt + 1;
        end if;

      --//-------------------------------------------
      --//���� ����������
      --//-------------------------------------------
      when S_WAIT_CONNECT =>

          fsm_state_cs <= S_WAIT_CONNECT;
          i_timer_en<='0';--//CLR TIMER

--        --//��� ������������ ����� � ���-���� ������������� � DUAL_GTP
--        if i_timer = CONV_STD_LOGIC_VECTOR(C_TIME_OUT, i_timer'length) then
--        --//����� �������� �����
--        --3.5ms = 4 ������� ��� ���������� ������ connect_cntr
--          i_timer_en<='0';--//CLR TIMER
--
--          i_link_ok<=i_link_establish;
--
--          if  i_link_establish="11" then
--          --//���� ���������� � ����� �������
--            fsm_state_cs <= S_IDLE;
--          else
--          --//��� ���������� � ����� �� �������.
--          --//���������� �������� ���������� �����
--            fsm_state_cs <= S_READ_CH0;
--
--          end if;
--
--        end if;

    end case;
--  end if;--//--if p_in_clk_en='1' then
end if;
end process lfsm;


--i_sata_version<="11";--//����� ������ SATA-1
i_sata_version<="00";--//����� ������ SATA-2

--process(p_in_rst,p_in_clk)
--  variable a : std_logic;
--  variable b : std_logic;
--begin
--  if p_in_rst='1' then
--    a:='0';
--    b:='0';
--    i_sata_version<=(others=>'0');
--
--  elsif p_in_clk'event and p_in_clk='1' then
----  if p_in_clk_en='1' then
--
--      if p_in_cfg_sata_version="01" then
--        --//�������� ���������� ������ � SATA-1
--        i_sata_version<=(others=>'1');
--      elsif p_in_cfg_sata_version="10" then
--        --//�������� ���������� ������ � SATA-2
--        i_sata_version<=(others=>'0');
--
--      elsif p_in_cfg_sata_version="00" then
--
--        if p_in_gtp_pll_lock='0' or p_in_usr_dcm_lock='1' then
--        --//������� �� ������������
--          a:='0';
--          b:='0';
--          i_sata_version<="00";
--
--        elsif fsm_state_cs=S_IDLE then
--
--          if i_link_establish="00" then
--          --//��� ���������� � ����� �������
--            a:='0';
--            b:='0';
--            i_sata_version<="00";
--
--          elsif i_link_establish="01" then
--          --//��� ���������� ������ 0-�� ������
--            a:='0';
--            i_sata_version(0)<='0';
--          elsif i_link_establish="10" then
--          --//��� ���������� ������ � 1-�� ������
--            b:='0';
--            i_sata_version(1)<='0';
--          end if;
--
--        elsif fsm_state_cs=S_WAIT_CONNECT and i_timer=CONV_STD_LOGIC_VECTOR(C_TIME_OUT, i_timer'length) then
--
--          if i_link_establish="00" then
--          --//------------------------------------------
--          --//��� ���������� � ����� �������
--          --//------------------------------------------
--            --//A) 0-� �����
--            if i_link_ok(0)='1' then
--            --//���� ���������� ��� ���� �����������, ��
--            --//���. ����� �������� ���������� SATA-2
--              a:='0';
--              i_sata_version(0)<='0';
--            else
--            --//���� ���������� �� ����, �� ������
--            --//������������ �� ������ ��������.
--              a:=not a;
--              i_sata_version(0)<=a;
--            end if;
--
--            --//B) 1-� �����
--            if i_link_ok(1)='1' then
--            --//���� ���������� ��� ���� �����������, ��
--            --//���. ����� �������� ���������� SATA-2
--              b:='0';
--              i_sata_version(1)<='0';
--            else
--            --//���� ���������� �� ����, �� ������
--            --//������������ �� ������ ��������.
--              b:=not b;
--              i_sata_version(1)<=b;
--            end if;
--
--          elsif i_link_establish="01" then
--          --//------------------------------------------
--          --//���� ���������� ������ � 0-�� ������
--          --//------------------------------------------
--            --//A) 0-� �����
--
--            --//B) 1-� �����
--            if i_link_ok(1)='1' then
--            --//���� ���������� ��� ���� �����������, ��
--            --//���. ����� �������� ���������� SATA-2
--              b:='0';
--              i_sata_version(1)<='0';
--            else
--            --//���� ���������� �� ����, �� ������
--            --//������������ �� ������ ��������.
--              b:=not b;
--              i_sata_version(1)<=b;
--            end if;
--
--          elsif i_link_establish="10" then
--          --//------------------------------------------
--          --//���� ���������� ������ � 1-�� ������
--          --//------------------------------------------
--            --//A) 0-� �����
--            if i_link_ok(0)='1' then
--            --//���� ���������� ��� ���� �����������, ��
--            --//���. ����� �������� ���������� SATA-2
--              a:='0';
--              i_sata_version(0)<='0';
--            else
--            --//���� ���������� �� ����, �� ������
--            --//������������ �� ������ ��������.
--              a:=not a;
--              i_sata_version(0)<=a;
--            end if;
--
--            --//B) 1-� �����
--
--          end if;
--        end if;
--      end if;
--
----  end if;--//  if p_in_clk_en='1' then
--  end if;
--end process;


--END MAIN
end behavioral;
