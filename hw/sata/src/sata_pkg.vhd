------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 07.02.2011 10:47:04
-- Module Name : sata_pkg
--
-- Description : ���������/���� ������/
--               ������������ � ������� SATA
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;

library work;
use work.vicg_common_pkg.all;

package sata_pkg is

---------------------------------------------------------
--����
---------------------------------------------------------
type T04GTCHCount is array (0 to 3) of integer;
type T08SHCount is array (0 to 7) of integer;
type T08SHCountSel is array (0 to 1) of T08SHCount;
type T8x08SHCountSel is array (0 to 7) of T08SHCountSel;


---------------------------------------------------------
--User Cfg
---------------------------------------------------------
--//��������� ��� FPGA:
--//0 - "V5_GTP"
--//1 - "V5_GTX"
--//2 - "V6_GTX"
--//3 - "S6_GTPA"
constant C_FPGA_TYPE         : integer:=0;
constant C_SH_MAIN_NUM       : integer:=0; --//���������� ������ GT ������ �� �������� ����� ����� ������� ��� ������������ sata_dcm.vhd


---------------------------------------------------------
--���������
---------------------------------------------------------
--//��� ���-�� HDD:
constant C_HDD_COUNT_MAX     : integer:=2;--//

--//���-�� ������� � ����� ������ GT:
constant C_GTCH_COUNT_MAX_SEL: T04GTCHCount:=(2, 2, 1, 2);--//�ax ���-�� ������� ��� ������ ���������� GT(gig tx/rx)
constant C_GTCH_COUNT_MAX    : integer:=C_GTCH_COUNT_MAX_SEL(C_FPGA_TYPE);


--//����� ���-�� ������� GT:
---------------------------------------------------------------------------
--//G_HDD_COUNT - ��������:               | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
---------------------------------------------------------------------------
constant C_2CGT_COUNT      : T08SHCount:=(  1,  1,  2,  2,  3,  3,  4,  4 );--//��� GT � ����� ��������(DUAL)
constant C_1CGT_COUNT      : T08SHCount:=(  1,  2,  3,  4,  5,  6,  7,  8 );--//��� GT c ����� �������
constant C_GT_COUNT_SEL    : T08SHCountSel:=(C_1CGT_COUNT, C_2CGT_COUNT);

constant C_SH_COUNT_MAX    : T08SHCount:=C_GT_COUNT_SEL(C_GTCH_COUNT_MAX-1);

--//���-�� ����������� ������� � ������ sata_host.vhd
----------------------------------------------------------------------------------------
--//G_HDD_COUNT - ��������:       | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |   / ���-�� RocketIO |
----------------------------------------------------------------------------------------
--//GT � ����� ��������(DUAL)
--//Virtex5
constant C_2CGT0_CH : T08SHCount:=( 1,  2,  2,  2,  2,  2,  2,  2 );--|  1              |
constant C_2CGT1_CH : T08SHCount:=( 0,  0,  1,  2,  2,  2,  2,  2 );--|  2              |
constant C_2CGT2_CH : T08SHCount:=( 0,  0,  0,  0,  1,  2,  2,  2 );--|  3              |
constant C_2CGT3_CH : T08SHCount:=( 0,  0,  0,  0,  0,  0,  1,  2 );--|  4              |
constant C_2CGT4_CH : T08SHCount:=( 0,  0,  0,  0,  0,  0,  0,  0 );--|                 |
constant C_2CGT5_CH : T08SHCount:=( 0,  0,  0,  0,  0,  0,  0,  0 );--|                 |
constant C_2CGT6_CH : T08SHCount:=( 0,  0,  0,  0,  0,  0,  0,  0 );--|                 |
constant C_2CGT7_CH : T08SHCount:=( 0,  0,  0,  0,  0,  0,  0,  0 );--|                 |
--//GT c ����� �������
--//Virtex6
constant C_1CGT0_CH : T08SHCount:=( 1,  1,  1,  1,  1,  1,  1,  1 );--|  1              |
constant C_1CGT1_CH : T08SHCount:=( 0,  1,  1,  1,  1,  1,  1,  1 );--|  2              |
constant C_1CGT2_CH : T08SHCount:=( 0,  0,  1,  1,  1,  1,  1,  1 );--|  3              |
constant C_1CGT3_CH : T08SHCount:=( 0,  0,  0,  1,  1,  1,  1,  1 );--|  4              |
constant C_1CGT4_CH : T08SHCount:=( 0,  0,  0,  0,  1,  1,  1,  1 );--|  5              |
constant C_1CGT5_CH : T08SHCount:=( 0,  0,  0,  0,  0,  1,  1,  1 );--|  6              |
constant C_1CGT6_CH : T08SHCount:=( 0,  0,  0,  0,  0,  0,  1,  1 );--|  7              |
constant C_1CGT7_CH : T08SHCount:=( 0,  0,  0,  0,  0,  0,  0,  1 );--|  8              |

constant C_GT0_CH_COUNT : T08SHCountSel:=(C_1CGT0_CH, C_2CGT0_CH);
constant C_GT1_CH_COUNT : T08SHCountSel:=(C_1CGT1_CH, C_2CGT1_CH);
constant C_GT2_CH_COUNT : T08SHCountSel:=(C_1CGT2_CH, C_2CGT2_CH);
constant C_GT3_CH_COUNT : T08SHCountSel:=(C_1CGT3_CH, C_2CGT3_CH);
constant C_GT4_CH_COUNT : T08SHCountSel:=(C_1CGT4_CH, C_2CGT4_CH);
constant C_GT5_CH_COUNT : T08SHCountSel:=(C_1CGT5_CH, C_2CGT5_CH);
constant C_GT6_CH_COUNT : T08SHCountSel:=(C_1CGT6_CH, C_2CGT6_CH);
constant C_GT7_CH_COUNT : T08SHCountSel:=(C_1CGT7_CH, C_2CGT7_CH);



