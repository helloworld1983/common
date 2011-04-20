-------------------------------------------------------------------------
-- Company     : Telemix
-- Engineer    : Golovachenko Victor
--
-- Create Date : 10/26/2007
-- Module Name : prj_def
--
-- Description :
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;

use work.vicg_common_pkg.all;

package prj_def is

constant C_ON        : std_logic:='1';
constant C_OFF       : std_logic:='0';
constant C_YES       : std_logic:='1';
constant C_NO        : std_logic:='0';

--����� �������� FPGA
--//15..3 - ver; 3..0 - rev
constant C_FPGA_FIRMWARE_VERSION             : integer:=16#0307#;

--//������ �����
constant C_FHOST_DBUS                        : integer:=32;--//���� ������ ������ dsn_host.vhd (������ ��������!!!)

--//VCTRL
constant C_VIDEO_PKT_HEADER_SIZE             : integer:=5;

--//--------------------------------------------------------------
--//HOST
--//--------------------------------------------------------------
--//--------------------------------------------------------------
--//���� ������ dsn_host.vhd / Bit Map:
--//--------------------------------------------------------------
constant C_DEV_FIFO_FLAG_TXFIFO_PFULL_BIT    : integer:=0;
constant C_DEV_FIFO_FLAG_RXFIFO_EMPTY_BIT    : integer:=1;
constant C_DEV_FIFO_FLAG_LAST_BIT            : integer:=C_DEV_FIFO_FLAG_RXFIFO_EMPTY_BIT;

--//--------------------------------------------------------------
--//�������� ������ dsn_host.vhd:
--//--------------------------------------------------------------
constant C_HOST_REG_FIRMWARE                 : integer:=16#000001#;--//������ �������� FPGA
constant C_HOST_REG_GLOB_CTRL0               : integer:=16#000002#;--//���������� ����������

constant C_HOST_REG_TRN_DMA_ADDR             : integer:=16#000003#;--//����� ������ ��������� � ������ PC ��������� PCI-Express
constant C_HOST_REG_TRN_DMA_DLEN             : integer:=16#000005#;--//������ ������(� ������) ��������� � ������ PC ��������� PCI-Express

constant C_HOST_REG_USR_MEM_ADDR             : integer:=16#000007#;--//����� ��� ������������� � FPGA
constant C_HOST_REG_DEV_CTRL                 : integer:=16#000008#;--//���������� ����-���� ������������� � ������ dsn_host.vhd

constant C_HOST_REG_STATUS_DEV               : integer:=16#000009#;--//������� ��������� � ������� ����� ������ ������ dsn_host.vhd
constant C_HOST_REG_STATUS_DEV_L             : integer:=16#000009#;
constant C_HOST_REG_STATUS_DEV_M             : integer:=16#00000A#;

constant C_HOST_REG_PCIEXP_CTRL              : integer:=16#00000C#;--//��� + ������("������" ���������) PCI-Express

constant C_HOST_REG_DEV_DATA                 : integer:=16#00000D#;--//������� ������ ��� ��������� ������������ � ������ dsn_host.vhd
                                                                   --(��� ������ ����� �� ����������� DMA ����������)

constant C_HOST_REG_IRQ_CTRL                 : integer:=16#00000E#;--//���������� ����������

constant C_HOST_REG_VCTRL_FRMRK              : integer:=16#00000F#;--//������ ���������� ����������

constant C_HOST_REG_TST0                     : integer:=16#000010#;--//�������� ��������
constant C_HOST_REG_TST1                     : integer:=16#000011#;
constant C_HOST_REG_TST2                     : integer:=16#000012#;
--constant C_HOST_REG_TST3                     : integer:=16#000013#;
--constant C_HOST_REG_TST4                     : integer:=16#000014#;

constant C_HOST_REG_TRC_FRMRK                : integer:=16#000015#;--//������ ���������� ����������
constant C_HOST_REG_TRCNIK_DSIZE             : integer:=16#000016#;--//������ ���������� ����������


--//Bit Maps:
--//Register C_HOST_REG_FIRMWARE / Bit Map:
constant C_HREG_FRMWARE_LAST_BIT                  : integer:=15;--//

--//Register C_HOST_REG_GLOB_CTRL0 / Bit Map:
constant C_HREG_GCTRL0_RST_ALL_BIT                : integer:=0;--//
constant C_HREG_GCTRL0_LBUS_SEL_BIT               : integer:=1;--//
constant C_HREG_GCTRL0_RST_HDD_BIT                : integer:=2;--//
constant C_HREG_GCTRL0_RST_ETH_BIT                : integer:=3;--//
constant C_HREG_GCTRL0_RDDONE_VCTRL_BIT           : integer:=4;--//
constant C_HREG_GCTRL0_RDDONE_TRC_BIT             : integer:=5;--//
constant C_HREG_GCTRL0_RDDONE_TRCNIK_BIT          : integer:=6;--//
constant C_HREG_GCTRL0_RESERV7_BIT                : integer:=7;--//
constant C_HREG_GCTRL0_RESERV8_BIT                : integer:=8;--//
constant C_HREG_GCTRL0_RESERV9_BIT                : integer:=9;--//
constant C_HREG_GCTRL0_LAST_BIT                   : integer:=C_HREG_GCTRL0_RESERV9_BIT+1;--//

--//Register C_HOST_REG_IRQ_CTRL / Bit Map:
constant C_HREG_INT_CTRL_WD_IRQ_SRC_LSB_BIT       : integer:=0; --// ����� ��������� ����������
constant C_HREG_INT_CTRL_WD_IRQ_SRC_MSB_BIT       : integer:=3; --//
constant C_HREG_INT_CTRL_WD_IRQ_SRC_EN_BIT        : integer:=5; --// ���������� ���������� �� ���������������� ���������
constant C_HREG_INT_CTRL_WD_IRQ_SRC_DIS_BIT       : integer:=6; --// ��������� ���������� �� ���������������� ���������
constant C_HREG_INT_CTRL_WD_IRQ_SRC_CLR_BIT       : integer:=7; --// ����� ������� ���������� �����. ��������� ����������
constant C_HREG_INT_CTRL_WD_LAST_BIT              : integer:=C_HREG_INT_CTRL_WD_IRQ_SRC_CLR_BIT;

constant C_HREG_INT_CTRL_RD_IRQ_SRC_EN_LSB_BIT    : integer:=0; --// ������ ����������/���������� ���������� �� �����. ���������
constant C_HREG_INT_CTRL_RD_IRQ_SRC_EN_MSB_BIT    : integer:=15;--//
constant C_HREG_INT_CTRL_RD_ACT_SRC_LSB_BIT       : integer:=16;--// ������ ���������� ���������� �� �����. ���������
constant C_HREG_INT_CTRL_RD_ACT_SRC_MSB_BIT       : integer:=31;--//

--//���� C_HREG_INT_CTRL_WD_IRQ_SRC - ������ ���������� ����������:
constant C_HIRQ_PCIEXP_DMA_WR                     : integer:=16#00#;--//TRN: PC<-FPGA
constant C_HIRQ_PCIEXP_DMA_RD                     : integer:=16#01#;--//TRN: PC->FPGA
constant C_HIRQ_TMR0                              : integer:=16#02#;
constant C_HIRQ_ETH_RXBUF                         : integer:=16#03#;
constant C_HIRQ_DEVCFG_RXBUF                      : integer:=16#04#;
constant C_HIRQ_HDD_CMDDONE                       : integer:=16#05#;
constant C_HIRQ_VIDEO_CH0                         : integer:=16#06#;
constant C_HIRQ_VIDEO_CH1                         : integer:=16#07#;
constant C_HIRQ_VIDEO_CH2                         : integer:=16#08#;
constant C_HIRQ_TRACK_NIK                         : integer:=16#09#;
constant C_HIRQ_TRACK                             : integer:=16#0A#;

