-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 2010.06
-- Module Name : dsn_hdd_rambuf
--
-- ����������/�������� :
--  ����������� ������ ��� HDD ����� ���
--
--
-- Revision:
-- Revision 0.01 - File Created
-- Revision 0.02 - ��������� ��������� �������� ����� ������� ������ � RAMBUF >= ������ C_HDD_RAMBUF_PFULL, �
--                 ��������� ������ rd_prt ��������� ����� � ����� RAMBUF. � ���� ������ ���������� ������ ������
--                 �� RAMBUF � 2-� �����:
--                 1. ������� ���������� i_rd_lenreq_dbl ������
--                 2. ����� ���������� i_rd_lenreq_dbl_remain ������
--                 (����������� ��. ���� .������ ���������� ��������� ������/������ ���)
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
use work.prj_def.all;
use work.memory_ctrl_pkg.all;

entity dsn_hdd_rambuf is
generic
(
G_MODULE_USE      : string:="ON";
G_HDD_RAMBUF_SIZE : integer:=23 --//(� BYTE). ������������ ��� 2 � ������� G_HDD_RAMBUF_SIZE
);
port
(
-------------------------------
-- ����������������
-------------------------------
p_in_cfg_ramadr            : in    std_logic_vector(31 downto 0);--//������� ����� rambuf � ���
p_in_cfg_rambuf            : in    std_logic_vector(31 downto 0);--//���������� ������� rambuf

--//�������
p_out_sts_rdy              : out   std_logic;                    --//������ ��������� � �������� ��������� + p_in_vbuf_empty and p_in_dwnp_buf_empty
p_out_sts_err              : out   std_logic;                    --//������ ������: i_rambuf_full or i_vbuf_full

--//--------------------------
--//����� � ������� �����������
--//--------------------------
p_in_vbuf_dout             : in    std_logic_vector(31 downto 0);
p_out_vbuf_rd              : out   std_logic;
p_in_vbuf_empty            : in    std_logic;
p_in_vbuf_full             : in    std_logic;
p_in_vbuf_pfull            : in    std_logic;

--//--------------------------
--//����� � ������� HDD
--//--------------------------
p_out_hdd_txd              : out   std_logic_vector(31 downto 0);
p_out_hdd_txd_wr           : out   std_logic;
p_in_hdd_txbuf_full        : in    std_logic;
--p_in_hdd_txbuf_empty       : in    std_logic;

p_in_hdd_rxd               : in    std_logic_vector(31 downto 0);
p_out_hdd_rxd_rd           : out   std_logic;
p_in_hdd_rxbuf_empty       : in    std_logic;

---------------------------------
-- ����� � memory_ctrl.vhd
---------------------------------
p_out_memarb_req           : out   std_logic;                    --//������ � ������� ��� �� ���������� ����������
p_in_memarb_en             : in    std_logic;                    --//���������� �������

p_out_mem_bank1h           : out   std_logic_vector(15 downto 0);
p_out_mem_ce               : out   std_logic;
p_out_mem_cw               : out   std_logic;
p_out_mem_rd               : out   std_logic;
p_out_mem_wr               : out   std_logic;
p_out_mem_term             : out   std_logic;
p_out_mem_adr              : out   std_logic_vector(C_MEMCTRL_ADDR_WIDTH - 1 downto 0);
p_out_mem_be               : out   std_logic_vector(C_MEMCTRL_DATA_WIDTH / 8 - 1 downto 0);
p_out_mem_din              : out   std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);
p_in_mem_dout              : in    std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);

p_in_mem_wf                : in    std_logic;
p_in_mem_wpf               : in    std_logic;
p_in_mem_re                : in    std_logic;
p_in_mem_rpe               : in    std_logic;

p_out_mem_clk              : out   std_logic;

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
end dsn_hdd_rambuf;

architecture behavioral of dsn_hdd_rambuf is


