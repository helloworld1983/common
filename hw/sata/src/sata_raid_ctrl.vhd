-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 31.03.2011 18:27:17
-- Module Name : sata_raid_ctrl
--
-- ���������� : ���������� �������� sata_host.vhd
--
-- �����: ������������� RAMBUF �������� �� ��� ���� ��� ������, ����� �������� ��.
--        ���������� --//��������� ������������� RAMBUF ������ ��� ����������� ���� ������:
--
-- Revision:
-- Revision 0.01 - File Created
--
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
use work.sata_raid_pkg.all;
use work.sata_unit_pkg.all;

entity sata_raid_ctrl is
generic
(
G_HDD_COUNT : integer:=1;    --//���-�� sata ����-� (min/max - 1/8)
G_DBGCS     : string :="OFF";
G_DBG       : string :="OFF";
G_SIM       : string :="OFF"
);
port
(
--------------------------------------------------
--����� � ������� dsn_hdd.vhd
--------------------------------------------------
p_in_usr_ctrl           : in    std_logic_vector(C_USR_GCTRL_LAST_BIT downto 0);
p_out_usr_status        : out   TUsrStatus;

--//ctrl - hw start
p_out_hw_work           : out   std_logic;
p_out_hw_start          : out   std_logic;
p_in_hw_start           : in    std_logic;

--//cmdpkt
p_in_usr_cxd            : in    std_logic_vector(15 downto 0);
p_in_usr_cxd_wr         : in    std_logic;

--//txfifo
p_in_usr_txd            : in    std_logic_vector(31 downto 0);
p_out_usr_txd_rd        : out   std_logic;
p_in_usr_txbuf_empty    : in    std_logic;

--//rxfifo
p_out_usr_rxd           : out   std_logic_vector(31 downto 0);
p_out_usr_rxd_wr        : out   std_logic;
p_in_usr_rxbuf_full     : in    std_logic;

--------------------------------------------------
--����� � ������� sata_raid_decoder.vhd
--------------------------------------------------
p_in_sh_status          : in    TALStatus_SHCountMax;
p_out_sh_ctrl           : out   TALCtrl_SHCountMax;

p_in_raid               : in    TRaid;
p_in_sh_num             : in    std_logic_vector(2 downto 0);
p_out_sh_hdd            : out   std_logic_vector(2 downto 0);
p_out_sh_mask           : out   std_logic_vector(G_HDD_COUNT-1 downto 0);
p_out_sh_padding        : out   std_logic;

p_out_sh_cxd            : out   std_logic_vector(15 downto 0);
p_out_sh_cxd_sof_n      : out   std_logic;
p_out_sh_cxd_eof_n      : out   std_logic;
p_out_sh_cxd_src_rdy_n  : out   std_logic;

p_out_sh_txd            : out   std_logic_vector(31 downto 0);
p_out_sh_txd_wr         : out   std_logic;
p_in_sh_txbuf_full      : in    std_logic;

p_in_sh_rxd             : in    std_logic_vector(31 downto 0);
p_out_sh_rxd_rd         : out   std_logic;
p_in_sh_rxbuf_empty     : in    std_logic;

--------------------------------------------------
--��������������� �������
--------------------------------------------------
p_in_tst                : in    std_logic_vector(31 downto 0);
p_out_tst               : out   std_logic_vector(31 downto 0);
p_out_dbgcs             : out   TSH_ila;

p_in_sh_tst             : in    TBus32_SHCountMax;
p_out_sh_tst            : out   TBus32_SHCountMax;

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk                : in    std_logic;
p_in_rst                : in    std_logic
);
end sata_raid_ctrl;

architecture behavioral of sata_raid_ctrl is

constant CI_SECTOR_SIZE_BYTE : integer:=selval(C_SECTOR_SIZE_BYTE, C_SIM_SECTOR_SIZE_DWORD*4, strcmp(G_SIM, "OFF"));

signal i_hwstart_dly_on            : std_logic;
signal i_err_clr                   : std_logic;
signal i_err_streambuf             : std_logic;
signal i_usr_status                : TUsrStatus;

signal i_dma_armed                 : std_logic;

signal sr_dev_err                  : std_logic_vector(0 to 1);

signal i_cmdpkt                    : THDDPkt;
signal i_cmdpkt_cnt                : std_logic_vector(3 downto 0);--//������� ������ ������������ ���������� ������
signal i_cmdpkt_get_done           : std_logic;                   --//����� cmd ������ ��������

type TUserMode is record
sw       : std_logic;
hw       : std_logic;
hw_work  : std_logic;
lbaend   : std_logic;
stop     : std_logic;
end record;
signal i_usrmode                   : TUserMode;