constant C_HIRQ_COUNT                             : integer:=C_HIRQ_TRACK_NIK+1;--//������� ���-�� ���������� ����������
constant C_HIRQ_COUNT_MAX                         : integer:=16; --//������������ ���-�� ���������� ���������.
                                                                 --//�������� � ������:
                                                                 --//C_HREG_INT_CTRL_WD_IRQ_SRC_xxx
                                                                 --//C_HREG_INT_CTRL_RD_IRQ_SRC_EN_xxx
                                                                 --//C_HREG_INT_CTRL_RD_ACT_SRC_xxx


--//Register C_HOST_REG_INT_STATUS / Bit Map: (��������� ����������)
constant C_HREG_INT_STATUS_PCIEXP_DMA_BIT          : integer:=0;--//
constant C_HREG_INT_STATUS_TMR0_BIT                : integer:=1;--//
constant C_HREG_INT_STATUS_ETH_RXBUF_BIT           : integer:=2;--//
constant C_HREG_INT_STATUS_LAST_BIT                : integer:=C_HREG_INT_STATUS_ETH_RXBUF_BIT;


--//Register C_HOST_REG_DEV_CTRL / Bit Map:
constant C_HREG_DEV_CTRL_DEV_TRN_START_BIT         : integer:=0; --// (�������� �����)������ ������� ��������
constant C_HREG_DEV_CTRL_DEV_DIR_BIT               : integer:=1; --// 1/0 � ������/������ ������ � ���������������� ����������
constant C_HREG_DEV_CTRL_DEV_RESERV2_BIT           : integer:=2; --//
constant C_HREG_DEV_CTRL_DEV_DIN_RDY_BIT           : integer:=3; --//
constant C_HREG_DEV_CTRL_DEV_ADDR_LSB_BIT          : integer:=4; --// ����� ����������������� ����������
constant C_HREG_DEV_CTRL_DEV_ADDR_MSB_BIT          : integer:=7; --//
constant C_HREG_DEV_CTRL_DEV_RESERV8_BIT           : integer:=8; --//
constant C_HREG_DEV_CTRL_DEV_TRN_RST_BIT           : integer:=9; --// (�������� �����) ����� ������� ��������
constant C_HREG_DEV_CTRL_DEV_RESERV10_BIT          : integer:=10;--//
constant C_HREG_DEV_CTRL_DEV_RESERV11_BIT          : integer:=11;--//
constant C_HREG_DEV_CTRL_DEV_TRN_PARAM_IDX_LSB_BIT : integer:=12;--//
constant C_HREG_DEV_CTRL_DEV_TRN_PARAM_IDX_MSB_BIT : integer:=19;--//
constant C_HREG_DEV_CTRL_DEV_DMA_BUF_COUNT_LSB_BIT : integer:=20;--//
constant C_HREG_DEV_CTRL_DEV_DMA_BUF_COUNT_MSB_BIT : integer:=27;--//
constant C_HREG_DEV_CTRL_DEV_VCH_LSB_BIT           : integer:=28;--//
constant C_HREG_DEV_CTRL_DEV_VCH_MSB_BIT           : integer:=29;--//
constant C_HREG_DEV_CTRL_DEV_LAST_BIT              : integer:=C_HREG_DEV_CTRL_DEV_VCH_MSB_BIT;--//

--//���� C_HREG_DEV_CTRL_DEV_ADDR - ������ ����������������� ���������:
constant C_HDEV_NOT_SELECT                         : integer:=0;
constant C_HDEV_ETHG_DBUF                          : integer:=2;--//������ RX/TX ��� ������ � EthG
constant C_HDEV_HDD_DBUF                           : integer:=3;--//������ RX/TX ��� ������ � HDD
constant C_HDEV_MEM_DBUF                           : integer:=4;--//���
constant C_HDEV_CFG_DBUF                           : integer:=5;--//������ RX/TX ��� ������ � ������ ���������������� ���������
constant C_HDEV_VCH_DBUF                           : integer:=6;--//����� ���������������
constant C_HDEV_TRC_DBUF                           : integer:=7;--//����� ������ ������ ��������

constant C_HDEV_COUNT                              : integer:=7+1;


--//������ i_dev_txdata_rdy_mask / Bit Map:
constant C_HREG_TXDATA_RDY_CFGDEV_BIT              : integer:=C_HDEV_CFG_DBUF; --//: integer:=0;
constant C_HREG_TXDATA_RDY_ETHG_BIT                : integer:=C_HDEV_ETHG_DBUF;--//: integer:=2;
--constant C_HREG_TXDATA_RDY_HDDCMD_BIT              : integer:=C_FDEV_ADR_HDD_CBUF; --//: integer:=1;


--//Register C_HOST_REG_USR_MEM_ADDR / Bit Map:
constant C_HREG_USR_MEM_ADR_OFFSET_LSB_BIT       : integer:=0;
constant C_HREG_USR_MEM_ADR_OFFSET_MSB_BIT       : integer:=27;
constant C_HREG_USR_MEM_ADR_BANK_LSB_BIT         : integer:=28;
constant C_HREG_USR_MEM_ADR_BANK_MSB_BIT         : integer:=29;
constant C_HREG_USR_MEM_LAST_BIT                 : integer:=C_HREG_USR_MEM_ADR_BANK_MSB_BIT;


--//Register C_HOST_REG_STATUS_DEV / Bit Map:
constant C_HREG_STATUS_DEV_CFGDEV_MOD_RDY_BIT    : integer:=0;
constant C_HREG_STATUS_DEV_CFGDEV_RXBUF_RDY_BIT  : integer:=1;
constant C_HREG_STATUS_DEV_CFGDEV_TXBUF_RDY_BIT  : integer:=2;

constant C_HREG_STATUS_DEV_HDD_MOD_RDY_BIT       : integer:=3;
constant C_HREG_STATUS_DEV_HDD_MOD_ERR_BIT       : integer:=4;
constant C_HREG_STATUS_DEV_HDD_CMDBUF_RDY_BIT    : integer:=5;
constant C_HREG_STATUS_DEV_HDD_RXBUF_RDY_BIT     : integer:=6;
constant C_HREG_STATUS_DEV_HDD_TXBUF_RDY_BIT     : integer:=7;

constant C_HREG_STATUS_DEV_ETHG_MOD_RDY_BIT      : integer:=8;
constant C_HREG_STATUS_DEV_ETHG_MOD_ERR_BIT      : integer:=9;
constant C_HREG_STATUS_DEV_ETHG_RXBUF_RDY_BIT    : integer:=10;
constant C_HREG_STATUS_DEV_ETHG_TXBUF_RDY_BIT    : integer:=11;

constant C_HREG_STATUS_DEV_VCTRL_CH0_FRRDY_BIT   : integer:=12;
constant C_HREG_STATUS_DEV_VCTRL_CH1_FRRDY_BIT   : integer:=13;
constant C_HREG_STATUS_DEV_VCTRL_CH2_FRRDY_BIT   : integer:=14;

constant C_HREG_STATUS_DEV_RESERV_15BIT          : integer:=15;
constant C_HREG_STATUS_DEV_RESERV_16BIT          : integer:=16;

constant C_HREG_STATUS_DCM_ETH_GTP_LOCK_BIT      : integer:=17;
constant C_HREG_STATUS_DCM_LBUS_LOCK_BIT         : integer:=18;
constant C_HREG_STATUS_DCM_SATA_LOCK_BIT         : integer:=19;
constant C_HREG_STATUS_DCM_MEMCTRL_LOCK_BIT      : integer:=20;

constant C_HREG_STATUS_DEV_HDD_CMD_BUSY_BIT      : integer:=21;--//add 2010.08.27---------------------------------------------------------------------------
constant C_HREG_STATUS_DEV_HDD_TXBUFSTREAM_RDY_BIT: integer:=22;

constant C_HREG_STATUS_DEV_DSNTEST_RDY_BIT       : integer:=23;
constant C_HREG_STATUS_DEV_DSNTEST_ERR_BIT       : integer:=24;