constant C_HDD_TXSTREAM_FIFO_DEPTH : integer:=16#1000#;--//DWORD
constant C_HDD_RAMBUF_PFULL        : integer:=10;--//Program FULL level - 2**10 = 1024(0x400) - (� DWORD)
                                                 --//���� ������ � RAMBUF ���������� >= �������� ������, ��
                                                 --//������ ��������� ���������� ������ ��� ����������� �� ������� ������,
                                                 --//����� ������ ����� �������� ���������� �� ���������

----//�����������
--constant C_HDD_RAMBUF_PFULL        : integer:=7;

-- Small delay for simulation purposes.
constant dly : time := 1 ps;

type fsm_state is
(
S_IDLE,

S_MEMW_CHECK,
S_MEMW_START,
S_MEMW_WORK,

S_MEMR_CHECK,
S_MEMR_CHECK2,
S_MEMR_CHECK3,
S_MEMR_START,
S_MEMR_WORK,
S_MEMR_START2,

S_MEM_TST
);
signal fsm_state_cs: fsm_state;

signal b_cfg_memtrn                    : std_logic_vector(C_DSN_HDD_REG_RBUF_CTRL_TRNMEM_MSB_BIT-C_DSN_HDD_REG_RBUF_CTRL_TRNMEM_LSB_BIT downto 0);
signal b_cfg_work                      : std_logic;
signal b_cfg_testing                   : std_logic;
signal b_cfg_hw_stop                   : std_logic;

signal i_cfg_work_dly                  : std_logic_vector(1 downto 0);
signal i_cfg_work_upedge               : std_logic;
signal i_cfg_work_dwnedge              : std_logic;
signal i_cfg_stop_rq                   : std_logic;

signal i_wr_lenreq                     : std_logic_vector(7 downto 0);--//(� DWORD)
signal i_rd_lenreq                     : std_logic_vector(15 downto 0);--//(� DWORD)
signal i_rd_lenreq_dbl                 : std_logic_vector(15 downto 0);--//(� DWORD)
signal i_rd_lenreq_dbl_remain          : std_logic_vector(15 downto 0);--//(� DWORD)

signal i_dwnport_remain                : std_logic_vector(15 downto 0);--//(� DWORD)
signal i_dnwport_dcnt                  : std_logic_vector(15 downto 0);--//(� DWORD)

signal i_wr_ptr                        : std_logic_vector(31 downto 0);--//����� � BYTE
signal i_rd_ptr                        : std_logic_vector(31 downto 0);--//����� � BYTE

signal i_rambuf_dcnt                   : std_logic_vector(31 downto 0);--//(� DWORD): std_logic_vector(G_HDD_RAMBUF_SIZE-2 downto 0);--//(� DWORD)
signal i_rambuf_rdy                    : std_logic;
signal i_rambuf_full                   : std_logic;

signal i_dwn_fillen                    : std_logic;
signal i_dwnbuf_empty                  : std_logic;

signal i_vbuf_rdy                   : std_logic;
signal i_vbuf_full                  : std_logic;

signal i_mem_adr                       : std_logic_vector(31 downto 0);--//����� � BYTE
signal i_mem_lenreq                    : std_logic_vector(15 downto 0);--//������ ������������� ������ (� DWORD)
signal i_mem_dir                       : std_logic;
signal i_mem_start                     : std_logic;
signal i_mem_done                      : std_logic;
signal i_mem_rd_dbl                    : std_logic;
signal i_mem_pusr_rxbuf_wd             : std_logic;


signal tst_hdd_rambuf_err              : std_logic;
signal tst_rambuf_empty                : std_logic;
signal tst_fast_ramrd                  : std_logic;
--signal tst_rdptr_det                   : std_logic_vector(2 downto 0);
--signal tst_rdptr_detall                : std_logic;
--signal tst_fsmstate                    : std_logic_vector(3 downto 0);
--signal tst_fsmstate_dly                : std_logic_vector(3 downto 0);


--MAIN
begin



gen_use_on : if strcmp(G_MODULE_USE,"ON") generate

--//----------------------------------
--//��������������� �������
--//----------------------------------
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
--    tst_fsmstate_dly<=(others=>'0');
--    tst_rdptr_det<=(others=>'0');
--    tst_rdptr_detall<='0';

    tst_hdd_rambuf_err<='0';
  elsif p_in_clk'event and p_in_clk='1' then
