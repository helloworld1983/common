-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 2010.06
-- Module Name : video_writer
--
-- ����������/�������� :
--  ������ ����� ������������ � ����������� ���
--  � ���������� � ������ �������� ��� ����������� ����� ���
--  ���������������� ����� ������
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

library work;
use work.vicg_common_pkg.all;
use work.prj_def.all;
use work.dsn_video_ctrl_pkg.all;
use work.mem_wr_pkg.all;
use work.prj_cfg.all;

entity video_writer is
generic(
G_USR_OPT         : std_logic_vector(3 downto 0):=(others=>'0');
G_DBGCS           : string :="OFF";

G_MEM_BANK_M_BIT  : integer:=29;
G_MEM_BANK_L_BIT  : integer:=28;

G_MEM_VCH_M_BIT   : integer:=25;
G_MEM_VCH_L_BIT   : integer:=24;
G_MEM_VFR_M_BIT   : integer:=23;
G_MEM_VFR_L_BIT   : integer:=23;
G_MEM_VLINE_M_BIT : integer:=22;
G_MEM_VLINE_L_BIT : integer:=12;

G_MEM_AWIDTH      : integer:=32;
G_MEM_DWIDTH      : integer:=32
);
port(
-------------------------------
-- ����������������
-------------------------------
p_in_cfg_load         : in    std_logic;                   --�������� ���������� ������
p_in_cfg_mem_trn_len  : in    std_logic_vector(7 downto 0);--������ ��������� ���������� MEM_WR
p_in_cfg_prm_vch      : in    TWriterVCHParams;            --��������� ������ ����� �������
p_in_cfg_set_idle_vch : in    std_logic_vector(C_VCTRL_VCH_COUNT - 1 downto 0);

p_in_vfr_buf          : in    TVfrBufs;                    --����� ������ ��� ����� ������������� ������� ����

--�������
p_out_vfr_rdy         : out   std_logic_vector(C_VCTRL_VCH_COUNT - 1 downto 0);--���� �����
p_out_vrow_mrk        : out   std_logic_vector(31 downto 0);--������ ������

----------------------------
--Upstream Port (����� � ������� ������������)
----------------------------
p_in_upp_data         : in    std_logic_vector(G_MEM_DWIDTH - 1 downto 0);
p_out_upp_data_rd     : out   std_logic;
p_in_upp_buf_empty    : in    std_logic;
p_in_upp_buf_full     : in    std_logic;
p_in_upp_buf_pfull    : in    std_logic;

---------------------------------
-- ����� � mem_ctrl.vhd
---------------------------------
p_out_mem             : out   TMemIN;
p_in_mem              : in    TMemOUT;

-------------------------------
--���������������
-------------------------------
p_in_tst              : in    std_logic_vector(31 downto 0);
p_out_tst             : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk              : in    std_logic;
p_in_rst              : in    std_logic
);
end video_writer;

architecture behavioral of video_writer is

constant CI_VIDEO_PKT_HEADER_SIZE : integer :=
selval(8, selval(8, selval(6, 5, G_MEM_DWIDTH = 64), G_MEM_DWIDTH = 128), G_MEM_DWIDTH = 256);

constant CI_VPKT_HEADER_SIZE_COUNT : integer :=
selval(1, selval(2, selval(3, 5, G_MEM_DWIDTH = 64), G_MEM_DWIDTH = 128), G_MEM_DWIDTH = 256);

-- Small delay for simulation purposes.
constant dly : time := 1 ps;

type fsm_state is (
S_IDLE,
S_PKT_HEADER_READ,
S_MEM_START,
S_MEM_START2,
S_MEM_WR,
S_PKT_SKIP,
S_PKT_SKIP1,
S_PKT_SKIP2
);
signal fsm_state_cs: fsm_state;

signal i_vpkt_cnt                  : std_logic_vector(3 downto 0);
signal i_vpkt_header_rd            : std_logic;
signal i_vpkt_payload_rd           : std_logic;