--//-------------------------------------------------
--//User Global Ctrl
--//-------------------------------------------------
constant C_USR_GCTRL_CLR_ERR_BIT         : integer:=0;
constant C_USR_GCTRL_CLR_BUF_BIT         : integer:=1;
constant C_USR_GCTRL_ATADONE_ACK_BIT     : integer:=2;
constant C_USR_GCTRL_TST_ON_BIT          : integer:=3;
constant C_USR_GCTRL_TST_RANDOM_BIT      : integer:=4;
constant C_USR_GCTRL_RAMBUF_ERR_BIT      : integer:=5;
constant C_USR_GCTRL_RESERV_BIT          : integer:=6;
constant C_USR_GCTRL_LAST_BIT            : integer:=C_USR_GCTRL_RESERV_BIT;


--//-------------------------------------------------
--//User Application Layer
--//-------------------------------------------------
--//������ ���������� ������ � WORD
constant C_USRAPP_CMDPKT_SIZE_WORD       : integer:=8;

--//User CMD Pkt :
--//���� UsrCtrl/Map:
constant C_CMDPKT_SATA_CS_L_BIT          : integer:=0;
constant C_CMDPKT_SATA_CS_M_BIT          : integer:=7;
constant C_CMDPKT_RAIDCMD_L_BIT          : integer:=8;
constant C_CMDPKT_RAIDCMD_M_BIT          : integer:=10;
--constant C_CMDPKT_RESERV0_BIT            : integer:=11;
constant C_CMDPKT_SATACMD_L_BIT          : integer:=12;
constant C_CMDPKT_SATACMD_M_BIT          : integer:=14;
--constant C_CMDPKT_RESERV1_BIT            : integer:=15;

--//(C_CMDPKT_RAIDCMD_M downto C_CMDPKT_RAIDCMD_L)/Map:
constant C_RAIDCMD_STOP                   : integer:=0; --//������ �� ����������� ���������
constant C_RAIDCMD_SW                     : integer:=1; --//������ �� ����������� ���������
constant C_RAIDCMD_HW                     : integer:=2; --//���������� ������
constant C_RAIDCMD_LBAEND                 : integer:=3;--//��������� ��������� ������ LBA (��� ������ � ������ HW)
--constant C_RAIDCMD_TSTW                   : integer:=4;
--constant C_RAIDCMD_TSTR                   : integer:=5;

--//(C_CMDPKT_SATACMD_M downto C_CMDPKT_SATACMD_L)/Map:
constant C_SATACMD_NULL                   : integer:=0;
constant C_SATACMD_ATACOMMAND             : integer:=1;
constant C_SATACMD_ATACONTROL             : integer:=2;
constant C_SATACMD_FPDMA_W                : integer:=3;
constant C_SATACMD_FPDMA_R                : integer:=4;
constant C_SATACMD_SET_SATA1              : integer:=5;
constant C_SATACMD_SET_SATA2              : integer:=6;
constant C_SATACMD_COUNT                  : integer:=C_SATACMD_SET_SATA2+1;


--//-------------------------------------------------
--//Application Layer
--//-------------------------------------------------
--//Register / Adress Map:
constant C_ALREG_USRCTRL                 : integer:=16#00#;
constant C_ALREG_FEATURE                 : integer:=16#01#;
constant C_ALREG_LBA_LOW                 : integer:=16#02#;
constant C_ALREG_LBA_MID                 : integer:=16#03#;
constant C_ALREG_LBA_HIGH                : integer:=16#04#;
constant C_ALREG_SECTOR_COUNT            : integer:=16#05#;
constant C_ALREG_DEVICE                  : integer:=16#06#;-- + C_ALREG_DEV_CONTROL
constant C_ALREG_COMMAND                 : integer:=16#07#;

--//�������� ATA / Bit Map:
--//������� ATA_COMMAND/ Commad Map:
constant C_ATA_CMD_IDENTIFY_DEV          : integer:=16#EC#;
constant C_ATA_CMD_IDENTIFY_PACKET_DEV   : integer:=16#A1#;
constant C_ATA_CMD_NOP                   : integer:=16#00#;
constant C_ATA_CMD_WRITE_SECTORS_EXT     : integer:=16#34#;--//PIO Write
constant C_ATA_CMD_READ_SECTORS_EXT      : integer:=16#24#;--//PIO Read
constant C_ATA_CMD_WRITE_DMA_EXT         : integer:=16#35#;--//DMA Write
constant C_ATA_CMD_READ_DMA_EXT          : integer:=16#25#;--//DMA Read
constant C_ATA_CMD_WRITE_FPDMA_QUEUED    : integer:=16#61#;--//QUEUED FPDMA Write
constant C_ATA_CMD_READ_FPDMA_QUEUED     : integer:=16#60#;--//QUEUED FPDMA Read
constant C_ATA_CMD_READ_LOG_EXT          : integer:=16#2F#;--//

--//������� ATA_STATUS/Bit Map:
constant C_ATA_STATUS_BUSY_BIT           : integer:=7;--���-�� ������
constant C_ATA_STATUS_DRDY_BIT           : integer:=6;--���-�� ������ � �������� �������
constant C_ATA_STATUS_DRQ_BIT            : integer:=3;--���-�� ������ � ������ �������
constant C_ATA_STATUS_ERR_BIT            : integer:=0;--������

--//������� ATA_DEV_CONTROL/Bit Map:
constant C_ATA_DEV_CONTROL_nIEN_BIT      : integer:=1;--������������ ������� ����������(0/1 - ���������/���������)
constant C_ATA_DEV_CONTROL_SRST_BIT      : integer:=2;--
constant C_ATA_IRQ_ON                    : std_logic:='0';
constant C_ATA_IRQ_OFF                   : std_logic:='1';

--//������� ATA_DEVICE/Bit Map:
constant C_ATA_DEVICE_LBA_BIT            : integer:=6;--����� ���������. 1/0 - LBA/CHS (��������/����������). � ����� ������ ��������� ������ LBA!!!

--//������� ATA_ERROR/Bit Map:
constant C_ATA_ERROR_ABRT_BIT            : integer:=2;--command aborted



--//����������/Map:
--//��. ������ User Global Ctrl

--//�������/Map:
--//���� - SStatus/Map:
--//����� �������� ��. d1532v3r4b ATA-ATAPI-7.pdf �.�.19.2.1
constant C_ASSTAT_DET_BIT_L              : integer:=0;
constant C_ASSTAT_DET_BIT_M              : integer:=3;
constant C_ASSTAT_SPD_BIT_L              : integer:=4;
constant C_ASSTAT_SPD_BIT_M              : integer:=7;
constant C_ASSTAT_IPM_BIT_L              : integer:=8;
constant C_ASSTAT_IPM_BIT_M              : integer:=11;
constant C_ASSTAT_RESERV_BIT             : integer:=12;
constant C_ALSSTAT_LAST_BIT              : integer:=C_ASSTAT_RESERV_BIT;

--//SStatus/DET/Map:
constant C_ASSTAT_DET_NODEV              : integer:=0;
constant C_ASSTAT_DET_DEVICE             : integer:=1;
constant C_ASSTAT_DET_LINK_ESTABLISH     : integer:=3;


--//���� - SError/Map:
--//����� �������� ��. d1532v3r4b ATA-ATAPI-7.pdf �.�.19.2.2
constant C_ASERR_I_ERR_BIT               : integer:=0;
--constant C_ASERR_M_ERR_BIT               : integer:=1;--//�� ���������
--constant C_ASERR_T_ERR_BIT               : integer:=8;--//�� ���������
constant C_ASERR_ATAERR_DIAG_L_BIT       : integer:=1;--//������� shadow_error
constant C_ASERR_ATAERR_DIAG_M_BIT       : integer:=8;--//

constant C_ASERR_C_ERR_BIT               : integer:=9;
constant C_ASERR_P_ERR_BIT               : integer:=10;
--constant C_ASERR_E_ERR_BIT               : integer:=11;--//�� ���������
constant C_ASERR_ATA_ERR_BIT             : integer:=11;

constant C_ASERR_N_DIAG_BIT              : integer:=16;--//PHY Layer:if (i_link_establish_change='1' and i_usrmode(C_USRCMD_SET_SATA1)='0' and i_usrmode(C_USRCMD_SET_SATA2)='0') then
constant C_ASERR_I_DIAG_BIT              : integer:=17;--//�� ���������
constant C_ASERR_W_DIAG_BIT              : integer:=18;--//PHY Layer:if p_in_pl_status(C_PSTAT_COMWAKE_RCV_BIT)='1' then
constant C_ASERR_B_DIAG_BIT              : integer:=19;--//PHY Layer:if p_in_pl_status(C_PSTAT_DET_ESTABLISH_ON_BIT)='1' and p_in_pl_status(C_PRxSTAT_ERR_NOTINTABLE_BIT)='1' then
constant C_ASERR_D_DIAG_BIT              : integer:=20;--//PHY Layer:if p_in_pl_status(C_PSTAT_DET_ESTABLISH_ON_BIT)='1' and p_in_pl_status(C_PRxSTAT_ERR_DISP_BIT)='1' then
constant C_ASERR_C_DIAG_BIT              : integer:=21;--//Link Layer: --//CRC ERROR
constant C_ASERR_H_DIAG_BIT              : integer:=22;--//Link Layer: --//1/0 - CRC ERROR on (send FIS/rcv FIS)
constant C_ASERR_S_DIAG_BIT              : integer:=23;--//Link Layer:if p_in_ll_status(C_LSTAT_RxERR_IDLE)='1' or p_in_ll_status(C_LSTAT_TxERR_IDLE)='1' then
constant C_ASERR_T_DIAG_BIT              : integer:=24;--//Link Layer:if p_in_ll_status(C_LSTAT_RxERR_ABORT)='1' or p_in_ll_status(C_LSTAT_TxERR_ABORT)='1' then
constant C_ASERR_F_DIAG_BIT              : integer:=25;--//Transport Layer: FIS CRC-OK, but FISTYPE/FISLEN ERROR

constant C_ASERR_DET_L_BIT               : integer:=26;--//PHY Layer: C_PSTAT_DET_DEV_ON_BIT
constant C_ASERR_DET_M_BIT               : integer:=27;--//PHY Layer: C_PSTAT_DET_ESTABLISH_ON_BIT
constant C_ASERR_SPD_L_BIT               : integer:=28;--//PHY Layer: SATA speed negatiation
constant C_ASERR_SPD_M_BIT               : integer:=30;
constant C_ASERR_IPM_L_BIT               : integer:=31;--//i_reg_shadow.status(C_ATA_STATUS_DRDY_BIT)

constant C_ALSERR_LAST_BIT               : integer:=C_ASERR_IPM_L_BIT;

