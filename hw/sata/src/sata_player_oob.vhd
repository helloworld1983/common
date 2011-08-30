-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 25/11/2008
-- Module Name : sata_player_oob
--
-- ����������/�������� :
--   1. ����������� � ������������ ���������� � SATA ���-���.
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
use work.sata_glob_pkg.all;
use work.sata_pkg.all;
use work.sata_sim_lite_pkg.all;

entity sata_player_oob is
generic
(
G_GT_DBUS : integer:=16;
G_DBG     : string :="OFF";
G_SIM     : string :="OFF"
);
port
(
--------------------------------------------------
--
--------------------------------------------------
p_in_ctrl           : in    std_logic_vector(C_PLCTRL_LAST_BIT downto 0);--//��������� ��. sata_pkg.vhd/���� - PHY Layer/����������/Map:
p_out_status        : out   std_logic_vector(C_PLSTAT_LAST_BIT downto 0);--//��������� ��. sata_pkg.vhd/���� - PHY Layer/�������/Map

p_in_primitive_det  : in    std_logic_vector(C_TPMNAK downto C_TALIGN);--//��������� ��. sata_pkg.vhd/���� - PHY Layer/������ ����������
p_out_d10_2_senddis : out   std_logic;                    --//���������� �������� ���� D10.2

--------------------------------------------------
--RocketIO Receiver
--------------------------------------------------
p_out_gt_txelecidle : out   std_logic;                    --//TX electircal idel
p_out_gt_txcomstart : out   std_logic;                    --//TX OOB enable
p_out_gt_txcomtype  : out   std_logic;                    --//TX OOB type select

p_in_gt_rxelecidle  : in    std_logic;                    --//RX electrical idle
p_in_gt_rxstatus    : in    std_logic_vector(2 downto 0); --//RX OOB type

p_out_gt_rst        : out   std_logic;                    --//����� Tx/Rx PCM

--------------------------------------------------
--��������������� �������
--------------------------------------------------
p_in_tst            : in    std_logic_vector(31 downto 0);
p_out_tst           : out   std_logic_vector(31 downto 0);
p_out_dbg           : out   TPLoob_dbgport;

--------------------------------------------------
--System
--------------------------------------------------
p_in_tmrclk         : in    std_logic;--//������������ ������� timeout. ������� ������ ���� 75MHz!!!
p_in_clk            : in    std_logic;
p_in_rst            : in    std_logic
);
end sata_player_oob;

architecture behavioral of sata_player_oob is

signal fsm_ploob_cs             : TPLoob_fsm_state;

signal i_gt_txelecidle         : std_logic;
signal i_gt_txcomstart         : std_logic;
signal i_gt_txcomtype          : std_logic;
signal i_gt_pcm_rst            : std_logic;

signal i_tmr                    : std_logic_vector(19 downto 0);--//timer-timeout
signal i_tmrout                 : std_logic;                    --//timeout - clk domane p_in_tmrclk

signal i_timeout                : std_logic;                    --//timeout - clk domane p_in_clk
signal i_timer_rst_n            : std_logic;                    --//����� ������� timqout

signal i_status                 : std_logic_vector(C_PLSTAT_LAST_BIT downto 0);

signal i_d10_2_senddis          : std_logic;
signal i_tmr_dly                : std_logic_vector(8 downto 0);


--MAIN
begin

--//----------------------------------
--//��������������� �������
--//----------------------------------
gen_dbg_off : if strcmp(G_DBG,"OFF") generate
p_out_tst(31 downto 0)<=(others=>'0');
end generate gen_dbg_off;

gen_dbg_on : if strcmp(G_DBG,"ON") generate
p_out_tst(31 downto 0)<=(others=>'0');
--ltstout:process(p_in_rst,p_in_clk)
--begin
--  if p_in_rst='1' then
--    p_out_tst(31 downto 1)<=(others=>'0');
--  elsif p_in_clk'event and p_in_clk='1' then
--    p_out_tst(0)<='0';
--  end if;
--end process ltstout;

end generate gen_dbg_on;



--//----------------------------------
--//����� � main PHY Layer
--//----------------------------------
p_out_gt_txelecidle<=i_gt_txelecidle;
p_out_gt_txcomstart<=i_gt_txcomstart;
p_out_gt_txcomtype <=i_gt_txcomtype;

p_out_gt_rst<=i_gt_pcm_rst;

p_out_d10_2_senddis<=i_d10_2_senddis;

p_out_status<=i_status;