constant C_HREG_STATUS_DEV_TRC_DRDY_BIT          : integer:=25;--//add 2010.10.04
constant C_HREG_STATUS_DEV_TRCNIK_DRDY_BIT       : integer:=26;--//add 2010.11.21

constant C_HREG_STATUS_DEV_INT_ACT_BIT           : integer:=27;--//
constant C_HREG_STATUS_DEV_DMA_BUSY_BIT          : integer:=28;--//
constant C_HREG_STATUS_DEV_PCIEXP_ERR_BIT        : integer:=29;--//
constant C_HREG_STATUS_DEV_PCIEXP_DMA_WR_DONE_BIT: integer:=30;--//
constant C_HREG_STATUS_DEV_PCIEXP_DMA_RD_DONE_BIT: integer:=31;--//
constant C_HREG_STATUS_DEV_LAST_BIT              : integer:=C_HREG_STATUS_DEV_PCIEXP_DMA_RD_DONE_BIT;--//


--//Register C_HOST_REG_PCIEXP_CTRL / Bit Map:
constant C_HREG_PCIEXP_CTRL_REQ_LINK_LSB_BIT        : integer:=0; --//
constant C_HREG_PCIEXP_CTRL_REQ_LINK_MSB_BIT        : integer:=5; --//
constant C_HREG_PCIEXP_CTRL_NEG_LINK_LSB_BIT        : integer:=6; --//
constant C_HREG_PCIEXP_CTRL_NEG_LINK_MSB_BIT        : integer:=11;--//
constant C_HREG_PCIEXP_CTRL_REQ_MAX_PAYLOAD_LSB_BIT : integer:=12;--//
constant C_HREG_PCIEXP_CTRL_REQ_MAX_PAYLOAD_MSB_BIT : integer:=14;--//
constant C_HREG_PCIEXP_CTRL_NEG_MAX_PAYLOAD_LSB_BIT : integer:=15;--//
constant C_HREG_PCIEXP_CTRL_NEG_MAX_PAYLOAD_MSB_BIT : integer:=17;--//
constant C_HREG_PCIEXP_CTRL_NEG_MAX_RD_REQ_LSB_BIT  : integer:=18;--//
constant C_HREG_PCIEXP_CTRL_NEG_MAX_RD_REQ_MSB_BIT  : integer:=20;--//

constant C_HREG_PCIEXP_CTRL_MSI_EN_BIT              : integer:=21;--//
constant C_HREG_PCIEXP_CTRL_PHANT_FUNC_BIT          : integer:=22;--//
constant C_HREG_PCIEXP_CTRL_NOSNOOP_BIT             : integer:=23;--//
constant C_HREG_PCIEXP_CTRL_DMA_RD_NOSNOOP_BIT      : integer:=23;--//
constant C_HREG_PCIEXP_CTRL_CPLD_MALFORMED_BIT      : integer:=24;--//
constant C_HREG_PCIEXP_CTRL_RESERV25_BIT            : integer:=25;--//--------------------�� ���������

constant C_HREG_PCIEXP_CTRL_CPL_STREAMING_BIT       : integer:=26;
constant C_HREG_PCIEXP_CTRL_METRING_BIT             : integer:=27;
constant C_HREG_PCIEXP_CTRL_TRN_RNP_OK_BIT          : integer:=28;
constant C_HREG_PCIEXP_CTRL_DMA_RD_RELEX_ORDER_BIT  : integer:=29;
constant C_HREG_PCIEXP_CTRL_DMA_WD_RELEX_ORDER_BIT  : integer:=30;
constant C_HREG_PCIEXP_CTRL_DMA_WD_NOSNOOP_BIT      : integer:=31;

constant C_HREG_PCIEXP_CTRL_LAST_BIT                : integer:=C_HREG_PCIEXP_CTRL_DMA_WD_NOSNOOP_BIT;

--//���� C_HREG_PCIEXP_CTRL_REQ_LINK/C_HREG_PCIEXP_CTRL_NEG_LINK - ��������
constant C_PCIEXP_LINK_X1                           : integer:=1;
constant C_PCIEXP_LINK_X2                           : integer:=2;
constant C_PCIEXP_LINK_X4                           : integer:=4;
constant C_PCIEXP_LINK_X8                           : integer:=8;
constant C_PCIEXP_LINK_X12                          : integer:=12;
constant C_PCIEXP_LINK_X16                          : integer:=16;
constant C_PCIEXP_LINK_X32                          : integer:=32;

--//���� C_HREG_PCIEXP_CTRL_REQ_MAX_PAYLOAD/C_HREG_PCIEXP_CTRL_NEG_MAX_PAYLOAD - ��������
constant C_PCIEXP_MAX_PAYLOAD_SIZE_128_BYTE         : integer:=0;
constant C_PCIEXP_MAX_PAYLOAD_SIZE_256_BYTE         : integer:=1;
constant C_PCIEXP_MAX_PAYLOAD_SIZE_512_BYTE         : integer:=2;
constant C_PCIEXP_MAX_PAYLOAD_SIZE_1024_BYTE        : integer:=3;
constant C_PCIEXP_MAX_PAYLOAD_SIZE_2048_BYTE        : integer:=4;
constant C_PCIEXP_MAX_PAYLOAD_SIZE_4096_BYTE        : integer:=5;

--//�������� ��� ���� NEG_MAX_RD_REQ �������� C_HOST_REG_PCIEXP_CTRL
constant C_PCIEXP_MAX_READ_REQ_SIZE_128_BYTE        : integer:=0;
constant C_PCIEXP_MAX_READ_REQ_SIZE_256_BYTE        : integer:=1;
constant C_PCIEXP_MAX_READ_REQ_SIZE_512_BYTE        : integer:=2;
constant C_PCIEXP_MAX_READ_REQ_SIZE_1024_BYTE       : integer:=3;
constant C_PCIEXP_MAX_READ_REQ_SIZE_2048_BYTE       : integer:=4;
constant C_PCIEXP_MAX_READ_REQ_SIZE_4096_BYTE       : integer:=5;





--//--------------------------------------------------------------
--//������ ���������������� (cfgdev.vhd)
--//--------------------------------------------------------------
--//������ �������� ��������� ����� ������ cfgdev.vhd
--//Device Address map:
constant C_CFGDEV_SWT                        : integer:=16#00#;
constant C_CFGDEV_HDD                        : integer:=16#01#;
constant C_CFGDEV_ETHG                       : integer:=16#02#;
constant C_CFGDEV_VCTRL                      : integer:=16#03#;
constant C_CFGDEV_TESTING                    : integer:=16#04#;
constant C_CFGDEV_TMR                        : integer:=16#05#;
constant C_CFGDEV_TRACK_NIK                  : integer:=16#06#;
--constant C_CFGDEV_TRACK                      : integer:=16#07#;
--constant C_CFGDEV_RESERV0                    : integer:=16#08#;
--constant C_CFGDEV_RESERV1                    : integer:=16#09#;
--constant C_CFGDEV_RESERV2                    : integer:=16#0A#;
--constant C_CFGDEV_RESERV3                    : integer:=16#0B#;

constant C_CFGDEV_COUNT                      : integer:=16#06# + 1;



--//--------------------------------------------------------------
--//�������� ������ dsn_timer.vhd
--//--------------------------------------------------------------
constant C_DSN_TMR_REG_CTRL                      : integer:=16#000#;
constant C_DSN_TMR_REG_CMP_L                     : integer:=16#001#;
constant C_DSN_TMR_REG_CMP_M                     : integer:=16#002#;

--//Bit Maps:
--//Register C_DSN_TMR_REG_CTRL / Bit Map:
constant C_DSN_TMR_REG_CTRL_IDX_LSB_BIT          : integer:=0;
constant C_DSN_TMR_REG_CTRL_IDX_MSB_BIT          : integer:=1;
constant C_DSN_TMR_REG_CTRL_EN_BIT               : integer:=2;
constant C_DSN_TMR_REG_CTRL_DIS_BIT              : integer:=3;