--//���� - User/Map:
constant C_AUSER_BUSY_BIT                : integer:=0;
constant C_AUSER_DWR_START_BIT           : integer:=1;--//������������ ������������ ������ hdd_rambuf.vhd ������ ������ ���
constant C_AUSER_LLRXP_HOLD_BIT          : integer:=2;--
constant C_AUSER_LLTXP_HOLD_BIT          : integer:=3;--
constant C_AUSER_TLTX_ON_BIT             : integer:=4;--
constant C_AUSER_TLRX_ON_BIT             : integer:=5;--
--constant C_AUSER_LLTX_ON_BIT             : integer:=6;--
--constant C_AUSER_LLRX_ON_BIT             : integer:=7;--
constant C_AUSER_RESERV_BIT              : integer:=7;
constant C_ALUSER_LAST_BIT               : integer:=C_AUSER_RESERV_BIT;


--//-------------------------------------------------
--//Transport Layer
--//-------------------------------------------------
--//����������/Map:
constant C_TCTRL_RCOMMAND_WR_BIT         : integer:=16#00#;
constant C_TCTRL_RCONTROL_WR_BIT         : integer:=16#01#;
constant C_TLCTRL_LAST_BIT               : integer:=C_TCTRL_RCONTROL_WR_BIT;

--//�������/Map:
constant C_TSTAT_RxFISTYPE_ERR_BIT       : integer:=0;--//Transport Layer �� ���� ���������� ��� ��������� ������
constant C_TSTAT_RxFISLEN_ERR_BIT        : integer:=1;--//
constant C_TSTAT_TxERR_CRC_REPEAT_BIT    : integer:=2;--//���� ������� ��������� ������� ��������� FIS_H2D, �� ������ ��� ������� �� Link Layer C_LSTAT_TxERR_CRC
constant C_TSTAT_TxFISHOST2DEV_BIT       : integer:=3;--//������������� ��� ���� �������� FIS_HOST2DEV
constant C_TSTAT_DWR_START_BIT           : integer:=4;--//������������ ������ hdd_rambuf.vhd ������ ������ ���
constant C_TSTAT_FSMTxD_ON_BIT           : integer:=5;--//��� ��������� ��������
constant C_TSTAT_FSMRxD_ON_BIT           : integer:=6;--//��� ��������� ��������
constant C_TLSTAT_LAST_BIT               : integer:=C_TSTAT_FSMRxD_ON_BIT;

--//FIS Type:
constant C_FIS_REG_HOST2DEV              : integer:=16#27#;
constant C_FIS_REG_DEV2HOST              : integer:=16#34#;
constant C_FIS_DMA_ACTIVATE              : integer:=16#39#;
constant C_FIS_DMASETUP                  : integer:=16#41#;
constant C_FIS_DATA                      : integer:=16#46#;
constant C_FIS_BIST_ACTIVATE             : integer:=16#58#;
constant C_FIS_PIOSETUP                  : integer:=16#5F#;
constant C_FIS_SET_DEV_BITS              : integer:=16#A1#;
constant C_FIS_RESERV0                   : integer:=16#A6#;
constant C_FIS_RESERV1                   : integer:=16#B8#;
constant C_FIS_RESERV2                   : integer:=16#BF#;
constant C_FIS_VENDOR_SPEC0              : integer:=16#C7#;
constant C_FIS_VENDOR_SPEC1              : integer:=16#D4#;
constant C_FIS_RESERV3                   : integer:=16#D9#;

--//FIS Bit Map:
constant C_FIS_DIR_BIT                   : integer:=16#05#;
constant C_FIS_INT_BIT                   : integer:=16#06#;
constant C_FIS_AUTO_ACTIVATE_BIT         : integer:=16#07#;
constant C_DIR_H2D                       : std_logic:='0';
constant C_DIR_D2H                       : std_logic:='1';

--//FIS Length:
constant C_FIS_REG_HOST2DEV_DWSIZE       : integer:=5;
constant C_FIS_REG_DEV2HOST_DWSIZE       : integer:=5;
constant C_FIS_DMA_ACTIVATE_DWSIZE       : integer:=1;
constant C_FIS_DMASETUP_DWSIZE           : integer:=7;
constant C_FIS_BIST_ACTIVATE_DWSIZE      : integer:=3;
constant C_FIS_PIOSETUP_DWSIZE           : integer:=5;
constant C_FIS_SET_DEV_BITS_DWSIZE       : integer:=2;

type TTL_fsm_state is
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
--S_HT_DmaSetupFIS,        --//�������� FIS_DMASETUP
--S_HT_DmaSetupTransStatus,

S_HT_DS_FIS,     --//����� FIS_DMASETUP

S_HT_DMA_FIS,    --�����/��������� FIS_DMA_ACTIVATE
S_HT_DMAOTrans1, --�������� ������ �� SATA
S_HT_DMAOTrans2,
S_HT_DMAEnd,
S_HT_DMAITrans   --����� ������ �� SATA

);

--//-------------------------------------------------
--//Link Layer
--//-------------------------------------------------
--//����������/Map:
constant C_LCTRL_TxSTART_BIT              : integer:=16#00#;--//Transport Layer ����� ������ �������� ������
constant C_LCTRL_TRN_ESCAPE_BIT           : integer:=16#01#;--//Transport Layer ����� �������� ������� ����������
constant C_LCTRL_TL_CHECK_ERR_BIT         : integer:=16#02#;--//Transport Layer ������������� ��� ��������� ������ ��� �������� ����������� ������: FITYPE_ERR, FISLEN_ERR
constant C_LCTRL_TL_CHECK_DONE_BIT        : integer:=16#03#;--//Transport Layer �������� �������� ����������� ������
--constant C_LCTRL_PARTIAL_BIT             : integer:=16#04#;
--constant C_LCTRL_SLUMBER_BIT             : integer:=16#05#;
constant C_LLCTRL_LAST_BIT                 : integer:=C_LCTRL_TL_CHECK_DONE_BIT;