--//--------------------------------------------------
--//timer-timeout(�����: ������������ �� 75MHz)
--//--------------------------------------------------
ltimeout:process(p_in_rst,i_timer_rst_n,p_in_tmrclk)
begin
  if p_in_rst='1' or i_timer_rst_n='0' then
    i_tmr<=(others=>'0');
    i_tmrout<='0';
  elsif p_in_tmrclk'event and p_in_tmrclk='1' then

    i_tmr<=i_tmr+1;

    if i_tmr=CONV_STD_LOGIC_VECTOR(C_OOB_TIMEOUT_880us, i_tmr'length)then
      i_tmrout<='1';
    end if;

  end if;
end process ltimeout;


--//--------------------------------------------------
--//������� ����������:
--//���������� ��������� ������������ ���������� � SATA �����������
--//--------------------------------------------------
lfsm:process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    fsm_ploob_cs <= S_HR_IDLE;

    i_gt_txelecidle<='1';
    i_gt_txcomstart<='0';
    i_gt_txcomtype <='0';
    i_gt_pcm_rst<='0';

    i_status<=(others=>'0');
    i_d10_2_senddis<='0';

    i_timer_rst_n<='0';
    i_timeout<='0';
    i_tmr_dly<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then

    i_timeout<=i_tmrout;

    case fsm_ploob_cs is

      --//-------------------------------
      --//
      --//-------------------------------
      when S_HR_IDLE =>

        i_d10_2_senddis<='0';
        i_status<=(others=>'0');

        i_gt_txelecidle<='1';
        i_gt_txcomstart<='0';
        i_gt_txcomtype <='0';

        fsm_ploob_cs <= S_HR_COMRESET;

      --//-------------------------------
      --//�������� ������� COMRESET
      --//-------------------------------
      when S_HR_COMRESET =>

        i_gt_txcomstart<='1';--//���� ������� COMRESET
        i_gt_txcomtype <='0';

        if i_tmr_dly=CONV_STD_LOGIC_VECTOR(selval(16#0288#, 16#003#, strcmp(G_SIM, "OFF")), i_tmr_dly'length) then
          i_tmr_dly<=(others=>'0');
          fsm_ploob_cs <= S_HR_COMRESET_DONE;
        else
          i_tmr_dly<=i_tmr_dly + 1;
        end if;

      when S_HR_COMRESET_DONE =>

        i_gt_txcomstart<='0';

        if p_in_gt_rxstatus(0)='1' then
        --//��� ����������� �������� ������� COMRESET
        --//(���� TXCOMSTART operation complete)
--          i_gt_txelecidle<='0';
          i_timer_rst_n<='0';
          fsm_ploob_cs <= S_HR_AwaitCOMINIT;

        else
          if i_timeout='1' then
            i_timer_rst_n<='0';
            fsm_ploob_cs <= S_HR_IDLE;
          else
            i_timer_rst_n<='1';
          end if;
        end if;


      --//-------------------------------
      --//����� ������� COMINIT
      --//-------------------------------
      when S_HR_AwaitCOMINIT =>

        if p_in_gt_rxstatus(2 downto 0)="100" then
            --��������� ������ COMINIT
            i_timer_rst_n<='0';
            fsm_ploob_cs <= S_HR_AwaitNoCOMINIT;

        else
          if i_timeout='1' then
            i_timer_rst_n<='0';
            fsm_ploob_cs <= S_HR_IDLE;
          else
            i_timer_rst_n<='1';
          end if;
        end if;

      when S_HR_AwaitNoCOMINIT =>

        if p_in_gt_rxstatus(2 downto 0)="000" then
            --//�������� ����� ������� COMINIT
            i_timer_rst_n<='0';
            fsm_ploob_cs <= S_HR_Calibrate;

        else
          if i_timeout='1' then
            i_timer_rst_n<='0';
            fsm_ploob_cs <= S_HR_IDLE;
          else
            i_timer_rst_n<='1';
          end if;
        end if;

      --//-------------------------------
      --//����������
      --//-------------------------------
      when S_HR_Calibrate =>

--        i_gt_txelecidle<='1';
        fsm_ploob_cs <= S_HR_COMWAKE;


      --//-------------------------------
      --//�������� ������� COMWAKE
      --//-------------------------------
      when S_HR_COMWAKE =>

        i_gt_txcomstart<='1';--//���� ������� COMWAKE
        i_gt_txcomtype <='1';

        if i_tmr_dly=CONV_STD_LOGIC_VECTOR(16#03#, i_tmr_dly'length) then
          i_tmr_dly<=(others=>'0');
          fsm_ploob_cs <= S_HR_COMWAKE_DONE;
        else
          i_tmr_dly<=i_tmr_dly + 1;
        end if;

      when S_HR_COMWAKE_DONE =>

        i_gt_txcomstart<='0';

        if p_in_gt_rxstatus(0)='1' then
        --//��� ����������� �������� ������� COMWAKE
        --//(���� TXCOMSTART operation complete)
--          i_gt_txelecidle<='0';
          i_timer_rst_n<='0';
          fsm_ploob_cs <= S_HR_AwaitCOMWAKE;
        else
          if i_timeout='1' then
            i_timer_rst_n<='0';
            fsm_ploob_cs <= S_HR_IDLE;
          else
            i_timer_rst_n<='1';
          end if;
        end if;


      --//-------------------------------
      --//����� ������� COMWAKE
      --//-------------------------------
      when S_HR_AwaitCOMWAKE =>

        if p_in_gt_rxstatus(2 downto 0)="010" then
            --��������� ������ COMWAKE
            i_timer_rst_n<='0';
            i_status(C_PSTAT_COMWAKE_RCV_BIT)<='1';
            fsm_ploob_cs <= S_HR_AwaitNoCOMWAKE;
        else
          if i_timeout='1' then
            i_timer_rst_n<='0';
            fsm_ploob_cs <= S_HR_IDLE;
          else
            i_timer_rst_n<='1';
          end if;
        end if;

      when S_HR_AwaitNoCOMWAKE =>

        if p_in_gt_rxstatus(2 downto 0)="000" then
        --//�������� ����� ������� COMWAKE
            i_timer_rst_n<='0';

            i_gt_pcm_rst<='1';--//����� GT_TXPCM(RXPCM)
                               --//��. Table 5-7/ ug196_Virtex-5 FPGA RocketIO GTP Transceiver User Guide.pdf

            i_status(C_PSTAT_DET_DEV_ON_BIT)<='1';
            fsm_ploob_cs <= S_HR_AwaitAlign;
        else
          if i_timeout='1' then
            fsm_ploob_cs <= S_HR_IDLE;
            i_timer_rst_n<='0';
          else
            i_timer_rst_n<='1';
          end if;
        end if;


      --//-------------------------------
      --//����� ALIGN ���������
      --//-------------------------------
      when S_HR_AwaitAlign =>

        i_gt_pcm_rst<='0';

        if p_in_gt_rxelecidle='0' then
            i_gt_txelecidle<='0';

            if p_in_primitive_det(C_TALIGN)='1' then
                --������ ALIGN Primitive
                i_d10_2_senddis<='1';--���������� �������� ���� D10.2, � �������� �������� ALIGN ���������
                i_timer_rst_n<='0';
                fsm_ploob_cs <= S_HR_SendAlign;
            else
              if i_timeout='1' then
                i_timer_rst_n<='0';
                fsm_ploob_cs <= S_HR_IDLE;
              else
                i_timer_rst_n<='1';
              end if;
            end if;
        else
          i_timer_rst_n<='0';
          fsm_ploob_cs <= S_HR_IDLE;
        end if;


      --//-------------------------------
      --//�������� ALIGN ���������
      --//-------------------------------
      when S_HR_SendAlign =>

        if i_timeout='1' then
          i_timer_rst_n<='0';
          i_tmr_dly<=(others=>'0');
          fsm_ploob_cs <= S_HR_IDLE;

        else

          i_timer_rst_n<='1';

          if p_in_primitive_det(C_TALIGN)='1' then
            i_tmr_dly<=(others=>'0');

          elsif CONV_INTEGER(p_in_primitive_det)/=0 then

            if (i_tmr_dly=CONV_STD_LOGIC_VECTOR(3-1, i_tmr_dly'length)) then
              --���� ������ ������� 3 �� AILGN ���������, ��
              --������ ��� ���������� �����������
              i_tmr_dly<=(others=>'0');

              i_status(C_PSTAT_DET_ESTABLISH_ON_BIT)<='1';
              i_status(C_PSTAT_SPD_BIT_M downto C_PSTAT_SPD_BIT_L)<=p_in_ctrl(C_PCTRL_SPD_BIT_M downto C_PCTRL_SPD_BIT_L);

              fsm_ploob_cs <= S_HR_Connect;
            else
              i_tmr_dly<=i_tmr_dly+1;
            end if;
          end if;
        end if;


      --//-------------------------------
      --//��������� ���������� ���������
      --//-------------------------------
      when S_HR_Connect =>

        i_timer_rst_n<='0';

        if p_in_gt_rxelecidle = '1' then
          fsm_ploob_cs <= S_HR_Disconnect;
        end if;

      --//��� ������ ������
      when S_HR_Disconnect =>

        i_status(C_PSTAT_DET_DEV_ON_BIT)<='0';
        i_status(C_PSTAT_DET_ESTABLISH_ON_BIT)<='0';

    end case;

  end if;
end process lfsm;



--//-----------------------------------
--//Debug/Sim
--//-----------------------------------
--gen_sim_on : if strcmp(G_SIM,"ON") generate

p_out_dbg.fsm<=fsm_ploob_cs;

p_out_dbg.status.link_establish<=i_status(C_PSTAT_DET_ESTABLISH_ON_BIT);
p_out_dbg.status.dev_detect<=i_status(C_PSTAT_DET_DEV_ON_BIT);
p_out_dbg.status.speed<=i_status(C_PSTAT_SPD_BIT_M downto C_PSTAT_SPD_BIT_L);
p_out_dbg.status.rcv_comwake<=i_status(C_PSTAT_COMWAKE_RCV_BIT);

p_out_dbg.speed<=p_in_ctrl(C_PCTRL_SPD_BIT_M downto C_PCTRL_SPD_BIT_L);

--end generate gen_sim_on;

--END MAIN
end behavioral;