constant C_DSN_TMR_REG_CTRL_STATUS_EN_LSB_BIT    : integer:=0;
constant C_DSN_TMR_REG_CTRL_STATUS_EN_MSB_BIT    : integer:=3;

constant C_DSN_TMR_REG_CTRL_LAST_BIT             : integer:=C_DSN_TMR_REG_CTRL_DIS_BIT;

--//���������� ���-�� �������� � dsn_timer.vhd
constant C_DSN_TMR_COUNT_TMR                     : integer:=16#001#;



--//--------------------------------------------------------------
--//�������� ������ dsn_switch.vhd
--//--------------------------------------------------------------
--//Register MAP:
constant C_DSN_SWT_REG_CTRL_L                : integer:=16#00#;
--constant C_DSN_SWT_REG_CTRL_M                : integer:=16#01#;
constant C_DSN_SWT_REG_TST0                  : integer:=16#02#;
constant C_DSN_SWT_REG_FMASK_ETHG_HOST       : integer:=16#08#;
constant C_DSN_SWT_REG_FMASK_ETHG_HDD        : integer:=16#10#;--//C_DSN_SWT_REG_FMASK_ETHG_HOST + C_DSN_SWT_FMASK_MAX_COUNT
constant C_DSN_SWT_REG_FMASK_ETHG_VCTRL      : integer:=16#18#;--//C_DSN_SWT_REG_FMASK_ETHG_HDD + C_DSN_SWT_FMASK_MAX_COUNT


--//Bit Maps:
--//Register C_DSN_SWT_REG_CTRL / Bit Map:
constant C_DSN_SWT_REG_CTRL_ETHTXD_LOOPBACK_BIT     : integer:=0;
constant C_DSN_SWT_REG_CTRL_RST_ETH_BUFS_BIT        : integer:=1;
constant C_DSN_SWT_REG_CTRL_RST_VCTRL_BUFS_BIT      : integer:=3;
constant C_DSN_SWT_REG_CTRL_TSTDSN_TO_VCTRL_BUFIN_BIT: integer:=4;
constant C_DSN_SWT_REG_CTRL_TSTDSN_TO_HDDBUF_BIT    : integer:=5;
constant C_DSN_SWT_REG_CTRL_TSTDSN_TO_ETHTX_BIT     : integer:=6;
constant C_DSN_SWT_REG_CTRL_LAST_BIT                : integer:=C_DSN_SWT_REG_CTRL_TSTDSN_TO_ETHTX_BIT;


--//Register C_DSN_SWT_REG_TST0 / Bit Map:
constant C_DSN_SWT_REG_TST0_LAST_BIT                : integer:=7;


--//Register C_DSN_SWT_REG_FMASK_XXX /:
constant C_DSN_SWT_FMASK_MAX_COUNT        : integer:=16#08#;--//��� ��������� ���-�� ����� ��� ����� ���������� �������
constant C_DSN_SWT_ETHG_HOST_FMASK_COUNT  : integer:=16#03#;--//���-�� ����� ��� ���������� ������� � ����������� ETH-HOST
constant C_DSN_SWT_ETHG_HDD_FMASK_COUNT   : integer:=16#03#;--//���-�� ����� ��� ���������� ������� � ����������� ETH-HDD
constant C_DSN_SWT_ETHG_VCTRL_FMASK_COUNT : integer:=16#03#;--//���-�� ����� ��� ���������� ������� � ����������� ETH-VCTRL

constant C_FLTR_VARIANT_DWIDTH            : integer :=8;
Type TEthFmask is array (0 to (2*C_DSN_SWT_FMASK_MAX_COUNT)-1) of std_logic_vector(C_FLTR_VARIANT_DWIDTH-1 downto 0);

--����� ���������� (7...0), ���
-- 3..0 - ��� ������
-- 7..4 - ������ ������



--//--------------------------------------------------------------
--//�������� ������ dsn_hdd.vhd
--//--------------------------------------------------------------
constant C_DSN_HDD_REG_CTRL_L                : integer:=16#000#;
--constant C_DSN_HDD_REG_CTRL_M                : integer:=16#001#;
constant C_DSN_HDD_REG_TST0                  : integer:=16#002#;
constant C_DSN_HDD_REG_TST1                  : integer:=16#003#;
constant C_DSN_HDD_REG_STATUS                : integer:=16#004#;
constant C_DSN_HDD_REG_STATUS_SATA0_L        : integer:=16#005#;
constant C_DSN_HDD_REG_STATUS_SATA0_M        : integer:=16#006#;
constant C_DSN_HDD_REG_STATUS_SATA1_L        : integer:=16#007#;
constant C_DSN_HDD_REG_STATUS_SATA1_M        : integer:=16#008#;
constant C_DSN_HDD_REG_STATUS_SATA2_L        : integer:=16#009#;
constant C_DSN_HDD_REG_STATUS_SATA2_M        : integer:=16#00A#;
constant C_DSN_HDD_REG_STATUS_SATA3_L        : integer:=16#00B#;
constant C_DSN_HDD_REG_STATUS_SATA3_M        : integer:=16#00C#;
constant C_DSN_HDD_REG_STATUS_SATA4_L        : integer:=16#00D#;
constant C_DSN_HDD_REG_STATUS_SATA4_M        : integer:=16#00E#;
constant C_DSN_HDD_REG_STATUS_SATA5_L        : integer:=16#00F#;
constant C_DSN_HDD_REG_STATUS_SATA5_M        : integer:=16#010#;

constant C_DSN_HDD_REG_LBA_BPOINT_LSB        : integer:=16#011#;
constant C_DSN_HDD_REG_LBA_BPOINT_MID        : integer:=16#012#;
constant C_DSN_HDD_REG_LBA_BPOINT_MSB        : integer:=16#013#;

constant C_DSN_HDD_REG_TEST_TCMD_L           : integer:=16#016#;
constant C_DSN_HDD_REG_TEST_TCMD_M           : integer:=16#017#;
constant C_DSN_HDD_REG_TEST_TWORK_L          : integer:=16#018#;
constant C_DSN_HDD_REG_TEST_TWORK_M          : integer:=16#019#;
constant C_DSN_HDD_REG_TEST_TDLY_L           : integer:=16#01B#;
constant C_DSN_HDD_REG_TEST_TDLY_M           : integer:=16#01C#;

constant C_DSN_HDD_REG_CMDFIFO               : integer:=16#01E#;

constant C_DSN_HDD_REG_STATUS_M              : integer:=16#01F#;--//��������� 2010.09.08

constant C_DSN_HDD_REG_RBUF_ADR_L            : integer:=16#020#;--//add 2010.10.03
constant C_DSN_HDD_REG_RBUF_ADR_M            : integer:=16#021#;--//add 2010.10.03
--constant C_DSN_HDD_REG_RBUF_SIZE_L           : integer:=16#022#;--//add 2010.10.03
--constant C_DSN_HDD_REG_RBUF_SIZE_M           : integer:=16#023#;--//add 2010.10.03
--constant C_DSN_HDD_REG_RBUF_LEVEL            : integer:=16#024#;--//add 2010.10.03
--constant C_DSN_HDD_REG_RBUF_FIFO_SIZE        : integer:=16#025#;--//add 2010.10.03
constant C_DSN_HDD_REG_RBUF_CTRL             : integer:=16#026#;--//add 2010.10.03

--//Bit Maps:
--//Register C_DSN_HDD_REG_CTRL_L / Bit Map:
--//������ ����� ������ ��������������� ������� �������� � sata_pkg.vhd/C_FSATA_REG_CTRL0_xxx
constant C_DSN_HDD_REG_CTRLL_SATA_VER_LSB_BIT : integer:=0; --//C_FSATA_REG_CTRL0_SATA_VER_LSB_BIT
constant C_DSN_HDD_REG_CTRLL_SATA_VER_MSB_BIT : integer:=1; --//C_FSATA_REG_CTRL0_SATA_VER_MSB_BIT
constant C_DSN_HDD_REG_CTRLL_OVERFLOW_DET_BIT : integer:=2;
constant C_DSN_HDD_REG_CTRLL_BUFRST_BIT       : integer:=3; --//
constant C_DSN_HDD_REG_CTRLL_ERR_CLR_BIT      : integer:=6; --//������ ����� ���� ������ ������, �.�. �� �������� � ���������� �������
                                                            --//������ � ������ dsn_sata.vhd/C_FSATA_REG_CTRL0_ERR_CLR_BIT