signal i_lba_end                   : std_logic_vector(i_cmdpkt.lba'range);

signal i_atacmdw_start             : std_logic_vector(G_HDD_COUNT-1 downto 0);
signal i_atacmdnew                 : std_logic;
signal i_atacmdnew_cnt             : std_logic_vector(3 downto 0);
signal i_atacmdtest                : std_logic;

signal i_sh_atacmd                 : THDDPkt;
signal sr_sh_bsy                   : std_logic_vector(0 to 1);
type TShDetect is record
cmddone : std_logic;--//���������� ���������� ��� �������
err     : std_logic;--//���������� ������
end record;
signal i_sh_det                    : TShDetect;
signal sr_sh_cmddone               : std_logic_vector(0 to 4);

signal i_sh_cmddone_width          : std_logic;
signal i_sh_cmddone_width_cnt      : std_logic_vector(2 downto 0);
signal i_hw_start_in               : std_logic;
signal sr_hw_start_in              : std_logic_vector(0 to 1);

signal i_sh_cmd_hw_start           : std_logic:='0';
signal i_sh_cmd_en                 : std_logic;
signal i_sh_cmd_start              : std_logic;
signal i_sh_cmdcnt                 : std_logic_vector(i_cmdpkt_cnt'range);
signal i_sh_cmdcnt_en              : std_logic;
signal i_sh_cxdout                 : std_logic_vector(p_in_usr_cxd'range);
signal i_sh_cxd_sof                : std_logic;
signal i_sh_cxd_eof                : std_logic;
signal i_sh_cxd_src_rdy            : std_logic;

--signal i_sh_trn_byte_count         : std_logic_vector(i_cmdpkt.scount'length + log2(CI_SECTOR_SIZE_BYTE)-1 downto 0);
--signal i_sh_trn_dw_count           : std_logic_vector(i_sh_trn_byte_count'range);
signal i_sh_hddcnt_ld              : std_logic_vector(p_in_sh_num'range);
signal i_sh_hddcnt                 : std_logic_vector(p_in_sh_num'range);
signal i_sh_trn_en                 : std_logic;
signal i_sh_trn_den                : std_logic;
signal i_sh_txd_wr                 : std_logic;
signal i_sh_rxd_rd                 : std_logic;
signal i_sh_padding                : std_logic;
signal i_sh_padding_en             : std_logic;

signal i_raid_cl_byte_count        : std_logic_vector(i_cmdpkt.scount'length + log2(CI_SECTOR_SIZE_BYTE)-1 downto 0);
signal i_raid_cl_dw_count          : std_logic_vector(i_raid_cl_byte_count'range);
signal i_raid_cl_cntdw             : std_logic_vector(i_raid_cl_dw_count'range);
signal i_raid_cl_done              : std_logic;
--signal i_raid_cl_cntdw             : std_logic_vector(i_cmdpkt.scount'range);
--signal i_raid_cnts                 : std_logic_vector(i_cmdpkt.scount'range);
signal i_raid_trn_cnts             : std_logic_vector(i_cmdpkt.scount'range); --//������� �������� ������� ��� �������
signal sr_raid_trn_sdone           : std_logic;--_vector(0 to 1); --//��� ������� ���������� ���������� ��� ������� ��� ���� HDD � RAID
signal i_raid_trn_done             : std_logic_vector(1 downto 0);
signal sr_raid_trn_done            : std_logic;--_vector(0 to 0); --//������� ��������� RAID ���������


signal i_tst                       : std_logic_vector(G_HDD_COUNT-1 downto 0);
signal sr_tst_bsy                  : std_logic_vector(0 to 1):=(others=>'0');
signal tst_cmddone                 : std_logic:='0';
signal sr_hw_work                  : std_logic_vector(0 to 1):=(others=>'0');
signal tst_hw_stop                 : std_logic:='0';
signal tst_det_clr_err             : std_logic:='0';


--MAIN
begin

--//----------------------------------
--//��������������� �������
--//----------------------------------
gen_dbg_off : if strcmp(G_DBG,"OFF") generate
p_out_tst(31 downto 0)<=(others=>'0');
end generate gen_dbg_off;

gen_dbg_on : if strcmp(G_DBG,"ON") generate
--p_out_tst(31 downto 0)<=(others=>'0');
ltstout:process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    for i in 0 to G_HDD_COUNT-1 loop
    i_tst(i)<='0';
    end loop;
  elsif p_in_clk'event and p_in_clk='1' then
    for i in 0 to G_HDD_COUNT-1 loop
    i_tst(i)<=OR_reduce(p_in_sh_tst(i)(2 downto 0));
    end loop;
  end if;
end process ltstout;

p_out_tst(0)<=OR_reduce(i_tst);
p_out_tst(31 downto 1)<=(others=>'0');
end generate gen_dbg_on;



--//------------------------------------------
--//�������������
--//------------------------------------------
i_err_clr<=p_in_usr_ctrl(C_USR_GCTRL_ERR_CLR_BIT);
i_err_streambuf<=p_in_usr_ctrl(C_USR_GCTRL_ERR_STREAMBUF_BIT);--//������ ��� ������ HW
i_hwstart_dly_on<=p_in_usr_ctrl(C_USR_GCTRL_HWSTART_DLY_ON_BIT);

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_atacmdnew<='0';
    i_atacmdnew_cnt<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then

    --//��������� �������
    if i_cmdpkt_get_done='1' and i_sh_cmd_en='1' then
      i_atacmdnew<='1';
    elsif i_atacmdnew_cnt(i_atacmdnew_cnt'high)='1' then
      i_atacmdnew<='0';
    end if;

    if i_atacmdnew='0' then
      i_atacmdnew_cnt<=(others=>'0');
    else
      i_atacmdnew_cnt<=i_atacmdnew_cnt+1;
    end if;

  end if;
end process;

i_atacmdtest<=i_atacmdnew when (i_cmdpkt.command=CONV_STD_LOGIC_VECTOR(C_ATA_CMD_WRITE_SECTORS_EXT, i_cmdpkt.command'length) or
                                i_cmdpkt.command=CONV_STD_LOGIC_VECTOR(C_ATA_CMD_WRITE_DMA_EXT, i_cmdpkt.command'length)) else '0';

gen_sh_pout : for i in 0 to C_HDD_COUNT_MAX-1 generate
p_out_sh_tst(i)<=(others=>'0'); --//��������������� ����� ������� sata_host
p_out_sh_ctrl(i)<=p_in_usr_ctrl;--//�������� ����������� ���������� ������� sata_host
end generate gen_sh_pout;


--//----------------------------------
--//�������� ������
--//----------------------------------
p_out_usr_status<=i_usr_status;

--//RAMBUF:
i_usr_status.dmacfg.sw_mode<=i_usrmode.sw;
i_usr_status.dmacfg.hw_mode<=i_usrmode.hw_work;
i_usr_status.dmacfg.armed<=i_dma_armed;
i_usr_status.dmacfg.atacmdnew<=i_atacmdnew;
i_usr_status.dmacfg.atacmdw<=OR_reduce(i_atacmdw_start);
i_usr_status.dmacfg.atadone<=sr_sh_cmddone(2);
i_usr_status.dmacfg.error<=OR_reduce(i_usr_status.ch_err(G_HDD_COUNT-1 downto 0));
i_usr_status.dmacfg.clr_err<=i_err_clr;
i_usr_status.dmacfg.raid.used<=p_in_raid.used;
i_usr_status.dmacfg.raid.hddcount<=p_in_raid.hddcount;
i_usr_status.dmacfg.scount<=i_sh_atacmd.scount;
i_usr_status.dmacfg.tstgen_start<=i_atacmdtest;

process(p_in_rst,p_in_clk)
  variable dma_armed: std_logic;
begin
  if p_in_rst='1' then
      dma_armed:='0';
    i_dma_armed<='0';
  elsif p_in_clk'event and p_in_clk='1' then

    dma_armed:='0';

    --//��������� ������������� RAMBUF ������ ��� ����������� ���� ������:
    if i_cmdpkt_get_done='1' then
      if  i_cmdpkt.command=CONV_STD_LOGIC_VECTOR(C_ATA_CMD_IDENTIFY_DEV, i_cmdpkt.command'length) or
          i_cmdpkt.command=CONV_STD_LOGIC_VECTOR(C_ATA_CMD_WRITE_SECTORS_EXT, i_cmdpkt.command'length) or
          i_cmdpkt.command=CONV_STD_LOGIC_VECTOR(C_ATA_CMD_READ_SECTORS_EXT, i_cmdpkt.command'length) or
          i_cmdpkt.command=CONV_STD_LOGIC_VECTOR(C_ATA_CMD_WRITE_DMA_EXT, i_cmdpkt.command'length) or
          i_cmdpkt.command=CONV_STD_LOGIC_VECTOR(C_ATA_CMD_READ_DMA_EXT, i_cmdpkt.command'length)  then
            dma_armed:='1';
      end if;
    end if;

    i_dma_armed<=dma_armed;

  end if;
end process;



--//���-�� HDD ������������ � FPGA
i_usr_status.hdd_count<=CONV_STD_LOGIC_VECTOR(G_HDD_COUNT, i_usr_status.hdd_count'length);

--//����� ��������:
i_usr_status.lba_bp<=i_sh_atacmd.lba;

--//������� ����������:
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_usr_status.dev_bsy<='0';
    i_usr_status.dev_rdy<='0';
    i_usr_status.dev_err<='0';
    i_usr_status.dev_ipf<='0';
--    i_usr_status.usr<=(others=>'0');
--    i_usr_status.lba_bp<=(others=>'0');
    for i in 0 to G_HDD_COUNT-1 loop
      i_usr_status.ch_bsy(i)<='0';
      i_usr_status.ch_rdy(i)<='0';
      i_usr_status.ch_err(i)<='0';
      i_usr_status.ch_ipf(i)<='0';
      i_usr_status.ch_ataerror(i)<=(others=>'0');
      i_usr_status.ch_atastatus(i)<=(others=>'0');
      i_usr_status.ch_serror(i)<=(others=>'0');
      i_usr_status.ch_sstatus(i)<=(others=>'0');
--      i_usr_status.ch_usr(i)<=(others=>'0');
    end loop;

    i_atacmdw_start<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then

    --//���������� �������:
    i_usr_status.dev_bsy<=OR_reduce(i_usr_status.ch_bsy(G_HDD_COUNT-1 downto 0)) or i_usrmode.hw_work;
    i_usr_status.dev_err<=OR_reduce(i_usr_status.ch_err(G_HDD_COUNT-1 downto 0)) or i_err_streambuf;
    i_usr_status.dev_rdy<=AND_reduce(i_usr_status.ch_rdy(G_HDD_COUNT-1 downto 0));
    i_usr_status.dev_ipf<=(AND_reduce(i_usr_status.ch_ipf(G_HDD_COUNT-1 downto 0)) and i_usrmode.sw) or
                          (AND_reduce(i_usr_status.ch_ipf(G_HDD_COUNT-1 downto 0)) and not i_usrmode.hw_work);
--    i_usr_status.lba_bp<=i_sh_atacmd.lba;
--    i_usr_status.usr<=(others=>'0');

    --//������� ������������ �������:
    for i in 0 to G_HDD_COUNT-1 loop
      i_atacmdw_start(i)    <=p_in_sh_status(i).usr(C_AUSR_DWR_START_BIT);
      i_usr_status.ch_bsy(i)<=p_in_sh_status(i).usr(C_AUSR_BSY_BIT);
      i_usr_status.ch_err(i)<=p_in_sh_status(i).usr(C_AUSR_ERR_BIT);
      i_usr_status.ch_rdy(i)<=p_in_sh_status(i).sstatus(C_ASSTAT_IPM_BIT_L);
      i_usr_status.ch_ipf(i)<=p_in_sh_status(i).ipf;--//IPF - (Interrupt pending flag) ��� �� �������� ����������

      i_usr_status.ch_ataerror(i) <=p_in_sh_status(i).ataerror;
      i_usr_status.ch_atastatus(i)<=p_in_sh_status(i).atastatus;
      i_usr_status.ch_serror(i)   <=p_in_sh_status(i).serror;
      i_usr_status.ch_sstatus(i)  <=p_in_sh_status(i).sstatus;
--      i_usr_status.ch_usr(i)<=(others=>'0');
    end loop;

  end if;
end process;


--//�������� ������
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then

    sr_dev_err<=(others=>'0');
    sr_sh_bsy<=(others=>'0');
    i_sh_det.cmddone<='0';
    i_sh_det.err<='0';
    sr_sh_cmddone<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then

    sr_dev_err<=i_usr_status.dev_err & sr_dev_err(0 to 0);

    sr_sh_bsy<=OR_reduce(i_usr_status.ch_bsy(G_HDD_COUNT-1 downto 0)) & sr_sh_bsy(0 to 0);

    i_sh_det.cmddone<=( not p_in_raid.used and not sr_sh_bsy(0) and sr_sh_bsy(1)) or
                      (     p_in_raid.used and sr_raid_trn_done );

    i_sh_det.err<=sr_dev_err(0) and not sr_dev_err(1);

    sr_sh_cmddone<=i_sh_det.cmddone & sr_sh_cmddone(0 to 3);

  end if;
end process;






--//------------------------------------------
--//�����/��������� ���������� ������
--//------------------------------------------
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_cmdpkt_cnt<=(others=>'0');
    i_cmdpkt_get_done<='0';

  elsif p_in_clk'event and p_in_clk='1' then
    if p_in_usr_cxd_wr='1' then
      if i_cmdpkt_cnt=CONV_STD_LOGIC_VECTOR(C_HDDPKT_DCOUNT-1, i_cmdpkt_cnt'length) then
        i_cmdpkt_cnt<=(others=>'0');
      else
        i_cmdpkt_cnt<=i_cmdpkt_cnt + 1;
      end if;

      if i_cmdpkt_cnt=CONV_STD_LOGIC_VECTOR(C_HDDPKT_DCOUNT-1, i_cmdpkt_cnt'length) then
        i_cmdpkt_get_done<='1';
      end if;
    else
      i_cmdpkt_get_done<='0';
    end if;

  end if;
end process;

--//����� ���������� ������
process(p_in_rst,p_in_clk)
  variable raidcmd: std_logic_vector(C_HDDPKT_RAIDCMD_M_BIT-C_HDDPKT_RAIDCMD_L_BIT downto 0);
  variable satacmd: std_logic_vector(C_HDDPKT_SATACMD_M_BIT-C_HDDPKT_SATACMD_L_BIT downto 0);
begin
  if p_in_rst='1' then
    i_cmdpkt.ctrl<=(others=>'0');
    i_cmdpkt.feature<=(others=>'0');
    i_cmdpkt.lba<=(others=>'0');
    i_cmdpkt.scount<=(others=>'0');
    i_cmdpkt.command<=(others=>'0');
    i_cmdpkt.control<=(others=>'0');
    i_cmdpkt.device<=(others=>'0');
    i_cmdpkt.raid_cl<=(others=>'0');

    i_usrmode.stop<='0';
    i_usrmode.sw<='0';
    i_usrmode.hw<='0';
    i_usrmode.lbaend<='0';

    i_sh_cmd_en<='0';

  elsif p_in_clk'event and p_in_clk='1' then

    if p_in_usr_cxd_wr='1' then
      if    i_cmdpkt_cnt=CONV_STD_LOGIC_VECTOR(C_HDDPKT_USRCTRL, i_cmdpkt_cnt'length) then i_cmdpkt.ctrl<=p_in_usr_cxd;

          --//������������� ������ ������:
          raidcmd:=p_in_usr_cxd(C_HDDPKT_RAIDCMD_M_BIT downto C_HDDPKT_RAIDCMD_L_BIT);
          satacmd:=p_in_usr_cxd(C_HDDPKT_SATACMD_M_BIT downto C_HDDPKT_SATACMD_L_BIT);

          if    raidcmd=CONV_STD_LOGIC_VECTOR(C_RAIDCMD_STOP, raidcmd'length) then
            i_usrmode.stop<='1';
            i_usrmode.sw<='0';
            i_usrmode.hw<='0';
            i_usrmode.lbaend<='0';

          elsif raidcmd=CONV_STD_LOGIC_VECTOR(C_RAIDCMD_SW, raidcmd'length) then
            i_usrmode.stop<='0';
            i_usrmode.sw<='1';
            i_usrmode.hw<='0';
            i_usrmode.lbaend<='0';

          elsif raidcmd=CONV_STD_LOGIC_VECTOR(C_RAIDCMD_HW, raidcmd'length) then
            i_usrmode.stop<='0';
            i_usrmode.sw<='0';
            i_usrmode.hw<='1';
            i_usrmode.lbaend<='0';

          elsif raidcmd=CONV_STD_LOGIC_VECTOR(C_RAIDCMD_LBAEND, raidcmd'length) then
            i_usrmode.stop<='0';
            i_usrmode.sw<='0';
            i_usrmode.hw<='0';
            i_usrmode.lbaend<='1';

          end if;

          if    satacmd=CONV_STD_LOGIC_VECTOR(C_SATACMD_ATACOMMAND, satacmd'length) or
                satacmd=CONV_STD_LOGIC_VECTOR(C_SATACMD_ATACONTROL, satacmd'length) then
            i_sh_cmd_en<='1';
          else
            i_sh_cmd_en<='0';
          end if;

      elsif i_cmdpkt_cnt=CONV_STD_LOGIC_VECTOR(C_HDDPKT_FEATURE, i_cmdpkt_cnt'length)      then i_cmdpkt.feature<=p_in_usr_cxd;
      elsif i_cmdpkt_cnt=CONV_STD_LOGIC_VECTOR(C_HDDPKT_LBA_LOW, i_cmdpkt_cnt'length)      then i_cmdpkt.lba(8*(0+1)-1 downto 8*0)<=p_in_usr_cxd( 7 downto 0);
                                                                                                i_cmdpkt.lba(8*(1+1)-1 downto 8*1)<=p_in_usr_cxd(15 downto 8);
      elsif i_cmdpkt_cnt=CONV_STD_LOGIC_VECTOR(C_HDDPKT_LBA_MID, i_cmdpkt_cnt'length)      then i_cmdpkt.lba(8*(2+1)-1 downto 8*2)<=p_in_usr_cxd( 7 downto 0);
                                                                                                i_cmdpkt.lba(8*(3+1)-1 downto 8*3)<=p_in_usr_cxd(15 downto 8);
      elsif i_cmdpkt_cnt=CONV_STD_LOGIC_VECTOR(C_HDDPKT_LBA_HIGH, i_cmdpkt_cnt'length)     then i_cmdpkt.lba(8*(4+1)-1 downto 8*4)<=p_in_usr_cxd( 7 downto 0);
                                                                                                i_cmdpkt.lba(8*(5+1)-1 downto 8*5)<=p_in_usr_cxd(15 downto 8);

      elsif i_cmdpkt_cnt=CONV_STD_LOGIC_VECTOR(C_HDDPKT_SECTOR_COUNT, i_cmdpkt_cnt'length) then i_cmdpkt.scount<=p_in_usr_cxd;
      elsif i_cmdpkt_cnt=CONV_STD_LOGIC_VECTOR(C_HDDPKT_DEVICE, i_cmdpkt_cnt'length)       then i_cmdpkt.device<=p_in_usr_cxd(7 downto 0);
                                                                                                i_cmdpkt.control<=p_in_usr_cxd(15 downto 8);
      elsif i_cmdpkt_cnt=CONV_STD_LOGIC_VECTOR(C_HDDPKT_COMMAND, i_cmdpkt_cnt'length)      then i_cmdpkt.command<=p_in_usr_cxd(7 downto 0);
      elsif i_cmdpkt_cnt=CONV_STD_LOGIC_VECTOR(C_HDDPKT_RAID_CL, i_cmdpkt_cnt'length)      then i_cmdpkt.raid_cl<=p_in_usr_cxd;

      end if;
    end if; --//if p_in_usr_cxd_wr='1' then

  end if;
end process;


--//�������� ���������� ������ � ������ sata_host.vhd
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_sh_cmd_start<='0';
    i_sh_cmdcnt<=(others=>'0');
    i_sh_cmdcnt_en<='0';
    i_sh_cxd_sof<='0';
    i_sh_cxd_eof<='0';
    i_sh_cxd_src_rdy<='0';

  elsif p_in_clk'event and p_in_clk='1' then

    i_sh_cmd_start<=(i_cmdpkt_get_done and (i_usrmode.hw or i_usrmode.sw)) or
                    (i_sh_cmd_hw_start and i_usrmode.hw_work);

    if i_sh_cmd_start='1' then
      i_sh_cmdcnt_en<='1';
    elsif i_sh_cmdcnt=CONV_STD_LOGIC_VECTOR(C_HDDPKT_DCOUNT, i_sh_cmdcnt'length) then
      i_sh_cmdcnt_en<='0';
    end if;

    if i_sh_cmdcnt_en='0' then
      i_sh_cmdcnt<=(others=>'0');
    else
      i_sh_cmdcnt<=i_sh_cmdcnt + 1;
    end if;

    if i_sh_cmdcnt_en='1' and i_sh_cmdcnt=(i_sh_cmdcnt'range=>'0') then
      i_sh_cxd_sof<='1';
    else
      i_sh_cxd_sof<='0';
    end if;

    if i_sh_cmdcnt=CONV_STD_LOGIC_VECTOR(C_HDDPKT_DCOUNT, i_sh_cmdcnt'length) then
      i_sh_cxd_eof<='1';
    else
      i_sh_cxd_eof<='0';
    end if;

    i_sh_cxd_src_rdy<=i_sh_cmdcnt_en;

  end if;
end process;

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_sh_cxdout<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then
    if i_sh_cmdcnt_en='1' then
      if    i_sh_cmdcnt=CONV_STD_LOGIC_VECTOR(C_HDDPKT_USRCTRL, i_sh_cmdcnt'length)      then i_sh_cxdout<=i_cmdpkt.ctrl;
      elsif i_sh_cmdcnt=CONV_STD_LOGIC_VECTOR(C_HDDPKT_FEATURE, i_sh_cmdcnt'length)      then i_sh_cxdout<=i_sh_atacmd.feature;
      elsif i_sh_cmdcnt=CONV_STD_LOGIC_VECTOR(C_HDDPKT_LBA_LOW, i_sh_cmdcnt'length)      then i_sh_cxdout( 7 downto 0)<=i_sh_atacmd.lba(8*(0+1)-1 downto 8*0);--lba_low
                                                                                              i_sh_cxdout(15 downto 8)<=i_sh_atacmd.lba(8*(3+1)-1 downto 8*3);--lba_low(exp)
      elsif i_sh_cmdcnt=CONV_STD_LOGIC_VECTOR(C_HDDPKT_LBA_MID, i_sh_cmdcnt'length)      then i_sh_cxdout( 7 downto 0)<=i_sh_atacmd.lba(8*(1+1)-1 downto 8*1);--lba_mid
                                                                                              i_sh_cxdout(15 downto 8)<=i_sh_atacmd.lba(8*(4+1)-1 downto 8*4);--lba_mid(exp)
      elsif i_sh_cmdcnt=CONV_STD_LOGIC_VECTOR(C_HDDPKT_LBA_HIGH, i_sh_cmdcnt'length)     then i_sh_cxdout( 7 downto 0)<=i_sh_atacmd.lba(8*(2+1)-1 downto 8*2);--lba_high
                                                                                              i_sh_cxdout(15 downto 8)<=i_sh_atacmd.lba(8*(5+1)-1 downto 8*5);--lba_high(exp)
      elsif i_sh_cmdcnt=CONV_STD_LOGIC_VECTOR(C_HDDPKT_SECTOR_COUNT, i_sh_cmdcnt'length) then i_sh_cxdout<=i_sh_atacmd.scount;
      elsif i_sh_cmdcnt=CONV_STD_LOGIC_VECTOR(C_HDDPKT_DEVICE, i_sh_cmdcnt'length)       then i_sh_cxdout( 7 downto 0)<=i_sh_atacmd.device;
                                                                                              i_sh_cxdout(15 downto 8)<=i_sh_atacmd.control;

      elsif i_sh_cmdcnt=CONV_STD_LOGIC_VECTOR(C_HDDPKT_COMMAND, i_sh_cmdcnt'length)      then i_sh_cxdout( 7 downto 0)<=i_sh_atacmd.command;
                                                                                              i_sh_cxdout(15 downto 8)<=(others=>'0');
      elsif i_sh_cmdcnt=CONV_STD_LOGIC_VECTOR(C_HDDPKT_RAID_CL, i_sh_cmdcnt'length)      then i_sh_cxdout<=i_sh_atacmd.raid_cl;
      end if;
    end if;

  end if;
end process;


p_out_sh_mask<=i_cmdpkt.ctrl(G_HDD_COUNT+C_HDDPKT_SATA_CS_L_BIT-1 downto C_HDDPKT_SATA_CS_L_BIT);

p_out_sh_cxd<=i_sh_cxdout;
p_out_sh_cxd_sof_n<=not i_sh_cxd_sof;
p_out_sh_cxd_eof_n<=not i_sh_cxd_eof;
p_out_sh_cxd_src_rdy_n<=not i_sh_cxd_src_rdy;




--//HW mode
p_out_hw_work  <=i_usrmode.hw_work;
p_out_hw_start <=i_sh_cmddone_width;

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_sh_cmddone_width<='0';
    i_sh_cmddone_width_cnt<=(others=>'0');

    i_hw_start_in<='0';
    sr_hw_start_in<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then

    --//��������� ������� ������� �������� ����������� ����� ��� �������,
    --//�.�. ������ sata_hwstart_ctrl.vhd �������� �� ������ �������
    if sr_sh_cmddone(4)='1' then
      i_sh_cmddone_width<='1';
    elsif i_sh_cmddone_width_cnt(i_sh_cmddone_width_cnt'high)='1' then
      i_sh_cmddone_width<='0';
    end if;

    if i_sh_cmddone_width='0' then
      i_sh_cmddone_width_cnt<=(others=>'0');
    else
      i_sh_cmddone_width_cnt<=i_sh_cmddone_width_cnt+1;
    end if;

    --//�������� ������ ����� �� ��������� ��������
    i_hw_start_in<=p_in_hw_start;
    sr_hw_start_in<=i_hw_start_in & sr_hw_start_in(0 to 0);

  end if;
end process;

--//����� ����������� �������: � ����������� ��������� ��� ������ ��� ��������
process(p_in_clk)
begin
  if p_in_clk'event and p_in_clk='1' then
    i_sh_cmd_hw_start<=(not i_hwstart_dly_on and sr_sh_cmddone(4)) or
                       (    i_hwstart_dly_on and not sr_hw_start_in(0) and sr_hw_start_in(1));
  end if;
end process;

--//����� HW: �������� ������
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_usrmode.hw_work<='0';
    i_sh_padding_en<='0';
  elsif p_in_clk'event and p_in_clk='1' then
    --//������ � HW ������
    if (i_usrmode.stop='1' and i_cmdpkt_get_done='1') or (i_sh_atacmd.lba>=i_lba_end and sr_sh_cmddone(1)='1') or i_sh_det.err='1' then
      i_usrmode.hw_work<='0';
    elsif i_usrmode.hw='1' and i_cmdpkt_get_done='1' then
      i_usrmode.hw_work<='1';
    end if;

    if i_err_clr='1' or i_usrmode.sw='1' or i_usrmode.lbaend='1' or i_usr_status.dev_rdy='0' then
      i_sh_padding_en<='0';
    elsif ((i_usrmode.stop='1' and i_cmdpkt_get_done='1') or i_sh_det.err='1') then
      i_sh_padding_en<='1';
    end if;

  end if;
end process;

--//����� HW: ����� ������ ������� STOP
--//WRITE HDD - ������������ ����������� ������ ��� ��������� ���������� (��� ������� sata_txbuf ������������� wr='1')
--//READ HDD  - ��� ������� sata_rxbuf ������������� ������ rd='1' ��� ����� ����� �������� ���������� ��������� ����������
i_sh_padding<=i_sh_padding_en and sr_sh_bsy(0) and not i_usrmode.hw_work;

--//��������� LBA End
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_lba_end<=(others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then

    if i_usrmode.lbaend='1' and i_cmdpkt_get_done='1' then
      i_lba_end<=i_cmdpkt.lba;
    end if;

  end if;
end process;

--//��������� ���������� ������� ��� �������
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_sh_atacmd.lba<=(others=>'0');
    i_sh_atacmd.scount<=(others=>'0');
    i_sh_atacmd.feature<=(others=>'0');
    i_sh_atacmd.device<=(others=>'0');
    i_sh_atacmd.control<=(others=>'0');
    i_sh_atacmd.command<=(others=>'0');
    i_sh_atacmd.raid_cl<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then

    if (i_usrmode.sw='1' or i_usrmode.hw='1') and i_cmdpkt_get_done='1' then
    --//�������� ������� ��� �������:
      i_sh_atacmd.lba<=i_cmdpkt.lba;
      i_sh_atacmd.scount<=i_cmdpkt.scount;
      i_sh_atacmd.feature<=i_cmdpkt.feature;
      i_sh_atacmd.device<=i_cmdpkt.device;
      i_sh_atacmd.control<=i_cmdpkt.control;
      i_sh_atacmd.command<=i_cmdpkt.command;
      i_sh_atacmd.raid_cl<=i_cmdpkt.raid_cl;

    elsif i_sh_det.cmddone='1' then
    --//LBA update
      i_sh_atacmd.lba<=i_sh_atacmd.lba + EXT(i_sh_atacmd.scount, i_sh_atacmd.lba'length);
    end if;

  end if;
end process;


--//-----------------------------
--//������/������ ������� ������� sata_host
--//-----------------------------
p_out_sh_hdd<=i_sh_hddcnt;
p_out_sh_padding<=i_sh_padding;

--//������ � TxBUF sata_host
p_out_sh_txd<=p_in_usr_txd;
p_out_sh_txd_wr<=i_sh_txd_wr;

--//                                                                     | ������ � ����� HDD   |  ������ � RAID               |
i_sh_txd_wr<=( (not p_in_usr_txbuf_empty and not p_in_sh_txbuf_full) and (not p_in_raid.used or (i_sh_trn_en and p_in_raid.used)) );

p_out_usr_txd_rd<=i_sh_txd_wr;


--//������ �� RxBUF sata_host
p_out_usr_rxd<=p_in_sh_rxd;
--p_out_usr_rxd_wr<=i_sh_rxd_rd;--//sata_rxfifo - FWFT(First-Word-Fall-Through) FIFO

--//sata_rxfifo - SATANDART FIFO (��������� �������� �.�.
--//������ �� ������ ��������� ����� ��������� 1clk ������� rd)
process(p_in_clk)
begin
  if p_in_clk'event and p_in_clk='1' then
    p_out_usr_rxd_wr<=i_sh_rxd_rd;
  end if;
end process;

--//                                                                     | ������ � ����� HDD   |  ������ � RAID               |
i_sh_rxd_rd<=( (not p_in_usr_rxbuf_full and not p_in_sh_rxbuf_empty) and (not p_in_raid.used or (i_sh_trn_en and p_in_raid.used)) );

p_out_sh_rxd_rd<=i_sh_rxd_rd;


--//��������� ������ ���������� ���������� ������
i_sh_trn_den<=i_sh_txd_wr or i_sh_rxd_rd;

i_raid_cl_byte_count<=i_sh_atacmd.raid_cl&CONV_STD_LOGIC_VECTOR(0, log2(CI_SECTOR_SIZE_BYTE));
i_raid_cl_dw_count<=("00"&i_raid_cl_byte_count(i_raid_cl_dw_count'high downto 2));
process(p_in_rst,p_in_clk)
  variable raid_cl_done: std_logic;
begin
  if p_in_rst='1' then
      raid_cl_done:='0';

    i_sh_trn_en<='0';
    i_raid_cl_done<='0';

  elsif p_in_clk'event and p_in_clk='1' then

      raid_cl_done:='0';

    if (p_in_raid.used='0' and i_sh_det.cmddone='1') or i_err_clr='1' then
      i_sh_trn_en<='0';

    elsif p_in_raid.used='1' then
    --//����� ������ � RAID
        if i_sh_cmd_start='1' or (i_raid_cl_done='1' and (i_raid_trn_cnts/=i_sh_atacmd.scount or (i_raid_trn_cnts=i_sh_atacmd.scount and i_sh_hddcnt/=p_in_raid.hddcount))) then
          i_sh_trn_en<='1';

        else
          if i_sh_trn_en='1' and i_sh_trn_den='1' and i_raid_cl_cntdw=(i_raid_cl_dw_count - 1) then
          --//��������� ��������� ���� �������� RAID
            i_sh_trn_en<='0';
              raid_cl_done:='1';

          end if;
        end if;
    end if;

    i_raid_cl_done<=raid_cl_done;

  end if;
end process;

--//������� ������ �������� ������ RAID
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_raid_cl_cntdw<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then
    if i_raid_cl_done='1' or i_sh_cmd_start='1' or i_err_clr='1' then
      i_raid_cl_cntdw<=(others=>'0');

    elsif p_in_raid.used='1' and i_sh_trn_den='1' then
       i_raid_cl_cntdw<=i_raid_cl_cntdw+1;
    end if;
  end if;
end process;

--//������� �������� RAID
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_raid_trn_cnts<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then
    if i_sh_cmd_start='1' or i_err_clr='1' then
      i_raid_trn_cnts<=(others=>'0');

    elsif p_in_raid.used='1' and i_sh_trn_den='1' and i_raid_cl_cntdw=(i_raid_cl_dw_count - 1) and i_sh_hddcnt=p_in_raid.hddcount then
       i_raid_trn_cnts<=i_raid_trn_cnts + i_sh_atacmd.raid_cl;
    end if;
  end if;
end process;


--//������� hdd RAID
gen_sh_bufadr_ld : for i in 0 to i_sh_hddcnt'high generate
--//���� �������� � ����� HDD: ��������� ����� �����. HDD
--//���� �������� �      RAID: ��������� 0 (�.�. ������ �������� � sata_host=0)
i_sh_hddcnt_ld(i)<=p_in_sh_num(i) and not p_in_raid.used;
end generate gen_sh_bufadr_ld;

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_sh_hddcnt<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then
    if i_sh_cmd_start='1' or (p_in_raid.used='1' and i_raid_cl_done='1' and i_sh_hddcnt=p_in_raid.hddcount) then
      i_sh_hddcnt<=i_sh_hddcnt_ld;

    elsif i_raid_cl_done='1' then
      i_sh_hddcnt<=i_sh_hddcnt+1;
    end if;
  end if;
end process;

--//�������:
process(p_in_rst,p_in_clk)
  variable raid_trn_sdone: std_logic;
begin
  if p_in_rst='1' then
      raid_trn_sdone:='0';
    sr_raid_trn_sdone<='0';--(others=>'0');
    i_raid_trn_done<=(others=>'0');
    sr_raid_trn_done<='0';--(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then

    raid_trn_sdone:='0';

    --//��� ������� ���������� ���������� ��� ������� ��� ���� HDD RAID
    if p_in_raid.used='1' and i_raid_cl_done='1' and i_raid_trn_cnts=i_sh_atacmd.scount and i_sh_hddcnt=p_in_raid.hddcount then
      raid_trn_sdone:='1';
    end if;

    sr_raid_trn_sdone<=raid_trn_sdone;-- & sr_raid_trn_sdone(0 to 0);

    --//������� ���������� RAID - ���������:
    if p_in_raid.used='0' or AND_reduce(i_raid_trn_done)='1' or i_err_clr='1' then
      i_raid_trn_done<=(others=>'0');
    else
      --//������� ��� ������� ���������
      if sr_sh_bsy(0)='0' and sr_sh_bsy(1)='1' then
        i_raid_trn_done(0)<='1';
      end if;
      --//���������� ����������� ���-�� �������� ��� ���������� ������� ��� �������
      if sr_raid_trn_sdone='1' then
        i_raid_trn_done(1)<='1';
      end if;
    end if;

    sr_raid_trn_done<=AND_reduce(i_raid_trn_done);-- & sr_raid_trn_done(0 to 0);

  end if;
end process;




--//-----------------------------------
--//Debug/Sim
--//-----------------------------------
gen_dbgcs_off : if strcmp(G_DBGCS,"OFF") generate
p_out_dbgcs.clk   <=p_in_clk;
p_out_dbgcs.trig0 <=(others=>'0');
p_out_dbgcs.data  <=(others=>'0');
end generate gen_dbgcs_off;


gen_dbgcs_on : if strcmp(G_DBGCS,"ON") generate

p_out_dbgcs.clk   <=p_in_clk;
process(p_in_clk)
begin
if p_in_clk'event and p_in_clk='1' then

p_out_dbgcs.trig0(0)<=i_sh_det.cmddone;
p_out_dbgcs.trig0(1)<=i_sh_det.err;
p_out_dbgcs.trig0(2)<=sr_raid_trn_done;
p_out_dbgcs.trig0(3)<=i_atacmdnew;
p_out_dbgcs.trig0(4)<=p_in_usr_txbuf_empty;--i_raid_trn_cnts(0);--
p_out_dbgcs.trig0(5)<=tst_det_clr_err;
p_out_dbgcs.trig0(6)<=p_in_sh_txbuf_full;
p_out_dbgcs.trig0(7)<=i_err_clr;
p_out_dbgcs.trig0(8)<=tst_hw_stop;
p_out_dbgcs.trig0(9)<=i_sh_padding_en;
p_out_dbgcs.trig0(10)<=i_sh_trn_den;
p_out_dbgcs.trig0(11)<=i_sh_cmd_start;
p_out_dbgcs.trig0(14 downto 12)<=i_sh_hddcnt(2 downto 0);
p_out_dbgcs.trig0(15)          <=i_sh_atacmd.lba(0);--i_raid_cl_done;
p_out_dbgcs.trig0(16)          <=i_sh_atacmd.lba(1);--p_in_usr_cxd_wr;
p_out_dbgcs.trig0(17)          <=i_sh_atacmd.lba(2);
p_out_dbgcs.trig0(18)<=tst_cmddone;--(dev_done)
p_out_dbgcs.trig0(19)<='0';--��������������� ��� tmr_timeout
p_out_dbgcs.trig0(24 downto 20)<=(others=>'0');--��������������� ��� i_fsm_llayer(4 downto 0);--sh0
p_out_dbgcs.trig0(29 downto 25)<=(others=>'0');--��������������� ��� i_fsm_tlayer(4 downto 0);
p_out_dbgcs.trig0(34 downto 30)<=(others=>'0');--��������������� ��� i_fsm_llayer(4 downto 0);--sh1
p_out_dbgcs.trig0(39 downto 35)<=(others=>'0');--��������������� ��� i_fsm_tlayer(4 downto 0);
p_out_dbgcs.trig0(40)<='0';--���������������
p_out_dbgcs.trig0(41)<='0';

p_out_dbgcs.data(0)<=i_sh_det.cmddone;
p_out_dbgcs.data(1)<=i_sh_trn_den;
p_out_dbgcs.data(2)<=i_usrmode.hw_work;
p_out_dbgcs.data(3)<=i_usrmode.hw;
p_out_dbgcs.data(4)<=i_sh_cmd_start;--p_in_usr_txbuf_empty;
p_out_dbgcs.data(5)<=p_in_sh_rxbuf_empty;
p_out_dbgcs.data(6)<=p_in_sh_txbuf_full;
p_out_dbgcs.data(7)<=i_sh_det.err;
p_out_dbgcs.data(8)<=i_usr_status.ch_bsy(0);
p_out_dbgcs.data(9)<=i_usr_status.ch_bsy(1);
p_out_dbgcs.data(10)<=i_sh_hddcnt(0);
p_out_dbgcs.data(11)<=i_sh_hddcnt(1);
p_out_dbgcs.data(20 downto 12)<=i_raid_cl_cntdw(8 downto 0);
--p_out_dbgcs.data(16 downto 12)<=i_raid_trn_cnts(4 downto 0);
--p_out_dbgcs.data(20 downto 17)<=i_sh_atacmd.lba(3 downto 0);
p_out_dbgcs.data(21)<=p_in_usr_txbuf_empty;
p_out_dbgcs.data(22)<=i_raid_trn_done(1);--//detect raid_trn_sdone
p_out_dbgcs.data(23)<=sr_raid_trn_done;
p_out_dbgcs.data(24)<=i_sh_trn_en;
p_out_dbgcs.data(25)<=i_raid_cl_done;
p_out_dbgcs.data(26)<=i_sh_padding_en;
p_out_dbgcs.data(27)<=i_sh_padding;
p_out_dbgcs.data(28)<=i_raid_trn_done(0);
p_out_dbgcs.data(29)<='0';--//���������������
p_out_dbgcs.data(122 downto 30)<=(others=>'0');--//���������������


tst_cmddone<=sr_tst_bsy(1) and not sr_tst_bsy(0);
sr_tst_bsy<=i_usr_status.dev_bsy & sr_tst_bsy(0 to 0);

sr_hw_work<=i_usrmode.hw_work & sr_hw_work(0 to 0);
tst_hw_stop<=not sr_hw_work(0) and sr_hw_work(1);

if i_atacmdnew='1' then
  tst_det_clr_err<='0';
else
  if i_err_clr='1' then
    tst_det_clr_err<='1';
  end if;
end if;

end if;
end process;

end generate gen_dbgcs_on;


--END MAIN
end behavioral;