--//�������/Map:
constant C_LSTAT_RxOK                     : integer:=0;--//����� ������ - ��
constant C_LSTAT_RxSTART                  : integer:=1;--//����� ������ - Link Layer ��������� SOF - ����� ����� ������
constant C_LSTAT_RxERR_CRC                : integer:=2;--//����� ������ - ������: CRC
constant C_LSTAT_RxERR_IDLE               : integer:=3;--//����� ������ - ������: ������ �������� �������� �� ������
constant C_LSTAT_RxERR_ABORT              : integer:=4;--//����� ������ - ������: ������ �������� SYNC
constant C_LSTAT_TxOK                     : integer:=5;--//�������� ������ - ��
constant C_LSTAT_TxDMAT                   : integer:=6;--//�������� ������ - ������ �������� DMA - Terminate
constant C_LSTAT_TxERR_CRC                : integer:=7;--//�������� ������ - ������: CRC
constant C_LSTAT_TxERR_IDLE               : integer:=8;--//�������� ������ - ������: ������ �������� �������� �� ������
constant C_LSTAT_TxERR_ABORT              : integer:=9;--//�������� ������ - ������: ������ �������� SYNC
constant C_LSTAT_TxHOLD                   : integer:=10;--//��� ��������� ��������
constant C_LSTAT_RxHOLD                   : integer:=11;--//��� ��������� ��������
constant C_LLSTAT_LAST_BIT                : integer:=C_LSTAT_RxHOLD;

--//�������� ����������� � �������� ������ �� ��������� S_LT_SendHold �������� ���������� Link Layer
constant C_LL_TXDATA_RETURN_TMR          : integer:=20;

type TLL_fsm_state is
(
--------------------------------------------
-- Link idle states.
--------------------------------------------
S_L_RESET,
S_L_IDLE,
S_L_SyncEscape,
S_L_NoCommErr,
S_L_NoComm,
S_L_SendAlign,

----------------------------------------------
---- Link transfer states.
----------------------------------------------
S_LT_H_SendChkRdy,
S_LT_SendSOF,
S_LT_SendData,
S_LT_SendCRC,
S_LT_SendEOF,
S_LT_Wait,
S_LT_RcvrHold,
S_LT_SendHold,

--------------------------------------------
-- Link reciever states.
--------------------------------------------
S_LR_RcvChkRdy,
S_LR_RcvWaitFifo,
S_LR_RcvData,
S_LR_Hold,
S_LR_SendHold,
S_LR_RcvEOF,
S_LR_GoodCRC,
S_LR_GoodEnd,
S_LR_BadEnd

);

--//-------------------------------------------------
--//PHY Layer
--//-------------------------------------------------
--//PHY Layer /Reciver
--//�������/Map:
constant C_PRxSTAT_ERR_DISP_BIT          : integer:=0;--//������ - received with a disparity error.
constant C_PRxSTAT_ERR_NOTINTABLE_BIT    : integer:=1;--//������ - indicates that RXDATA is the result of an illegal 8B/10B code
constant C_PRxSTAT_LAST_BIT              : integer:=C_PRxSTAT_ERR_NOTINTABLE_BIT;

--//����������/Map:
constant C_PCTRL_SPD_BIT_L               : integer:=0;
constant C_PCTRL_SPD_BIT_M               : integer:=1;
constant C_PLCTRL_LAST_BIT               : integer:=C_PCTRL_SPD_BIT_M;

--//�������/Map:
constant C_PSTAT_DET_DEV_ON_BIT          : integer:=C_PRxSTAT_LAST_BIT + 1;--//��������������: 0/1 - ���������� �� ����������/���������� �� ���������� �� �����������!!
constant C_PSTAT_DET_ESTABLISH_ON_BIT    : integer:=C_PRxSTAT_LAST_BIT + 2;--//��������������: 0/1 - ���������� � ����������� �� �����������/����������� (����� ��������)
constant C_PSTAT_SPD_BIT_L               : integer:=C_PRxSTAT_LAST_BIT + 3;--//C������� ����������: "00"/"01"/"10" -  �� �����������/Gen1/Gen2
constant C_PSTAT_SPD_BIT_M               : integer:=C_PRxSTAT_LAST_BIT + 4;
constant C_PSTAT_COMWAKE_RCV_BIT         : integer:=C_PRxSTAT_LAST_BIT + 5;--//0/1 - ������ COMWAKE �� ��������� �� ������/������
constant C_PLSTAT_LAST_BIT               : integer:=C_PSTAT_COMWAKE_RCV_BIT;

type TPLoob_fsm_state is
(
S_HR_IDLE,
S_HR_COMRESET,
S_HR_COMRESET_DONE,
S_HR_AwaitCOMINIT,
S_HR_AwaitNoCOMINIT,
S_HR_Calibrate,
S_HR_COMWAKE,
S_HR_COMWAKE_DONE,
S_HR_AwaitCOMWAKE,
S_HR_AwaitNoCOMWAKE,
S_HR_AwaitAlign,
S_HR_SendAlign,
S_HR_Connect,
S_HR_Disconnect
);

--//sata_player_tx.vhd
--//�������� ��������� ALIGN
constant C_ALIGN_TMR                     : integer:=256;--//������ �������� ���������� ALIGN (������ ������ ��������!!!)
constant C_ALIGN_BURST                   : integer:=2;  --//���-�� ������������ ���������� �� ���� ��� (������ ������ ��������!!!)

--//������ ������� � BYTE
constant C_SECTOR_SIZE_BYTE              : integer:=512;
--max ���-�� Dword � FISDATA ����� SOF � EOF, �������� FISTYPE � CRC
constant C_FR_DWORD_COUNT_MAX            : integer:=2048;