constant C_DSN_HDD_REG_CTRLL_LAST_BIT         : integer:=C_DSN_HDD_REG_CTRLL_ERR_CLR_BIT;

--//Bit Maps:
--//Register C_DSN_HDD_REG_RBUF_ADR / Bit Map:
constant C_DSN_HDD_REG_RBUF_ADR_OFFSET_LSB_BIT     : integer:=C_HREG_USR_MEM_ADR_OFFSET_LSB_BIT;--0;
constant C_DSN_HDD_REG_RBUF_ADR_OFFSET_MSB_BIT     : integer:=C_HREG_USR_MEM_ADR_OFFSET_MSB_BIT;--27;
constant C_DSN_HDD_REG_RBUF_ADR_BANK_LSB_BIT       : integer:=C_HREG_USR_MEM_ADR_BANK_LSB_BIT;--28;
constant C_DSN_HDD_REG_RBUF_ADR_BANK_MSB_BIT       : integer:=C_HREG_USR_MEM_ADR_BANK_MSB_BIT;--29;
constant C_DSN_HDD_REG_RBUF_LAST_BIT               : integer:=C_DSN_HDD_REG_RBUF_ADR_BANK_MSB_BIT;

--//Register C_DSN_HDD_REG_RBUF_CTRL / Bit Map:
constant C_DSN_HDD_REG_RBUF_CTRL_TRNMEM_LSB_BIT   : integer:=0;
constant C_DSN_HDD_REG_RBUF_CTRL_TRNMEM_MSB_BIT   : integer:=7;
constant C_DSN_HDD_REG_RBUF_CTRL_RESERV_8BIT      : integer:=8;
constant C_DSN_HDD_REG_RBUF_CTRL_RESERV_9BIT      : integer:=9;
constant C_DSN_HDD_REG_RBUF_CTRL_RESERV_10BIT     : integer:=10;
constant C_DSN_HDD_REG_RBUF_CTRL_TEST_BIT         : integer:=11;
constant C_DSN_HDD_REG_RBUF_CTRL_STOP_BIT         : integer:=12;
constant C_DSN_HDD_REG_RBUF_CTRL_START_BIT        : integer:=13;
constant C_DSN_HDD_REG_RBUF_CTRL_RST_BIT          : integer:=14;
constant C_DSN_HDD_REG_RBUF_CTRL_STOPSYN_BIT      : integer:=15;


--//Register C_DSN_HDD_REG_TST0 / Bit Map:
constant C_DSN_HDD_REG_TST0_LAST_BIT         : integer:=16#007#;

--//Register C_DSN_HDD_REG_TST1 / Bit Map:
constant C_DSN_HDD_REG_TST1_LAST_BIT         : integer:=16#007#;

--//��������� 2010.09.08
--//Register C_DSN_HDD_REG_STATUS_M / Bit Map:
constant C_DSN_HDD_REG_STATUSM_HDDBUF_OVERFLOW_BIT : integer:=0;
---------------



--//--------------------------------------------------------------
--//�������� ������ dsn_ethg.vhd
--//--------------------------------------------------------------
constant C_DSN_ETHG_REG_CTRL_L                : integer:=16#000#;
--constant C_DSN_ETHG_REG_CTRL_M                : integer:=16#001#;
constant C_DSN_ETHG_REG_TST0                  : integer:=16#002#;
--constant C_DSN_ETHG_REG_TST1                  : integer:=16#003#;
constant C_DSN_ETHG_REG_MAC_USRCTRL           : integer:=16#004#;
constant C_DSN_ETHG_REG_MAC_PATRN0            : integer:=16#005#;
constant C_DSN_ETHG_REG_MAC_PATRN1            : integer:=16#006#;
constant C_DSN_ETHG_REG_MAC_PATRN2            : integer:=16#007#;
constant C_DSN_ETHG_REG_MAC_PATRN3            : integer:=16#008#;
constant C_DSN_ETHG_REG_MAC_PATRN4            : integer:=16#009#;
constant C_DSN_ETHG_REG_MAC_PATRN5            : integer:=16#00A#;
constant C_DSN_ETHG_REG_MAC_PATRN6            : integer:=16#00B#;
--constant C_DSN_ETHG_REG_MAC_PATRN7            : integer:=16#00C#;

--//Bit Maps:
--//Register C_DSN_ETHG_REG_MAC_USRCTRL / Bit Map:
constant C_DSN_ETHG_REG_MAC_TX_PATRN_SIZE_LSB_BIT : integer:=0;--//constant C_PKT_MARKER_PATTERN_SIZE_LSB_BIT : integer:=0;
constant C_DSN_ETHG_REG_MAC_TX_PATRN_SIZE_MSB_BIT : integer:=3;--//constant C_PKT_MARKER_PATTERN_SIZE_MSB_BIT : integer:=3;
constant C_DSN_ETHG_REG_MAC_RX_PATRN_SIZE_LSB_BIT : integer:=4;--//constant C_PKT_MARKER_PATTERN_SIZE_LSB_BIT : integer:=0;
constant C_DSN_ETHG_REG_MAC_RX_PATRN_SIZE_MSB_BIT : integer:=7;--//constant C_PKT_MARKER_PATTERN_SIZE_MSB_BIT : integer:=3;

constant C_DSN_ETHG_REG_MAC_RX_CHECK_MAC_DIS_BIT  : integer:=8; --//
constant C_DSN_ETHG_REG_MAC_RX_PADDING_CLR_DIS_BIT: integer:=9; --//
constant C_DSN_ETHG_REG_MAC_RX_SWAP_BYTE_BIT      : integer:=10; --//


--//Register C_DSN_ETHG_REG_CTRL_L / Bit Map:
constant C_DSN_ETHG_REG_CTRL_SWAP_LOOPBACK0_BIT      : integer:=0; --//address - Loopback ��������� ������ � ������� ������� MAC ������� src/dst
constant C_DSN_ETHG_REG_CTRL_SWAP_LOOPBACK1_BIT      : integer:=1; --//loop    - Loopback ��������� ������
constant C_DSN_ETHG_REG_CTRL_SWAP_LOOPBACK2_BIT      : integer:=2; --//swap    - � ������ ������� �� ������������
constant C_DSN_ETHG_REG_CTRL_SFP_TX_DISABLE_BIT      : integer:=3; --//���������� ����������� �� SFP

constant C_DSN_ETHG_REG_CTRL_GTP_CLKIN_MUX_VLSB_BIT  : integer:=8; --//�������� ��� �����������. �������������� CLKIN RocketIO ETH
constant C_DSN_ETHG_REG_CTRL_GTP_CLKIN_MUX_VMSB_BIT  : integer:=10; --//
constant C_DSN_ETHG_REG_CTRL_GTP_SOUTH_MUX_VAL_BIT   : integer:=11; --//�������� ��� �����������. �������������� CLKSOUTH RocketIO ETH
constant C_DSN_ETHG_REG_CTRL_GTP_NORTH_MUX_VAL_BIT   : integer:=12; --//�������� ��� �����������. �������������� CLKNORTH RocketIO ETH
constant C_DSN_ETHG_REG_CTRL_GTP_CLKIN_MUX_CNG_BIT   : integer:=13; --//1- �������������������� �������������� CLKIN RocketIO ETH
constant C_DSN_ETHG_REG_CTRL_GTP_SOUTH_MUX_CNG_BIT   : integer:=14; --//1- �������������������� �������������� CLKSOUTH RocketIO ETH
constant C_DSN_ETHG_REG_CTRL_GTP_NORTH_MUX_CNG_BIT   : integer:=15; --//1- �������������������� �������������� CLKNORTH RocketIO ETH



