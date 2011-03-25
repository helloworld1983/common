-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 05.03.2011 13:10:01
-- Module Name : sata_tlayer
--
-- ���������� :
--   Transport Layer:
--   1. ����������� ��������� ������ � �����-��� �� ������ FIS,
--      �������� ������������ SATA ��� ������ Transport Layer
--     (��. �� 10.4 Serial ATA Specification v2.5 (2005-10-27).pdf)
--
-- Revision:
-- Revision 0.01 - 25.11.2008 - ������ ������ ��� �������� SATA
-- Revision 1.00 - ������ ��������� �������
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

entity sata_tlayer is
generic
(
G_DBG      : string  := "OFF";
G_SIM      : string  := "OFF"
);
port
(
--------------------------------------------------
--����� � USRAPP Layer
--------------------------------------------------
--//����� � TXFIFO
p_in_txfifo_dout          : in    std_logic_vector(31 downto 0);
p_out_txfifo_rd           : out   std_logic;
p_in_txfifo_status        : in    TTxBufStatus;                 --//��������� ��. sata_pkg.vhd/���� - ����

--//����� � RXFIFO
p_out_rxfifo_din          : out   std_logic_vector(31 downto 0);
p_out_rxfifo_wd           : out   std_logic;
p_in_rxfifo_status        : in    TRxBufStatus;                 --//��������� ��. sata_pkg.vhd/���� - ����

--------------------------------------------------
--����� � APP Layer
--------------------------------------------------
p_in_tl_ctrl              : in    std_logic_vector(C_TLCTRL_LAST_BIT downto 0);--//��������� ��. sata_pkg.vhd/���� - Transport Layer/����������/Map:
p_out_tl_status           : out   std_logic_vector(C_TLSTAT_LAST_BIT downto 0);--//��������� ��. sata_pkg.vhd/���� - Transport Layer/�������/Map:

p_in_reg_dma              : in    TRegDMA;                       --//��������� ��. sata_pkg.vhd/���� - ����
p_in_reg_shadow           : in    TRegShadow;
p_out_reg_hold            : out   TRegHold;
p_out_reg_update          : out   TRegShadowUpdate;

--------------------------------------------------
--����� � Link Layer
--------------------------------------------------
p_out_ll_ctrl             : out   std_logic_vector(C_LLCTRL_LAST_BIT downto 0);
p_in_ll_status            : in    std_logic_vector(C_LLSTAT_LAST_BIT downto 0);

p_out_ll_txd_close        : out   std_logic;                    --//
p_out_ll_txd              : out   std_logic_vector(31 downto 0);--//
p_in_ll_txd_rd            : in    std_logic;                    --//
p_out_ll_txd_status       : out   TTxBufStatus;                 --//��������� ��. sata_pkg.vhd/���� - ����

p_in_ll_rxd               : in    std_logic_vector(31 downto 0);--//
p_in_ll_rxd_wr            : in    std_logic;                    --//
p_out_ll_rxd_status       : out   TRxBufStatus;                 --//��������� ��. sata_pkg.vhd/���� - ����

--------------------------------------------------
--����� � PHY Layer
--------------------------------------------------
--p_in_pl_ctrl              : in    std_logic_vector(C_PLCTRL_LAST_BIT downto 0);
p_in_pl_status            : in    std_logic_vector(C_PLSTAT_LAST_BIT downto 0);

--------------------------------------------------
--��������������� �������
--------------------------------------------------
p_in_tst                  : in    std_logic_vector(31 downto 0);
p_out_tst                 : out   std_logic_vector(31 downto 0);

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk               : in    std_logic;
p_in_rst               : in    std_logic
);
end sata_tlayer;

architecture behavioral of sata_tlayer is

constant CI_FR_DWORD_COUNT_MAX : integer:=selval(C_FR_DWORD_COUNT_MAX, C_SIM_FR_DWORD_COUNT_MAX, strcmp(G_SIM, "OFF"));

type fsm_tlayer_state is
(
--------------------------------------------
--Host transport idle states.
--------------------------------------------
S_IDLE,
S_HT_ChkTyp,  --//�������� ���� ������������ FIS

--------------------------------------------
--�������� FIS_REG_HOST2DEV: �������� ATA command
--------------------------------------------
S_HT_CmdFIS,
S_HT_CmdTransStatus,

--------------------------------------------
--�������� FIS_REG_HOST2DEV: �������� ATA control
--------------------------------------------
S_HT_CtrlFIS,
S_HT_CtrlTransStatus,

--------------------------------------------
--�����/��������� FIS_REG_DEV2HOST
--------------------------------------------
S_HT_RegFIS,
S_HT_RegTransStatus,

--------------------------------------------
--�����/��������� FIS_REG_SET_DEVICE_BITS
--------------------------------------------
S_HT_DB_FIS,
S_HT_Dev_Bits,

----------------------------------------------
----�����/��������� FIS_BIST_ACTIVATE (������������ ��� ������������. ��������� ���� loopback)
----------------------------------------------
--S_HT_Xmit_BIST,  --��������
--S_HT_TransBISTStatus,

S_HT_RcvBIST,    --�����
S_HT_BISTTrans1,

--------------------------------------------
--������ � ������ PIO
--------------------------------------------
S_HT_PS_FIS,     --�����/��������� FIS_PIOSETUP
S_HT_PIOOTrans1, --�������� ������ �� SATA
S_HT_PIOOTrans2,
S_HT_PIOEnd,
S_HT_PIOITrans1, --����� ������ �� SATA
S_HT_PIOITrans2,

----------------------------------------------
----������ � ������ DMA
----------------------------------------------
S_HT_DmaSetupFIS,        --//�������� FIS_DMASETUP
S_HT_DmaSetupTransStatus,

S_HT_DS_FIS,     --//����� FIS_DMASETUP

S_HT_DMA_FIS,    --�����/��������� FIS_DMA_ACTIVATE
S_HT_DMAOTrans1, --�������� ������ �� SATA
S_HT_DMAOTrans2,
S_HT_DMAEnd,
S_HT_DMAITrans   --����� ������ �� SATA

);
signal fsm_tlayer_cs: fsm_tlayer_state;

signal i_reg_hold                  : TRegHold;
signal i_reg_update                : TRegShadowUpdate;

signal i_ll_ctrl                   : std_logic_vector(C_LLCTRL_LAST_BIT downto 0);--//���������� ��� Link Layer
signal i_ll_state_illegal          : std_logic;                                   --//������ ��� �������� �� ������ ��������� � ������
                                                                                  --//�������� ���������� LInk Layer
signal i_tl_status                 : std_logic_vector(C_TLSTAT_LAST_BIT downto 0);--//������� Transport Layer

signal i_irq                       : std_logic;

--signal i_firq_bit                  : std_logic;
signal i_fdir_bit                  : std_logic;--//�����/�������� FISDATA
signal i_fpiosetup                 : std_logic;--//������������ � ������ FIS_PIOSETUP
signal i_fdone                     : std_logic;--//
signal i_fdata_tx_en               : std_logic;--//�������� FISDATA
signal i_fdata_txd_en              : std_logic;--//0/1 - FISDATA(header)/FISDATA(data)
signal i_fdata_close               : std_logic;--//������� FISDATA
signal i_fdcnt                     : std_logic_vector(16 downto 0);--//������� dword send/rcv FIS
signal i_fh2d                      : std_logic_vector(31 downto 0);--//������� ������ FIS_HOST2DEV
signal i_fh2d_close                : std_logic;                    --//������� FIS_HOST2DEV
signal i_fh2d_tx_en                : std_logic;                    --//������������� ��� ���� �������� FIS_HOST2DEV
signal i_fdmasetup_tx_en           : std_logic;                    --//������������� ��� ���� �������� FIS_DMASETUP
signal i_fauto_activate_bit        : std_logic;
--signal i_fbist_pattern             : std_logic_vector(7 downto 0);
--signal i_fbist_rxd                 : std_logic_vector(31 downto 0);

signal i_trn_err_cnt               : std_logic_vector(1 downto 0);--//������� ��� Link Layer �������������� � TxERR_CRC ��� ��������� ������� ��������� FIS_HOST2DEV
signal i_trn_repeat                : std_logic;                   --//������ �������� FIS_HOST2DEV.

signal i_dmasetup_hold_tsf_count   : std_logic_vector(31 downto 0);
signal i_dma_trncount_dw           : std_logic_vector(31 downto 0);--//������ ����������(DWORD) ����� DMA
signal i_dma_txd                   : std_logic;                    --//������������� ��� ���� �������� � ������ DMA
signal i_dma_dcnt                  : std_logic_vector(31 downto 0);--//������� dword � ������ DMA