--//sata_player_oob.vhd
constant C_OOB_TIMEOUT_880us             : integer:=10#66000#; --=880us �� 75MHz
constant C_OOB_TIMEOUT_10ms              : integer:=10#750000#;--=10ms �� 75MHz

--//������ ������������ SATA
--//�����: ������� ��� ���������, ����� ����� ������ ������� ����� sata_spd_ctrl.vhd sata_host.vhd
constant C_FSATA_GEN1 : integer:=0;
constant C_FSATA_GEN2 : integer:=1;
constant C_FSATA_GEN_COUNT : integer:=2;
constant C_FSATA_GEN_DEFAULT : integer:=C_FSATA_GEN2;


--��� ������� � 8b/10b
constant C_CHAR_K: std_logic:='1';
constant C_CHAR_D: std_logic:='0';

--���� 8b/10b
constant C_K28_5 : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(16#BC#, 8);
constant C_K28_3 : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(16#7C#, 8);

constant C_D10_2 : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(16#4A#, 8);
constant C_D10_5 : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(16#AA#, 8);
constant C_D21_1 : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(16#35#, 8);
constant C_D21_2 : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(16#55#, 8);
constant C_D21_3 : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(16#75#, 8);
constant C_D21_4 : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(16#95#, 8);
constant C_D21_5 : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(16#B5#, 8);
constant C_D21_6 : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(16#D5#, 8);
constant C_D21_7 : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(16#F5#, 8);
constant C_D22_1 : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(16#36#, 8);
constant C_D22_2 : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(16#56#, 8);
constant C_D23_0 : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(16#17#, 8);
constant C_D23_1 : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(16#37#, 8);
constant C_D23_2 : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(16#57#, 8);
constant C_D24_2 : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(16#58#, 8);
constant C_D25_4 : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(16#99#, 8);
constant C_D27_3 : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(16#7B#, 8);

--��������� SATA
constant C_PDAT_ALIGN  : std_logic_vector(31 downto 0):=C_D27_3&C_D10_2&C_D10_2&C_K28_5;
constant C_PDAT_SOF    : std_logic_vector(31 downto 0):=C_D23_1&C_D23_1&C_D21_5&C_K28_3;
constant C_PDAT_EOF    : std_logic_vector(31 downto 0):=C_D21_6&C_D21_6&C_D21_5&C_K28_3;
constant C_PDAT_DMAT   : std_logic_vector(31 downto 0):=C_D22_1&C_D22_1&C_D21_5&C_K28_3;
constant C_PDAT_CONT   : std_logic_vector(31 downto 0):=C_D25_4&C_D25_4&C_D10_5&C_K28_3;
constant C_PDAT_SYNC   : std_logic_vector(31 downto 0):=C_D21_5&C_D21_5&C_D21_4&C_K28_3;
constant C_PDAT_HOLD   : std_logic_vector(31 downto 0):=C_D21_6&C_D21_6&C_D10_5&C_K28_3;
constant C_PDAT_HOLDA  : std_logic_vector(31 downto 0):=C_D21_4&C_D21_4&C_D10_5&C_K28_3;
constant C_PDAT_X_RDY  : std_logic_vector(31 downto 0):=C_D23_2&C_D23_2&C_D21_5&C_K28_3;
constant C_PDAT_R_RDY  : std_logic_vector(31 downto 0):=C_D10_2&C_D10_2&C_D21_4&C_K28_3;
constant C_PDAT_R_IP   : std_logic_vector(31 downto 0):=C_D21_2&C_D21_2&C_D21_5&C_K28_3;
constant C_PDAT_R_OK   : std_logic_vector(31 downto 0):=C_D21_1&C_D21_1&C_D21_5&C_K28_3;
constant C_PDAT_R_ERR  : std_logic_vector(31 downto 0):=C_D22_2&C_D22_2&C_D21_5&C_K28_3;
constant C_PDAT_WTRM   : std_logic_vector(31 downto 0):=C_D24_2&C_D24_2&C_D21_5&C_K28_3;
constant C_PDAT_PMREQ_P: std_logic_vector(31 downto 0):=C_D23_0&C_D23_0&C_D21_5&C_K28_3;
constant C_PDAT_PMREQ_S: std_logic_vector(31 downto 0):=C_D21_3&C_D21_3&C_D21_4&C_K28_3;
constant C_PDAT_PMACK  : std_logic_vector(31 downto 0):=C_D21_4&C_D21_4&C_D21_4&C_K28_3;
constant C_PDAT_PMNAK  : std_logic_vector(31 downto 0):=C_D21_7&C_D21_7&C_D21_4&C_K28_3;

constant C_PDAT_TPRM   : std_logic_vector(3 downto 0):=C_CHAR_D&C_CHAR_D&C_CHAR_D&C_CHAR_K;
constant C_PDAT_TDATA  : std_logic_vector(3 downto 0):=C_CHAR_D&C_CHAR_D&C_CHAR_D&C_CHAR_D;


--//������ ����������
--//������ ������ --- ��� ����� ���� �� ����� p_out_rxtype
--//������ �������� - ��� ����� ����������
constant C_TALIGN   : integer:=0;
constant C_TSYNC    : integer:=1;
constant C_TSOF     : integer:=2;
constant C_TEOF     : integer:=3;
constant C_THOLDA   : integer:=4;
constant C_THOLD    : integer:=5;
constant C_TCONT    : integer:=6;
constant C_TDMAT    : integer:=7;
constant C_TX_RDY   : integer:=8;
constant C_TR_RDY   : integer:=9;
constant C_TR_IP    : integer:=10;
constant C_TR_OK    : integer:=11;
constant C_TR_ERR   : integer:=12;
constant C_TWTRM    : integer:=13;
constant C_TPMREQ_P : integer:=14;
constant C_TPMREQ_S : integer:=15;
constant C_TPMACK   : integer:=16;
constant C_TPMNAK   : integer:=17;
constant C_TDATA_EN : integer:=18;--//������
constant C_TD10_2   : integer:=19;
constant C_TNONE    : integer:=20;


---------------------------------------------------------
--����
---------------------------------------------------------
type TBus02_GTCH is array (0 to C_GTCH_COUNT_MAX-1) of std_logic_vector (1 downto 0);
type TBus03_GTCH is array (0 to C_GTCH_COUNT_MAX-1) of std_logic_vector (2 downto 0);
type TBus04_GTCH is array (0 to C_GTCH_COUNT_MAX-1) of std_logic_vector (3 downto 0);
type TBus07_GTCH is array (0 to C_GTCH_COUNT_MAX-1) of std_logic_vector (6 downto 0);
type TBus08_GTCH is array (0 to C_GTCH_COUNT_MAX-1) of std_logic_vector (7 downto 0);
type TBus16_GTCH is array (0 to C_GTCH_COUNT_MAX-1) of std_logic_vector (15 downto 0);
type TBus21_GTCH is array (0 to C_GTCH_COUNT_MAX-1) of std_logic_vector (20 downto 0);
type TBus32_GTCH is array (0 to C_GTCH_COUNT_MAX-1) of std_logic_vector (31 downto 0);

--//
type TUsrCmdPkt is record
ctrl         : std_logic_vector(15 downto 0);
feature      : std_logic_vector(15 downto 0);
lba          : std_logic_vector(47 downto 0);
scount       : std_logic_vector(15 downto 0);
command      : std_logic_vector(7 downto 0);
control      : std_logic_vector(7 downto 0);
device       : std_logic_vector(7 downto 0);
--reserv       : std_logic_vector(7 downto 0);
end record;


--//
type TRegHold is record
device       : std_logic_vector(7 downto 0);
status       : std_logic_vector(7 downto 0);
error        : std_logic_vector(7 downto 0);
lba_low      : std_logic_vector(7 downto 0);
lba_low_exp  : std_logic_vector(7 downto 0);
lba_mid      : std_logic_vector(7 downto 0);
lba_mid_exp  : std_logic_vector(7 downto 0);
lba_high     : std_logic_vector(7 downto 0);
lba_high_exp : std_logic_vector(7 downto 0);
scount       : std_logic_vector(7 downto 0);
scount_exp   : std_logic_vector(7 downto 0);
e_status     : std_logic_vector(7 downto 0);
tsf_count    : std_logic_vector(15 downto 0);
sb_error     : std_logic_vector(7 downto 0);
sb_status    : std_logic_vector(7 downto 0);
end record;

--//
type TRegShadow is record
command      : std_logic_vector(7 downto 0);
status       : std_logic_vector(7 downto 0);
error        : std_logic_vector(7 downto 0);
device       : std_logic_vector(7 downto 0);
control      : std_logic_vector(7 downto 0);
lba_low      : std_logic_vector(7 downto 0);
lba_low_exp  : std_logic_vector(7 downto 0);
lba_mid      : std_logic_vector(7 downto 0);
lba_mid_exp  : std_logic_vector(7 downto 0);
lba_high     : std_logic_vector(7 downto 0);
lba_high_exp : std_logic_vector(7 downto 0);
scount       : std_logic_vector(7 downto 0);
scount_exp   : std_logic_vector(7 downto 0);
feature      : std_logic_vector(7 downto 0);
feature_exp  : std_logic_vector(7 downto 0);
end record;

type TRegShadowUpdate is record
fd2h      : std_logic;--//���������� Shadow Reg �� ������ FIS_DEV2HOST
fpio      : std_logic;--//���������� Shadow Reg �� ������ FIS_PIOSETUP
fpio_e    : std_logic;--//���������� Shadow Reg � ���������� ����������� ���������� ��� ��������
fsdb      : std_logic;--//���������� Shadow Reg �� ������ FIS_SetDevice_Bits
end record;

type TRegFPDMASetup is record
dir           : std_logic;--//��. ��������� C_DIR_H2D/C_DIR_D2H
addr          : std_logic_vector(63 downto 0);
offset        : std_logic_vector(31 downto 0);
trncount_byte : std_logic_vector(31 downto 0);
end record;

--//
type TALStatus is record
ATAStatus : std_logic_vector(7 downto 0);
ATAError  : std_logic_vector(7 downto 0);
--SStatus   : std_logic_vector(C_ALSSTAT_LAST_BIT downto 0);
SError    : std_logic_vector(C_ALSERR_LAST_BIT downto 0);
Usr       : std_logic_vector(C_ALUSER_LAST_BIT downto 0);
fpdma     : TRegFPDMASetup;
end record;

type TTxBufStatus is record
full    : std_logic;--//full
pfull   : std_logic;--//prog full
aempty  : std_logic;--//almost empty
empty   : std_logic;--//empty
rdcount : std_logic_vector(3 downto 0);
--wrcount : std_logic_vector(3 downto 0);
end record;

type TRxBufStatus is record
full    : std_logic;--//full
pfull   : std_logic;--//prog full
empty   : std_logic;--//empty
wrcount : std_logic_vector(3 downto 0);
end record;

type TMeasureStatus is record
tdly  : std_logic_vector(31 downto 0);
twork : std_logic_vector(31 downto 0);
end record;

type TSpdCtrl is record
change   : std_logic;
sata_ver : std_logic_vector(C_PCTRL_SPD_BIT_M downto C_PCTRL_SPD_BIT_L);
end record;

type TSpdCtrl_GTCH is array (0 to C_GTCH_COUNT_MAX-1) of TSpdCtrl;

type TPLStat_GTCH is array (0 to C_GTCH_COUNT_MAX-1) of std_logic_vector(C_PLSTAT_LAST_BIT downto 0);
type TLLStat_GTCH is array (0 to C_GTCH_COUNT_MAX-1) of std_logic_vector(C_LLSTAT_LAST_BIT downto 0);
type TTLStat_GTCH is array (0 to C_GTCH_COUNT_MAX-1) of std_logic_vector(C_TLSTAT_LAST_BIT downto 0);

type TPLCtrl_GTCH is array (0 to C_GTCH_COUNT_MAX-1) of std_logic_vector(C_PLCTRL_LAST_BIT downto 0);
type TLLCtrl_GTCH is array (0 to C_GTCH_COUNT_MAX-1) of std_logic_vector(C_LLCTRL_LAST_BIT downto 0);
type TTLCtrl_GTCH is array (0 to C_GTCH_COUNT_MAX-1) of std_logic_vector(C_TLCTRL_LAST_BIT downto 0);
type TALCtrl_GTCH is array (0 to C_GTCH_COUNT_MAX-1) of std_logic_vector(C_USR_GCTRL_LAST_BIT downto 0);

type TTxBufStatus_GTCH is array (0 to C_GTCH_COUNT_MAX-1) of TTxBufStatus;
type TRxBufStatus_GTCH is array (0 to C_GTCH_COUNT_MAX-1) of TRxBufStatus;

type TRegHold_GTCH is array (0 to C_GTCH_COUNT_MAX-1) of TRegHold;
type TRegFPDMASetup_GTCH is array (0 to C_GTCH_COUNT_MAX-1) of TRegFPDMASetup;
type TRegShadow_GTCH is array (0 to C_GTCH_COUNT_MAX-1) of TRegShadow;
type TRegShadowUpdate_GTCH is array (0 to C_GTCH_COUNT_MAX-1) of TRegShadowUpdate;
type TALStatus_GTCH is array (0 to C_GTCH_COUNT_MAX-1) of TALStatus;


type TALCtrlGTCH_SHCountMax is array (0 to C_SH_COUNT_MAX(C_HDD_COUNT_MAX-1)-1) of TALCtrl_GTCH;
type TALStatusGTCH_SHCountMax is array (0 to C_SH_COUNT_MAX(C_HDD_COUNT_MAX-1)-1) of TALStatus_GTCH;
type TTxBufStatusGTCH_SHCountMax is array (0 to C_SH_COUNT_MAX(C_HDD_COUNT_MAX-1)-1) of TTxBufStatus_GTCH;
type TRxBufStatusGTCH_SHCountMax is array (0 to C_SH_COUNT_MAX(C_HDD_COUNT_MAX-1)-1) of TRxBufStatus_GTCH;

type TBusGTCH_SHCountMax is array (0 to C_SH_COUNT_MAX(C_HDD_COUNT_MAX-1)-1) of std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
type TBus02GTCH_SHCountMax is array (0 to C_SH_COUNT_MAX(C_HDD_COUNT_MAX-1)-1) of TBus02_GTCH;
type TBus03GTCH_SHCountMax is array (0 to C_SH_COUNT_MAX(C_HDD_COUNT_MAX-1)-1) of TBus03_GTCH;
type TBus04GTCH_SHCountMax is array (0 to C_SH_COUNT_MAX(C_HDD_COUNT_MAX-1)-1) of TBus04_GTCH;
type TBus16GTCH_SHCountMax is array (0 to C_SH_COUNT_MAX(C_HDD_COUNT_MAX-1)-1) of TBus16_GTCH;
type TBus32GTCH_SHCountMax is array (0 to C_SH_COUNT_MAX(C_HDD_COUNT_MAX-1)-1) of TBus32_GTCH;


type TBus32_SHCountMax is array (0 to C_HDD_COUNT_MAX-1) of std_logic_vector(31 downto 0);
type TBus16_SHCountMax is array (0 to C_HDD_COUNT_MAX-1) of std_logic_vector(15 downto 0);
type TBus02_SHCountMax is array (0 to C_HDD_COUNT_MAX-1) of std_logic_vector(1 downto 0);
type TBus03_SHCountMax is array (0 to C_HDD_COUNT_MAX-1) of std_logic_vector(2 downto 0);
type TBus04_SHCountMax is array (0 to C_HDD_COUNT_MAX-1) of std_logic_vector(3 downto 0);
type TALCtrl_SHCountMax is array (0 to C_HDD_COUNT_MAX-1) of std_logic_vector(C_USR_GCTRL_LAST_BIT downto 0);
type TALStatus_SHCountMax is array (0 to C_HDD_COUNT_MAX-1) of TALStatus;
type TTxBufStatus_SHCountMax is array (0 to C_HDD_COUNT_MAX-1) of TTxBufStatus;
type TRxBufStatus_SHCountMax is array (0 to C_HDD_COUNT_MAX-1) of TRxBufStatus;


--//
type TMeasureALStatus is record
Usr : std_logic_vector(C_ALUSER_LAST_BIT downto 0);
end record;
type TMeasureALStatus_SHCountMax is array (0 to C_HDD_COUNT_MAX-1) of TMeasureALStatus;

Type T04_SHCountMax is array (0 to C_SH_COUNT_MAX(C_HDD_COUNT_MAX-1)-1) of std_logic_vector(3 downto 0);


---------------------------------------------------------
--��������� �������
---------------------------------------------------------


end sata_pkg;


package body sata_pkg is

---------------------------------------------------------
--�������
---------------------------------------------------------


end sata_pkg;