--//--------------------------------------------------------------
--//�������� ������ dsn_video_ctrl.vhd
--//--------------------------------------------------------------
constant C_DSN_VCTRL_REG_CTRL_L                : integer:=16#000#;
--constant C_DSN_VCTRL_REG_CTRL_M                : integer:=16#001#;
constant C_DSN_VCTRL_REG_TST0                  : integer:=16#002#;
constant C_DSN_VCTRL_REG_TST1                  : integer:=16#003#;
constant C_DSN_VCTRL_REG_PRM_DATA_LSB          : integer:=16#004#;
constant C_DSN_VCTRL_REG_PRM_DATA_MSB          : integer:=16#005#;
constant C_DSN_VCTRL_REG_MEM_TRN_LEN           : integer:=16#006#;


--//Bit Maps:
--//Register C_DSN_VCTRL_REG_CTRL / Bit Map:
constant C_DSN_VCTRL_REG_CTRL_CH_IDX_LSB_BIT          : integer:=0;
constant C_DSN_VCTRL_REG_CTRL_CH_IDX_MSB_BIT          : integer:=3;
constant C_DSN_VCTRL_REG_CTRL_PRM_IDX_LSB_BIT         : integer:=4;
constant C_DSN_VCTRL_REG_CTRL_PRM_IDX_MSB_BIT         : integer:=6;
constant C_DSN_VCTRL_REG_CTRL_SET_BIT                 : integer:=7;
constant C_DSN_VCTRL_REG_CTRL_SET_IDLE_BIT            : integer:=8;
constant C_DSN_VCTRL_REG_CTRL_RAMCOE_ADDR_BIT         : integer:=9;
constant C_DSN_VCTRL_REG_CTRL_RAMCOE_DATA_BIT         : integer:=10;
constant C_DSN_VCTRL_REG_CTRL_RAMCOE_NUM_LSB_BIT      : integer:=11;
constant C_DSN_VCTRL_REG_CTRL_RAMCOE_NUM_MSB_BIT      : integer:=14;
constant C_DSN_VCTRL_REG_CTRL_LAST_BIT                : integer:=C_DSN_VCTRL_REG_CTRL_RAMCOE_NUM_MSB_BIT;

constant C_DSN_VCTRL_REG_CTRL_RAMCOE_SCALE_NUM        : integer:=0;
constant C_DSN_VCTRL_REG_CTRL_RAMCOE_P_COLR_NUM       : integer:=1;
constant C_DSN_VCTRL_REG_CTRL_RAMCOE_P_COLG_NUM       : integer:=2;
constant C_DSN_VCTRL_REG_CTRL_RAMCOE_P_COLB_NUM       : integer:=3;
constant C_DSN_VCTRL_REG_CTRL_RAMCOE_GAMMA_GRAY_NUM   : integer:=4;
constant C_DSN_VCTRL_REG_CTRL_RAMCOE_GAMMA_COLR_NUM   : integer:=5;
constant C_DSN_VCTRL_REG_CTRL_RAMCOE_GAMMA_COLG_NUM   : integer:=6;
constant C_DSN_VCTRL_REG_CTRL_RAMCOE_GAMMA_COLB_NUM   : integer:=7;

--//������ ��������� ����������:
constant C_DSN_VCTRL_PRM_MEM_ADDR_WR                : integer:=0;--//������� ����� ������ ������ �����
constant C_DSN_VCTRL_PRM_MEM_ADDR_RD                : integer:=1;--//������� ����� ������ ������ �����
constant C_DSN_VCTRL_PRM_FR_ZONE_SKIP               : integer:=2;
constant C_DSN_VCTRL_PRM_FR_ZONE_ACTIVE             : integer:=3;
constant C_DSN_VCTRL_PRM_FR_OPTIONS                 : integer:=4;
--//��� ���-�� ������� ��������� ����������:
constant C_DSN_VCTRL_PRM_MAX_COUNT                  : integer:=4+1;--C_DSN_VCTRL_REG_CTRL_PRM_IDX_MSB_BIT-C_DSN_VCTRL_REG_CTRL_PRM_IDX_LSB_BIT+1;


--//Register VCTRL_REG_MEM_ADDR / Bit Map:
constant C_DSN_VCTRL_REG_MEM_ADR_OFFSET_LSB_BIT     : integer:=C_HREG_USR_MEM_ADR_OFFSET_LSB_BIT;--0;
constant C_DSN_VCTRL_REG_MEM_ADR_OFFSET_MSB_BIT     : integer:=C_HREG_USR_MEM_ADR_OFFSET_MSB_BIT;--27;
constant C_DSN_VCTRL_REG_MEM_ADR_BANK_LSB_BIT       : integer:=C_HREG_USR_MEM_ADR_BANK_LSB_BIT;--28;
constant C_DSN_VCTRL_REG_MEM_ADR_BANK_MSB_BIT       : integer:=C_HREG_USR_MEM_ADR_BANK_MSB_BIT;--29;
constant C_DSN_VCTRL_REG_MEM_LAST_BIT               : integer:=C_DSN_VCTRL_REG_MEM_ADR_BANK_MSB_BIT;

--//��� �������� ������ ��� ��� ������/������ ���������������:
--//                                                : integer:=0; --//������� ����������(VLINE_LSB-1...0)
constant C_DSN_VCTRL_MEM_VLINE_LSB_BIT              : integer:=11;--//������ ���������� (MSB...LSB)
constant C_DSN_VCTRL_MEM_VLINE_MSB_BIT              : integer:=21;
constant C_DSN_VCTRL_MEM_VFRAME_LSB_BIT             : integer:=22;--//����� ����� ����� ������ (MSB...LSB)
constant C_DSN_VCTRL_MEM_VFRAME_MSB_BIT             : integer:=23;--//
constant C_DSN_VCTRL_MEM_VCH_LSB_BIT                : integer:=24;--//����� ����� ������ (MSB...LSB) (��� ���-�� ����� �������=4)
constant C_DSN_VCTRL_MEM_VCH_MSB_BIT                : integer:=25;

--//��� ���-�� ������������ (�����):
constant C_DSN_VCTRL_VBUF_MAX_COUNT                 : integer:=4; --//min/max - 2/2

--//��� ���-�� ������� �����: (���������� ��������� C_DSN_VCTRL_MEM_VCH_xxx_BIT )
--constant C_DSN_VCTRL_VCH_COUNT                      : integer:=C_DSN_VCTRL_VCH_COUNT_USE;
constant C_DSN_VCTRL_VCH_MAX_COUNT                  : integer:=4;


--//Register C_DSN_VCTRL_REG_TST0 / Bit Map:
constant C_DSN_VCTRL_REG_TST0_DBG_TBUFRD_BIT         : integer:=0;--//������� ������ �������� - ����������� ����������� RAM/TRACK/TBUF
constant C_DSN_VCTRL_REG_TST0_DBG_EBUFRD_BIT         : integer:=1;--//������� ������ �������� - ����������� ����������� RAM/TRACK/EBUF
constant C_DSN_VCTRL_REG_TST0_DBG_SOBEL_BIT          : integer:=2;--//1/0 - ������� ������ ������ ������ Grad/Video
constant C_DSN_VCTRL_REG_TST0_DBG_DIS_DEMCOLOR_BIT   : integer:=5;--//1/0 - ��������� ������ ������ vcoldemosaic_main.vhd
constant C_DSN_VCTRL_REG_TST0_DBG_DCOUNT_BIT         : integer:=6;--//1 - ������ ������ ������ ����������� �������
constant C_DSN_VCTRL_REG_TST0_DBG_PICTURE_BIT        : integer:=7;--//�������� ������ ����� � ��� + �������� ������������� �������� vbuf,
                                                                  --//��� ���(7)=1 - vbuf=0
constant C_DSN_VCTRL_REG_TST0_SKIPFR_CNT_CLR_BIT     : integer:=8;--//��� 1 - ���������� ����� ��������� ���������� ������ tst_vfrskip,
                                                                  --//��� 0 - ���
constant C_DSN_VCTRL_REG_TST0_DBG_RDHOLD_BIT         : integer:=10;--//�������� ������� ����������� ������� ������
constant C_DSN_VCTRL_REG_TST0_DBG_TRCHOLD_BIT        : integer:=11;--//�������� ������� ����������� ������� ��������
constant C_DSN_VCTRL_REG_TST0_LAST_BIT               : integer:=12;


--//--------------------------------------------------------------
--//�������� ������ dsn_track.vhd
--//--------------------------------------------------------------
constant C_DSN_TRC_REG_WIN_SKIP_LSB          : integer:=16#000#;
constant C_DSN_TRC_REG_WIN_SKIP_MSB          : integer:=16#001#;
constant C_DSN_TRC_REG_WIN_ACTIVE_LSB        : integer:=16#002#;
constant C_DSN_TRC_REG_WIN_ACTIVE_MSB        : integer:=16#003#;
constant C_DSN_TRC_REG_THRESHOLD             : integer:=16#004#;
constant C_DSN_TRC_REG_FR_OPTION_LSB         : integer:=16#005#;
constant C_DSN_TRC_REG_FR_OPTION_MSB         : integer:=16#006#;
constant C_DSN_TRC_REG_MEM_ATBUF_LSB         : integer:=16#007#;--//������� ����� ������ ���� ��������
constant C_DSN_TRC_REG_MEM_ATBUF_MSB         : integer:=16#008#;
constant C_DSN_TRC_REG_MEM_AEBUF_LSB         : integer:=16#009#;--//������� ����� ������ ���� �������� (������)
constant C_DSN_TRC_REG_MEM_AEBUF_MSB         : integer:=16#00A#;
constant C_DSN_TRC_REG_ZONE_SKIP_LSB         : integer:=16#00B#;
constant C_DSN_TRC_REG_ZONE_SKIP_MSB         : integer:=16#00C#;
constant C_DSN_TRC_REG_ZONE_ACTIVE_LSB       : integer:=16#00D#;
constant C_DSN_TRC_REG_ZONE_ACTIVE_MSB       : integer:=16#00E#;

constant C_DSN_TRC_REG_CTRL_L                : integer:=16#010#;
--constant C_DSN_TRC_REG_CTRL_M                : integer:=16#011#;
constant C_DSN_TRC_REG_MEM_TRN_LEN           : integer:=16#012#;
constant C_DSN_TRC_REG_TST0                  : integer:=16#013#;
--constant C_DSN_TRC_REG_TST1                  : integer:=16#014#;


--//������ �������� = ���-�� ����� �������
--//�����: ���� ������� ������ ��� 1-�� ������
constant C_DSN_TRC_CH_COUNT                       : integer:=1;--//������ ���-��
constant C_DSN_TRC_CH_MAX_COUNT                   : integer:=3;--//Max ���-��

--//Register C_DSN_TRC_REG_MEM_ADDR / Bit Map:
constant C_DSN_TRC_REG_MEM_ADR_OFFSET_LSB_BIT     : integer:=C_HREG_USR_MEM_ADR_OFFSET_LSB_BIT;--0;
constant C_DSN_TRC_REG_MEM_ADR_OFFSET_MSB_BIT     : integer:=C_HREG_USR_MEM_ADR_OFFSET_MSB_BIT;--27;
constant C_DSN_TRC_REG_MEM_ADR_BANK_LSB_BIT       : integer:=C_HREG_USR_MEM_ADR_BANK_LSB_BIT;--28;
constant C_DSN_TRC_REG_MEM_ADR_BANK_MSB_BIT       : integer:=C_HREG_USR_MEM_ADR_BANK_MSB_BIT;--29;
constant C_DSN_TRC_REG_MEM_LAST_BIT               : integer:=C_DSN_TRC_REG_MEM_ADR_BANK_MSB_BIT;


constant C_DSN_TRC_MEM_VCH                        : integer:=3;
constant C_DSN_TRC_MEM_VFR_TBUF                   : integer:=1;
constant C_DSN_TRC_MEM_VFR_EBUF                   : integer:=0;


--//Bit Maps:
--//Register C_DSN_TRC_REG_CTRL / Bit Map:
constant C_DSN_TRC_REG_CTRL_CH_IDX_LSB_BIT          : integer:=0;
constant C_DSN_TRC_REG_CTRL_CH_IDX_MSB_BIT          : integer:=3;
constant C_DSN_TRC_REG_CTRL_SET_BIT                 : integer:=7;
constant C_DSN_TRC_REG_CTRL_WORK_BIT                : integer:=9;
constant C_DSN_TRC_REG_CTRL_LAST_BIT                : integer:=C_DSN_TRC_REG_CTRL_WORK_BIT;


--//Register C_DSN_TRC_REG_TST0 / Bit Map:
constant C_DSN_TRC_REG_TST0_DIS_WRRESULT_BIT        : integer:=0;
--constant C_DSN_TRC_REG_TST0_NXTFR_MNL_BIT           : integer:=1;
constant C_DSN_TRC_REG_TST0_TRCZONE_MNL_BIT         : integer:=2;--//1/0 - ���� ��������=�� ���������� dsn_track.vhd / ���� ��������=VCTRL/FR_ACTIVE
constant C_DSN_TRC_REG_TST0_COLOR_BIT               : integer:=3;--//�������� ���������� ������� vcoldemosaic_main.vhd � ��������. (0/1 - baypass/���������� �� VCTRL)
constant C_DSN_TRC_REG_TST0_SOBEL_CTRL_DIV_BIT      : integer:=4;--//1/0 - dx/2 � dy/2 /��� �������
constant C_DSN_TRC_REG_TST0_SOBEL_CTRL_MULT_BIT     : integer:=5;--//1/0 - ������ ������ ������������ ������� (dx^2 + dy^2)^0.5
constant C_DSN_TRC_REG_TST0_DIS_WRTBUF_BIT          : integer:=6;--//1/0 - ���������/��������� ������ ������ � TBUF
constant C_DSN_TRC_REG_TST0_TRCWIN_DIN_SEL_BIT      : integer:=7;--//1/0 - �� ���� ������ trc_win ������/����������� ������� ����� ������
constant C_DSN_TRC_REG_TST0_TBUF_CLR_BIT            : integer:=8;--//1 - ������� ������ RAM/TRACK/TBUF (������ ������� � ����� ��������������)
constant C_DSN_TRC_REG_TST0_LAST_BIT                : integer:=C_DSN_TRC_REG_TST0_TBUF_CLR_BIT;


--//--------------------------------------------------------------
--//�������� ������ dsn_track_nik.vhd
--//--------------------------------------------------------------
constant C_DSN_TRCNIK_REG_IP0                       : integer:=16#000#;
constant C_DSN_TRCNIK_REG_IP1                       : integer:=16#001#;
constant C_DSN_TRCNIK_REG_IP2                       : integer:=16#002#;
constant C_DSN_TRCNIK_REG_IP3                       : integer:=16#003#;
constant C_DSN_TRCNIK_REG_IP4                       : integer:=16#004#;
constant C_DSN_TRCNIK_REG_IP5                       : integer:=16#005#;
constant C_DSN_TRCNIK_REG_IP6                       : integer:=16#006#;
constant C_DSN_TRCNIK_REG_IP7                       : integer:=16#007#;
constant C_DSN_TRCNIK_REG_OPT                       : integer:=16#008#;
constant C_DSN_TRCNIK_REG_MEM_RBUF_LSB              : integer:=16#009#;--//������� ����� ������ ����������
constant C_DSN_TRCNIK_REG_MEM_RBUF_MSB              : integer:=16#00A#;

constant C_DSN_TRCNIK_REG_CTRL_L                    : integer:=16#010#;
--constant C_DSN_TRCNIK_REG_CTRL_M                    : integer:=16#011#;
constant C_DSN_TRCNIK_REG_MEM_TRN_LEN               : integer:=16#012#;
constant C_DSN_TRCNIK_REG_TST0                      : integer:=16#013#;
--constant C_DSN_TRCNIK_REG_TST1                      : integer:=16#014#;