signal i_piosetup_trncount_byte   : std_logic_vector(15 downto 0);--//������ ����������(BYTE) ����� PIO
signal i_piosetup_trncount_dw     : std_logic_vector(15 downto 0);--//������ ����������(DWORD) ����� PIO

signal i_rxd_en                    : std_logic;--//���������� ������ ������ � ���� p_out_rxfifo_wd
signal i_rxd_err                   : std_logic;
type TDlySrD is array (0 to 0) of std_logic_vector(31 downto 0);
signal sr_llrxd                    : TDlySrD;                 --//����� �������� ������/���������� ������ � ����� p_in_ll_rxd/p_in_ll_rxd_wr
signal sr_llrxd_en                 : std_logic_vector(0 to 0);

signal i_txfifo_pfull              : std_logic;--//������������ ������� �������� ������� Tx/Rx
signal i_rxfifo_empty              : std_logic;

signal tst_val                     : std_logic;
signal tst_tl_ctrl                 : TSimTLCtrl;
signal tst_tl_status               : TSimTLStatus;
signal tst_fms_cs                  : std_logic_vector(4 downto 0);
signal tst_fms_cs_dly              : std_logic_vector(tst_fms_cs'range);


--MAIN
begin

--//----------------------------------
--//��������������� �������
--//----------------------------------
gen_dbg_off : if strcmp(G_DBG,"OFF") generate
p_out_tst(31 downto 0)<=(others=>'0');
end generate gen_dbg_off;

gen_dbg_on : if strcmp(G_DBG,"ON") generate
tstout:process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    tst_fms_cs_dly<=(others=>'0');
    p_out_tst(31 downto 1)<=(others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then

    tst_fms_cs_dly<=tst_fms_cs;

    p_out_tst(0)<=tst_val or OR_reduce(tst_fms_cs_dly) or i_irq;
  end if;
end process tstout;

tst_fms_cs<=CONV_STD_LOGIC_VECTOR(16#01#, tst_fms_cs'length) when fsm_tlayer_cs=S_HT_ChkTyp else
            CONV_STD_LOGIC_VECTOR(16#02#, tst_fms_cs'length) when fsm_tlayer_cs=S_HT_CmdFIS else
            CONV_STD_LOGIC_VECTOR(16#03#, tst_fms_cs'length) when fsm_tlayer_cs=S_HT_CmdTransStatus else
            CONV_STD_LOGIC_VECTOR(16#04#, tst_fms_cs'length) when fsm_tlayer_cs=S_HT_RegFIS else
            CONV_STD_LOGIC_VECTOR(16#05#, tst_fms_cs'length) when fsm_tlayer_cs=S_HT_RegTransStatus else
            CONV_STD_LOGIC_VECTOR(16#06#, tst_fms_cs'length) when fsm_tlayer_cs=S_HT_PS_FIS else
            CONV_STD_LOGIC_VECTOR(16#07#, tst_fms_cs'length) when fsm_tlayer_cs=S_HT_PIOOTrans1 else
            CONV_STD_LOGIC_VECTOR(16#08#, tst_fms_cs'length) when fsm_tlayer_cs=S_HT_PIOOTrans2 else
            CONV_STD_LOGIC_VECTOR(16#09#, tst_fms_cs'length) when fsm_tlayer_cs=S_HT_PIOEnd else
            CONV_STD_LOGIC_VECTOR(16#0A#, tst_fms_cs'length) when fsm_tlayer_cs=S_HT_PIOITrans1 else
            CONV_STD_LOGIC_VECTOR(16#0B#, tst_fms_cs'length) when fsm_tlayer_cs=S_HT_PIOITrans2 else
            CONV_STD_LOGIC_VECTOR(16#0C#, tst_fms_cs'length) when fsm_tlayer_cs=S_HT_DMA_FIS else
            CONV_STD_LOGIC_VECTOR(16#0D#, tst_fms_cs'length) when fsm_tlayer_cs=S_HT_DMAOTrans1 else
            CONV_STD_LOGIC_VECTOR(16#0E#, tst_fms_cs'length) when fsm_tlayer_cs=S_HT_DMAOTrans2 else
            CONV_STD_LOGIC_VECTOR(16#0F#, tst_fms_cs'length) when fsm_tlayer_cs=S_HT_DMAEnd else
            CONV_STD_LOGIC_VECTOR(16#10#, tst_fms_cs'length) when fsm_tlayer_cs=S_HT_DMAITrans else
            CONV_STD_LOGIC_VECTOR(16#11#, tst_fms_cs'length) when fsm_tlayer_cs=S_HT_DmaSetupFIS else
            CONV_STD_LOGIC_VECTOR(16#12#, tst_fms_cs'length) when fsm_tlayer_cs=S_HT_DmaSetupTransStatus else
            CONV_STD_LOGIC_VECTOR(16#13#, tst_fms_cs'length) when fsm_tlayer_cs=S_HT_DS_FIS else
            CONV_STD_LOGIC_VECTOR(16#14#, tst_fms_cs'length) when fsm_tlayer_cs=S_HT_CtrlFIS else
            CONV_STD_LOGIC_VECTOR(16#15#, tst_fms_cs'length) when fsm_tlayer_cs=S_HT_CtrlTransStatus else
            CONV_STD_LOGIC_VECTOR(16#16#, tst_fms_cs'length) when fsm_tlayer_cs=S_HT_DB_FIS else
            CONV_STD_LOGIC_VECTOR(16#17#, tst_fms_cs'length) when fsm_tlayer_cs=S_HT_Dev_Bits else
            CONV_STD_LOGIC_VECTOR(16#18#, tst_fms_cs'length) when fsm_tlayer_cs=S_HT_RcvBIST else
            CONV_STD_LOGIC_VECTOR(16#19#, tst_fms_cs'length) when fsm_tlayer_cs=S_HT_BISTTrans1 else
            CONV_STD_LOGIC_VECTOR(16#00#, tst_fms_cs'length) ; --//when fsm_tlayer_cs=S_IDLE else

end generate gen_dbg_on;



--------------------------------------------------
--����� � USRAPP Layer
--------------------------------------------------
p_out_txfifo_rd<=not(i_fh2d_tx_en or i_fdmasetup_tx_en) and p_in_ll_txd_rd and i_fdata_tx_en and not i_fdata_close;

p_out_rxfifo_din<=p_in_ll_rxd;
p_out_rxfifo_wd<=p_in_ll_rxd_wr and i_rxd_en;


--------------------------------------------------
--����� � Application Layer
--------------------------------------------------
p_out_tl_status<=i_tl_status;

p_out_reg_hold<=i_reg_hold;
p_out_reg_update<=i_reg_update;


--------------------------------------------------
--����� � Link Layer
--------------------------------------------------
p_out_ll_ctrl<=i_ll_ctrl;--//���������� LINK �������


p_out_ll_rxd_status.pfull<=p_in_rxfifo_status.pfull;
p_out_ll_rxd_status.empty<=i_rxfifo_empty;

p_out_ll_txd_status.aempty<=not(i_fh2d_tx_en or i_fdmasetup_tx_en) and p_in_txfifo_status.aempty;
p_out_ll_txd_status.empty<=not(i_fh2d_tx_en or i_fdmasetup_tx_en) and p_in_txfifo_status.empty;
p_out_ll_txd_status.pfull<=i_txfifo_pfull;

p_out_ll_txd <=p_in_txfifo_dout when i_fdata_txd_en='1' else i_fh2d;

p_out_ll_txd_close <=i_fh2d_close or i_fdata_close;

i_fdata_close<='1' when ( i_fpiosetup='1' and i_fdcnt=EXT(i_piosetup_trncount_dw, i_fdcnt'length) ) or
                        ( i_dma_txd='1' and i_fdata_txd_en='1' and (i_dma_dcnt=i_dma_trncount_dw or OR_reduce(i_dma_dcnt(log2(CI_FR_DWORD_COUNT_MAX)-1 downto 0))='0') ) else
                 '0';

--//�������������� �������� ������� ������
process(p_in_rst,p_in_clk)
begin
  if p_in_clk'event and p_in_clk='1' then
    i_txfifo_pfull<=p_in_txfifo_status.pfull; --//�.�. ������ pFull ����� ���� �������� � wr_clk ������ Tx
    i_rxfifo_empty<=p_in_rxfifo_status.empty; --//�.�. ������ empty ����� ���� �������� � rd_clk ������ Rx
  end if;
end process;


--//-----------------------------
--//�������������
--//-----------------------------
--//���-�� ���� ��� �������� � ������ PIO
i_piosetup_trncount_byte<=i_reg_hold.tsf_count;
i_piosetup_trncount_dw<=("00"&i_piosetup_trncount_byte(15 downto 2));

i_dma_trncount_dw<=("00"&p_in_reg_dma.trncount_byte(31 downto 2));

i_ll_state_illegal<=not p_in_pl_status(C_PSTAT_DET_ESTABLISH_ON_BIT) or
                    p_in_ll_status(C_LSTAT_RxERR_IDLE) or
                    p_in_ll_status(C_LSTAT_RxERR_ABORT) or
                    p_in_ll_status(C_LSTAT_TxERR_IDLE) or
                    p_in_ll_status(C_LSTAT_TxERR_ABORT) ;



--//-----------------------------
--//����� ��������
--//-----------------------------
lsr_ll : process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then

    for i in 0 to 0 loop
    sr_llrxd(i)<=(others=>'0');
    end loop;
    sr_llrxd_en<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then

    sr_llrxd(0)<=p_in_ll_rxd;-- & sr_llrxd(0 to 1);
    sr_llrxd_en(0)<=p_in_ll_rxd_wr;-- & sr_llrxd_en(0 to 1);

  end if;
end process lsr_ll;



--//#########################################
--//Transport Layer - ������� ����������
--//��������� ���������� �������� ������������ SATA
--//(��. �� 10.4 Serial ATA Specification v2.5 (2005-10-27).pdf)
--//#########################################
lfsm : process(p_in_rst,p_in_clk)
begin

if p_in_rst='1' then

  fsm_tlayer_cs<= S_IDLE;

  i_ll_ctrl<=(others=>'0');
  i_tl_status<=(others=>'0');
  i_irq<='0';

--  i_ftxd<=(others=>'0');
--  i_firq_bit<='0';
  i_fdir_bit<='0';
  i_fpiosetup<='0';
  i_fdone<='0';
  i_fdata_tx_en<='0';
  i_fdata_txd_en<='0';
  i_fh2d<=(others=>'0');
  i_fh2d_close<='0';
  i_fh2d_tx_en<='0';
  i_fauto_activate_bit<='0';
  i_fdcnt<=(others=>'0');
  i_fdmasetup_tx_en<='0';
--  i_fbist_pattern<=(others=>'0');
--  i_fbist_rxd<=(others=>'0');

  i_dma_dcnt<=(others=>'0');
  i_dma_txd<='0';
  i_dmasetup_hold_tsf_count<=(others=>'0');

  i_reg_hold.device<=(others=>'0');
  i_reg_hold.status<=(others=>'0');
  i_reg_hold.error<=(others=>'0');
  i_reg_hold.lba_low<=(others=>'0');
  i_reg_hold.lba_low_exp<=(others=>'0');
  i_reg_hold.lba_mid<=(others=>'0');
  i_reg_hold.lba_mid_exp<=(others=>'0');
  i_reg_hold.lba_high<=(others=>'0');
  i_reg_hold.lba_high_exp<=(others=>'0');
  i_reg_hold.scount<=(others=>'0');
  i_reg_hold.scount_exp<=(others=>'0');
  i_reg_hold.e_status<=(others=>'0');
  i_reg_hold.tsf_count<=(others=>'0');
  i_reg_hold.sb_error<=(others=>'0');
  i_reg_hold.sb_status<=(others=>'0');

  i_reg_update.fd2h<='0';
  i_reg_update.fpio<='0';
  i_reg_update.fpio_e<='0';
  i_reg_update.fsdb<='0';

  i_rxd_en<='0';
  i_rxd_err<='0';

  i_trn_err_cnt<=(others=>'0');
  i_trn_repeat<='0';

elsif p_in_clk'event and p_in_clk='1' then

  case fsm_tlayer_cs is

    --$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    --//Transport IDLE states
    --$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    when S_IDLE =>

      i_reg_update.fd2h<='0';
      i_reg_update.fpio<='0';
      i_reg_update.fpio_e<='0';
      i_reg_update.fsdb<='0';
      i_irq<='0';

      i_tl_status(C_TSTAT_TxERR_CRC_REPEAT_BIT)<='0';
      i_tl_status(C_TSTAT_RxFISTYPE_ERR_BIT)<='0';
      i_tl_status(C_TSTAT_RxFISLEN_ERR_BIT)<='0';

      i_ll_ctrl(C_LCTRL_TL_CHECK_ERR_BIT)<='0';
      i_ll_ctrl(C_LCTRL_TL_CHECK_DONE_BIT)<='0';

      i_fdata_txd_en<='0';
      i_fdata_tx_en<='0';
      i_fdone<='0';

      if p_in_ll_status(C_LSTAT_RxSTART)='1' then
      --//Link Layer ������������� � ������ ����� ������ �� SATA ���������
        i_tl_status(C_TSTAT_TxFISHOST2DEV_BIT)<='0';

        i_fh2d_tx_en<='0';
        i_fdmasetup_tx_en<='0';
        fsm_tlayer_cs <= S_HT_ChkTyp;

      elsif i_fpiosetup='1' and i_fdir_bit=C_DIR_H2D then
        i_tl_status(C_TSTAT_TxFISHOST2DEV_BIT)<='0';

        i_fh2d_tx_en<='0';
        i_fdmasetup_tx_en<='0';
        if i_txfifo_pfull='0' then
        --//���� ����� � TxBUF ��������� ������ ��� �������
          i_ll_ctrl(C_LCTRL_TxSTART_BIT)<='1';
          fsm_tlayer_cs <= S_HT_PIOOTrans2;

        end if;

      elsif p_in_tl_ctrl(C_TCTRL_RCOMMAND_WR_BIT)='1' or i_trn_repeat='1' then
      --//FIS_REG_HOST2DEV : ��������  - ATA command
        if p_in_tl_ctrl(C_TCTRL_RCOMMAND_WR_BIT)='1' then
          i_trn_err_cnt<=(others=>'0');
        end if;

        i_ll_ctrl(C_LCTRL_TxSTART_BIT)<='1';
        i_tl_status(C_TSTAT_TxFISHOST2DEV_BIT)<='1';

        i_fh2d_tx_en<='1';
        i_fdmasetup_tx_en<='0';
        fsm_tlayer_cs <= S_HT_CmdFIS;

      elsif p_in_tl_ctrl(C_TCTRL_RCONTROL_WR_BIT)='1' or i_trn_repeat='1' then
      --//FIS_REG_HOST2DEV : ��������  - ATA control
        if p_in_tl_ctrl(C_TCTRL_RCONTROL_WR_BIT)='1' then
          i_trn_err_cnt<=(others=>'0');
        end if;

        i_ll_ctrl(C_LCTRL_TxSTART_BIT)<='1';
        i_tl_status(C_TSTAT_TxFISHOST2DEV_BIT)<='1';

        i_fh2d_tx_en<='1';
        i_fdmasetup_tx_en<='0';
        fsm_tlayer_cs <= S_HT_CtrlFIS;

      elsif p_in_tl_ctrl(C_TCTRL_DMASETUP_WR_BIT)='1' then
      --//FIS_DMA_SETUP : ��������
        i_ll_ctrl(C_LCTRL_TxSTART_BIT)<='1';
        i_fdmasetup_tx_en<='1';
        fsm_tlayer_cs <= S_HT_DmaSetupFIS;

      else
        i_tl_status(C_TSTAT_TxFISHOST2DEV_BIT)<='0';

        i_fh2d_tx_en<='0';
        i_fdmasetup_tx_en<='0';

      end if;

    --//------------------------------------------
    --//����� ������: �������� FIS Type
    --//------------------------------------------
    when S_HT_ChkTyp =>

      if i_ll_state_illegal='1' then
        fsm_tlayer_cs <= S_IDLE;

      else

        if i_ll_ctrl(C_LCTRL_TL_CHECK_ERR_BIT)='1' then
            --//��� ������������ FIS �� ���������.
            --//���� ���������� ������ ������
            if p_in_ll_status(C_LSTAT_RxOK)='1' or p_in_ll_status(C_LSTAT_RxERR_CRC)='1' then

                i_tl_status(C_TSTAT_RxFISTYPE_ERR_BIT)<='1';
                i_ll_ctrl(C_LCTRL_TL_CHECK_DONE_BIT)<='1';--//������ Link ������ ��������� �������� ������������� R_ERR/R_OK
                fsm_tlayer_cs <= S_IDLE;

            end if;

        else
          --//����������� ��� ������������ FIS
          if p_in_ll_rxd_wr='1' then

              if p_in_ll_rxd(7 downto 0)=CONV_STD_LOGIC_VECTOR(C_FIS_REG_DEV2HOST, 8) then
                  fsm_tlayer_cs <= S_HT_RegFIS;

              elsif p_in_ll_rxd(7 downto 0)=CONV_STD_LOGIC_VECTOR(C_FIS_PIOSETUP, 8) then
                  fsm_tlayer_cs <= S_HT_PS_FIS;

              elsif p_in_ll_rxd(7 downto 0)=CONV_STD_LOGIC_VECTOR(C_FIS_DMA_ACTIVATE, 8) then
                  i_fdir_bit<=C_DIR_H2D;
                  i_fdcnt<=i_fdcnt + 1;
                  fsm_tlayer_cs <= S_HT_DMA_FIS;

              elsif p_in_ll_rxd(7 downto 0)=CONV_STD_LOGIC_VECTOR(C_FIS_DATA, 8) then
                  i_rxd_en<='1';

                  if i_fpiosetup='1' and i_fdir_bit=C_DIR_D2H then
                  --//����� ������ � ������ PIO
                    fsm_tlayer_cs <= S_HT_PIOITrans1;

                  else
                  --//����� ������ � ������ DMA
                    i_fdir_bit<=C_DIR_D2H;
                    fsm_tlayer_cs <= S_HT_DMAITrans;

                  end if;

              elsif p_in_ll_rxd(7 downto 0)=CONV_STD_LOGIC_VECTOR(C_FIS_DMASETUP, 8) then
                  fsm_tlayer_cs <= S_HT_DS_FIS;

              elsif p_in_ll_rxd(7 downto 0)=CONV_STD_LOGIC_VECTOR(C_FIS_SET_DEV_BITS, 8) then
                  fsm_tlayer_cs <= S_HT_DB_FIS;

              elsif p_in_ll_rxd(7 downto 0)=CONV_STD_LOGIC_VECTOR(C_FIS_BIST_ACTIVATE, 8) then
                  fsm_tlayer_cs <= S_HT_RcvBIST;

              else
                --//�� ���� �� ����� FIS �� ���������!!!
                i_ll_ctrl(C_LCTRL_TL_CHECK_ERR_BIT)<='1';

              end if;

           end if;

        end if;--//if p_in_ll_rxd_wr='1' then
      end if;--//if i_ll_state_illegal


    --//-------------------------------------------
    --//FIS_REG_HOST2DEV: �������� ATA command
    --//-------------------------------------------
    when S_HT_CmdFIS =>

      if i_ll_state_illegal='1' then
        i_ll_ctrl(C_LCTRL_TxSTART_BIT)<='0';
        fsm_tlayer_cs <= S_IDLE;

      else

        if p_in_ll_txd_rd='1' then
            i_ll_ctrl(C_LCTRL_TxSTART_BIT)<='0';

            if i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#00#, 3) then
              i_fh2d(8*(0+1)-1 downto 8*0)<=CONV_STD_LOGIC_VECTOR(C_FIS_REG_HOST2DEV, 8);

              i_fh2d(8*1+3 downto 8*1+0)<=(others=>'0');--//PM Port
              i_fh2d(8*1+4)<='0';--//Reseved
              i_fh2d(8*1+5)<='0';--//Reseved
              i_fh2d(8*1+6)<='0';--//Reseved
              i_fh2d(8*1+7)<='1';--//C-bit=1 - ���������� Command Register

              i_fh2d(8*(2+1)-1 downto 8*2)<=p_in_reg_shadow.command;
              i_fh2d(8*(3+1)-1 downto 8*3)<=p_in_reg_shadow.feature;

            elsif i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#01#, 3) then
              i_fh2d(8*(0+1)-1 downto 8*0)<=p_in_reg_shadow.lba_low(7 downto 0);
              i_fh2d(8*(1+1)-1 downto 8*1)<=p_in_reg_shadow.lba_mid(7 downto 0);
              i_fh2d(8*(2+1)-1 downto 8*2)<=p_in_reg_shadow.lba_high(7 downto 0);
              i_fh2d(8*(3+1)-1 downto 8*3)<=p_in_reg_shadow.device;

            elsif i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#02#, 3) then
              i_fh2d(8*(0+1)-1 downto 8*0)<=p_in_reg_shadow.lba_low_exp;
              i_fh2d(8*(1+1)-1 downto 8*1)<=p_in_reg_shadow.lba_mid_exp;
              i_fh2d(8*(2+1)-1 downto 8*2)<=p_in_reg_shadow.lba_high_exp;
              i_fh2d(8*(3+1)-1 downto 8*3)<=p_in_reg_shadow.feature_exp;

            elsif i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#03#, 3) then
              i_fh2d(8*(0+1)-1 downto 8*0)<=p_in_reg_shadow.scount;
              i_fh2d(8*(1+1)-1 downto 8*1)<=p_in_reg_shadow.scount_exp;
              i_fh2d(8*(2+1)-1 downto 8*2)<=(others=>'0');
              i_fh2d(8*(3+1)-1 downto 8*3)<=p_in_reg_shadow.control;

            elsif i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#04#, 3) then
              i_fh2d<=(others=>'0');

            end if;

            if i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#04#, 3) then
            --//������� ��� ������
              i_fh2d_close<='1';
              i_fdcnt<=(others=>'0');
              fsm_tlayer_cs <= S_HT_CmdTransStatus;

            else
              i_fdcnt<=i_fdcnt + 1;
            end if;

        end if;

      end if;--//if i_ll_state_illegal='1' then

    --//------------------------------------------
    --//FIS_REG_HOST2DEV: �������� ATA command
    --//------------------------------------------
    when S_HT_CmdTransStatus =>

      if i_ll_state_illegal='1' then
        i_fh2d_close<='0';
        fsm_tlayer_cs <= S_IDLE;

      else
          if p_in_ll_txd_rd='1' then
            i_fh2d_close<='0';
          end if;

          if p_in_ll_status(C_LSTAT_TxERR_CRC)='1' then

            if i_trn_err_cnt=(i_trn_err_cnt'range => '1') then
              i_trn_repeat<='0';
              i_tl_status(C_TSTAT_TxERR_CRC_REPEAT_BIT)<='1';
            else
              i_trn_err_cnt<=i_trn_err_cnt + 1;
              i_trn_repeat<='1';
            end if;

            fsm_tlayer_cs <= S_IDLE;

          elsif p_in_ll_status(C_LSTAT_TxOK)='1' then

            i_trn_err_cnt<=(others=>'0');
            i_trn_repeat<='0';
            fsm_tlayer_cs <= S_IDLE;

          end if;

      end if;--//if i_ll_state_illegal='1' then


    --//-------------------------------------------
    --//FIS_REG_HOST2DEV: �������� ATA Control
    --//-------------------------------------------
    when S_HT_CtrlFIS =>

      if i_ll_state_illegal='1' then
        i_ll_ctrl(C_LCTRL_TxSTART_BIT)<='0';
        fsm_tlayer_cs <= S_IDLE;

      else

        if p_in_ll_txd_rd='1' then
            i_ll_ctrl(C_LCTRL_TxSTART_BIT)<='0';

            if i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#00#, 3) then
              i_fh2d(8*(0+1)-1 downto 8*0)<=CONV_STD_LOGIC_VECTOR(C_FIS_REG_HOST2DEV, 8);

              i_fh2d(8*1+3 downto 8*1+0)<=(others=>'0');--//PM Port
              i_fh2d(8*1+4)<='0';--//Reseved
              i_fh2d(8*1+5)<='0';--//Reseved
              i_fh2d(8*1+6)<='0';--//Reseved
              i_fh2d(8*1+7)<='0';--//C-bit=0 - ���������� Device Control Register

              i_fh2d(8*(2+1)-1 downto 8*2)<=p_in_reg_shadow.command;
              i_fh2d(8*(3+1)-1 downto 8*3)<=p_in_reg_shadow.feature;

            elsif i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#01#, 3) then
              i_fh2d(8*(0+1)-1 downto 8*0)<=p_in_reg_shadow.lba_low(7 downto 0);
              i_fh2d(8*(1+1)-1 downto 8*1)<=p_in_reg_shadow.lba_mid(7 downto 0);
              i_fh2d(8*(2+1)-1 downto 8*2)<=p_in_reg_shadow.lba_high(7 downto 0);
              i_fh2d(8*(3+1)-1 downto 8*3)<=p_in_reg_shadow.device;

            elsif i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#02#, 3) then
              i_fh2d(8*(0+1)-1 downto 8*0)<=p_in_reg_shadow.lba_low_exp;
              i_fh2d(8*(1+1)-1 downto 8*1)<=p_in_reg_shadow.lba_mid_exp;
              i_fh2d(8*(2+1)-1 downto 8*2)<=p_in_reg_shadow.lba_high_exp;
              i_fh2d(8*(3+1)-1 downto 8*3)<=p_in_reg_shadow.feature_exp;

            elsif i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#03#, 3) then
              i_fh2d(8*(0+1)-1 downto 8*0)<=p_in_reg_shadow.scount;
              i_fh2d(8*(1+1)-1 downto 8*1)<=p_in_reg_shadow.scount_exp;
              i_fh2d(8*(2+1)-1 downto 8*2)<=(others=>'0');
              i_fh2d(8*(3+1)-1 downto 8*3)<=p_in_reg_shadow.control;

            elsif i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#04#, 3) then
              i_fh2d<=(others=>'0');

            end if;

            if i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#04#, 3) then
            --//������� ��� ������
              i_fh2d_close<='1';
              i_fdcnt<=(others=>'0');
              fsm_tlayer_cs <= S_HT_CtrlTransStatus;

            else
              i_fdcnt<=i_fdcnt + 1;
            end if;

        end if;

      end if;--//if i_ll_state_illegal='1' then

    --//------------------------------------------
    --//FIS_REG_HOST2DEV: �������� ATA Control
    --//------------------------------------------
    when S_HT_CtrlTransStatus =>

      if i_ll_state_illegal='1' then
        i_fh2d_close<='0';
        fsm_tlayer_cs <= S_IDLE;

      else
          if p_in_ll_txd_rd='1' then
            i_fh2d_close<='0';
          end if;

          if p_in_ll_status(C_LSTAT_TxERR_CRC)='1' then

            if i_trn_err_cnt=(i_trn_err_cnt'range => '1') then
              i_trn_repeat<='0';
              i_tl_status(C_TSTAT_TxERR_CRC_REPEAT_BIT)<='1';
            else
              i_trn_err_cnt<=i_trn_err_cnt + 1;
              i_trn_repeat<='1';
            end if;

            fsm_tlayer_cs <= S_IDLE;

          elsif p_in_ll_status(C_LSTAT_TxOK)='1' then

            i_trn_err_cnt<=(others=>'0');
            i_trn_repeat<='0';
            fsm_tlayer_cs <= S_IDLE;

          end if;

      end if;--//if i_ll_state_illegal='1' then


    --//------------------------------------------
    --//FIS_REG_DEV2HOST: ����� ������
    --//------------------------------------------
    when S_HT_RegFIS =>

      if i_ll_state_illegal='1' then
        i_fdcnt<=(others=>'0');
        fsm_tlayer_cs <= S_IDLE;

      else

        if p_in_ll_status(C_LSTAT_RxOK)='1' or p_in_ll_status(C_LSTAT_RxERR_CRC)='1' then
        --//����� ������ ��������
            if i_fdcnt(2 downto 0)/=CONV_STD_LOGIC_VECTOR(C_FIS_REG_DEV2HOST_DWSIZE, 3) then
              i_ll_ctrl(C_LCTRL_TL_CHECK_ERR_BIT)<='1';
            end if;

            i_fdcnt<=(others=>'0');
            fsm_tlayer_cs <= S_HT_RegTransStatus;

        elsif sr_llrxd_en(0)='1' then
        --//����� ����������� FIS

            if i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#00#, 3) then
              i_fdir_bit<=sr_llrxd(0)(C_FIS_DIR_BIT+8);
--              i_firq_bit<=sr_llrxd(0)(C_FIS_INT_BIT+8);
              if sr_llrxd(0)(C_FIS_INT_BIT+8)=C_IRQ_ON then
                i_irq<='1';
              end if;

              i_reg_hold.status <= sr_llrxd(0)(8*(2+1)-1 downto 8*2);
              i_reg_hold.error <= sr_llrxd(0)(8*(3+1)-1 downto 8*3);

            elsif i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#01#, 3) then
              i_reg_hold.lba_low <= sr_llrxd(0)(8*(0+1)-1 downto 8*0);
              i_reg_hold.lba_mid <= sr_llrxd(0)(8*(1+1)-1 downto 8*1);
              i_reg_hold.lba_high <= sr_llrxd(0)(8*(2+1)-1 downto 8*2);
              i_reg_hold.device <= sr_llrxd(0)(8*(3+1)-1 downto 8*3);

            elsif i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#02#, 3) then
              i_reg_hold.lba_low_exp <= sr_llrxd(0)(8*(0+1)-1 downto 8*0);
              i_reg_hold.lba_mid_exp <= sr_llrxd(0)(8*(1+1)-1 downto 8*1);
              i_reg_hold.lba_high_exp <= sr_llrxd(0)(8*(2+1)-1 downto 8*2);

            elsif i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#03#, 3) then
              i_reg_hold.scount <= sr_llrxd(0)(8*(0+1)-1 downto 8*0);
              i_reg_hold.scount_exp <= sr_llrxd(0)(8*(1+1)-1 downto 8*1);
              i_reg_hold.e_status <= sr_llrxd(0)(8*(3+1)-1 downto 8*3);

            elsif i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#04#, 3) then
              i_reg_hold.tsf_count(7 downto 0) <= sr_llrxd(0)(8*(0+1)-1 downto 8*0);
              i_reg_hold.tsf_count(15 downto 8) <= sr_llrxd(0)(8*(1+1)-1 downto 8*1);

            end if;

            i_fdcnt<=i_fdcnt + 1;

        end if;--//if sr_llrxd_en(0)='1' then
      end if;--//if i_ll_state_illegal

    --//------------------------------------------
    --//FIS_REG_DEV2HOST: ���������� ���������
    --//------------------------------------------
    when S_HT_RegTransStatus =>

      if i_ll_state_illegal='1' then
        fsm_tlayer_cs <= S_IDLE;

      else

          if p_in_ll_status(C_LSTAT_RxOK)='1' then
          --//CRC - OK!
            if i_ll_ctrl(C_LCTRL_TL_CHECK_ERR_BIT)='1' then
            --//FIS Length - ERROR!
              i_tl_status(C_TSTAT_RxFISLEN_ERR_BIT)<='1';
            else
              i_reg_update.fd2h<='1';
              i_dma_dcnt<=(others=>'0');
            end if;

            i_ll_ctrl(C_LCTRL_TL_CHECK_DONE_BIT)<='1';--//������ Link ������ ��������� �������� ������������� R_ERR/R_OK

          end if;

          fsm_tlayer_cs <= S_IDLE;

      end if;--//if i_ll_state_illegal


    --//------------------------------------------
    --//FIS_SET_DEVICE_BITS: ����� ������
    --//------------------------------------------
    when S_HT_DB_FIS =>

      if i_ll_state_illegal='1' then
        i_fdcnt<=(others=>'0');
        fsm_tlayer_cs <= S_IDLE;

      else

        if p_in_ll_status(C_LSTAT_RxOK)='1' or p_in_ll_status(C_LSTAT_RxERR_CRC)='1' then
        --//����� ������ ��������
            if i_fdcnt(2 downto 0)/=CONV_STD_LOGIC_VECTOR(C_FIS_SET_DEV_BITS_DWSIZE, 3) then
              i_ll_ctrl(C_LCTRL_TL_CHECK_ERR_BIT)<='1';
            end if;

            i_fdcnt<=(others=>'0');
            fsm_tlayer_cs <= S_HT_Dev_Bits;

        elsif sr_llrxd_en(0)='1' then
        --//����� ����������� FIS

            if i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#00#, 3) then
--              i_firq_bit<=sr_llrxd(0)(C_FIS_INT_BIT+8);
              if sr_llrxd(0)(C_FIS_INT_BIT+8)=C_IRQ_ON then
                i_irq<='1';
              end if;

              i_reg_hold.sb_status <= sr_llrxd(0)(8*(2+1)-1 downto 8*2);
              i_reg_hold.sb_error <= sr_llrxd(0)(8*(3+1)-1 downto 8*3);

            end if;

            i_fdcnt<=i_fdcnt + 1;

        end if;--//if sr_llrxd_en(0)='1' then
      end if;--//if i_ll_state_illegal

    --//------------------------------------------
    --//FIS_SET_DEVICE_BITS: ���������� ���������
    --//------------------------------------------
    when S_HT_Dev_Bits =>

      if i_ll_state_illegal='1' then
        fsm_tlayer_cs <= S_IDLE;

      else

          if p_in_ll_status(C_LSTAT_RxOK)='1' then
          --//CRC - OK!
            if i_ll_ctrl(C_LCTRL_TL_CHECK_ERR_BIT)='1' then
            --//FIS Length - ERROR!
              i_tl_status(C_TSTAT_RxFISLEN_ERR_BIT)<='1';
            else
              i_reg_update.fsdb<='1';
            end if;

            i_ll_ctrl(C_LCTRL_TL_CHECK_DONE_BIT)<='1';--//������ Link ������ ��������� �������� ������������� R_ERR/R_OK

          end if;

          fsm_tlayer_cs <= S_IDLE;

      end if;--//if i_ll_state_illegal


    --//------------------------------------------
    --//FIS_BIST_ACTIVATE: ����� ������
    --//------------------------------------------
    when S_HT_RcvBIST =>

      if i_ll_state_illegal='1' then
        i_fdcnt<=(others=>'0');
        fsm_tlayer_cs <= S_IDLE;

      else

        if p_in_ll_status(C_LSTAT_RxOK)='1' or p_in_ll_status(C_LSTAT_RxERR_CRC)='1' then
        --//����� ������ ��������
            if i_fdcnt(2 downto 0)/=CONV_STD_LOGIC_VECTOR(C_FIS_BIST_ACTIVATE_DWSIZE, 3) then
              i_ll_ctrl(C_LCTRL_TL_CHECK_ERR_BIT)<='1';
            end if;

            i_fdcnt<=(others=>'0');
            fsm_tlayer_cs <= S_HT_BISTTrans1;

        elsif sr_llrxd_en(0)='1' then
        --//����� ����������� FIS

--            if i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#00#, 3) then
--
--              i_fbist_pattern <= sr_llrxd(0)(8*(2+1)-1 downto 8*2);
--
--            elsif i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#01#, 3) then
--
--              i_fbist_rxd <= sr_llrxd(0)(8*(3+1)-1 downto 8*2);
--
--            elsif i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#03#, 3) then
--
--              i_fbist_rxd <= sr_llrxd(0)(8*(3+1)-1 downto 8*2);
--
--            end if;

            i_fdcnt<=i_fdcnt + 1;

        end if;--//if sr_llrxd_en(0)='1' then
      end if;--//if i_ll_state_illegal

    --//------------------------------------------
    --//FIS_BIST_ACTIVATE: ���������� ���������
    --//------------------------------------------
    when S_HT_BISTTrans1 =>

      if i_ll_state_illegal='1' then
        fsm_tlayer_cs <= S_IDLE;

      else

          if p_in_ll_status(C_LSTAT_RxOK)='1' then
          --//CRC - OK!
            if i_ll_ctrl(C_LCTRL_TL_CHECK_ERR_BIT)='1' then
            --//FIS Length - ERROR!
              i_tl_status(C_TSTAT_RxFISLEN_ERR_BIT)<='1';
            end if;

            i_ll_ctrl(C_LCTRL_TL_CHECK_DONE_BIT)<='1';--//������ Link ������ ��������� �������� ������������� R_ERR/R_OK

          end if;

          fsm_tlayer_cs <= S_IDLE;

      end if;--//if i_ll_state_illegal



    --$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    -- //���������� ������ � ������ PIO
    --$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    --//------------------------------------------
    --//����� PIO / ����� FIS_PIOSETUP
    --//------------------------------------------
    when S_HT_PS_FIS =>

      if i_ll_state_illegal='1' then
        i_fdcnt<=(others=>'0');
        i_fpiosetup<='0';
        fsm_tlayer_cs <= S_IDLE;

      else

        if p_in_ll_status(C_LSTAT_RxOK)='1' or p_in_ll_status(C_LSTAT_RxERR_CRC)='1' then
        --//����� ������ ��������
            if p_in_ll_status(C_LSTAT_RxOK)='1' then
            --//CRC - OK!
              if i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(C_FIS_PIOSETUP_DWSIZE, 3) then
              --//FIS Length - OK!
                i_fpiosetup<='1';

                if i_fdir_bit=C_DIR_H2D then
                --//�������� ������ (FPGA -> HDD)
                  fsm_tlayer_cs <= S_HT_PIOOTrans1;
                else
                --//����� ������ (FPGA <- HDD)
                  fsm_tlayer_cs <= S_IDLE;
                end if;

              else
                i_ll_ctrl(C_LCTRL_TL_CHECK_ERR_BIT)<='1';
                fsm_tlayer_cs <= S_IDLE;

              end if;

              i_ll_ctrl(C_LCTRL_TL_CHECK_DONE_BIT)<='1';--//������ Link ������ ��������� �������� ������������� R_ERR/R_OK

            else
              fsm_tlayer_cs <= S_IDLE;
            end if;

            i_fdcnt<=(others=>'0');

        elsif sr_llrxd_en(0)='1' then
        --//����� ����������� FIS

            if i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#00#, 3) then
              i_fdir_bit<=sr_llrxd(0)(C_FIS_DIR_BIT+8);
--              i_firq_bit<=sr_llrxd(0)(C_FIS_INT_BIT+8);
              if sr_llrxd(0)(C_FIS_INT_BIT+8)=C_IRQ_ON then
                i_irq<='1';
              end if;

              i_reg_hold.status <= sr_llrxd(0)(8*(2+1)-1 downto 8*2);
              i_reg_hold.error <= sr_llrxd(0)(8*(3+1)-1 downto 8*3);

            elsif i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#01#, 3) then
              i_reg_hold.lba_low <= sr_llrxd(0)(8*(0+1)-1 downto 8*0);
              i_reg_hold.lba_mid <= sr_llrxd(0)(8*(1+1)-1 downto 8*1);
              i_reg_hold.lba_high <= sr_llrxd(0)(8*(2+1)-1 downto 8*2);
              i_reg_hold.device <= sr_llrxd(0)(8*(3+1)-1 downto 8*3);

            elsif i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#02#, 3) then
              i_reg_hold.lba_low_exp <= sr_llrxd(0)(8*(0+1)-1 downto 8*0);
              i_reg_hold.lba_mid_exp <= sr_llrxd(0)(8*(1+1)-1 downto 8*1);
              i_reg_hold.lba_high_exp <= sr_llrxd(0)(8*(2+1)-1 downto 8*2);

            elsif i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#03#, 3) then
              i_reg_hold.scount <= sr_llrxd(0)(8*(0+1)-1 downto 8*0);
              i_reg_hold.scount_exp <= sr_llrxd(0)(8*(1+1)-1 downto 8*1);
              i_reg_hold.e_status <= sr_llrxd(0)(8*(3+1)-1 downto 8*3);

            elsif i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#04#, 3) then
              i_reg_hold.tsf_count(7 downto 0) <= sr_llrxd(0)(8*(0+1)-1 downto 8*0);
              i_reg_hold.tsf_count(15 downto 8) <= sr_llrxd(0)(8*(1+1)-1 downto 8*1);

            end if;

            i_fdcnt<=i_fdcnt + 1;

        end if;--//if sr_llrxd_en(0)='1' then

      end if;--//if i_ll_state_illegal

    --//------------------------------------------
    --//����� PIO / ����� FIS_PIOSETUP
    --//------------------------------------------
    when S_HT_PIOOTrans1 =>

      i_reg_update.fpio<='1';
      fsm_tlayer_cs <= S_IDLE;--fsm_tlayer_cs <= S_HT_PIOOTrans2;


    --//------------------------------------------
    --//����� PIO / �������� ������ (FPGA -> HDD)
    --//------------------------------------------
    when S_HT_PIOOTrans2 =>

      if i_ll_state_illegal='1' then
        i_ll_ctrl(C_LCTRL_TxSTART_BIT)<='0';
        i_fpiosetup<='0';
        fsm_tlayer_cs <= S_IDLE;

      else
        if p_in_ll_status(C_LSTAT_TxDMAT)='1' then
        --//ABORT!!!
        --//Link Layer ������������� � ������ ��������� DMAT
            i_ll_ctrl(C_LCTRL_TxSTART_BIT)<='0';

            i_fdcnt<=(others=>'0');
            i_fdata_txd_en<='0';
            i_fdata_tx_en<='0';
            fsm_tlayer_cs<=S_HT_PIOEnd;

        elsif p_in_ll_txd_rd='1' then
        --//�������� FISDATA
            i_ll_ctrl(C_LCTRL_TxSTART_BIT)<='0';

            if i_fdata_tx_en='0' then
            --//���������
                i_fdata_tx_en<='1';--//��������� FISDATA �������
                i_fh2d<=CONV_STD_LOGIC_VECTOR(C_FIS_DATA, i_fh2d'length);

            else
            --//������
                if i_fdcnt=EXT(i_piosetup_trncount_dw, i_fdcnt'length) then
                  i_fdcnt<=(others=>'0');
                  i_fdata_txd_en<='0';
                  i_fdata_tx_en<='0';
                  fsm_tlayer_cs<=S_HT_PIOEnd;

                else
                  i_fdata_txd_en<='1';
                  i_fdcnt<=i_fdcnt + 1;
                end if;
            end if;

        end if;--//if p_in_ll_txd_rd='1' then
      end if;--//if i_ll_state_illegal


    --//------------------------------------------
    --//����� PIO / ���������� �������
    --//------------------------------------------
    when S_HT_PIOEnd =>

      if i_ll_state_illegal='1' then
        i_fpiosetup<='0';
        fsm_tlayer_cs <= S_IDLE;

      else

          if i_fdir_bit=C_DIR_D2H then
          --����� ������ (FPGA <- HDD)

              if i_rxd_err='0' then
                i_reg_update.fpio_e<='1';
                i_ll_ctrl(C_LCTRL_TL_CHECK_DONE_BIT)<='1';--//������ Link ������ ��������� �������� ������������� R_ERR/R_OK
              end if;

              i_fpiosetup<='0';
              fsm_tlayer_cs <= S_IDLE;

          else
          --�������� ������ (FPGA -> HDD)
              if p_in_ll_status(C_LSTAT_TxERR_CRC)='1' then

                i_fpiosetup<='0';
                fsm_tlayer_cs <= S_IDLE;

              elsif p_in_ll_status(C_LSTAT_TxOK)='1' then

                i_fpiosetup<='0';
                i_reg_update.fpio_e<='1';
                fsm_tlayer_cs <= S_IDLE;

              end if;

          end if;

      end if;--//if i_ll_state_illegal

    --//------------------------------------------
    --//����� PIO / ����� ������ (FPGA <- HDD)
    --//------------------------------------------
    when S_HT_PIOITrans1 =>

      if i_ll_state_illegal='1' then
        i_fpiosetup<='0';
        i_rxd_en<='0';
        fsm_tlayer_cs <= S_IDLE;

      else
          i_reg_update.fpio<='1';
          fsm_tlayer_cs <= S_HT_PIOITrans2;

      end if;--//if i_ll_state_illegal

    --//------------------------------------------
    --//����� PIO / ����� ������ (FPGA <- HDD)
    --//-----------------------------------------
    when S_HT_PIOITrans2 =>

      i_reg_update.fpio<='0';

      if i_ll_state_illegal='1' then
        i_fpiosetup<='0';
        i_rxd_en<='0';
        fsm_tlayer_cs <= S_IDLE;

      else

--          if p_in_ll_status(C_LSTAT_RxDMAT)='1' then
--          --//ABORT!!!
--          --//Link Layer ������������� � ������ ��������� DMAT
--              i_fdcnt<=(others=>'0');
--              i_fdata_txd_en<='0';
--              fsm_tlayer_cs<=S_HT_PIOEnd;

          if p_in_ll_status(C_LSTAT_RxOK)='1' or p_in_ll_status(C_LSTAT_RxERR_CRC)='1' then
          --//����� ������ ��������
              i_rxd_en<='0';

              if p_in_ll_status(C_LSTAT_RxERR_CRC)='1' then
                i_rxd_err<='1';
              elsif p_in_ll_status(C_LSTAT_RxOK)='1' then
                i_rxd_err<='0';
              end if;

              fsm_tlayer_cs <= S_HT_PIOEnd;

          end if;

      end if;--//if i_ll_state_illegal



    --$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    -- //���������� ������ � ������ DMA
    --$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    --//-------------------------------------------
    --//FIS_DMASETUP: ��������
    --//-------------------------------------------
    when S_HT_DmaSetupFIS =>

      if i_ll_state_illegal='1' or p_in_ll_status(C_LSTAT_RxSTART)='1' then
      --//Link Layer ������������� � ������� � ������ �������� ��� � ������ ����� ������ �� SATA ���������
        i_ll_ctrl(C_LCTRL_TxSTART_BIT)<='0';
        fsm_tlayer_cs <= S_IDLE;

      else

        if p_in_ll_txd_rd='1' then
            i_ll_ctrl(C_LCTRL_TxSTART_BIT)<='0';

            if i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#00#, 3) then
              i_fh2d(8*(0+1)-1 downto 8*0)<=CONV_STD_LOGIC_VECTOR(C_FIS_DMASETUP, 8);

              i_fh2d(8*1+3 downto 8*1+0)<=(others=>'0');--//PM Port
              i_fh2d(8*1+4)<='0';--//Reseved
              i_fh2d(8*1+5)<=p_in_reg_dma.fpdma.dir;--//Direction
              i_fh2d(8*1+6)<='0';--//Interrupt
              i_fh2d(8*1+7)<='0';--//Auto-Activate

              i_fh2d(8*(2+1)-1 downto 8*2)<=(others=>'0');
              i_fh2d(8*(3+1)-1 downto 8*3)<=(others=>'0');

            elsif i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#01#, 3) then
              i_fh2d(8*(3+1)-1 downto 8*0)<=p_in_reg_dma.fpdma.addr_l;

            elsif i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#02#, 3) then
              i_fh2d(8*(3+1)-1 downto 8*0)<=p_in_reg_dma.fpdma.addr_m;

            elsif i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#03#, 3) then
              i_fh2d(8*(3+1)-1 downto 8*0)<=(others=>'0');

            elsif i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#04#, 3) then
              i_fh2d(8*(3+1)-1 downto 8*0)<=p_in_reg_dma.fpdma.offset;

            elsif i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#05#, 3) then
              i_fh2d(8*(3+1)-1 downto 8*0)<=p_in_reg_dma.trncount_byte;

            elsif i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#06#, 3) then
              i_fh2d(8*(3+1)-1 downto 8*0)<=(others=>'0');

            end if;

            if i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#06#, 3) then
            --//������� ��� ������
              i_fh2d_close<='1';
              i_fdcnt<=(others=>'0');
              fsm_tlayer_cs <= S_HT_DmaSetupTransStatus;

            else
              i_fdcnt<=i_fdcnt + 1;
            end if;

        end if;

      end if;--//if i_ll_state_illegal='1' then

    --//------------------------------------------
    --//FIS_DMASETUP: ��������
    --//------------------------------------------
    when S_HT_DmaSetupTransStatus =>

      if i_ll_state_illegal='1' then
        i_fh2d_close<='0';
        fsm_tlayer_cs <= S_IDLE;

      else
          if p_in_ll_txd_rd='1' then
            i_fh2d_close<='0';
          end if;

          if p_in_ll_status(C_LSTAT_TxERR_CRC)='1' then

            fsm_tlayer_cs <= S_IDLE;

          elsif p_in_ll_status(C_LSTAT_TxOK)='1' then

            fsm_tlayer_cs <= S_IDLE;

          end if;

      end if;--//if i_ll_state_illegal='1' then


    --//------------------------------------------
    --//FIS_DMASETUP: �����
    --//------------------------------------------
    when S_HT_DS_FIS =>

      if i_ll_state_illegal='1' then
        i_fdcnt<=(others=>'0');
        i_fauto_activate_bit<='0';
        fsm_tlayer_cs <= S_IDLE;

      else

        if p_in_ll_status(C_LSTAT_RxOK)='1' or p_in_ll_status(C_LSTAT_RxERR_CRC)='1' then
        --//����� ������ ��������
            if p_in_ll_status(C_LSTAT_RxOK)='1' then
            --//CRC - OK!
              if i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(C_FIS_DMASETUP_DWSIZE, 3) then
              --//FIS length - OK!
                  if i_fdir_bit=C_DIR_H2D and i_fauto_activate_bit='1' then
                  --//�������� ������ (FPGA -> HDD)
                    fsm_tlayer_cs <= S_HT_DMAOTrans2;
                  else
                  --//����� ������ (FPGA <- HDD)
                    fsm_tlayer_cs <= S_IDLE;
                  end if;

              else
                i_ll_ctrl(C_LCTRL_TL_CHECK_ERR_BIT)<='1';
                fsm_tlayer_cs <= S_IDLE;

              end if;

              i_ll_ctrl(C_LCTRL_TL_CHECK_DONE_BIT)<='1';--//������ Link ������ ��������� �������� ������������� R_ERR/R_OK

            else
              fsm_tlayer_cs <= S_IDLE;
            end if;

            i_fdcnt<=(others=>'0');

        elsif sr_llrxd_en(0)='1' then
        --//����� ����������� FIS

            if i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#00#, 3) then
              i_fdir_bit <= sr_llrxd(0)(C_FIS_DIR_BIT+8);
              i_fauto_activate_bit <= sr_llrxd(0)(C_FIS_AUTO_ACTIVATE_BIT+8);

            elsif i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#05#, 3) then
              i_dmasetup_hold_tsf_count <= sr_llrxd(0)(8*(3+1)-1 downto 8*0);

            end if;

            i_fdcnt<=i_fdcnt + 1;

        end if;--//if sr_llrxd_en(0)='1' then

      end if;--//if i_ll_state_illegal


    --//------------------------------------------
    --//����� DMA / ����� FIS DMA ACTIVATE
    --//------------------------------------------
    when S_HT_DMA_FIS =>

      if i_ll_state_illegal='1' then
        i_fdcnt<=(others=>'0');
        fsm_tlayer_cs <= S_IDLE;

      else

        if p_in_ll_status(C_LSTAT_RxOK)='1' or p_in_ll_status(C_LSTAT_RxERR_CRC)='1' then
        --//����� ������ ��������
          if p_in_ll_status(C_LSTAT_RxOK)='1' then
          --//CRC - OK!
            if i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(C_FIS_DMA_ACTIVATE_DWSIZE, 3) then
            --//FIS length - OK!
              fsm_tlayer_cs <= S_HT_DMAOTrans1;

            else
              i_ll_ctrl(C_LCTRL_TL_CHECK_ERR_BIT)<='1';
              fsm_tlayer_cs <= S_IDLE;

            end if;

            i_ll_ctrl(C_LCTRL_TL_CHECK_DONE_BIT)<='1';--//������ Link ������ ��������� �������� ������������� R_ERR/R_OK

          else
            fsm_tlayer_cs <= S_IDLE;
          end if;

          i_fdcnt<=(others=>'0');

        elsif p_in_ll_rxd_wr='1' then
        --//����� ����������� FIS
          i_fdcnt<=i_fdcnt + 1;

        end if;

      end if;--//if i_ll_state_illegal

    --//------------------------------------------
    --//����� DMA / �������� ������
    --//------------------------------------------
    when S_HT_DMAOTrans1 =>

      if i_ll_state_illegal='1' then
        fsm_tlayer_cs <= S_IDLE;

      else
          i_ll_ctrl(C_LCTRL_TL_CHECK_DONE_BIT)<='0';

          if i_txfifo_pfull='1' then
          --//���� ����� � TxBUF ��������� ������ ��� �������
            i_ll_ctrl(C_LCTRL_TxSTART_BIT)<='1';
            i_dma_txd<='1';
            fsm_tlayer_cs <= S_HT_DMAOTrans2;

          end if;

      end if;--//if i_ll_state_illegal

    --//------------------------------------------
    --//����� DMA / �������� ������
    --//------------------------------------------
    when  S_HT_DMAOTrans2 =>

      if i_ll_state_illegal='1' then
        i_ll_ctrl(C_LCTRL_TxSTART_BIT)<='0';
        i_dma_txd<='0';
        fsm_tlayer_cs <= S_IDLE;

      else

        i_ll_ctrl(C_LCTRL_TL_CHECK_DONE_BIT)<='0';

        if p_in_ll_status(C_LSTAT_TxDMAT)='1' then
        --//ABORT!!!
        --//Link Layer ������������� � ������ ��������� DMAT
          i_ll_ctrl(C_LCTRL_TxSTART_BIT)<='0';

          i_fdata_txd_en<='0';
          i_fdata_tx_en<='0';
          i_fdone<='0';
          fsm_tlayer_cs<=S_HT_DMAEnd;

        elsif i_fdone='0' then
            --//�������� FISDATA
            if p_in_ll_txd_rd='1' then

                i_ll_ctrl(C_LCTRL_TxSTART_BIT)<='0';

                if i_fdata_tx_en='0' then
                --//���������
                    i_fdata_tx_en<='1';--//��������� FISDATA �������
                    i_fh2d<=CONV_STD_LOGIC_VECTOR(C_FIS_DATA, i_fh2d'length);

                else
                --//������
                    if i_fdata_txd_en='1' and (i_dma_dcnt=i_dma_trncount_dw or OR_reduce(i_dma_dcnt(log2(CI_FR_DWORD_COUNT_MAX)-1 downto 0))='0') then
                      if i_dma_dcnt=i_dma_trncount_dw then
                      --//������� ��� ������
                        i_fdata_txd_en<='0';
                        i_fdata_tx_en<='0';
                        fsm_tlayer_cs<=S_HT_DMAEnd;
                      else
                      --//��������� � ��������� ���������� �������� ������
                        i_fdone<='1';
                      end if;

                    else
                      i_fdata_txd_en<='1';
                      i_dma_dcnt<=i_dma_dcnt + 1;
                    end if;

                end if;--//if i_fdata_txd_en='0' then
            end if;--//if p_in_ll_txd_rd='1' then

        else
          --//���� ������� �� Link Layer
            if p_in_ll_status(C_LSTAT_TxERR_CRC)='1' or p_in_ll_status(C_LSTAT_TxOK)='1' then
              i_dma_txd<='0';
              i_fdata_txd_en<='0';
              i_fdata_tx_en<='0';
              i_fdone<='0';
              fsm_tlayer_cs <= S_IDLE;

            end if;

        end if;--//if if p_in_ll_status

      end if;--//if i_ll_state_illegal


    --//------------------------------------------
    --//����� DMA / ���������� �������
    --//------------------------------------------
    when S_HT_DMAEnd =>

      if i_ll_state_illegal='1' then
        i_dma_txd<='0';
        fsm_tlayer_cs <= S_IDLE;

      else

          if i_fdir_bit=C_DIR_D2H then
          --����� ������ (FPGA <- HDD)
              if i_rxd_err='0' then
                i_ll_ctrl(C_LCTRL_TL_CHECK_DONE_BIT)<='1';--//������ Link ������ ��������� �������� ������������� R_ERR/R_OK
              end if;

              fsm_tlayer_cs <= S_IDLE;

          else
          --�������� ������ (FPGA -> HDD)
              if i_dma_dcnt=i_dma_trncount_dw then
              --//������� ��� ������
                i_dma_dcnt<=(others=>'0');
              end if;

              if p_in_ll_status(C_LSTAT_TxERR_CRC)='1' then
                i_dma_txd<='0';
                fsm_tlayer_cs <= S_IDLE;

              elsif p_in_ll_status(C_LSTAT_TxOK)='1' then
                i_dma_txd<='0';
                fsm_tlayer_cs <= S_IDLE;

              end if;

          end if;

      end if;--//if i_ll_state_illegal

    --//------------------------------------------
    --//����� DMA / ����� ������
    --//------------------------------------------
    when S_HT_DMAITrans =>

      if i_ll_state_illegal='1' then
        i_rxd_en<='0';
        fsm_tlayer_cs <= S_IDLE;

      else

          if p_in_ll_status(C_LSTAT_RxOK)='1' or p_in_ll_status(C_LSTAT_RxERR_CRC)='1' then
          --//����� ������ ��������
              i_rxd_en<='0';

              if p_in_ll_status(C_LSTAT_RxERR_CRC)='1' then
                i_rxd_err<='1';
              elsif p_in_ll_status(C_LSTAT_RxOK)='1' then
                i_rxd_err<='0';
              end if;

              fsm_tlayer_cs <= S_HT_DMAEnd;

          end if;

      end if;--//if i_ll_state_illegal

  end case;

end if;
end process lfsm;



gen_sim_off : if strcmp(G_SIM,"OFF") generate
tst_val<='0';
end generate gen_sim_off;

--//----------------------------------------
--//������ ��� �������������
--//----------------------------------------
--��� �������� �������  ������ ��� ������������
gen_sim_on : if strcmp(G_SIM,"ON") generate

tst_tl_ctrl.ata_command<=p_in_tl_ctrl(C_TCTRL_RCOMMAND_WR_BIT);
tst_tl_ctrl.ata_control<=p_in_tl_ctrl(C_TCTRL_RCONTROL_WR_BIT);
tst_tl_ctrl.fpdma<=p_in_tl_ctrl(C_TCTRL_DMASETUP_WR_BIT);

tst_tl_status.txfh2d_en<=i_tl_status(C_TSTAT_TxFISHOST2DEV_BIT);
tst_tl_status.rxfistype_err<=i_tl_status(C_TSTAT_RxFISTYPE_ERR_BIT);
tst_tl_status.rxfislen_err<=i_tl_status(C_TSTAT_RxFISLEN_ERR_BIT);
tst_tl_status.txerr_crc_repeat<=i_tl_status(C_TSTAT_TxERR_CRC_REPEAT_BIT);
tst_tl_status.usr_busy<=i_tl_status(C_TSTAT_USR_BUSY_BIT);

process(p_in_tl_ctrl,i_tl_status)
begin

  if tst_tl_status.rxfistype_err='1' or
     tst_tl_ctrl.ata_command='1' then
    tst_val<='1';
  else
    tst_val<='0';
  end if;
end process;

end generate gen_sim_on;

--END MAIN
end behavioral;