signal i_vfr_row_mrk               : std_logic_vector(31 downto 0);
signal i_vfr_row_mrk_l             : std_logic_vector(15 downto 0);
signal i_vfr_pix_count             : std_logic_vector(15 downto 0);
signal i_vfr_row_count             : std_logic_vector(15 downto 0);
Type TVfrNum is array (0 to C_VCTRL_VCH_COUNT - 1) of std_logic_vector(3 downto 0);
signal i_vfr_num                   : TVfrNum;
signal i_vfr_row                   : std_logic_vector(15 downto 0);
signal i_vch_num                   : std_logic_vector(3 downto 0);
signal i_vfr_rdy                   : std_logic_vector(p_out_vfr_rdy'range);

signal i_mem_ptr                   : std_logic_vector(31 downto 0);
signal i_mem_wrbase                : std_logic_vector(31 downto 0);
signal i_mem_adr                   : std_logic_vector(31 downto 0);
signal i_mem_trn_len               : std_logic_vector(15 downto 0);
signal i_mem_dlen_rq               : std_logic_vector(15 downto 0);
signal i_mem_start                 : std_logic;
signal i_mem_dir                   : std_logic;
signal i_mem_done                  : std_logic;

signal i_upp_data                  : std_logic_vector(255 downto 0);
signal i_upp_data_rd               : std_logic;
signal i_upp_hd_data_rd_out        : std_logic;

signal i_upp_pkt_skip_rd_out       : std_logic;
signal i_pkt_type_err              : std_logic_vector(3 downto 0);
signal i_pkt_type_err_out          : std_logic_vector(i_pkt_type_err'range);
signal i_pkt_size_byte             : std_logic_vector(15 downto 0);
signal i_pkt_skip_data             : std_logic_vector(15 downto 0);
signal i_pkt_skip_dcnt             : std_logic_vector(15 downto 0);
signal i_vpkt_skip_rd              : std_logic;
signal i_pix_num                   : std_logic_vector(15 downto 0);
signal i_pix_count_byte            : std_logic_vector(15 downto 0);

signal tst_fsmstate                : std_logic_vector(3 downto 0);
signal tst_fsmstate_out            : std_logic_vector(3 downto 0);
signal tst_err_det                 : std_logic;
signal tst_upp_buf_full            : std_logic;
signal tst_upp_buf_empty           : std_logic;
signal tst_timestump_cnt           : std_logic_vector(31 downto 0);

signal tst_upp_data                : std_logic_vector(p_in_upp_data'range);
signal tst_upp_data_rd             : std_logic;


--MAIN
begin


------------------------------------
--��������������� �������
------------------------------------
gen_dbgcs_off : if strcmp(G_DBGCS,"OFF") generate
p_out_tst(26 downto 0) <= (others=>'0');
p_out_tst(31 downto 26) <= "00" & i_pkt_type_err(2 downto 0) & '0';
end generate gen_dbgcs_off;

gen_dbgcs_on : if strcmp(G_DBGCS,"ON") generate
p_out_tst(3  downto 0) <= tst_fsmstate_out;
p_out_tst(4) <= i_mem_start or tst_err_det or tst_upp_buf_empty or OR_reduce(tst_upp_data) or tst_upp_data_rd;
p_out_tst(25 downto 5) <= (others=>'0');
p_out_tst(31 downto 26) <= "00" & i_pkt_type_err_out(2 downto 0) & '0';

process(p_in_clk)
begin
  if rising_edge(p_in_clk) then
    tst_fsmstate_out <= tst_fsmstate;
    tst_upp_buf_empty <= p_in_upp_buf_empty;

    if p_in_upp_buf_full = '1' then
      tst_upp_buf_full <= '1';
    elsif fsm_state_cs = S_IDLE then
      tst_upp_buf_full <= '0';
    end if;
    tst_err_det <= OR_reduce(i_pkt_type_err) or tst_upp_buf_full;

    tst_upp_data <= p_in_upp_data;
    tst_upp_data_rd <= i_upp_hd_data_rd_out or (i_vpkt_payload_rd and i_upp_data_rd) or i_upp_pkt_skip_rd_out;

  end if;
end process;

tst_fsmstate <= CONV_STD_LOGIC_VECTOR(16#01#, tst_fsmstate'length) when fsm_state_cs = S_PKT_HEADER_READ else
                CONV_STD_LOGIC_VECTOR(16#02#, tst_fsmstate'length) when fsm_state_cs = S_MEM_START       else
                CONV_STD_LOGIC_VECTOR(16#03#, tst_fsmstate'length) when fsm_state_cs = S_MEM_WR          else
                CONV_STD_LOGIC_VECTOR(16#04#, tst_fsmstate'length) when fsm_state_cs = S_PKT_SKIP        else
                CONV_STD_LOGIC_VECTOR(16#05#, tst_fsmstate'length) when fsm_state_cs = S_PKT_SKIP2       else
                CONV_STD_LOGIC_VECTOR(16#06#, tst_fsmstate'length) when fsm_state_cs = S_MEM_START2      else
                CONV_STD_LOGIC_VECTOR(16#00#, tst_fsmstate'length); --fsm_state_cs = S_IDLE              else
end generate gen_dbgcs_on;


------------------------------------------------
--�������
------------------------------------------------
p_out_vfr_rdy <= i_vfr_rdy;--����������: ���� ������� � ���
p_out_vrow_mrk <= i_vfr_row_mrk when p_in_tst(C_VCTRL_REG_TST0_DBG_TIMESTUMP_BIT) = '0'
                    else tst_timestump_cnt;--������ ������ ����������


------------------------------------------------
--����� � ������� ����� �������
--������� ������ ����� ����������
------------------------------------------------
p_out_upp_data_rd <= i_upp_hd_data_rd_out or (i_vpkt_payload_rd and i_upp_data_rd) or i_upp_pkt_skip_rd_out;

i_upp_hd_data_rd_out <= (i_vpkt_header_rd  and not p_in_upp_buf_empty);

i_upp_pkt_skip_rd_out <= (i_vpkt_skip_rd  and not p_in_upp_buf_empty);


------------------------------------------------
--������� ������ ����� ����������
------------------------------------------------
i_upp_data <= EXT(p_in_upp_data, i_upp_data'length);

process(p_in_clk)
Type TTimestump_test is array (0 to C_VCTRL_VCH_COUNT - 1) of std_logic_vector(31 downto 0);
variable timestump_cnt : TTimestump_test;
begin
if rising_edge(p_in_clk) then
  if p_in_rst = '1' then

    fsm_state_cs <= S_IDLE;

    i_vpkt_cnt <= (others=>'0');
    i_vpkt_header_rd <= '0';
    i_vpkt_payload_rd <= '0';

    i_vch_num <= (others=>'0');
    for i in 0 to C_VCTRL_VCH_COUNT - 1 loop
      i_vfr_num(i) <= (others=>'0');
      timestump_cnt(i) := (others=>'0');
    end loop;
    i_vfr_row_mrk <= (others=>'0');

    i_vfr_row <= (others=>'0');
    i_vfr_pix_count <= (others=>'0');
    i_vfr_row_count <= (others=>'0');
    i_vfr_row_mrk_l <= (others=>'0');
    i_vfr_rdy <= (others=>'0');

    i_mem_ptr <= (others=>'0');
    i_mem_wrbase <= (others=>'0');
    i_mem_adr <= (others=>'0');
    i_mem_dlen_rq <= (others=>'0');
    i_mem_trn_len <= (others=>'0');
    i_mem_dir <= '0';
    i_mem_start <= '0';

    i_vpkt_skip_rd <= '0';
    i_pkt_size_byte <= (others=>'0');
    i_pkt_skip_dcnt <= (others=>'0'); i_pkt_type_err <= (others=>'0');
    i_pix_num <= (others=>'0');

    i_pkt_skip_data <= (others=>'0');
    i_pix_count_byte <= (others=>'0');
    tst_timestump_cnt <= (others=>'0');

  else

    case fsm_state_cs is

      --------------------------------------
      --�������� ���������
      --------------------------------------
      when S_IDLE =>

        i_pkt_skip_dcnt <= (others=>'0');
        i_vfr_rdy <= (others=>'0');

        --���� ����� �������� ������ � ������
        if p_in_upp_buf_empty = '0' then

          if i_upp_data(15 downto 0) /= CONV_STD_LOGIC_VECTOR(0, 16) then
          --PktLen /= 0

            i_vpkt_header_rd <= '1';

            --��������� ������� ��������� ����� ������ (� DWORD)
            i_vpkt_cnt <= CONV_STD_LOGIC_VECTOR(CI_VPKT_HEADER_SIZE_COUNT - 1, i_vpkt_cnt'length);

            --bus=32b - incr(byte): 2 + (0 * 4) = 2 (���-�� ���� ���� length + ���-�� ���������� DW)
            --bus=64b - incr(byte): 2 + (1 * 4) = 6
            --bus=128b - incr(byte): 2 + (3 * 4) = 14
            --bus=256b - incr(byte): 2 + (3 * 4) = 14

            i_pkt_size_byte <=
              i_upp_data(15 downto 0)
                + selval(14, selval(14, selval(6, 2, G_MEM_DWIDTH = 64), G_MEM_DWIDTH = 128), G_MEM_DWIDTH = 256);

            i_pkt_type_err <= (others=>'0');
            fsm_state_cs <= S_PKT_HEADER_READ;

          else
            i_vpkt_skip_rd <= '1';
            i_pkt_type_err(3) <= '1';
            fsm_state_cs <= S_PKT_SKIP2;

          end if;
        end if;

      --------------------------------------
      --������ � ������ ��������� ������ �����������
      --------------------------------------
      when S_PKT_HEADER_READ =>

        if i_upp_hd_data_rd_out = '1' then

          i_pkt_skip_dcnt <= i_pkt_skip_dcnt + 1;

          if i_vpkt_cnt = (i_vpkt_cnt'range =>'0') then
          ------------------------------------------
          ------- �������� ���� ��������� ----------
          ------------------------------------------

            i_vpkt_header_rd <= '0';

            --��������� ���-�� �������� ������� ���� �������� � ���
            i_pix_count_byte <= i_pkt_size_byte
                                - CONV_STD_LOGIC_VECTOR((CI_VIDEO_PKT_HEADER_SIZE * 4)
                                      , i_pix_count_byte'length);

            if G_MEM_DWIDTH = 64 then
                --����� ���������� ������� � ������
                i_pix_num(15 downto 0) <= i_upp_data(15 downto 0);

                --������ ������
                i_vfr_row_mrk(15 downto 0) <= i_upp_data(31 downto 16);
                i_vfr_row_mrk(31 downto 16)<= i_upp_data((15 + 32) downto (0 + 32));

            elsif G_MEM_DWIDTH = 128 then

                for i in 0 to C_VCTRL_VCH_COUNT - 1 loop
                  if i_vch_num = i then
                    if i_vfr_num(i) /= i_upp_data(3 downto 0) then
                      --��������� ������ ������ �����!!!!!!!!!
                      --������������ ���������� ������
                      i_mem_wrbase <= p_in_cfg_prm_vch(i).mem_adr;
                    end if;

                    --��������� ����� �������� �����:
                    i_vfr_num(i) <= i_upp_data(3 downto 0);

                   end if;
                end loop;

                --������ �����: ���-�� ��������
                i_vfr_pix_count <= i_upp_data((31 + 0) downto (16 + 0));

                --������ �����: ���-�� �����
                i_vfr_row_count <= i_upp_data((15 + 32) downto (0 + 32));

                --����� ������� ������:
                i_vfr_row <= i_upp_data((31 + 32) downto (16 + 32));

                --����� ���������� ������� � ������
                i_pix_num(15 downto 0) <= i_upp_data((15 + 64) downto (0 + 64));

                --������ ������
                i_vfr_row_mrk(15 downto 0) <= i_upp_data((31 + 64) downto (16 + 64));
                i_vfr_row_mrk(31 downto 16)<= i_upp_data((15 + 96) downto (0 + 96));

              end if;

              fsm_state_cs <= S_MEM_START;

          else
          ---------------------------
          --������ ���������:
          ---------------------------
            --Header DWORD-0:
            if i_vpkt_cnt = CONV_STD_LOGIC_VECTOR(CI_VPKT_HEADER_SIZE_COUNT - 1, i_vpkt_cnt'length)
              and (G_MEM_DWIDTH < 256) then

                if i_upp_data(19 downto 16) = "0001"
                  and i_upp_data(27 downto 24) = "0011"
                    and i_upp_data(23 downto 20) < CONV_STD_LOGIC_VECTOR(C_VCTRL_VCH_COUNT, 4) then
                --��� ������ - ����� ������ + �������� ������ ��������� ������

                  --����� �������� ����� ������:
                  i_vch_num <= i_upp_data(23 downto 20);
                else
                  --�� ��� �����
                  i_vpkt_header_rd <= '0';
                  i_vpkt_skip_rd <= '1';

                  if i_upp_data(19 downto 16) /= "0001" then
                    i_pkt_type_err(0) <= '1';--pkt_type
                  end if;
                  if i_upp_data(23 downto 20) > CONV_STD_LOGIC_VECTOR(C_VCTRL_VCH_COUNT - 1, 4) then
                    i_pkt_type_err(1) <= '1';--vch
                  end if;
                  if i_upp_data(27 downto 24) /= "0011" then
                    i_pkt_type_err(2) <= '1';--src video
                  end if;

                  fsm_state_cs <= S_PKT_SKIP;
                end if;

            --Header DWORD - 1:
            elsif i_vpkt_cnt = CONV_STD_LOGIC_VECTOR(CI_VPKT_HEADER_SIZE_COUNT - 2, i_vpkt_cnt'length)
              and (G_MEM_DWIDTH < 128) then

                for i in 0 to C_VCTRL_VCH_COUNT - 1 loop
                  if i_vch_num = i then
                    if i_vfr_num(i) /= i_upp_data(3 downto 0) then
                      --��������� ������ ������ �����!!!!!!!!!
                      --������������ ���������� ������
                      i_mem_wrbase <= p_in_cfg_prm_vch(i).mem_adr;
                    end if;

                    --����� �������� �����:
                    i_vfr_num(i) <= i_upp_data(3 downto 0);

                   end if;
                end loop;

                --������ �����: ���-�� ��������
                i_vfr_pix_count <= i_upp_data(31 downto 16);

                --������ �����: ���-�� �����
                i_vfr_row_count <= i_upp_data((15 + 32) downto (0 + 32));

                --����� ������� ������:
                i_vfr_row <= i_upp_data((31 + 32) downto (16 + 32));

            end if;

            i_vpkt_cnt <= i_vpkt_cnt - 1;

          end if;

        end if;

      --------------------------------------
      --
      --------------------------------------
      when S_MEM_START =>

        for i in 0 to C_VCTRL_VCH_COUNT - 1 loop
          if i_vch_num = i then
            i_mem_ptr(G_MEM_VFR_M_BIT downto G_MEM_VFR_L_BIT) <= p_in_vfr_buf(i);
          end if;
        end loop;

        i_mem_ptr(G_MEM_VCH_M_BIT downto G_MEM_VCH_L_BIT) <= i_vch_num(G_MEM_VCH_M_BIT
                                                                        - G_MEM_VCH_L_BIT downto 0);
        i_mem_ptr(G_MEM_VLINE_M_BIT downto G_MEM_VLINE_L_BIT) <= i_vfr_row((G_MEM_VLINE_M_BIT
                                                                              - G_MEM_VLINE_L_BIT) + 0 downto 0);
        i_mem_ptr(G_MEM_VLINE_L_BIT - 1 downto 0) <= i_pix_num(G_MEM_VLINE_L_BIT - 1 downto 0);

        fsm_state_cs <= S_MEM_START2;

      --------------------------------------
      --��������� �������� ������ ���
      --------------------------------------
      when S_MEM_START2 =>

        i_vpkt_payload_rd <= '1';
        i_mem_dlen_rq <= EXT(i_pix_count_byte(i_pix_count_byte'high - 1 downto log2(G_MEM_DWIDTH/8))
                                                                                  , i_mem_dlen_rq'length)
                        + OR_reduce(i_pix_count_byte(log2(G_MEM_DWIDTH/8) - 1 downto 0));

        i_mem_trn_len <= EXT(p_in_cfg_mem_trn_len, i_mem_trn_len'length);
        i_mem_adr <= i_mem_wrbase + i_mem_ptr;
        i_mem_dir <= C_MEMWR_WRITE;
        i_mem_start <= '1';
        fsm_state_cs <= S_MEM_WR;

      ------------------------------------------------
      --������ ������
      ------------------------------------------------
      when S_MEM_WR =>

        i_mem_start <= '0';

        if i_mem_done = '1' then
        --�������� ���������
          i_vpkt_payload_rd <= '0';

          if i_vfr_row = (i_vfr_row_count - 1) then
          --��������� ��������� ������ �����.
          --������������� � ���������� �����:
            if i_vfr_pix_count = (i_pix_count_byte + i_pix_num) then
              for i in 0 to C_VCTRL_VCH_COUNT - 1 loop
                if i_vch_num = i then
                  i_vfr_rdy(i) <= '1';
                  timestump_cnt(i) := timestump_cnt(i) + 1;
                  tst_timestump_cnt <= timestump_cnt(i);
                end if;
              end loop;
            end if;
          end if;

          fsm_state_cs <= S_IDLE;

        end if;

      --------------------------------------
      --������� �������� ������
      --------------------------------------
      when S_PKT_SKIP =>
        --��������� ������� ������ ����� ���������� ����� ������� � ������ pkt,
        --���� ��������� ������ � �������� ������
        i_pkt_skip_data <= EXT(i_pkt_size_byte(i_pkt_size_byte'high downto log2(G_MEM_DWIDTH/8))
                                                                              , i_pkt_skip_data'length)
                         + OR_reduce(i_pkt_size_byte(log2(G_MEM_DWIDTH/8) - 1 downto 0));

        fsm_state_cs <= S_PKT_SKIP1;

      when S_PKT_SKIP1 =>

        if i_upp_pkt_skip_rd_out = '1' then
          if i_pkt_skip_dcnt = (i_pkt_skip_data - 1) then
            i_vpkt_skip_rd <= '0';
            fsm_state_cs <= S_IDLE;
          else
            i_pkt_skip_dcnt <= i_pkt_skip_dcnt + 1;
          end if;
        end if;

      --------------------------------------
      --
      --------------------------------------
      when S_PKT_SKIP2 =>

        i_vpkt_skip_rd <= '0';
        fsm_state_cs <= S_IDLE;

    end case;

  end if;
end if;
end process;


m_mem_wr : mem_wr
generic map(
G_USR_OPT        => G_USR_OPT,
G_MEM_BANK_M_BIT => G_MEM_BANK_M_BIT,
G_MEM_BANK_L_BIT => G_MEM_BANK_L_BIT,
G_MEM_AWIDTH     => G_MEM_AWIDTH,
G_MEM_DWIDTH     => G_MEM_DWIDTH
)
port map(
-------------------------------
-- ����������������
-------------------------------
p_in_cfg_mem_adr     => i_mem_adr,
p_in_cfg_mem_trn_len => i_mem_trn_len,
p_in_cfg_mem_dlen_rq => i_mem_dlen_rq,
p_in_cfg_mem_wr      => i_mem_dir,
p_in_cfg_mem_start   => i_mem_start,
p_out_cfg_mem_done   => i_mem_done,

-------------------------------
-- ����� � ����������������� ��������
-------------------------------
p_in_usr_txbuf_dout  => p_in_upp_data,
p_out_usr_txbuf_rd   => i_upp_data_rd,
p_in_usr_txbuf_empty => p_in_upp_buf_empty,

p_out_usr_rxbuf_din  => open,
p_out_usr_rxbuf_wd   => open,
p_in_usr_rxbuf_full  => '0',

---------------------------------
-- ����� � mem_ctrl.vhd
---------------------------------
p_out_mem            => p_out_mem,
p_in_mem             => p_in_mem,

-------------------------------
--System
-------------------------------
p_in_tst             => p_in_tst,
p_out_tst            => open,

p_in_clk             => p_in_clk,
p_in_rst             => p_in_rst
);


--END MAIN
end behavioral;

