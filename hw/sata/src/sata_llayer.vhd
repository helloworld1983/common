-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 13.02.2011 13:26:02
-- Module Name : sata_llayer
--
-- ���������� :
--   Link Layer:
--   1. ����������� ��������� ������ � �����-��� �� ������ SATA ����������,
--      �������� ������������ SATA ��� ������ Link Layer
--     (��. �� 9.6 Serial ATA Specification v2.5 (2005-10-27).pdf)
--   2. ����� RxFRAME �� PHY ������, ��-��������������� RxFRAME, ������� CRC � ������ RxDATA ������������� ������.
--   3. ������ TxDATA �� ������������� ������, ������ CRC, ������������ TxFRAME, ��������������� TxFRAME.
--
--      Rx/TxFRAME - SOF+Rx/TxDATA+CRC+EOF
--
-- Revision:
-- Revision 13.02.2011 - File Created
--
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

library work;
use work.vicg_common_pkg.all;
use work.sata_glob_pkg.all;
use work.sata_pkg.all;
use work.sata_sim_lite_pkg.all;
use work.sata_unit_pkg.all;

entity sata_llayer is
generic(
G_DBG : string:="OFF";
G_SIM : string:="OFF"
);
port(
--------------------------------------------------
--����� � Transport Layer
--------------------------------------------------
p_in_ctrl        : in    std_logic_vector(C_LLCTRL_LAST_BIT downto 0);--//��������� ��. sata_pkg.vhd/���� - Link Layer/����������/Map:
p_out_status     : out   std_logic_vector(C_LLSTAT_LAST_BIT downto 0);--//��������� ��. sata_pkg.vhd/���� - Link Layer/�������/Map:

p_in_txd_close   : in    std_logic;                    --//������� ������������ frame
p_in_txd         : in    std_logic_vector(31 downto 0);--//������ �� TX ������ ������������� ������
p_out_txd_rd     : out   std_logic;                    --//���������� ������ ������ TX ������ ������. ������
p_in_txd_status  : in    TTxBufStatus;                 --//��������� ��. sata_pkg.vhd/���� - ����

p_out_rxd        : out   std_logic_vector(31 downto 0);--//������ � RX ����� ������������� ������
p_out_rxd_wr     : out   std_logic;                    --//���������� ������ ������ � RX ����� ������. ������
p_in_rxd_status  : in    TRxBufStatus;                 --//��������� ��. sata_pkg.vhd/���� - ����

--------------------------------------------------
--����� � Phy Layer
--------------------------------------------------
p_in_phy_status  : in    std_logic_vector(C_PLSTAT_LAST_BIT downto 0);
p_in_phy_sync    : in    std_logic;                  --//������������� �� phy ������

p_in_phy_rxtype  : in    std_logic_vector(C_TDATA_EN downto C_TSYNC);--//��������� ��. sata_pkg.vhd/���� - PHY Layer/������ ����������
p_in_phy_rxd     : in    std_logic_vector(31 downto 0);

p_out_phy_txd    : out   std_logic_vector(31 downto 0);--//Tx -  ���������������� ������(���������������)
p_out_phy_txreq  : out   std_logic_vector(7 downto 0);--//������ �� �������� ���������/������
p_in_phy_txrdy_n : in    std_logic;                   --//������ ����������� 1/0 - ���� �������� ������� ALIGN/����� � ��������

--------------------------------------------------
--��������������� �������
--------------------------------------------------
p_in_tst         : in    std_logic_vector(31 downto 0);
p_out_tst        : out   std_logic_vector(31 downto 0);
p_out_dbg        : out   TLL_dbgport;

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk         : in    std_logic;--
p_in_rst         : in    std_logic
);
end sata_llayer;

architecture behavioral of sata_llayer is

signal fsm_llayer_cs               : TLL_fsm_state;

signal i_status                    : std_logic_vector(C_LSTAT_TxERR_ABORT downto C_LSTAT_RxOK);

signal i_init_work                 : std_logic;--//���������� ���������� � CRC � ������

signal i_srambler_en_rx            : std_logic;
signal i_srambler_en_tx            : std_logic;
signal i_srambler_en               : std_logic;
signal i_srambler_out              : std_logic_vector(31 downto 0);

signal i_crc_en                    : std_logic;
signal i_crc_in                    : std_logic_vector(31 downto 0);
signal i_crc_out                   : std_logic_vector(31 downto 0);

signal i_rcv_en                    : std_logic;--//����� ������
signal i_rxd_descr                 : std_logic_vector(31 downto 0);--//����������������� ������
signal i_rxd_descr_en              : std_logic;
signal i_rxd_only                  : std_logic;--//������ ��� ������������ CRC � ���������� ������ ������������� ������
signal i_rxd_out                   : std_logic_vector(31 downto 0);
signal i_rxd_en_out                : std_logic;
signal i_rxp                       : std_logic_vector(C_TX_RDY downto C_THOLDA);--//����� �������� ����������
signal i_return                    : std_logic;