--    tst_fsmstate_dly<=tst_fsmstate;
--
--    if i_rd_ptr/=CONV_STD_LOGIC_VECTOR(pwr(2,G_HDD_RAMBUF_SIZE), i_rd_ptr'length) then
--
--      if i_rd_ptr>=CONV_STD_LOGIC_VECTOR(pwr(2,G_HDD_RAMBUF_SIZE)-16#200#, i_rd_ptr'length) then
--        tst_rdptr_det(0)<='1';
--      else
--        tst_rdptr_det(0)<='0';
--      end if;
--
----      if i_rd_ptr>=CONV_STD_LOGIC_VECTOR(16#1FFF000#, i_rd_ptr'length) then
----        tst_rdptr_det(1)<='1';
----      else
----        tst_rdptr_det(1)<='0';
----      end if;
--
----      if i_rd_ptr>=CONV_STD_LOGIC_VECTOR(16#1FFFE00#, i_rd_ptr'length) then
----        tst_rdptr_det(2)<='1';
----      else
----        tst_rdptr_det(2)<='0';
----      end if;
--
--      tst_rdptr_det(1)<=i_rd_ptr(G_HDD_RAMBUF_SIZE-1);
--      tst_rdptr_det(2)<=i_rd_ptr(G_HDD_RAMBUF_SIZE-2);
--    end if;
--
--    tst_rdptr_detall<=OR_reduce(tst_rdptr_det);

    tst_hdd_rambuf_err<=i_rambuf_full or i_vbuf_full or i_cfg_work_dwnedge;

  end if;
end process;
--tst_fsmstate<=CONV_STD_LOGIC_VECTOR(16#01#,tst_fsmstate'length) when fsm_state_cs=S_MEMW_CHECK else
--              CONV_STD_LOGIC_VECTOR(16#02#,tst_fsmstate'length) when fsm_state_cs=S_MEMW_START else
--              CONV_STD_LOGIC_VECTOR(16#03#,tst_fsmstate'length) when fsm_state_cs=S_MEMW_WORK else
--              CONV_STD_LOGIC_VECTOR(16#04#,tst_fsmstate'length) when fsm_state_cs=S_MEMR_CHECK else
--              CONV_STD_LOGIC_VECTOR(16#05#,tst_fsmstate'length) when fsm_state_cs=S_MEMR_CHECK2 else
--              CONV_STD_LOGIC_VECTOR(16#06#,tst_fsmstate'length) when fsm_state_cs=S_MEMR_CHECK3 else
--              CONV_STD_LOGIC_VECTOR(16#07#,tst_fsmstate'length) when fsm_state_cs=S_MEMR_START else
--              CONV_STD_LOGIC_VECTOR(16#08#,tst_fsmstate'length) when fsm_state_cs=S_MEMR_WORK else
--              CONV_STD_LOGIC_VECTOR(16#09#,tst_fsmstate'length) when fsm_state_cs=S_MEMR_START2 else
--              CONV_STD_LOGIC_VECTOR(16#0A#,tst_fsmstate'length) when fsm_state_cs=S_MEM_TST else
--              CONV_STD_LOGIC_VECTOR(16#00#,tst_fsmstate'length); --//when fsm_state_cs=S_IDLE else

p_out_tst(0)<=tst_hdd_rambuf_err or tst_rambuf_empty or tst_fast_ramrd;-- or tst_rdptr_detall or OR_reduce(tst_fsmstate_dly);
p_out_tst(31 downto 1)<=(others=>'0');

--p_out_tst<=(others=>'0');



--//----------------------------------------------
--//������������ ������� ����������
--//----------------------------------------------
b_cfg_memtrn  <= p_in_cfg_rambuf(C_DSN_HDD_REG_RBUF_CTRL_TRNMEM_MSB_BIT downto C_DSN_HDD_REG_RBUF_CTRL_TRNMEM_LSB_BIT);
b_cfg_work    <= p_in_cfg_rambuf(C_DSN_HDD_REG_RBUF_CTRL_START_BIT);
b_cfg_testing <= p_in_cfg_rambuf(C_DSN_HDD_REG_RBUF_CTRL_TEST_BIT);
b_cfg_hw_stop <= p_in_cfg_rambuf(C_DSN_HDD_REG_RBUF_CTRL_STOPSYN_BIT);


--//----------------------------------------------
--//�������
--//----------------------------------------------
p_out_sts_err<=i_rambuf_full or i_vbuf_full;
p_out_sts_rdy<=i_rambuf_rdy and p_in_vbuf_empty and p_in_dwnp_buf_empty;

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_vbuf_rdy<='0';
    i_vbuf_full<='0';

    i_dwnbuf_empty<='0';

    i_cfg_work_dly<=(others=>'0');
    i_cfg_work_upedge<='0';
    i_cfg_work_dwnedge<='0';
    i_cfg_stop_rq<='0';

  elsif p_in_clk'event and p_in_clk='1' then

    i_vbuf_full<=p_in_vbuf_full;
    i_vbuf_rdy<=p_in_vbuf_pfull;

    i_dwnbuf_empty<=p_in_dwnp_buf_empty;

    i_cfg_work_dly(0)<=b_cfg_work;
    i_cfg_work_dly(1)<=i_cfg_work_dly(0);
    i_cfg_work_upedge <=    i_cfg_work_dly(0) and not i_cfg_work_dly(1);
    i_cfg_work_dwnedge<=not i_cfg_work_dly(0) and     i_cfg_work_dly(1);

    if b_cfg_hw_stop='1' or i_cfg_work_dwnedge='1' then
      i_cfg_stop_rq<='1';
    elsif fsm_state_cs = S_IDLE then
      i_cfg_stop_rq<='0';
    end if;
  end if;
end process;

--//----------------------------------------------
--//������� ���������� ������/������ ������ ���
--//----------------------------------------------

--//������ ������ ��������
process(p_in_rst,p_in_clk)
  variable var_update_addr: std_logic_vector(i_mem_lenreq'length+1 downto 0);
  variable var_width32b  : std_logic_vector(31 downto 0);
begin
  if p_in_rst='1' then
    var_update_addr:=(others=>'0');
    var_width32b:=(others=>'0');

    fsm_state_cs <= S_IDLE;
    i_rambuf_rdy<='0';
    i_rambuf_full<='0';
    i_rambuf_dcnt<=(others=>'0');

    i_wr_lenreq<=(others=>'0');
    i_rd_lenreq<=(others=>'0');
    i_rd_lenreq_dbl<=(others=>'0');
    i_rd_lenreq_dbl_remain<=(others=>'0');

    i_wr_ptr<=(others=>'0');
    i_rd_ptr<=(others=>'0');

    i_dnwport_dcnt<=(others=>'0');
    i_dwnport_remain<=(others=>'0');
    i_dwn_fillen<='0';

    i_mem_adr<=(others=>'0');
    i_mem_lenreq<=(others=>'0');
    i_mem_dir<='0';
    i_mem_start<='0';
    i_mem_rd_dbl<='0';

    tst_rambuf_empty<='1';
    tst_fast_ramrd<='0';

  elsif p_in_clk'event and p_in_clk='1' then

    case fsm_state_cs is

      --//------------------------------------
      --//�������� ���������
      --//------------------------------------
      when S_IDLE =>
        tst_rambuf_empty<='1';
        i_rambuf_rdy<='1';
        i_rambuf_full<='0';

        --//�������������
        if i_cfg_work_upedge='1' or b_cfg_testing='1' then

          i_rambuf_dcnt<=(others=>'0');--//������� ������ � RAMBUF (DWORD)
          i_dnwport_dcnt<=(others=>'0');--//���-�� ��������� ������ � ����� ��������� (DWORD)
          i_dwnport_remain<=(others=>'0');--//������� ������ �������� �������� � ����� ��������� (DWORD)

          --//��������� ������/������
          i_wr_ptr<=(others=>'0');
          i_rd_ptr<=(others=>'0');

          --//������ ���������� ������/������ ��� �� ��������� (DWORD)
          i_wr_lenreq<=EXT(b_cfg_memtrn(7 downto 0), i_wr_lenreq'length);
          i_rd_lenreq<=EXT(b_cfg_memtrn(7 downto 0), i_rd_lenreq'length);

          if b_cfg_testing='0' then
            fsm_state_cs <= S_MEMW_CHECK;
          else
            fsm_state_cs <= S_MEM_TST;
          end if;
        end if;



      --//----------------------------------------------
      --//----------------------------------------------
      --//������ � ����� ��������
      --//----------------------------------------------
      when S_MEMW_CHECK =>
        i_rambuf_rdy<='0';

        if i_dnwport_dcnt>=CONV_STD_LOGIC_VECTOR(C_HDD_TXSTREAM_FIFO_DEPTH, i_dnwport_dcnt'length) then
          --//� ����� ��������� �������� ��������� ������ ������
          i_dnwport_dcnt<=(others=>'0');
          i_dwn_fillen<='0';--//����� ����� ���������� ���������� ������ ���������
        end if;

        if i_cfg_stop_rq='1' then
        --//������������ ������ ���������
          fsm_state_cs <= S_IDLE;

        else
          if i_vbuf_rdy='0' then
              --//��� �� ���������� ������ ���-�� ������!!!
              fsm_state_cs <= S_MEMR_CHECK;--//������� � ������
          else
              if i_rambuf_dcnt(G_HDD_RAMBUF_SIZE-2)='1' then --//(-2 �.�. �������� i_rambuf_dcnt � DWPRD)
                --//RamBuffer/Full - � ������ ��� ���������� �����.
                i_rambuf_full<='1';

                fsm_state_cs <= S_MEMR_CHECK;--//������� � ������
              else
                fsm_state_cs <= S_MEMW_START;--//������� � ������
              end if;
          end if;
        end if;

      --//------------------------------------
      --//������ ������
      --//------------------------------------
      when S_MEMW_START =>
        i_rambuf_rdy<='0';

        if i_wr_ptr(G_HDD_RAMBUF_SIZE)='1' then
          --//������������� ��������� ������
          i_wr_ptr<=(others=>'0');
          --//��������� �������� ������ RAMBUF
          i_mem_adr<=p_in_cfg_ramadr;
        else
          --//Update ������ RAMBUF
          i_mem_adr<=i_wr_ptr + p_in_cfg_ramadr;
        end if;

        i_mem_lenreq<=EXT(i_wr_lenreq, i_mem_lenreq'length);
        i_mem_dir<=C_MEMCTRLCHWR_WRITE;
        i_mem_start<='1';
        fsm_state_cs <= S_MEMW_WORK;

      when S_MEMW_WORK =>

        i_mem_start<='0';

        --//��������� �������� ��� ���������� ������ ���.
        --//��� �������� ���������� �.�. �������� i_mem_lenreq � DWORD, �
        --//�������� i_wr_ptr ������ ���� � BYTE
        var_update_addr(1 downto 0) :=(others=>'0');
        var_update_addr(i_mem_lenreq'length+1 downto 2):=i_mem_lenreq;

        --//�������� ���������
        if i_mem_done='1' then
          --//��������� ��������� ������ + ������� ������ � ������
          i_wr_ptr<=i_wr_ptr + EXT(var_update_addr, i_wr_ptr'length);
          i_rambuf_dcnt<=i_rambuf_dcnt + EXT(i_mem_lenreq, i_rambuf_dcnt'length);

          tst_rambuf_empty<='0';
          fsm_state_cs <= S_MEMR_CHECK;--//������� � ������
        end if;



      --//----------------------------------------------
      --//----------------------------------------------
      --//������ � ����� ��������
      --//----------------------------------------------
      when S_MEMR_CHECK =>
        --//��������� ������� ������ �������� �������� � ����� ���������
        i_dwnport_remain<=CONV_STD_LOGIC_VECTOR(C_HDD_TXSTREAM_FIFO_DEPTH, i_dwnport_remain'length)-i_dnwport_dcnt;

        if i_dwn_fillen='0' then
            if i_dwnbuf_empty='1' then
            --//����� ��������� ����. => �������� � ��� ����������
              fsm_state_cs <= S_MEMR_CHECK2;
            else
            --//���� ����� ����������� ����� ���������
              fsm_state_cs <= S_MEMW_CHECK;--//������� � ������
            end if;
        else
        --//���� ���������� �� ���������� � ������ ���������
        --//��������� � ��� ����������
          fsm_state_cs <= S_MEMR_CHECK2;
        end if;

      when S_MEMR_CHECK2 =>

        i_dwn_fillen<='1';--//��������� ���������� � ����� ���������

        if i_rambuf_dcnt=(i_rambuf_dcnt'range =>'0') then
        --//RamBuffer/Empty - ��� ������ ��� ������
          tst_rambuf_empty<='1';
          fsm_state_cs <= S_MEMW_CHECK;--//������� � ������
        else
        --//��������� ������ ������ ������� ����� ���������� �� ���

            if i_dwnport_remain>=CONV_STD_LOGIC_VECTOR(pwr(2,C_HDD_RAMBUF_PFULL), i_dwnport_remain'length) then
            --//���� � ����� ��������� �������� �������� ������ > ��� = ������ C_HDD_RAMBUF_PFULL. ����� ...

                if i_rambuf_dcnt>=CONV_STD_LOGIC_VECTOR(pwr(2,C_HDD_RAMBUF_PFULL), i_rambuf_dcnt'length) then
                --//���� ������� ������ � RAMBUF > ��� = ������ C_HDD_RAMBUF_PFULL, �� �������� ������� �������
                --//������ �� RAMBUF ����� ���������� ������� ������������� ������
                  i_rd_lenreq<=CONV_STD_LOGIC_VECTOR(pwr(2,C_HDD_RAMBUF_PFULL), i_rd_lenreq'length);
                  tst_fast_ramrd<='1';
                else
                --//����� ���������� �� ��� ������� ������ ������� ����
                  i_rd_lenreq<=i_rambuf_dcnt(15 downto 0);
                end if;
            else
            --//���� � ����� ��������� �������� �������� ������ < ������ C_HDD_RAMBUF_PFULL. ����� ...

                if i_rambuf_dcnt>=EXT(i_dwnport_remain, i_rambuf_dcnt'length) then
                --//���� ������� ������ � RAMBUF > ��� = ������ i_dwnport_remain, �� �������� ������� �������
                --//������ �� RAMBUF ����� ���������� ������� ������������� ������
                  i_rd_lenreq<=i_dwnport_remain;
                else
                --//����� ���������� �� ��� ������� ������ ������� ����
                  i_rd_lenreq<=i_rambuf_dcnt(15 downto 0);
                end if;
            end if;

            fsm_state_cs <= S_MEMR_CHECK3;--S_MEMR_START;--//������� � ������

        end if;

      when S_MEMR_CHECK3 =>
        --//������� �������� i_rd_lenreq � �����
        var_update_addr(1 downto 0) :=(others=>'0');
        var_update_addr(i_mem_lenreq'length+1 downto 2):=i_rd_lenreq;

        --//������ ������ �� ������� RAM ������ ��� ������� ������� i_rd_lenreq
        if i_rd_ptr(G_HDD_RAMBUF_SIZE)='0' then
          if (i_rd_ptr + EXT(var_update_addr, i_rd_ptr'length))>CONV_STD_LOGIC_VECTOR(pwr(2,G_HDD_RAMBUF_SIZE), i_rd_ptr'length) then
            --//����� ����� �� ������� ������.

            i_mem_rd_dbl<='1';--//������ ������� ������� ������

            --//������ ������� ������ ������ ��� ��� 1-�� �����
            --//��������� ����� ���-�� ������ ����� ����� ����������� ��� ������� ������.
            var_width32b:=CONV_STD_LOGIC_VECTOR(pwr(2,G_HDD_RAMBUF_SIZE), var_width32b'length)-i_rd_ptr;
            i_rd_lenreq_dbl<=var_width32b(17 downto 2);--//�.�. i_rd_lenreq_dbl ������ ���� ������������ � DWORD
          end if;
        end if;

        fsm_state_cs <= S_MEMR_START;--//������� � ������

      --//----------------------------------------------
      --//������ ������
      --//----------------------------------------------
      when S_MEMR_START =>

        tst_fast_ramrd<='0';

        if i_rd_ptr(G_HDD_RAMBUF_SIZE)='1' then
        --//������������� ��������� ������
          i_rd_ptr<=(others=>'0');
          --//��������� �������� ������ RAMBUF
          i_mem_adr<=p_in_cfg_ramadr;
        else
          --//Update ������ RAMBUF
          i_mem_adr<=i_rd_ptr + p_in_cfg_ramadr;
        end if;

        if i_mem_rd_dbl='1' then
          --//������� ������:
          --//��������� ������ ������ ������ ��� ��� 1-�� �����
          i_mem_lenreq<=i_rd_lenreq_dbl;
          --//������ ������� ������ ������ ��� ��� 2-�� �����
          i_rd_lenreq_dbl_remain<=i_rd_lenreq - i_rd_lenreq_dbl;
        else
          i_mem_lenreq<=i_rd_lenreq;
        end if;
        i_mem_dir<=C_MEMCTRLCHWR_READ;
        i_mem_start<='1';
        fsm_state_cs <= S_MEMR_WORK;

      when S_MEMR_WORK =>

        i_mem_start<='0';

        --//��������� �������� ��� ���������� ������ ���.
        --//��� �������� ���������� �.�. �������� i_mem_lenreq � DWORD, �
        --//�������� i_wr_ptr ������ ���� � BYTE
        var_update_addr(1 downto 0) :=(others=>'0');
        var_update_addr(i_mem_lenreq'length+1 downto 2):=i_mem_lenreq;

        --//�������� ���������
        if i_mem_done='1' then
          i_rambuf_full<='0';--//����� ����� ����� ��� FULL

          --//��������� ��������� ������ + ������� ������ � ������
          i_rd_ptr<=i_rd_ptr + EXT(var_update_addr, i_rd_ptr'length);
          i_rambuf_dcnt<=i_rambuf_dcnt - EXT(i_mem_lenreq, i_rambuf_dcnt'length);

          --//������� ������ ��������� � ����� ���������
          i_dnwport_dcnt<=i_dnwport_dcnt + EXT(i_mem_lenreq, i_dnwport_dcnt'length);

          if i_mem_rd_dbl='1' then
            fsm_state_cs <= S_MEMR_START2;--//������� � ������� � 2-� �����
          else
            fsm_state_cs <= S_MEMW_CHECK;--//������� � ������
          end if;

        end if;

      when S_MEMR_START2 =>

        --//Update ������ RAMBUF + ��������� ������
        i_rd_ptr<=(others=>'0');
        i_mem_rd_dbl<='0';--//����� ����� ������� �������

        i_mem_adr<=p_in_cfg_ramadr;
        i_mem_lenreq<=i_rd_lenreq_dbl_remain;
        i_mem_dir<=C_MEMCTRLCHWR_READ;
        i_mem_start<='1';
        fsm_state_cs <= S_MEMR_WORK;



      --//----------------------------------------------
      --//������������
      --//----------------------------------------------
      when S_MEM_TST =>

        if b_cfg_testing='0' then
          fsm_state_cs <= S_IDLE;
        end if;
--
--        i_wr_ptr<=CONV_STD_LOGIC_VECTOR(16#1FFFF00#, i_wr_ptr'length);
--        i_rd_ptr<=CONV_STD_LOGIC_VECTOR(16#1FFFEE0#, i_rd_ptr'length);
----
----        i_wr_ptr<=CONV_STD_LOGIC_VECTOR(16#100#, i_wr_ptr'length);
----        i_rd_ptr<=CONV_STD_LOGIC_VECTOR(16#1C0#, i_rd_ptr'length);
--        fsm_state_cs <= S_MEMW_CHECK;

    end case;
  end if;
end process;



--//------------------------------------------------------
--//������ ������/������ ������ ��� (memory_ctrl.vhd)
--//------------------------------------------------------
p_out_hdd_txd_wr<=i_mem_pusr_rxbuf_wd or i_cfg_stop_rq; --//�� ����� ��������� ������� ���������, ���������� ������ �
                                                          --//����� ���������. ��� �����������, ��� ��� ���������
                                                          --//������ � HDD ������ ����� ������



m_mem_ctrl_wr : memory_ctrl_ch_wr
generic map(
G_MEM_BANK_MSB_BIT   => C_DSN_HDD_REG_RBUF_ADR_BANK_MSB_BIT,
G_MEM_BANK_LSB_BIT   => C_DSN_HDD_REG_RBUF_ADR_BANK_LSB_BIT
)
port map
(
-------------------------------
-- ����������������
-------------------------------
p_in_cfg_mem_adr           => i_mem_adr,
p_in_cfg_mem_trn_len       => i_mem_lenreq,
p_in_cfg_mem_dlen_rq       => i_mem_lenreq,
p_in_cfg_mem_wr            => i_mem_dir,
p_in_cfg_mem_start         => i_mem_start,
p_out_cfg_mem_done         => i_mem_done,

-------------------------------
-- ����� � ����������������� ��������
-------------------------------
p_in_usr_txbuf_dout        => p_in_hdd_rxd,--p_in_vbuf_dout,
p_out_usr_txbuf_rd         => p_out_hdd_rxd_rd,--p_out_vbuf_rd,
p_in_usr_txbuf_empty       => p_in_hdd_rxbuf_empty,--p_in_vbuf_empty,

p_out_usr_rxbuf_din        => p_out_hdd_txd,
p_out_usr_rxbuf_wd         => i_mem_pusr_rxbuf_wd,
p_in_usr_rxbuf_full        => p_in_hdd_txbuf_full,

---------------------------------
-- ����� � memory_ctrl.vhd
---------------------------------
p_out_memarb_req           => p_out_memarb_req,
p_in_memarb_en             => p_in_memarb_en,

p_out_mem_bank1h           => p_out_mem_bank1h,
p_out_mem_ce               => p_out_mem_ce,
p_out_mem_cw               => p_out_mem_cw,
p_out_mem_rd               => p_out_mem_rd,
p_out_mem_wr               => p_out_mem_wr,
p_out_mem_term             => p_out_mem_term,
p_out_mem_adr              => p_out_mem_adr,
p_out_mem_be               => p_out_mem_be,
p_out_mem_din              => p_out_mem_din,
p_in_mem_dout              => p_in_mem_dout,

p_in_mem_wf                => p_in_mem_wf,
p_in_mem_wpf               => p_in_mem_wpf,
p_in_mem_re                => p_in_mem_re,
p_in_mem_rpe               => p_in_mem_rpe,

p_out_mem_clk              => p_out_mem_clk,

-------------------------------
--���������������
-------------------------------
p_in_tst_ctrl              => "00000000000000000000000000000000",
p_out_tst                  => open,

-------------------------------
--System
-------------------------------
p_in_clk            => p_in_clk,
p_in_rst            => p_in_rst
);

end generate gen_use_on;


gen_use_off : if strcmp(G_MODULE_USE,"OFF") generate

p_out_sts_rdy <='0';
p_out_sts_err <='0';

p_out_mem_clk <= p_in_clk;

p_out_mem_bank1h <=(others=>'0');
p_out_mem_ce     <='0';
p_out_mem_cw     <='0';
p_out_mem_rd     <='0';
p_out_mem_wr     <='0';
p_out_mem_term   <='0';
p_out_mem_adr    <=(others=>'0');
p_out_mem_be     <=(others=>'0');
p_out_mem_din    <=(others=>'0');

p_out_memarb_req <='0';

p_out_vbuf_rd <= not p_in_vbuf_empty and not p_in_dwnp_buf_pfull;

p_out_hdd_txd <= p_in_vbuf_dout;
p_out_hdd_txd_wr <= not p_in_vbuf_empty and not p_in_dwnp_buf_pfull;

p_out_tst <= (others=>'0');

end generate gen_use_off;

--END MAIN
end behavioral;