--//������ �������� = ���-�� ����� �������
--//�����: ���� ������� ������ ��� 1-�� ������
constant C_DSN_TRCNIK_CH_COUNT                       : integer:=1;--//������ ���-��
constant C_DSN_TRCNIK_CH_MAX_COUNT                   : integer:=3;--//��� ���-��

--/������������ ������
constant C_DSN_TRCNIK_IP_COUNT                       : integer:=4;--//������� ���-��
constant C_DSN_TRCNIK_IP_MAX_COUNT                   : integer:=8;--//��� ���-��


--//Register C_DSN_TRCNIK_REG_MEM_ADDR / Bit Map:
constant C_DSN_TRCNIK_REG_MEM_ADR_OFFSET_LSB_BIT     : integer:=C_HREG_USR_MEM_ADR_OFFSET_LSB_BIT;--0;
constant C_DSN_TRCNIK_REG_MEM_ADR_OFFSET_MSB_BIT     : integer:=C_HREG_USR_MEM_ADR_OFFSET_MSB_BIT;--27;
constant C_DSN_TRCNIK_REG_MEM_ADR_BANK_LSB_BIT       : integer:=C_HREG_USR_MEM_ADR_BANK_LSB_BIT;--28;
constant C_DSN_TRCNIK_REG_MEM_ADR_BANK_MSB_BIT       : integer:=C_HREG_USR_MEM_ADR_BANK_MSB_BIT;--29;
constant C_DSN_TRCNIK_REG_MEM_LAST_BIT               : integer:=C_DSN_TRCNIK_REG_MEM_ADR_BANK_MSB_BIT;


--//Bit Maps:
--//Register C_DSN_TRCNIK_REG_CTRL / Bit Map:
constant C_DSN_TRCNIK_REG_CTRL_CH_LSB_BIT            : integer:=0;
constant C_DSN_TRCNIK_REG_CTRL_CH_MSB_BIT            : integer:=3;
constant C_DSN_TRCNIK_REG_CTRL_SET_BIT               : integer:=7;
constant C_DSN_TRCNIK_REG_CTRL_WORK_BIT              : integer:=9;
constant C_DSN_TRCNIK_REG_CTRL_LAST_BIT              : integer:=C_DSN_TRCNIK_REG_CTRL_WORK_BIT;


--//Register C_DSN_TRCNIK_REG_OPT / Bit Map:
constant C_DSN_TRCNIK_REG_OPT_SOBEL_CTRL_MULT_BIT     : integer:=0;--//1/0 - ������ ������ ������������ ������� (dx^2 + dy^2)^0.5
constant C_DSN_TRCNIK_REG_OPT_SOBEL_CTRL_DIV_BIT      : integer:=1;--//1/0 - dx/2 � dy/2 /��� �������
constant C_DSN_TRCNIK_REG_OPT_DBG_IP_LSB_BIT          : integer:=2;--//������� ������ ��������� ���������� (������� ���-�� ��)
constant C_DSN_TRCNIK_REG_OPT_DBG_IP_MSB_BIT          : integer:=4;--//
constant C_DSN_TRCNIK_REG_OPT_ANG_LSB_BIT             : integer:=5;--//����� ��������� ������� ����������� ��������� �������
constant C_DSN_TRCNIK_REG_OPT_ANG_MSB_BIT             : integer:=6;--//(���� ����������� 2-�, ��� 4)
constant C_DSN_TRCNIK_REG_OPT_LAST_BIT                : integer:=C_DSN_TRCNIK_REG_OPT_ANG_MSB_BIT;


--//Register C_DSN_TRCNIK_REG_TST0 / Bit Map:
constant C_DSN_TRCNIK_REG_TST0_DIS_WRRESULT_BIT       : integer:=0;
constant C_DSN_TRCNIK_REG_TST0_TIMEOUT_CLR_BIT        : integer:=1;--//
constant C_DSN_TRCNIK_REG_TST0_COLOR_DIS_BIT          : integer:=3;--//1/0 - ���������/��������� ������ ������ vcoldemosaic_main.vhd � ���� ������ ��������
constant C_DSN_TRCNIK_REG_TST0_COLOR_DBG_BIT          : integer:=4;--//������� ������ vcoldemosaic_main.vhd 0/1 - ����/���
constant C_DSN_TRCNKI_REG_TST0_LAST_BIT               : integer:=C_DSN_TRCNIK_REG_TST0_COLOR_DBG_BIT;

--//--------------------------------------------------------------
--//�������� ������ dsn_testing.vhd
--//--------------------------------------------------------------
constant C_DSN_TSTING_REG_CTRL_L                : integer:=16#000#;
constant C_DSN_TSTING_REG_CTRL_M                : integer:=16#001#;
constant C_DSN_TSTING_REG_TST0                  : integer:=16#002#;
constant C_DSN_TSTING_REG_T05_US                : integer:=16#003#;--
constant C_DSN_TSTING_REG_PIX                   : integer:=16#004#;
constant C_DSN_TSTING_REG_ROW                   : integer:=16#005#;
--constant C_DSN_TSTING_REG_FRAME_SIZE_LSB        : integer:=16#006#;
--constant C_DSN_TSTING_REG_FRAME_SIZE_MSB        : integer:=16#007#;
--constant C_DSN_TSTING_REG_PKTLEN                : integer:=16#008#;
constant C_DSN_TSTING_REG_ROW_SEND_TIME_DLY     : integer:=16#009#;
constant C_DSN_TSTING_REG_FR_SEND_TIME_DLY      : integer:=16#00A#;

constant C_DSN_TSTING_REG_TXBUF_FULL_CNT        : integer:=16#00B#;

constant C_DSN_TSTING_REG_COLOR_LSB             : integer:=16#00C#;
constant C_DSN_TSTING_REG_COLOR_MSB             : integer:=16#00D#;

--//Bit Maps:
--//Register C_DSN_TSTING_REG_CTRL / Bit Map:
constant C_DSN_TSTING_REG_CTRL_MODE_LSB_BIT       : integer:=0;
constant C_DSN_TSTING_REG_CTRL_MODE_MSB_BIT       : integer:=3;
constant C_DSN_TSTING_REG_CTRL_START_BIT          : integer:=4;
constant C_DSN_TSTING_REG_CTRL_FRTXD_2DW_CNT_BIT  : integer:=5;
constant C_DSN_TSTING_REG_CTRL_FRAME_GRAY_BIT     : integer:=6;--//1Pix=8bit
constant C_DSN_TSTING_REG_CTRL_FRAME_SET_MNL_BIT  : integer:=7;
constant C_DSN_TSTING_REG_CTRL_FRAME_CH_AUTO_BIT  : integer:=8;
constant C_DSN_TSTING_REG_CTRL_FRAME_CH_LSB_BIT   : integer:=9;
constant C_DSN_TSTING_REG_CTRL_FRAME_CH_MSB_BIT   : integer:=10;
constant C_DSN_TSTING_REG_CTRL_FRAME_DIAGONAL_BIT : integer:=11;
constant C_DSN_TSTING_REG_CTRL_FRAME_TSTDATA_2_BIT: integer:=12;
--constant C_DSN_TSTING_REG_CTRL_FRAME_START_SYNC_BIT: integer:=13;

constant C_DSN_TSTING_REG_CTRLM_FRAME_MOVE_LSB_BIT: integer:=0;
constant C_DSN_TSTING_REG_CTRLM_FRAME_MOVE_MSB_BIT: integer:=6;

--//���� C_DSN_TSTING_REG_CTRL_MODE:
--//��� - 0x00 - ����� �� ���������
constant C_DSN_TSTING_MODE_SEND_TXD_STREAM     : integer:=1;
constant C_DSN_TSTING_MODE_SEND_TXD_SINGL      : integer:=2;



end prj_def;


package body prj_def is

end prj_def;