signal i_txd_en                    : std_logic;
signal i_txd_out                   : std_logic_vector(31 downto 0);
signal i_tx_close_opt              : std_logic;--//�������������� �������� FRAME
signal i_txreq                     : std_logic_vector(p_out_phy_txreq'range);--//������ �� �������� ������/����������

signal i_txp_cnt                   : std_logic_vector(1 downto 0);--//������� ��������� ����������.
                                                                  --//��������� ��� ����������� ����� ���������� �������� CONT
signal i_txp_retransmit_en         : std_logic;
signal i_txp_retransmit            : std_logic;--//retransmit primitive after ALIGN (��. �� 9.4.5.2 Serial ATA Specification v2.5 (2005-10-27).pdf)
signal i_trn_term                  : std_logic;--//�������� ���������� �������� ������ �� ������� ������ ������ ��������� DMAT
                                               --//��� ������������� FRAME ���������� CRC,EOF

signal i_tmr                       : std_logic_vector(7 downto 0);--//timer

signal sr_phy_txrdy_n              : std_logic_vector(0 to 0);

signal i_tl_check_done             : std_logic;--//��������� ������ ���������� �������� Transport Layer
signal i_tl_check_ok               : std_logic;--//��������� �������� �������� ������ Transport Layer

--signal tst_txp_hold                : std_logic;
--signal tst_tx_close_opt            : std_logic;


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
end generate gen_dbg_on;



--//#########################################
--//�������
--//#########################################
gen_report : for i in C_LSTAT_RxOK to C_LSTAT_TxERR_ABORT  generate
p_out_status(i)<=i_status(i);
end generate gen_report;

p_out_status(C_LSTAT_FSMTxD_ON)<='1' when fsm_llayer_cs=S_LT_SendData or fsm_llayer_cs=S_LT_SendCRC else '0';
p_out_status(C_LSTAT_FSMRxD_ON)<='1' when fsm_llayer_cs=S_LR_RcvData or fsm_llayer_cs=S_LR_RcvEOF else '0';
--p_out_status(C_LSTAT_TxHOLD)<=tst_txp_hold;
--p_out_status(C_LSTAT_RxHOLD)<=i_rxp(C_THOLD);


--//#########################################
--//����� ������ �� PHY ������
--//#########################################
lrxd_descrambler:process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_rxd_descr<=(others=>'0');
    i_rxd_descr_en<='0';
  elsif p_in_clk'event and p_in_clk='1' then
    if i_srambler_en_rx='1' then
        for i in 0 to 31 loop
          i_rxd_descr(i)<=p_in_phy_rxd(i) xor i_srambler_out(i);--//De-scrambling
        end loop;
    end if;

    i_rxd_descr_en<=i_srambler_en_rx;

  end if;
end process lrxd_descrambler;

--//������� �������� ������ (����������� CRC �� ������ ������������ �� ������������ �������)
i_rxd_en_out<=i_rxd_descr_en and i_rxd_only;
lrxd_out:process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_rxd_out<=(others=>'0');
    i_rxd_only<='0';
  elsif p_in_clk'event and p_in_clk='1' then
    if i_rxd_descr_en='1' then
      i_rxd_out<=i_rxd_descr;
    end if;

    if fsm_llayer_cs=S_L_IDLE then
      i_rxd_only<='0';
    elsif i_rxd_descr_en='1' then
      i_rxd_only<='1';
    end if;

  end if;
end process lrxd_out;

--//�������� �������
process(p_in_clk)
begin
  if p_in_clk'event and p_in_clk='1' then
    p_out_rxd<=i_rxd_out;
    p_out_rxd_wr<=i_rxd_en_out;
  end if;
end process;



--//Transport Layer ������ ���������� �������� ����������� ������.
--//���������� ��� ������ ���������������� ��������� R_OK/R_ERR
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_tl_check_done<='0';
    i_tl_check_ok<='0';
  elsif p_in_clk'event and p_in_clk='1' then

    if fsm_llayer_cs=S_LR_GoodCRC then
      --//��� ����������� �������� Transport Layer
      if p_in_ctrl(C_LCTRL_TL_CHECK_DONE_BIT)='1' then
        if p_in_ctrl(C_LCTRL_TL_CHECK_ERR_BIT)='0' then
          i_tl_check_ok<='1';
        end if;
        i_tl_check_done<='1';
      end if;
    else
      i_tl_check_done<='0';
      i_tl_check_ok<='0';
    end if;

  end if;
end process;

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_tx_close_opt<='0';
  elsif p_in_clk'event and p_in_clk='1' then
    if p_in_phy_sync='1' and p_in_phy_txrdy_n='0' then
      if fsm_llayer_cs=S_L_IDLE then
        i_tx_close_opt<='0';
      elsif fsm_llayer_cs=S_LT_SendData and p_in_txd_close='1' then
        i_tx_close_opt<='1';
      end if;
    end if;
  end if;
end process;


--//#########################################
--//�������� ������ � PHY �������
--//#########################################
p_out_phy_txreq<=i_txreq;


--//������ ������ �� ������ ��������
p_out_txd_rd<=p_in_phy_sync and not p_in_phy_txrdy_n when fsm_llayer_cs=S_LT_SendData else '0';

i_txd_out<=i_crc_out when fsm_llayer_cs=S_LT_SendCRC or i_tx_close_opt='1' else p_in_txd;

gen_txd : for i in 0 to 31  generate
p_out_phy_txd(i)<=i_txd_out(i) xor i_srambler_out(i);--//Scrambling
end generate gen_txd;


process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_tmr<=(others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then

    if fsm_llayer_cs/=S_LT_SendHold then
      i_tmr<=(others=>'0');
    else
      if p_in_phy_sync='1' and p_in_txd_status.empty='0' then
        --//��������� ��� � Tx ������ ��������� ������.
        --//������ ��������� ������� ����� �������������� ��������
        --//��� ���� ����� � ������ ���������� �������� ������
        --//�������� �������� �������� � sata_pkg.vhd - C_LL_TXDATA_RETURN_TMR
          i_tmr<=i_tmr + 1;
      end if;
    end if;

  end if;
end process;



--//----------------------------
--//��������� ����� ���������� �������� ������������ SATA
--//(��. �� 9.5.1 Serial ATA Specification v2.5 (2005-10-27).pdf)
--//----------------------------
i_srambler_en_rx<=(p_in_phy_sync and p_in_phy_rxtype(C_TDATA_EN) and i_rcv_en and not i_rxp(C_TCONT));
i_srambler_en_tx<=(p_in_phy_sync and not p_in_phy_txrdy_n and (i_txd_en or i_trn_term));
i_srambler_en<=i_srambler_en_rx or i_srambler_en_tx;

m_scrambler : sata_scrambler
generic map(
G_INIT_VAL   => 16#F0F6#
)
port map(
p_in_SOF     => i_init_work,
p_in_en      => i_srambler_en,
p_out_result => i_srambler_out,

-----------------
--System
-----------------
--p_in_clk_en  => p_in_clk_en,
p_in_clk     => p_in_clk,
p_in_rst     => p_in_rst
);


--//----------------------------
--//������ CRC �������� ������������ SATA
--//(��. �� 9.5 Serial ATA Specification v2.5 (2005-10-27).pdf)
--//----------------------------
i_crc_in<=i_txd_out when fsm_llayer_cs=S_LT_SendData or fsm_llayer_cs=S_LT_SendCRC or i_trn_term='1' else i_rxd_descr;
i_crc_en<=i_srambler_en_tx or i_rxd_descr_en;

m_crc : sata_crc
generic map(
G_INIT_VAL    => 16#52325032#
)
port map(
p_in_SOF      => i_init_work,
--  p_in_EOF  => '0',
p_in_en       => i_crc_en,
p_in_data     => i_crc_in,
p_out_crc     => i_crc_out,

-----------------
--System
-----------------
--p_in_clk_en   => p_in_clk_en,
p_in_clk      => p_in_clk,
p_in_rst      => p_in_rst
);



--//#########################################
--//Link Layer - ������� ����������
--//��������� ���������� �������� ������������ SATA
--//(��. �� 9.6 Serial ATA Specification v2.5 (2005-10-27).pdf)
--//#########################################
--//��������� ������� ��� retransmit primitive after ALIGN
process(p_in_clk)
begin
  if p_in_clk'event and p_in_clk='1' then
      if p_in_phy_sync='1' then
        sr_phy_txrdy_n(0)<=p_in_phy_txrdy_n;
      end if;
  end if;
end process;
i_txp_retransmit<=p_in_phy_txrdy_n and not sr_phy_txrdy_n(0);--p_in_phy_txrdy_n and sr_phy_txrdy_n(0);--

lfsm:process(p_in_rst,p_in_clk)
begin

if p_in_rst='1' then

  fsm_llayer_cs<= S_L_RESET;

  i_status<=(others=>'0');

  i_init_work<='0';

  i_txreq<=(others=>'0');
  i_txp_cnt<=(others=>'0');
  i_txp_retransmit_en<='0';
  i_txd_en<='0';

  i_rxp<=(others=>'0');
  i_rcv_en<='0';

  i_return<='0';

  i_trn_term<='0';

--  tst_txp_hold<='0'; tst_tx_close_opt<='0';

elsif p_in_clk'event and p_in_clk='1' then
if p_in_phy_sync='1' then

  case fsm_llayer_cs is

    --$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    --$$$$$$$$$$$$ Link IDLE states $$$$$$$$$$$$
    --$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    --------------------------------------------
    -- Link idle. STATE: S_L_RESET
    --------------------------------------------
    when S_L_RESET =>
      i_status<=(others=>'0');

      i_init_work<='0';

      i_txreq<=CONV_STD_LOGIC_VECTOR(C_TALIGN, i_txreq'length);
      i_txp_cnt<=(others=>'0');
      i_txp_retransmit_en<='0';
      i_txd_en<='0';

      i_rcv_en<='0';
      i_rxp<=(others=>'0');

      fsm_llayer_cs <= S_L_NoComm;

    --------------------------------------------
    -- Link idle. STATE: S_L_IDLE /(x00 ��� �� ����� p_out_tst_fms_cs)
    --------------------------------------------
    when S_L_IDLE =>

      i_status(C_LSTAT_RxOK)<='0';
      i_status(C_LSTAT_RxERR_CRC)<='0';
      i_status(C_LSTAT_RxERR_IDLE)<='0';
      i_status(C_LSTAT_RxERR_ABORT)<='0';

      i_status(C_LSTAT_TxOK)<='0';
      i_status(C_LSTAT_TxERR_CRC)<='0';
      i_status(C_LSTAT_TxERR_IDLE)<='0';
      i_status(C_LSTAT_TxERR_ABORT)<='0';

--      tst_txp_hold<='0';
      i_return<='0';

      if p_in_phy_status(C_PSTAT_DET_ESTABLISH_ON_BIT)='0' then
      --//����� � ����������� ��������
        fsm_llayer_cs <= S_L_NoCommErr;

      else

          if p_in_phy_rxtype(C_TX_RDY)='1' then
          --���-�� ������ � �������� ������
              if p_in_phy_txrdy_n='0' then
                if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                  if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt + 1;
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TSYNC, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt+1;
                  end if;
                else
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                end if;

              elsif i_txp_retransmit='1' then
                i_txp_cnt<=CONV_STD_LOGIC_VECTOR(0, i_txp_cnt'length);
                i_txreq<=CONV_STD_LOGIC_VECTOR(C_TSYNC, i_txreq'length);

              end if;--//if p_in_phy_txrdy_n='0' then

              i_rxp(C_TX_RDY)<='1';
              fsm_llayer_cs <= S_LR_RcvWaitFifo;

          elsif p_in_ctrl(C_LCTRL_TxSTART_BIT)='1' then
          --������ �� �������� ������
              i_txreq<=CONV_STD_LOGIC_VECTOR(C_TSYNC, i_txreq'length);
              i_txp_cnt<=(others=>'0');
              fsm_llayer_cs <= S_LT_RcvRdy;

          else

              if i_txp_retransmit_en='0' then
              --Serial ATA Specification v2.5 (2005-10-27).pdf (�� 9.6.2 - Link IDLE state diagram/NOTE:4)
              --����� �������������� ��������� CONT, ������ ��������� ������� 10 �� ALIGN ����������,
              --��� ������� �������� �������� �� SYNC ��� ALIGN.
              --(� ����� ���, ���� ������������ CONT ����� ������ ���������)
                i_txreq<=CONV_STD_LOGIC_VECTOR(C_TSYNC, i_txreq'length);

              elsif p_in_phy_txrdy_n='0' then
                if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                  if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt + 1;
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TSYNC, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt+1;
                  end if;
                else
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                end if;

              elsif i_txp_retransmit='1' then
                i_txp_cnt<=CONV_STD_LOGIC_VECTOR(0, i_txp_cnt'length);
                i_txreq<=CONV_STD_LOGIC_VECTOR(C_TSYNC, i_txreq'length); --retransmit primitive after ALIGN

              end if;
          end if;

      end if;--//if p_in_phy_status(C_PSTAT_DET_ESTABLISH_ON_BIT)='0' then
      --//when S_L_IDLE =>


    --------------------------------------------
    -- Link idle. STATE: S_L_SyncEscape
    --------------------------------------------
    when S_L_SyncEscape =>

      if p_in_phy_status(C_PSTAT_DET_ESTABLISH_ON_BIT)='0' then
      --//����� � ����������� ��������
        fsm_llayer_cs <= S_L_NoCommErr;

      else

          i_init_work<='0';
          i_txd_en<='0';
          i_rcv_en<='0';
          i_return<='0'; --tst_txp_hold<='0';

          if p_in_phy_rxtype(C_TX_RDY)='1' or p_in_phy_rxtype(C_TSYNC)='1' then
              i_rxp<=(others=>'0');

              if p_in_phy_txrdy_n='0' then
                if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                  if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt + 1;
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TSYNC, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt+1;
                  end if;
                else
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                end if;

              elsif i_txp_retransmit='1' then
                i_txp_cnt<=CONV_STD_LOGIC_VECTOR(0, i_txp_cnt'length);
                i_txreq<=CONV_STD_LOGIC_VECTOR(C_TSYNC, i_txreq'length); --retransmit primitive after ALIGN

              end if;--//if p_in_phy_txrdy_n='0' then

              fsm_llayer_cs <= S_L_IDLE;
          else

              if p_in_phy_txrdy_n='0' then
                if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                  if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt + 1;
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TSYNC, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt+1;
                  end if;
                else
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                end if;

              elsif i_txp_retransmit='1' then
                i_txp_cnt<=CONV_STD_LOGIC_VECTOR(0, i_txp_cnt'length);
                i_txreq<=CONV_STD_LOGIC_VECTOR(C_TSYNC, i_txreq'length); --retransmit primitive after ALIGN

              end if;--//if p_in_phy_txrdy_n='0' then

          end if;

      end if;--//if p_in_phy_status(C_PSTAT_DET_ESTABLISH_ON_BIT)='0' then
      --//when S_L_SyncEscape =>

    --------------------------------------------
    -- Link idle. STATE: S_L_NoCommErr
    --------------------------------------------
    when S_L_NoCommErr =>

      i_status<=(others=>'0');

      i_init_work<='0';

      i_txreq<=CONV_STD_LOGIC_VECTOR(C_TALIGN, i_txreq'length);
      i_txp_cnt<=(others=>'0');
      i_txp_retransmit_en<='0';
      i_txd_en<='0';

      i_rxp<=(others=>'0');
      i_rcv_en<='0';
      i_return<='0'; --tst_txp_hold<='0';

      fsm_llayer_cs <= S_L_NoComm;

    --------------------------------------------
    -- Link idle. STATE: S_L_NoComm
    --------------------------------------------
    when S_L_NoComm =>

      if p_in_phy_status(C_PSTAT_DET_ESTABLISH_ON_BIT)='1' then
      --����� � ���������� �����������
        fsm_llayer_cs <= S_L_SendAlign;--S_L_IDLE;
      end if;

    --------------------------------------------
    -- Link idle. STATE: S_L_SendAlign
    --------------------------------------------
    when S_L_SendAlign =>

      if p_in_phy_status(C_PSTAT_DET_ESTABLISH_ON_BIT)='0' then
      --//����� � ����������� ��������
        i_txreq<=CONV_STD_LOGIC_VECTOR(C_TALIGN, i_txreq'length);
        fsm_llayer_cs <= S_L_NoCommErr;

      else
      --����� �����������
        i_txreq<=CONV_STD_LOGIC_VECTOR(C_TSYNC, i_txreq'length);
        fsm_llayer_cs <= S_L_IDLE;
      end if;




    --$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    --$$$$$$$$ Link transfer states $$$$$$$$$$$$
    --$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    --------------------------------------------
    -- Link transfer. STATE: S_LT_RcvRdy
    --------------------------------------------
    when S_LT_RcvRdy =>

      if p_in_phy_status(C_PSTAT_DET_ESTABLISH_ON_BIT)='0' then
      --//����� � ����������� ��������
        fsm_llayer_cs <= S_L_NoCommErr;

      else

          if p_in_phy_rxtype(C_TX_RDY)='1' then
          --//���-�� ������ � �������� ������
              i_txreq<=CONV_STD_LOGIC_VECTOR(C_TX_RDY, i_txreq'length);
              i_txp_cnt<=(others=>'0');
              i_rxp(C_TX_RDY)<='1';
              fsm_llayer_cs <= S_LR_RcvWaitFifo;

          elsif p_in_phy_rxtype(C_TR_RDY)='1' then
          --//���-�� ������ � ������ ������
              i_txreq<=CONV_STD_LOGIC_VECTOR(C_TX_RDY, i_txreq'length);
              i_txp_cnt<=(others=>'0');
              i_init_work<='1';--//������������� ������� CRC,Scrambler
              fsm_llayer_cs <= S_LT_SendSOF;

          else

              if p_in_phy_txrdy_n='0' then
                if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                  if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt + 1;
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TX_RDY, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt+1;
                  end if;
                else
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                end if;

              elsif i_txp_retransmit='1' then
                i_txp_cnt<=CONV_STD_LOGIC_VECTOR(0, i_txp_cnt'length);
                i_txreq<=CONV_STD_LOGIC_VECTOR(C_TX_RDY, i_txreq'length); --retransmit primitive after ALIGN

              end if;

          end if;

      end if;--//if p_in_phy_status(C_PSTAT_DET_ESTABLISH_ON_BIT)='0' then
      --//when S_LT_RcvRdy =>


    --------------------------------------------
    -- Link transfer. STATE: S_LT_SendSOF
    --------------------------------------------
    when S_LT_SendSOF =>

      if p_in_phy_status(C_PSTAT_DET_ESTABLISH_ON_BIT)='0' then
      --//����� � ����������� ��������
        fsm_llayer_cs <= S_L_NoCommErr;

      else

          i_init_work<='0';--//������������� ������� CRC,Scrambler

          if p_in_phy_rxtype(C_TSYNC)='1' then
          --//���-�� ��������� ������� ����������
              if p_in_phy_txrdy_n='0' then
                i_txreq<=CONV_STD_LOGIC_VECTOR(C_TSOF, i_txreq'length);
              end if;

              i_status(C_LSTAT_TxERR_ABORT)<='1';--//������. ����������� �������
              fsm_llayer_cs <= S_L_IDLE;

          else
              if p_in_phy_txrdy_n='0' then
                i_txreq<=CONV_STD_LOGIC_VECTOR(C_TSOF, i_txreq'length);
                fsm_llayer_cs <= S_LT_SendData;
              end if;

          end if;

      end if;--//if p_in_phy_status(C_PSTAT_DET_ESTABLISH_ON_BIT)='0' then
      --//when S_LT_SendSOF =>


    --------------------------------------------
    -- Link transfer. STATE: S_LT_SendData
    --------------------------------------------
    when S_LT_SendData =>

      if p_in_phy_status(C_PSTAT_DET_ESTABLISH_ON_BIT)='0' then
      --//����� � ����������� ��������
        fsm_llayer_cs <= S_L_NoCommErr;

      else

          if p_in_ctrl(C_LCTRL_TRN_ESCAPE_BIT)='1' then
          --//������������ ������� ����� �������� ������� ��������
              i_txreq<=CONV_STD_LOGIC_VECTOR(C_TDATA_EN, i_txreq'length);
              i_txp_cnt<=(others=>'0');
              fsm_llayer_cs <= S_L_SyncEscape;

          elsif p_in_phy_rxtype(C_TSYNC)='1' then
          --//���-�� ��������� ������� ����������
              i_txreq<=CONV_STD_LOGIC_VECTOR(C_TDATA_EN, i_txreq'length);
              i_txp_cnt<=(others=>'0');
              i_status(C_LSTAT_TxERR_ABORT)<='1';--//������. ����������� �������
              i_txd_en<='0';
              fsm_llayer_cs <= S_L_IDLE;

          elsif p_in_phy_rxtype(C_TDMAT)='1' or i_rxp(C_TDMAT)='1' then
          --//���-�� ������ ��������� ������� ����������
              i_txreq<=CONV_STD_LOGIC_VECTOR(C_TDATA_EN, i_txreq'length);
              if p_in_phy_txrdy_n='0' then
                if i_trn_term='1' then
                  i_trn_term<='0'; --tst_txp_hold<='0';
                  fsm_llayer_cs <= S_LT_SendCRC;
                else
                  i_trn_term<='1';
                end if;
              end if;

              i_rxp(C_TDMAT)<='1';
              i_rxp(C_THOLD)<='0';
              i_rxp(C_TCONT)<='0';

          elsif p_in_phy_rxtype(C_THOLD)='1' then
          --//���������� ������ ������������� �������� ������
          --//�������� ������ �� ���������!!!
              i_txd_en<='0';
              if p_in_phy_rxtype(C_THOLD)='1' then
                i_rxp(C_TCONT)<='0';
                i_rxp(C_THOLD)<='1';
              end if;
              i_txreq<=CONV_STD_LOGIC_VECTOR(C_TDATA_EN, i_txreq'length); --tst_txp_hold<='0';
              i_txp_cnt<=(others=>'0');
              fsm_llayer_cs <= S_LT_RcvHold;

          else

              if CONV_INTEGER(p_in_phy_rxtype(C_TDATA_EN-1 downto C_TSOF))/= 0 then
              --//������ ����� ��������, �� �� SYNC, DMAT, HOLD
                if p_in_phy_rxtype(C_TCONT)='1' then
                  i_rxp(C_TCONT)<='1';
                else
                  i_rxp<=(others=>'0');
                end if;
              end if;

              i_txreq<=CONV_STD_LOGIC_VECTOR(C_TDATA_EN, i_txreq'length);
              i_txp_cnt<=(others=>'0');

              if p_in_txd_close='1' then
              --�������� ������ ���������!!!
                  if p_in_phy_txrdy_n='0' then
                    fsm_llayer_cs <= S_LT_SendCRC; --tst_txp_hold<='0';
                  end if;

              elsif p_in_txd_status.aempty='1' then
              --�������� ������ �� ���������!!!, ����� Tx ����� ����
              --�������� � ������������ ���������� � ������������ �������� �� ��������� ������
                  i_txd_en<='0'; --tst_txp_hold<='1';
                  fsm_llayer_cs <= S_LT_SendHold;

              else

                  if p_in_phy_txrdy_n='0' then
                    i_txd_en<='1'; --tst_txp_hold<='0';
                  end if;

              end if;

          end if;

      end if; --//if p_in_phy_status(C_PSTAT_DET_ESTABLISH_ON_BIT)='0' then
      --//when S_LT_SendData =>

    --------------------------------------------
    -- Link transfer. STATE: S_LT_SendHold
    --------------------------------------------
    when S_LT_SendHold =>

      if p_in_phy_status(C_PSTAT_DET_ESTABLISH_ON_BIT)='0' then
      --//����� � ����������� ��������
        fsm_llayer_cs <= S_L_NoCommErr;

      else

          if p_in_ctrl(C_LCTRL_TRN_ESCAPE_BIT)='1' then
          --//������������ ������� ����� �������� ������� ��������
              i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLD, i_txreq'length);
              i_txp_cnt<=(others=>'0');
              fsm_llayer_cs <= S_L_SyncEscape;

          elsif p_in_phy_rxtype(C_TSYNC)='1' then
          --//���-�� ��������� ������� ����������
              i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLD, i_txreq'length);
              i_txp_cnt<=(others=>'0');
              i_rxp<=(others=>'0');
              i_status(C_LSTAT_TxERR_ABORT)<='1';--//������. ����������� �������
              fsm_llayer_cs <= S_L_IDLE;

          elsif p_in_phy_rxtype(C_TDMAT)='1' or i_rxp(C_TDMAT)='1' then
          --//���-�� ������ ��������� ������� ����������
              if p_in_phy_txrdy_n='0' then
                  if i_trn_term='1' then
                    i_trn_term<='0';
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TDATA_EN, i_txreq'length); --tst_txp_hold<='0';
                    fsm_llayer_cs <= S_LT_SendCRC;

                  else
                    i_trn_term<='1';
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLD, i_txreq'length);
                    i_txp_cnt<=(others=>'0');

                  end if;

              else
                  if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLD, i_txreq'length);
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                  end if;

              end if;

              i_rxp(C_TDMAT)<='1';
              i_rxp(C_THOLD)<='0';
              i_rxp(C_TCONT)<='0';

          elsif p_in_phy_rxtype(C_TCONT)='1' then
          --//�����!!! - ��� ����������� ������ ����� ���������� ������ ����������� ���������
              if p_in_phy_txrdy_n='0' then
                if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                  if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt + 1;
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLD, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt+1;
                  end if;
                else
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                end if;
              end if;

              i_rxp(C_TCONT)<='1';

          elsif CONV_INTEGER(p_in_phy_rxtype(C_TDATA_EN-1 downto C_TSOF))/= 0 and p_in_phy_rxtype(C_THOLD)='0' then
          --//������ ����� ��������, �� �� SYNC, DMAT, CONT, HOLD
              if i_tmr>=CONV_STD_LOGIC_VECTOR(C_LL_TXDATA_RETURN_TMR, i_tmr'length) or p_in_txd_close='1' then
                  --//������� � �������� ������
                  if p_in_phy_txrdy_n='0' then
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLD, i_txreq'length);
                    i_txp_cnt<=(others=>'0');
                    i_txd_en<='1';
                    fsm_llayer_cs <= S_LT_SendData;
                  end if;

              else
                  --���� ���� � TXBUF ������ ��������� ������
                  if p_in_phy_txrdy_n='0' then
                    if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                      if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                        i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                        i_txp_cnt<=i_txp_cnt + 1;
                      else
                        i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLD, i_txreq'length);
                        i_txp_cnt<=i_txp_cnt+1;
                      end if;
                    else
                      i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                    end if;
                  end if;

              end if;

              i_rxp<=(others=>'0');

          elsif p_in_phy_rxtype(C_THOLD)='1' or (i_rxp(C_THOLD)='1' and i_rxp(C_TCONT)='1') then
          --//������ �������� HOLD - ���-�� ������������� �������� �������� ������
              if p_in_phy_txrdy_n='0' then
                i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLD, i_txreq'length);
                i_txp_cnt<=(others=>'0');
                i_txd_en<='0'; --tst_txp_hold<='0';
                fsm_llayer_cs <= S_LT_RcvHold;
              end if;

              if p_in_phy_rxtype(C_THOLD)='1' then
                i_rxp(C_TCONT)<='0';
                i_rxp(C_THOLD)<='1';
              end if;

          else

              if i_tmr>=CONV_STD_LOGIC_VECTOR(C_LL_TXDATA_RETURN_TMR, i_tmr'length) or p_in_txd_close='1' then
                  --//������� � �������� ������
                  if p_in_phy_txrdy_n='0' then
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLD, i_txreq'length);
                    i_txp_cnt<=(others=>'0');
                    i_txd_en<='1';
                    fsm_llayer_cs <= S_LT_SendData;
                  end if;

              else
                  --���� ���� � TXBUF ������ ��������� ������
                  if p_in_phy_txrdy_n='0' then
                    if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                      if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                        i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                        i_txp_cnt<=i_txp_cnt + 1;
                      else
                        i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLD, i_txreq'length);
                        i_txp_cnt<=i_txp_cnt+1;
                      end if;
                    else
                      i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                    end if;
                  end if;

              end if;

          end if;

      end if;--//if p_in_phy_status(C_PSTAT_DET_ESTABLISH_ON_BIT)='0' then
      --//when S_LT_SendHold =>


    --------------------------------------------
    -- Link transfer. STATE: S_LT_RcvHold
    --------------------------------------------
    when S_LT_RcvHold =>

      if p_in_phy_status(C_PSTAT_DET_ESTABLISH_ON_BIT)='0' then
      --//����� � ����������� ��������
        fsm_llayer_cs <= S_L_NoCommErr;

      else

          if p_in_ctrl(C_LCTRL_TRN_ESCAPE_BIT)='1' then
          --//������������ ������� ����� �������� ������� ��������
              i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLDA, i_txreq'length);
              i_txp_cnt<=(others=>'0');
              fsm_llayer_cs <= S_L_SyncEscape;

          elsif p_in_phy_rxtype(C_TSYNC)='1' then
          --//���-�� ��������� ������� ����������
              i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLDA, i_txreq'length);
              i_txp_cnt<=(others=>'0');
              i_rxp<=(others=>'0');
              i_status(C_LSTAT_TxERR_ABORT)<='1';--//������. ����������� �������
              fsm_llayer_cs <= S_L_IDLE;

          elsif p_in_phy_rxtype(C_TDMAT)='1' or i_rxp(C_TDMAT)='1' then
          --//���-�� ������ ��������� ������� ����������
              if p_in_phy_txrdy_n='0' then
                  if i_trn_term='1' then
                    i_trn_term<='0';
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TDATA_EN, i_txreq'length);
                    fsm_llayer_cs <= S_LT_SendCRC;

                  else
                    i_trn_term<='1';
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLDA, i_txreq'length);
                    i_txp_cnt<=(others=>'0');

                  end if;

              else
                  if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLDA, i_txreq'length);
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                  end if;

              end if;

              i_rxp(C_TDMAT)<='1';
              i_rxp(C_THOLD)<='0';
              i_rxp(C_TCONT)<='0';

          elsif i_return='1' then

            if p_in_phy_txrdy_n='0' then
              i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLDA, i_txreq'length);
              i_txp_cnt<=(others=>'0');
              i_return<='0';
              if i_tx_close_opt='1' then
                --//�������� � �������� EOF
                i_txd_en<='0'; --tst_tx_close_opt<='1';
                fsm_llayer_cs <= S_LT_SendCRC;--(���� ������� FSM �� �� ���������!!!)
              elsif p_in_txd_status.empty='1' and  p_in_txd_close='0' then
                --//�������� � �������� ������ sh_txbuf
                i_txd_en<='0';
                fsm_llayer_cs <= S_LT_SendHold;--(���� ������� FSM �� �� ���������!!!)
              else
                --//����������� � �������� ������
                i_txd_en<='1';
                fsm_llayer_cs <= S_LT_SendData;
              end if;
            end if;

          elsif p_in_phy_rxtype(C_TCONT)='1' then
          --//�����!!! - ��� ����������� ������ ����� ���������� ������ ����������� ���������
              if p_in_phy_txrdy_n='0' then
                if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                  if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt + 1;
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLDA, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt+1;
                  end if;
                else
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                end if;
              end if;

              i_rxp(C_TCONT)<='1';

          elsif CONV_INTEGER(p_in_phy_rxtype(C_TDATA_EN-1 downto C_TSOF))/=0 and p_in_phy_rxtype(C_THOLD)='0' then
          --//������ ����� ��������, �� �� SYNC, DMAT, CONT, HOLD
              if p_in_phy_txrdy_n='0' then
                i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLDA, i_txreq'length);
                i_txp_cnt<=(others=>'0');
                i_return<='0';
                if i_tx_close_opt='1' then
                  --//�������� � �������� EOF
                  i_txd_en<='0'; --tst_tx_close_opt<='1';
                  fsm_llayer_cs <= S_LT_SendCRC;--(���� ������� FSM �� �� ���������!!!)
                elsif p_in_txd_status.empty='1' and  p_in_txd_close='0' then
                  --//�������� � �������� ������ sh_txbuf
                  i_txd_en<='0';
                  fsm_llayer_cs <= S_LT_SendHold;--(���� ������� FSM �� �� ���������!!!)
                else
                  --//����������� � �������� ������
                  i_txd_en<='1';
                  fsm_llayer_cs <= S_LT_SendData;
                end if;
              else
                i_return<='1';
              end if;

              i_rxp<=(others=>'0');

          elsif p_in_phy_rxtype(C_THOLD)='1' or (i_rxp(C_THOLD)='1' and i_rxp(C_TCONT)='1') then
          --//������ �������� HOLD - ���-�� ������������� �������� �������� ������
              if p_in_phy_txrdy_n='0' then
                if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                  if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt + 1;
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLDA, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt+1;
                  end if;
                else
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                end if;
              end if;

              if p_in_phy_rxtype(C_THOLD)='1' then
                i_rxp(C_TCONT)<='0';
                i_rxp(C_THOLD)<='1';
              end if;

          else

              if p_in_phy_txrdy_n='0' then
                if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                  if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt + 1;
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLDA, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt+1;
                  end if;
                else
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                end if;
              end if;

          end if;

      end if;--if p_in_phy_status(C_PSTAT_DET_ESTABLISH_ON_BIT)='0' then
      --//when S_LT_RcvHold =>


    --------------------------------------------
    -- Link transfer. STATE: S_LT_SendCRC
    --------------------------------------------
    when S_LT_SendCRC =>
      --tst_tx_close_opt<='0';
      if p_in_phy_status(C_PSTAT_DET_ESTABLISH_ON_BIT)='0' then
      --//����� � ����������� ��������
        fsm_llayer_cs <= S_L_NoCommErr;

      else

          if p_in_phy_rxtype(C_TSYNC)='1' then
          --//���-�� ��������� ������� ����������
              i_rxp<=(others=>'0');
              i_txd_en<='0';
              i_txreq<=CONV_STD_LOGIC_VECTOR(C_TEOF, i_txreq'length);
              i_txp_cnt<=(others=>'0');
              i_status(C_LSTAT_TxERR_ABORT)<='1';--//������. ����������� �������
              fsm_llayer_cs <= S_L_IDLE;

          else

              if p_in_phy_txrdy_n='0' then
                if i_rxp(C_TDMAT)='1' then
                  i_status(C_LSTAT_TxDMAT)<='1';--//������. ����������� �������
                end if;
                i_rxp<=(others=>'0');
                i_txd_en<='0';
                i_txreq<=CONV_STD_LOGIC_VECTOR(C_TEOF, i_txreq'length);
                i_txp_cnt<=(others=>'0');

                fsm_llayer_cs <= S_LT_SendEOF;
              end if;

          end if;

      end if;--//if p_in_phy_status(C_PSTAT_DET_ESTABLISH_ON_BIT)='0' then
      --//when S_LT_SendCRC =>

    --------------------------------------------
    -- Link transfer. STATE: S_LT_SendEOF
    --------------------------------------------
    when S_LT_SendEOF =>

      if p_in_phy_status(C_PSTAT_DET_ESTABLISH_ON_BIT)='0' then
      --//����� � ����������� ��������
          fsm_llayer_cs <= S_L_NoCommErr;

      else

          i_status(C_LSTAT_TxDMAT)<='0';

          if p_in_phy_rxtype(C_TSYNC)='1' then
          --//���-�� ��������� ������� ����������
              i_txreq<=CONV_STD_LOGIC_VECTOR(C_TWTRM, i_txreq'length);
              i_status(C_LSTAT_TxERR_ABORT)<='1';--//������. ����������� �������
              fsm_llayer_cs <= S_L_IDLE;

          else

            if p_in_phy_txrdy_n='0' then
              i_txreq<=CONV_STD_LOGIC_VECTOR(C_TWTRM, i_txreq'length);
              fsm_llayer_cs <= S_LT_Wait;
            end if;

          end if;

      end if;--//if p_in_phy_status(C_PSTAT_DET_ESTABLISH_ON_BIT)='0' then
      --//when S_LT_SendEOF =>

    --------------------------------------------
    -- Link transfer. STATE: S_LT_Wait
    --------------------------------------------
    when S_LT_Wait =>

      if p_in_phy_status(C_PSTAT_DET_ESTABLISH_ON_BIT)='0' then
      --//����� � ����������� ��������
        fsm_llayer_cs <= S_L_NoCommErr;

      else

          if p_in_phy_rxtype(C_TSYNC)='1' then
          --//���-�� ��������� ������� ����������
              i_txreq<=CONV_STD_LOGIC_VECTOR(C_TWTRM, i_txreq'length);
              i_txp_cnt<=(others=>'0');
              i_status(C_LSTAT_TxERR_ABORT)<='1';--//������. ����������� �������
              fsm_llayer_cs <= S_L_IDLE;

          elsif p_in_phy_rxtype(C_TR_OK)='1' then
          --//�������� ����������� CRC - ��!!!
              if p_in_phy_txrdy_n='0' then
                if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TWTRM, i_txreq'length);
                else
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                end if;
              end if;

              i_txp_cnt<=(others=>'0');
              i_status(C_LSTAT_TxOK)<='1';--//������. ����������� �������.
              fsm_llayer_cs <= S_L_IDLE;

          elsif p_in_phy_rxtype(C_TR_ERR)='1' then
          --//�������� ����������� CRC - ERROR!!!
              if p_in_phy_txrdy_n='0' then
                if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TWTRM, i_txreq'length);
                else
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                end if;
              end if;

              i_txp_cnt<=(others=>'0');
              i_status(C_LSTAT_TxERR_CRC)<='1';--//������. ����������� �������.
              fsm_llayer_cs <= S_L_IDLE;

          else

              if p_in_phy_txrdy_n='0' then
                if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                  if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt + 1;
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TWTRM, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt+1;
                  end if;
                else
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                end if;

              elsif i_txp_retransmit='1' then
                i_txp_cnt<=CONV_STD_LOGIC_VECTOR(0, i_txp_cnt'length);
                i_txreq<=CONV_STD_LOGIC_VECTOR(C_TWTRM, i_txreq'length); --retransmit primitive after ALIGN

              end if;

          end if;

      end if;--//if p_in_phy_status(C_PSTAT_DET_ESTABLISH_ON_BIT)='0' then
      --//when S_LT_Wait =>





    --$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    --$$$$$$$$ Link reciever states $$$$$$$$$$$$
    --$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    --------------------------------------------
    -- Link recieve. STATE: S_LR_RcvWaitFifo
    --------------------------------------------
    when S_LR_RcvWaitFifo =>

      if p_in_phy_status(C_PSTAT_DET_ESTABLISH_ON_BIT)='0' then
      --//����� � ����������� ��������
        fsm_llayer_cs <= S_L_NoCommErr;

      else

          if p_in_phy_rxtype(C_TCONT)='1' then
          --//�����!!! - ��� ����������� ������ ����� ���������� ������ ����������� ���������
              if p_in_phy_txrdy_n='0' then
                if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                  if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt + 1;
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TSYNC, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt+1;
                  end if;
                else
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                end if;

              elsif i_txp_retransmit='1' then
                i_txp_cnt<=CONV_STD_LOGIC_VECTOR(0, i_txp_cnt'length);
                i_txreq<=CONV_STD_LOGIC_VECTOR(C_TSYNC, i_txreq'length); --retransmit primitive after ALIGN

              end if;--//if p_in_phy_txrdy_n='0' then

              i_rxp(C_TCONT)<='1';

          elsif CONV_INTEGER(p_in_phy_rxtype(C_TDATA_EN-1 downto C_TSOF))/= 0 and p_in_phy_rxtype(C_TX_RDY)='0' then
          --//ERROR!!! - ������ ��������� �������� ��� ����� �������� ��������
              i_txreq<=CONV_STD_LOGIC_VECTOR(C_TSYNC, i_txreq'length);
              i_txp_cnt<=(others=>'0');
              i_rxp<=(others=>'0');
              i_status(C_LSTAT_RxERR_IDLE)<='1';--//������. ����������� �������
              fsm_llayer_cs <= S_L_IDLE;

          elsif p_in_phy_rxtype(C_TX_RDY)='1' or (i_rxp(C_TX_RDY)='1' and i_rxp(C_TCONT)='1') then
          --//���-�� ������ � �������� ������
              if p_in_phy_txrdy_n='0' then

                  if p_in_rxd_status.pfull='0' then --if p_in_rxd_status.empty='1' then
                  --//RXBUF ����� ����� � ������ ������
                      i_txreq<=CONV_STD_LOGIC_VECTOR(C_TSYNC, i_txreq'length);
                      i_txp_cnt<=(others=>'0');
                      i_init_work<='1';--//������������� ������� CRC,Scrambler
                      fsm_llayer_cs <= S_LR_RcvChkRdy;

                  else

                      if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                        if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                          i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                          i_txp_cnt<=i_txp_cnt + 1;
                        else
                          i_txreq<=CONV_STD_LOGIC_VECTOR(C_TSYNC, i_txreq'length);
                          i_txp_cnt<=i_txp_cnt+1;
                        end if;
                      else
                        i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                      end if;

                  end if;--//if p_in_rxd_status.empty='1' then

              elsif i_txp_retransmit='1' then
                i_txp_cnt<=CONV_STD_LOGIC_VECTOR(0, i_txp_cnt'length);
                i_txreq<=CONV_STD_LOGIC_VECTOR(C_TSYNC, i_txreq'length); --retransmit primitive after ALIGN

              end if;--//if p_in_phy_txrdy_n='0' then

              if p_in_phy_rxtype(C_TX_RDY)='1' then
                i_rxp(C_TCONT)<='0';
                i_rxp(C_TX_RDY)<='1';
              end if;

          else

              if p_in_phy_txrdy_n='0' then
                if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                  if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt + 1;
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TSYNC, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt+1;
                  end if;
                else
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                end if;

              elsif i_txp_retransmit='1' then
                i_txp_cnt<=CONV_STD_LOGIC_VECTOR(0, i_txp_cnt'length);
                i_txreq<=CONV_STD_LOGIC_VECTOR(C_TSYNC, i_txreq'length); --retransmit primitive after ALIGN

              end if;--//if p_in_phy_txrdy_n='0' then

          end if;

      end if;--//if p_in_phy_status(C_PSTAT_DET_ESTABLISH_ON_BIT)='0' then
      --//when S_LR_RcvWaitFifo =>

    --------------------------------------------
    -- Link recieve. STATE: S_LR_RcvChkRdy
    --------------------------------------------
    when S_LR_RcvChkRdy =>

      if p_in_phy_status(C_PSTAT_DET_ESTABLISH_ON_BIT)='0' then
      --//����� � ����������� ��������
        fsm_llayer_cs <= S_L_NoCommErr;

      else

          i_init_work<='0';--//������������� ������� CRC,Scrambler

          if p_in_phy_rxtype(C_TSOF)='1' then
          --//FRAME START
              i_txreq<=CONV_STD_LOGIC_VECTOR(C_TR_RDY, i_txreq'length);
              i_txp_cnt<=(others=>'0');
              i_txp_retransmit_en<='1';
              i_rxp<=(others=>'0');
              i_rcv_en<='1';
              i_status(C_LSTAT_RxSTART)<='1';--//������. ����������� �������
              fsm_llayer_cs <= S_LR_RcvData;

          elsif p_in_phy_rxtype(C_TCONT)='1' then
          --//�����!!! - ��� ����������� ������ ����� ���������� ������ ����������� ���������
              if p_in_phy_txrdy_n='0' then
                if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                  if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt + 1;
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TR_RDY, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt+1;
                  end if;
                else
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                end if;

              elsif i_txp_retransmit='1' then
                i_txp_cnt<=CONV_STD_LOGIC_VECTOR(0, i_txp_cnt'length);
                i_txreq<=CONV_STD_LOGIC_VECTOR(C_TR_RDY, i_txreq'length); --retransmit primitive after ALIGN

              end if;--//if p_in_phy_txrdy_n='0' then

              i_rxp(C_TCONT)<='1';

          elsif CONV_INTEGER(p_in_phy_rxtype(C_TDATA_EN-1 downto C_TSOF))/= 0 and p_in_phy_rxtype(C_TX_RDY)='0' then
          --//ERROR!!! - ������ ��������� �������� ��� ����� �������� ��������
              i_txreq<=CONV_STD_LOGIC_VECTOR(C_TR_RDY, i_txreq'length);
              i_txp_cnt<=(others=>'0');
              i_rxp<=(others=>'0');
              i_status(C_LSTAT_RxERR_IDLE)<='1';--//������. ����������� �������
              fsm_llayer_cs <= S_L_IDLE;

          elsif p_in_phy_rxtype(C_TX_RDY)='1' or (i_rxp(C_TX_RDY)='1' and i_rxp(C_TCONT)='1') then
          --//���-�� ������ � �������� ������
              if p_in_phy_txrdy_n='0' then
                if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                  if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt + 1;
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TR_RDY, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt+1;
                  end if;
                else
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                end if;

              elsif i_txp_retransmit='1' then
                i_txp_cnt<=CONV_STD_LOGIC_VECTOR(0, i_txp_cnt'length);
                i_txreq<=CONV_STD_LOGIC_VECTOR(C_TR_RDY, i_txreq'length); --retransmit primitive after ALIGN

              end if;--//if p_in_phy_txrdy_n='0' then

              if p_in_phy_rxtype(C_TX_RDY)='1' then
                i_rxp(C_TCONT)<='0';
                i_rxp(C_TX_RDY)<='1';
              end if;

          else

              if p_in_phy_txrdy_n='0' then
                if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                  if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt + 1;
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TR_RDY, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt+1;
                  end if;
                else
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                end if;

              elsif i_txp_retransmit='1' then
                i_txp_cnt<=CONV_STD_LOGIC_VECTOR(0, i_txp_cnt'length);
                i_txreq<=CONV_STD_LOGIC_VECTOR(C_TR_RDY, i_txreq'length); --retransmit primitive after ALIGN

              end if;--//if p_in_phy_txrdy_n='0' then

          end if;

      end if;--//if p_in_phy_status(C_PSTAT_DET_ESTABLISH_ON_BIT)='0' then
      --//when S_LR_RcvChkRdy =>

    --------------------------------------------
    -- Link recieve. STATE: S_LR_RcvData
    --------------------------------------------
    when S_LR_RcvData =>

      if p_in_phy_status(C_PSTAT_DET_ESTABLISH_ON_BIT)='0' then
      --//����� � ����������� ��������
        fsm_llayer_cs <= S_L_NoCommErr;

      else

          i_status(C_LSTAT_RxSTART)<='0';

          if p_in_ctrl(C_LCTRL_TRN_ESCAPE_BIT)='1' then
          --//������������ ������� ����� �������� ������� ��������
              i_txreq<=CONV_STD_LOGIC_VECTOR(C_TR_IP, i_txreq'length);
              i_txp_cnt<=(others=>'0');
              i_rxp<=(others=>'0');
              i_rcv_en<='0';
              fsm_llayer_cs <= S_L_SyncEscape;

          elsif p_in_phy_rxtype(C_TSYNC)='1' then
          --//���-�� ��������� ������� ����������
              i_txreq<=CONV_STD_LOGIC_VECTOR(C_TR_IP, i_txreq'length);
              i_txp_cnt<=(others=>'0');
              i_rxp<=(others=>'0');
              i_status(C_LSTAT_RxERR_ABORT)<='1';--//������. ����������� �������
              i_rcv_en<='0';
              fsm_llayer_cs <= S_L_IDLE;

          elsif p_in_phy_rxtype(C_TWTRM)='1' then
          --//ERROR!!! - ����� �������� WTRM, �� ������ ������ EOF
              i_txreq<=CONV_STD_LOGIC_VECTOR(C_TR_IP, i_txreq'length);
              i_txp_cnt<=(others=>'0');
              i_rxp<=(others=>'0');
              i_rcv_en<='0';
              fsm_llayer_cs <= S_LR_BadEnd;

          elsif p_in_phy_rxtype(C_TEOF)='1' then
          --//FRAME END
              if p_in_phy_txrdy_n='0' then
                if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                  if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt + 1;
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TR_IP, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt+1;
                  end if;
                else
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                end if;

              elsif i_txp_retransmit='1' then
                i_txp_cnt<=CONV_STD_LOGIC_VECTOR(0, i_txp_cnt'length);
                i_txreq<=CONV_STD_LOGIC_VECTOR(C_TR_IP, i_txreq'length); --retransmit primitive after ALIGN

              end if;--//if p_in_phy_txrdy_n='0' then

              i_rxp<=(others=>'0');
              i_rcv_en<='0';
              fsm_llayer_cs <= S_LR_RcvEOF;

          elsif p_in_phy_rxtype(C_THOLD)='1' then
          --//�����-�� ������������ ��� �������� ��������
              i_txreq<=CONV_STD_LOGIC_VECTOR(C_TR_IP, i_txreq'length);
              i_txp_cnt<=(others=>'0');
              i_rxp<=(others=>'0');
--              i_rcv_en<='0';
              fsm_llayer_cs <= S_LR_RcvHold;

          elsif CONV_INTEGER(p_in_phy_rxtype(C_TDATA_EN-1 downto C_TSOF))/= 0 or i_rxp(C_TCONT)='1' then
          --//������ ����� ��������, �� �� SYNC, C_TWTRM, EOF, C_THOLD
              if p_in_phy_txrdy_n='0' then
                if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                  if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt + 1;
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TR_IP, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt+1;
                  end if;
                else
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                end if;

              elsif i_txp_retransmit='1' then
                i_txp_cnt<=CONV_STD_LOGIC_VECTOR(0, i_txp_cnt'length);
                i_txreq<=CONV_STD_LOGIC_VECTOR(C_TR_IP, i_txreq'length); --retransmit primitive after ALIGN

              end if;--//if p_in_phy_txrdy_n='0' then

              if p_in_phy_rxtype(C_TCONT)='1' then
              --//�����!!! - ��� ����������� ������ ����� ���������� ������ ����������� ���������
                i_rxp(C_TCONT)<='1';

              elsif CONV_INTEGER(p_in_phy_rxtype(C_TDATA_EN-1 downto C_TSOF))/= 0 then
                i_rxp(C_TCONT)<='0';
                i_rcv_en<='1';

              end if;

          elsif p_in_phy_rxtype(C_TDATA_EN)='1' then
          --//�������� ������ �� ���-��

              if p_in_phy_txrdy_n='0' then

                  if p_in_rxd_status.pfull='1' then
                  --//RXBUF �� ����� � ������ ������
                  --//������������ ���-�� ������������� �������� ������
                      i_txreq<=CONV_STD_LOGIC_VECTOR(C_TR_IP, i_txreq'length);
                      i_txp_cnt<=(others=>'0');
                      i_rxp<=(others=>'0'); --tst_txp_hold<='1';
                      fsm_llayer_cs <= S_LR_SendHold;

                  else
                  --//RXBUF ����� � ������ ������
                      i_rcv_en<='1';

                      if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                        if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                          i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                          i_txp_cnt<=i_txp_cnt + 1;
                        else
                          i_txreq<=CONV_STD_LOGIC_VECTOR(C_TR_IP, i_txreq'length);
                          i_txp_cnt<=i_txp_cnt+1;
                        end if;
                      else
                        i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                      end if;

                  end if;

              elsif i_txp_retransmit='1' then
                i_txp_cnt<=CONV_STD_LOGIC_VECTOR(0, i_txp_cnt'length);
                i_txreq<=CONV_STD_LOGIC_VECTOR(C_TR_IP, i_txreq'length); --retransmit primitive after ALIGN

              end if;--//if p_in_phy_txrdy_n='0' then

          else

              if p_in_phy_txrdy_n='0' then
                if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                  if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt + 1;
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TR_IP, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt+1;
                  end if;
                else
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                end if;

              elsif i_txp_retransmit='1' then
                i_txp_cnt<=CONV_STD_LOGIC_VECTOR(0, i_txp_cnt'length);
                i_txreq<=CONV_STD_LOGIC_VECTOR(C_TR_IP, i_txreq'length); --retransmit primitive after ALIGN

              end if;--//if p_in_phy_txrdy_n='0' then

          end if;

      end if;--//if p_in_phy_status(C_PSTAT_DET_ESTABLISH_ON_BIT)='0' then
      --//when S_LR_RcvData =>

    --------------------------------------------
    -- Link recieve. STATE: S_LR_SendHold (�������� �������� HOLD)
    --------------------------------------------
    when S_LR_SendHold =>

      if p_in_phy_status(C_PSTAT_DET_ESTABLISH_ON_BIT)='0' then
      --//����� � ����������� ��������
        fsm_llayer_cs <= S_L_NoCommErr;

      else

          if p_in_ctrl(C_LCTRL_TRN_ESCAPE_BIT)='1' then
          --//������������ ������� ����� �������� ������� ��������
              i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLD, i_txreq'length);
              i_txp_cnt<=(others=>'0');
              i_rxp<=(others=>'0');
              i_rcv_en<='0';
              fsm_llayer_cs <= S_L_SyncEscape;

          elsif p_in_phy_rxtype(C_TSYNC)='1' then
          --//���-�� ��������� ������� ����������
              i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLD, i_txreq'length);
              i_txp_cnt<=(others=>'0');
              i_rxp<=(others=>'0');
              i_status(C_LSTAT_RxERR_ABORT)<='1';--//������. ����������� �������
              i_rcv_en<='0';
              fsm_llayer_cs <= S_L_IDLE;

          elsif p_in_phy_rxtype(C_TEOF)='1' then
          --//FRAME END
              i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLD, i_txreq'length);
              i_txp_cnt<=(others=>'0');
              i_rxp<=(others=>'0');
              i_rcv_en<='0'; --tst_txp_hold<='0';
              fsm_llayer_cs <= S_LR_RcvEOF;

          elsif p_in_phy_rxtype(C_TCONT)='1' then
          --//�����!!! - ��� ����������� ������ ����� ���������� ������ ����������� ���������
              if p_in_phy_txrdy_n='0' then
                if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                  if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt + 1;
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLD, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt+1;
                  end if;
                else
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                end if;

              elsif i_txp_retransmit='1' then
                i_txp_cnt<=CONV_STD_LOGIC_VECTOR(0, i_txp_cnt'length);
                i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLD, i_txreq'length); --retransmit primitive after ALIGN

              end if;--//if p_in_phy_txrdy_n='0' then

              i_rxp(C_TCONT)<='1';
--                i_rcv_en<='0';

          elsif p_in_phy_rxtype(C_THOLDA)='1'then

              if p_in_phy_txrdy_n='0' then
                if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                  if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt + 1;
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLD, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt+1;
                  end if;
                else
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                end if;

              elsif i_txp_retransmit='1' then
                i_txp_cnt<=CONV_STD_LOGIC_VECTOR(0, i_txp_cnt'length);
                i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLD, i_txreq'length); --retransmit primitive after ALIGN

              end if;--//if p_in_phy_txrdy_n='0' then

              if p_in_phy_rxtype(C_THOLDA)='1' then
                i_rxp(C_TCONT)<='0';
                i_rxp(C_THOLDA)<='1';
                i_rxp(C_THOLD)<='0';
              end if;

          elsif p_in_phy_rxtype(C_THOLD)='1' or (i_rxp(C_THOLD)='1' and i_rxp(C_TCONT)='1') then
          --//�����-�� ������������ ��� �������� ��������
              if p_in_rxd_status.empty='1' then
              --//���� ���� ����� ����� RxBUF
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLD, i_txreq'length);
                  i_txp_cnt<=(others=>'0'); --tst_txp_hold<='0';
                  fsm_llayer_cs <= S_LR_RcvHold;

              else

                  if p_in_phy_txrdy_n='0' then
                    if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                      if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                        i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                        i_txp_cnt<=i_txp_cnt + 1;
                      else
                        i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLD, i_txreq'length);
                        i_txp_cnt<=i_txp_cnt+1;
                      end if;
                    else
                      i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                    end if;

                  elsif i_txp_retransmit='1' then
                    i_txp_cnt<=CONV_STD_LOGIC_VECTOR(0, i_txp_cnt'length);
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLD, i_txreq'length); --retransmit primitive after ALIGN

                  end if;--//if p_in_phy_txrdy_n='0' then
              end if;

              if p_in_phy_rxtype(C_THOLD)='1' then
                i_rxp(C_TCONT)<='0';
                i_rxp(C_THOLD)<='1';
                i_rxp(C_THOLDA)<='0';
              end if;

          else

              if p_in_rxd_status.empty='1' then
              --RXBUF ����� � ������ ������
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLD, i_txreq'length);
                  i_txp_cnt<=(others=>'0'); --tst_txp_hold<='0';
                  fsm_llayer_cs <= S_LR_RcvData;

              else

                  if p_in_phy_txrdy_n='0' then
                    if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                      if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                        i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                        i_txp_cnt<=i_txp_cnt + 1;
                      else
                        i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLD, i_txreq'length);
                        i_txp_cnt<=i_txp_cnt+1;
                      end if;
                    else
                      i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                    end if;

                  elsif i_txp_retransmit='1' then
                    i_txp_cnt<=CONV_STD_LOGIC_VECTOR(0, i_txp_cnt'length);
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLD, i_txreq'length); --retransmit primitive after ALIGN

                  end if;--//if p_in_phy_txrdy_n='0' then

              end if;

          end if;

      end if;--//if p_in_phy_status(C_PSTAT_DET_ESTABLISH_ON_BIT)='0' then
      --//when S_LR_SendHold =>


    --------------------------------------------
    -- Link recieve. STATE: S_LR_RcvHold (����� �������� HOLD)
    --------------------------------------------
    when S_LR_RcvHold =>

      if p_in_phy_status(C_PSTAT_DET_ESTABLISH_ON_BIT)='0' then
      --//����� � ����������� ��������
        fsm_llayer_cs <= S_L_NoCommErr;

      else

          if p_in_ctrl(C_LCTRL_TRN_ESCAPE_BIT)='1' then
          --//������������ ������� ����� �������� ������� ��������
              i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLDA, i_txreq'length);
              i_txp_cnt<=(others=>'0');
              i_rxp<=(others=>'0');
              i_rcv_en<='0';
              fsm_llayer_cs <= S_L_SyncEscape;

          elsif p_in_phy_rxtype(C_TSYNC)='1' then
          --//���-�� ��������� ������� ����������
              i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLDA, i_txreq'length);
              i_txp_cnt<=(others=>'0');
              i_rxp<=(others=>'0');
              i_status(C_LSTAT_RxERR_ABORT)<='1';--//������. ����������� �������
              i_rcv_en<='0';
              fsm_llayer_cs <= S_L_IDLE;

          elsif p_in_phy_rxtype(C_TEOF)='1' then
          --//FRAME END
              i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLDA, i_txreq'length);
              i_txp_cnt<=(others=>'0');
              i_rxp<=(others=>'0');
              i_rcv_en<='0';
              fsm_llayer_cs <= S_LR_RcvEOF;

          elsif p_in_phy_rxtype(C_TCONT)='1' then
          --//�����!!! - ��� ����������� ������ ����� ���������� ������ ����������� ���������
              if p_in_phy_txrdy_n='0' then
                if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                  if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt + 1;
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLDA, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt+1;
                  end if;
                else
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                end if;

              elsif i_txp_retransmit='1' then
                i_txp_cnt<=CONV_STD_LOGIC_VECTOR(0, i_txp_cnt'length);
                i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLDA, i_txreq'length); --retransmit primitive after ALIGN

              end if;--//if p_in_phy_txrdy_n='0' then

              i_rxp(C_TCONT)<='1';
--                i_rcv_en<='0';

          elsif p_in_phy_rxtype(C_THOLD)='1' or (i_rxp(C_THOLD)='1' and i_rxp(C_TCONT)='1') then
          --//�����-�� ������������ ��� �������� ��������
              if p_in_phy_txrdy_n='0' then
                if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                  if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt + 1;
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLDA, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt+1;
                  end if;
                else
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                end if;

              elsif i_txp_retransmit='1' then
                i_txp_cnt<=CONV_STD_LOGIC_VECTOR(0, i_txp_cnt'length);
                i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLDA, i_txreq'length); --retransmit primitive after ALIGN

              end if;--//if p_in_phy_txrdy_n='0' then

              if p_in_phy_rxtype(C_THOLD)='1' then
                i_rxp(C_TCONT)<='0';
                i_rxp(C_THOLD)<='1';
                i_rcv_en<='1';
              end if;

          elsif CONV_INTEGER(p_in_phy_rxtype(C_TDATA_EN downto C_TSOF))/= 0 and i_rxp(C_TCONT)='0' then --elsif p_in_phy_rxtype(C_TDATA_EN)='1' and i_rxp(C_TCONT)='0' then
          --//������ ������ DWORD, �� �� SYNC, EOF, CONT, HOLD ��� ������ C_TDATA_EN
          --//������������ � ������ ������
              i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLDA, i_txreq'length);
              i_txp_cnt<=(others=>'0');
              i_rxp<=(others=>'0');
              fsm_llayer_cs <= S_LR_RcvData;

          else

              if p_in_phy_txrdy_n='0' then
                if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                  if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt + 1;
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLDA, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt+1;
                  end if;
                else
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                end if;

              elsif i_txp_retransmit='1' then
                i_txp_cnt<=CONV_STD_LOGIC_VECTOR(0, i_txp_cnt'length);
                i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLDA, i_txreq'length); --retransmit primitive after ALIGN

              end if;--//if p_in_phy_txrdy_n='0' then

          end if;

      end if;--if p_in_phy_status(C_PSTAT_DET_ESTABLISH_ON_BIT)='0' then
      --//when S_LR_RcvHold =>

    --------------------------------------------
    -- Link recieve. STATE: S_LR_RcvEOF
    --------------------------------------------
    when S_LR_RcvEOF =>

      if p_in_phy_status(C_PSTAT_DET_ESTABLISH_ON_BIT)='0' then
      --//����� � ����������� ��������
        fsm_llayer_cs <= S_L_NoCommErr;

      else

          if p_in_phy_txrdy_n='0' then

              i_txreq<=CONV_STD_LOGIC_VECTOR(C_TR_IP, i_txreq'length);
              i_txp_cnt<=(others=>'0');

              --//������ ���������/���������� CRC
              if i_crc_out=(i_crc_out'range =>'0') then
                i_status(C_LSTAT_RxOK)<='1';--//������. ����������� �������
                fsm_llayer_cs <= S_LR_GoodCRC;
              else
                i_status(C_LSTAT_RxERR_CRC)<='1';--//������. ����������� �������
                fsm_llayer_cs <= S_LR_BadEnd;
              end if;

          end if;--//if p_in_phy_txrdy_n='0' then

      end if;--//if p_in_phy_status(C_PSTAT_DET_ESTABLISH_ON_BIT)='0' then
      --//when S_LR_RcvEOF =>

    --------------------------------------------
    -- Link recieve. STATE: S_LR_GoodCRC
    --------------------------------------------
    when S_LR_GoodCRC =>

      if p_in_phy_status(C_PSTAT_DET_ESTABLISH_ON_BIT)='0' then
      --//����� � ����������� ��������
        fsm_llayer_cs <= S_L_NoCommErr;

      else

          if p_in_phy_rxtype(C_TSYNC)='1' then
          --//���-�� ��������� ������� ����������
              i_txreq<=CONV_STD_LOGIC_VECTOR(C_TR_IP, i_txreq'length);
              i_txp_cnt<=(others=>'0');
              i_status(C_LSTAT_RxERR_ABORT)<='1';--//������. ����������� �������
              fsm_llayer_cs <= S_L_IDLE;

          else

              if i_tl_check_done='1' then

                  if p_in_phy_txrdy_n='0' then

                      i_txreq<=CONV_STD_LOGIC_VECTOR(C_TR_IP, i_txreq'length);
                      i_txp_cnt<=(others=>'0');

                      --//��� ������������� �� ������������� ������
                      if i_tl_check_ok='1' then
                        fsm_llayer_cs <= S_LR_GoodEnd;
                      else
                        fsm_llayer_cs <= S_LR_BadEnd;
                      end if;

                  end if;

              else

                  if p_in_phy_txrdy_n='0' then
                    if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                      if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                        i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                        i_txp_cnt<=i_txp_cnt + 1;
                      else
                        i_txreq<=CONV_STD_LOGIC_VECTOR(C_TR_IP, i_txreq'length);
                        i_txp_cnt<=i_txp_cnt+1;
                      end if;
                    else
                      i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                    end if;

                  elsif i_txp_retransmit='1' then
                    i_txp_cnt<=CONV_STD_LOGIC_VECTOR(0, i_txp_cnt'length);
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TR_IP, i_txreq'length); --retransmit primitive after ALIGN

                  end if;--//if p_in_phy_txrdy_n='0' then

              end if;--//if i_tl_check_done='1' then

          end if;

      end if;--//if p_in_phy_status(C_PSTAT_DET_ESTABLISH_ON_BIT)='0' then
      --//when S_LR_GoodCRC =>

    --------------------------------------------
    -- Link recieve. STATE: S_LR_GoodEnd
    --------------------------------------------
    when S_LR_GoodEnd =>

      if p_in_phy_status(C_PSTAT_DET_ESTABLISH_ON_BIT)='0' then
      --//����� � ����������� ��������
        fsm_llayer_cs <= S_L_NoCommErr;

      else
          --//��� �� ���������� �������� SYNC
          if p_in_phy_rxtype(C_TSYNC)='1' then

              i_txreq<=CONV_STD_LOGIC_VECTOR(C_TR_OK, i_txreq'length);
              i_txp_cnt<=(others=>'0');
              fsm_llayer_cs <= S_L_IDLE;

          else

              if p_in_phy_txrdy_n='0' then
                if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                  if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt + 1;
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TR_OK, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt+1;
                  end if;
                else
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                end if;

              elsif i_txp_retransmit='1' then
                i_txp_cnt<=CONV_STD_LOGIC_VECTOR(0, i_txp_cnt'length);
                i_txreq<=CONV_STD_LOGIC_VECTOR(C_TR_OK, i_txreq'length); --retransmit primitive after ALIGN

              end if;--//if p_in_phy_txrdy_n='0' then
          end if;

      end if;--//f p_in_phy_status(C_PSTAT_DET_ESTABLISH_ON_BIT)='0' then
      --//when S_LR_GoodEnd =>

    --------------------------------------------
    -- Link recieve. STATE: S_LR_BadEnd
    --------------------------------------------
    when S_LR_BadEnd =>

      if p_in_phy_status(C_PSTAT_DET_ESTABLISH_ON_BIT)='0' then
      --//����� � ����������� ��������
        fsm_llayer_cs <= S_L_NoCommErr;

      else

          if p_in_phy_rxtype(C_TSYNC)='1' then

              i_txreq<=CONV_STD_LOGIC_VECTOR(C_TR_ERR, i_txreq'length);
              i_txp_cnt<=(others=>'0');
              fsm_llayer_cs <= S_L_IDLE;

          else

              if p_in_phy_txrdy_n='0' then
                if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                  if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt + 1;
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TR_ERR, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt+1;
                  end if;
                else
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                end if;

              elsif i_txp_retransmit='1' then
                i_txp_cnt<=CONV_STD_LOGIC_VECTOR(0, i_txp_cnt'length);
                i_txreq<=CONV_STD_LOGIC_VECTOR(C_TR_ERR, i_txreq'length); --retransmit primitive after ALIGN

              end if;--//if p_in_phy_txrdy_n='0' then
          end if;

      end if;--//f p_in_phy_status(C_PSTAT_DET_ESTABLISH_ON_BIT)='0' then
      --//when S_LR_BadEnd =>


  end case;
end if;
end if;
end process lfsm;



--//-----------------------------------
--//Debug/Sim
--//-----------------------------------
--gen_sim_on : if strcmp(G_SIM,"ON") generate

p_out_dbg.fsm<=fsm_llayer_cs;

p_out_dbg.rxp.dmat<=i_rxp(C_TDMAT);
p_out_dbg.rxp.hold<=i_rxp(C_THOLD);
p_out_dbg.rxp.holda<=i_rxp(C_THOLDA);
p_out_dbg.rxp.xrdy<=i_rxp(C_TX_RDY);
p_out_dbg.rxp.cont<=i_rxp(C_TCONT);

p_out_dbg.ctrl.trn_escape<=p_in_ctrl(C_LCTRL_TRN_ESCAPE_BIT);
p_out_dbg.ctrl.txstart<=p_in_ctrl(C_LCTRL_TxSTART_BIT );
p_out_dbg.ctrl.tl_check_err<=p_in_ctrl(C_LCTRL_TL_CHECK_ERR_BIT);
p_out_dbg.ctrl.tl_check_done<=p_in_ctrl(C_LCTRL_TL_CHECK_DONE_BIT);

p_out_dbg.status.rxok<=i_status(C_LSTAT_RxOK);
p_out_dbg.status.rxstart<=i_status(C_LSTAT_RxSTART);
p_out_dbg.status.rxerr_crc<=i_status(C_LSTAT_RxERR_CRC);
p_out_dbg.status.rxerr_idle<=i_status(C_LSTAT_RxERR_IDLE);
p_out_dbg.status.rxerr_abort<=i_status(C_LSTAT_RxERR_ABORT);
p_out_dbg.status.txok<=i_status(C_LSTAT_TxOK);
p_out_dbg.status.txdmat<=i_status(C_LSTAT_TxDMAT);
p_out_dbg.status.txerr_crc<=i_status(C_LSTAT_TxERR_CRC);
p_out_dbg.status.txerr_idle<=i_status(C_LSTAT_TxERR_IDLE);
p_out_dbg.status.txerr_abort<=i_status(C_LSTAT_TxERR_ABORT);
p_out_dbg.status.txhold_on<='0';--tst_txp_hold;
p_out_dbg.status.rxhold_on<=i_rxp(C_THOLD);

p_out_dbg.rxbuf_status<=p_in_rxd_status;
p_out_dbg.txbuf_status<=p_in_txd_status;
p_out_dbg.txd_close<=p_in_txd_close;
p_out_dbg.txd_close_opt<='0';--tst_tx_close_opt;
p_out_dbg.txp_cnt<=i_txp_cnt;

--end generate gen_sim_on;

--END MAIN
end behavioral;

