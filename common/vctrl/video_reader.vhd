-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 2010.06
-- Module Name : video_reader
--
-- ����������/�������� :
--  ������ ����� ����������� �� ���
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

library work;
use work.vicg_common_pkg.all;
use work.prj_cfg.all;
use work.prj_def.all;
use work.memory_ctrl_pkg.all;
use work.dsn_video_ctrl_pkg.all;


entity video_reader is
generic(
G_MEM_BANK_MSB_BIT   : integer:=29;
G_MEM_BANK_LSB_BIT   : integer:=28;

G_MEM_VCH_MSB_BIT    : integer:=25;
G_MEM_VCH_LSB_BIT    : integer:=24;
G_MEM_VFRAME_LSB_BIT : integer:=23;
G_MEM_VFRAME_MSB_BIT : integer:=23;
G_MEM_VROW_MSB_BIT   : integer:=22;
G_MEM_VROW_LSB_BIT   : integer:=12
);
port
(
-------------------------------
-- ����������������
-------------------------------
p_in_cfg_mem_trn_len : in    std_logic_vector(7 downto 0);
p_in_cfg_prm_vch     : in    TReaderVCHParams;

p_in_hrd_chsel       : in    std_logic_vector(3 downto 0);--//����: ����� ����������� ��������� ��� ������
p_in_hrd_start       : in    std_logic;                   --//����: ������ ������ �����
p_in_hrd_done        : in    std_logic;                   --//����: ������������� ������� �����

p_in_vfr_buf         : in    TVfrBufs;                    --//����� ����������� � ������� ������ ��� ���������������� �����������
p_in_vfr_nrow        : in    std_logic;                   --//���������� ������ ��������� ������

--//�������
p_out_vch_fr_new     : out   std_logic;
p_out_vch_rd_done    : out   std_logic;
p_out_vch            : out   std_logic_vector(3 downto 0);
p_out_vch_color_fst  : out   std_logic_vector(1 downto 0);
p_out_vch_color      : out   std_logic;
p_out_vch_pcolor     : out   std_logic;
p_out_vch_active_pix : out   std_logic_vector(15 downto 0);
p_out_vch_active_row : out   std_logic_vector(15 downto 0);
p_out_vch_zoom       : out   std_logic_vector(3 downto 0);
p_out_vch_zoom_type  : out   std_logic;
p_out_vch_mirx       : out   std_logic;

--//--------------------------
--//Upstream Port
--//--------------------------
p_out_upp_data       : out   std_logic_vector(31 downto 0);
p_out_upp_data_wd    : out   std_logic;
p_in_upp_buf_empty   : in    std_logic;
p_in_upp_buf_full    : in    std_logic;

---------------------------------
-- ����� � memory_ctrl.vhd
---------------------------------
p_out_memarb_req     : out   std_logic;                    --//������ � ������� ��� �� ���������� ����������
p_in_memarb_en       : in    std_logic;                    --//���������� �������

p_out_mem_bank1h     : out   std_logic_vector(15 downto 0);
p_out_mem_ce         : out   std_logic;
p_out_mem_cw         : out   std_logic;
p_out_mem_rd         : out   std_logic;
p_out_mem_wr         : out   std_logic;
p_out_mem_term       : out   std_logic;
p_out_mem_adr        : out   std_logic_vector(C_MEMCTRL_ADDR_WIDTH - 1 downto 0);
p_out_mem_be         : out   std_logic_vector(C_MEMCTRL_DATA_WIDTH / 8 - 1 downto 0);
p_out_mem_din        : out   std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);
p_in_mem_dout        : in    std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);

p_in_mem_wf          : in    std_logic;
p_in_mem_wpf         : in    std_logic;
p_in_mem_re          : in    std_logic;
p_in_mem_rpe         : in    std_logic;

p_out_mem_clk        : out   std_logic;

-------------------------------
--���������������
-------------------------------
p_in_tst             : in    std_logic_vector(31 downto 0);
p_out_tst            : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk             : in    std_logic;
p_in_rst             : in    std_logic
);
end video_reader;

architecture behavioral of video_reader is

-- Small delay for simulation purposes.
constant dly : time := 1 ps;

type fsm_state is
(
S_IDLE,
S_LD_PRMS,
S_ROW_FINED0,
S_ROW_FINED1,
S_MEM_SET_ADR,
S_MEM_START,
S_MEM_RD,
S_ROW_NXT,
S_WAIT_HOST_ACK
);
signal fsm_state_cs: fsm_state;

signal i_mem_ptr                     : std_logic_vector(31 downto 0);
signal i_mem_rdbase                  : std_logic_vector(31 downto 0);
signal i_mem_adr                     : std_logic_vector(31 downto 0);
signal i_mem_trn_len                 : std_logic_vector(15 downto 0);
signal i_mem_dlen_rq                 : std_logic_vector(15 downto 0);
signal i_mem_start                   : std_logic;
signal i_mem_dir                     : std_logic;
signal i_mem_done                    : std_logic;

signal i_vch_num                     : std_logic_vector(p_in_hrd_chsel'high downto 0);
signal i_vfr_zoom                    : std_logic_vector(3 downto 0);
signal i_vfr_zoom_type               : std_logic;
signal i_vfr_pcolor                  : std_logic;
signal i_vfr_color                   : std_logic;
signal i_vfr_color_fst               : std_logic_vector(1 downto 0);
signal i_vfr_mirror                  : TFrXYMirror;
signal i_vfr_row_cnt                 : std_logic_vector(G_MEM_VFRAME_LSB_BIT-G_MEM_VROW_LSB_BIT downto 0);
signal i_vfr_active_row              : std_logic_vector(i_vfr_row_cnt'high downto 0);
signal i_vfr_active_row_cnt          : std_logic_vector(i_vfr_row_cnt'high downto 0);
signal i_vfr_subsampling             : std_logic_vector(1 downto 0);
signal i_vfr_done                    : std_logic;
signal i_vfr_new                     : std_logic;
signal i_vfr_buf                     : std_logic_vector(C_DSN_VCTRL_MEM_VFRAME_MSB_BIT-C_DSN_VCTRL_MEM_VFRAME_LSB_BIT downto 0);

signal tst_dbg_rdTBUF                : std_logic;
signal tst_dbg_rdEBUF                : std_logic;

--signal tst_fsmstate                  : std_logic_vector(3 downto 0);
--signal tst_fsmstate_dly              : std_logic_vector(3 downto 0);
--signal tst_mem_ctrl_ch_wr_out        : std_logic_vector(31 downto 0);

--MAIN
begin


--//----------------------------------
--//��������������� �������
--//----------------------------------
--process(p_in_rst,p_in_clk)
--begin
--  if p_in_rst='1' then
--    p_out_tst(0)<='0';
--    tst_fsmstate_dly<=(others=>'0');
--  elsif p_in_clk'event and p_in_clk='1' then
--
--    tst_fsmstate_dly<=tst_fsmstate;
--    p_out_tst(0) <=OR_reduce(tst_fsmstate_dly);-- or tst_mem_ctrl_ch_wr_out(0);--i_upp_data_wd;
--
--  end if;
--end process;
--p_out_tst(31 downto 1)<=(others=>'0');
--
--tst_fsmstate<=CONV_STD_LOGIC_VECTOR(16#01#,tst_fsmstate'length) when fsm_state_cs=S_LD_PRMS else
--              CONV_STD_LOGIC_VECTOR(16#02#,tst_fsmstate'length) when fsm_state_cs=S_ROW_FINED0 else
--              CONV_STD_LOGIC_VECTOR(16#03#,tst_fsmstate'length) when fsm_state_cs=S_ROW_FINED1 else
--              CONV_STD_LOGIC_VECTOR(16#04#,tst_fsmstate'length) when fsm_state_cs=S_MEM_SET_ADR else
--              CONV_STD_LOGIC_VECTOR(16#05#,tst_fsmstate'length) when fsm_state_cs=S_MEM_START else
--              CONV_STD_LOGIC_VECTOR(16#06#,tst_fsmstate'length) when fsm_state_cs=S_MEM_RD else
--              CONV_STD_LOGIC_VECTOR(16#07#,tst_fsmstate'length) when fsm_state_cs=S_ROW_NXT else
--              CONV_STD_LOGIC_VECTOR(16#08#,tst_fsmstate'length) when fsm_state_cs=S_WAIT_HOST_ACK else
--              CONV_STD_LOGIC_VECTOR(16#00#,tst_fsmstate'length); --//fsm_state_cs=S_IDLE else

p_out_tst(31 downto 0)<=(others=>'0');


tst_dbg_rdTBUF<=p_in_tst(C_DSN_VCTRL_REG_TST0_DBG_TBUFRD_BIT);
tst_dbg_rdEBUF<=p_in_tst(C_DSN_VCTRL_REG_TST0_DBG_EBUFRD_BIT);

--//----------------------------------------------
--//�������
--//----------------------------------------------
p_out_vch_rd_done<=i_vfr_done;
p_out_vch_fr_new<=i_vfr_new;

--//��������� ������ �������� �����
p_out_vch <= i_vch_num;

p_out_vch_color_fst <=i_vfr_color_fst;
p_out_vch_color     <=i_vfr_color;
p_out_vch_pcolor    <=i_vfr_pcolor;
p_out_vch_active_pix<=i_mem_dlen_rq;
p_out_vch_active_row<=EXT(i_vfr_active_row, p_out_vch_active_row'length);
p_out_vch_zoom      <=i_vfr_zoom;
p_out_vch_zoom_type <=i_vfr_zoom_type;
p_out_vch_mirx      <=i_vfr_mirror.pix;



--//----------------------------------------------
--//������� ������ ����� �����
--//----------------------------------------------
--//������ ������ ��������
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then

    fsm_state_cs <= S_IDLE;

    i_mem_rdbase<=(others=>'0');
    i_mem_ptr<=(others=>'0');
    i_mem_adr<=(others=>'0');
    i_mem_trn_len<=(others=>'0');
    i_mem_dlen_rq<=(others=>'0');
    i_mem_dir<='0';
    i_mem_start<='0';

    i_vfr_buf<=(others=>'0');
    i_vfr_pcolor<='0';
    i_vfr_color<='0';
    i_vfr_color_fst<=(others=>'0');
    i_vfr_mirror.pix<='0';
    i_vfr_mirror.row<='0';
    i_vfr_row_cnt<=(others=>'0');
    i_vfr_active_row<=(others=>'0');
    i_vfr_active_row_cnt<=(others=>'0');
    i_vfr_subsampling<=(others=>'0');
    i_vfr_zoom<=(others=>'0');
    i_vfr_zoom_type<='0';

    i_vfr_done<='0';
    i_vch_num<=(others=>'0');
    i_vfr_new<='0';

  elsif p_in_clk'event and p_in_clk='1' then
  --  if clk_en='1' then

    case fsm_state_cs is

      --//------------------------------------
      --//�������� ���������
      --//------------------------------------
      when S_IDLE =>

        i_vfr_done<='0';

        --//�������� ��������� ����� ������
        if p_in_hrd_start='1' then
          i_mem_trn_len<=EXT(p_in_cfg_mem_trn_len, i_mem_trn_len'length);
          i_vch_num<=p_in_hrd_chsel;

          fsm_state_cs <= S_LD_PRMS;
        end if;

      --//------------------------------------
      --//�������� ����������
      --//------------------------------------
      when S_LD_PRMS =>

        --//�������� ��������� ����� ������
        for i in 0 to C_DSN_VCTRL_VCH_COUNT-1 loop
          if i_vch_num=i then

            --//--------------------------
            --//
            --//--------------------------
            i_vfr_buf<=p_in_vfr_buf(i);

            --//--------------------------
            --//���� ���:
            --//--------------------------
            i_mem_rdbase<=p_in_cfg_prm_vch(i).mem_adr;

            --//--------------------------
            --//����:
            --//--------------------------
            i_vfr_pcolor<=p_in_cfg_prm_vch(i).fr_pcolor;
            i_vfr_color<=p_in_cfg_prm_vch(i).fr_color;
            i_vfr_color_fst<=p_in_cfg_prm_vch(i).fr_color_fst;

            --//--------------------------
            --//ZOOM:
            --//--------------------------
            i_vfr_zoom<=p_in_cfg_prm_vch(i).fr_zoom;
            i_vfr_zoom_type<=p_in_cfg_prm_vch(i).fr_zoom_type;

            --//--------------------------
            --//��������������:
            --//--------------------------
            i_vfr_mirror.pix<=p_in_cfg_prm_vch(i).fr_mirror.pix;
            i_vfr_mirror.row<=p_in_cfg_prm_vch(i).fr_mirror.row;

            --//--------------------------
            --//�������:
            --//--------------------------
            --//�������������� ������ ���������� ������
            --//(������ ���� ����� ������� ����� ������)
            if p_in_cfg_prm_vch(i).fr_subsampling="10" then
              --//������������ �� �������� - ���� / ����� ������ 4-�� ������� � ������ 4-� ������
                i_mem_dlen_rq<="00"&p_in_cfg_prm_vch(i).fr_size.activ.pix(p_in_cfg_prm_vch(i).fr_size.activ.pix'length-1 downto 2);
            elsif p_in_cfg_prm_vch(i).fr_subsampling="01" then
              --//������������ �� �������� - ���� / ����� ������ 2-�� ������� � ������ 2-� ������
                i_mem_dlen_rq<='0'&p_in_cfg_prm_vch(i).fr_size.activ.pix(p_in_cfg_prm_vch(i).fr_size.activ.pix'length-1 downto 1);
            else
              --//������������ �� �������� - ���
              i_mem_dlen_rq<=p_in_cfg_prm_vch(i).fr_size.activ.pix;
            end if;

            --//--------------------------
            --//������������:
            --//--------------------------
            i_vfr_subsampling<=p_in_cfg_prm_vch(i).fr_subsampling;

            --//--------------------------
            --//������:
            --//--------------------------
            i_vfr_active_row<=p_in_cfg_prm_vch(i).fr_size.activ.row(i_vfr_active_row'high downto 0);

            --//�������������� ������� �����
            if p_in_cfg_prm_vch(i).fr_mirror.row='0' then
              i_vfr_row_cnt<=p_in_cfg_prm_vch(i).fr_size.skip.row(i_vfr_row_cnt'high downto 0);
              i_vfr_active_row_cnt<=(others=>'0');
            else
              i_vfr_row_cnt<=p_in_cfg_prm_vch(i).fr_size.activ.row(i_vfr_row_cnt'high downto 0) + p_in_cfg_prm_vch(i).fr_size.skip.row(i_vfr_row_cnt'high downto 0);
              i_vfr_active_row_cnt<=p_in_cfg_prm_vch(i).fr_size.activ.row(i_vfr_row_cnt'high downto 0)-1;
            end if;

          end if;
        end loop;

        i_mem_ptr<=(others=>'0');
        i_vfr_new<='1';

        fsm_state_cs <= S_ROW_FINED0;

      --//------------------------------------
      --//
      --//------------------------------------
      when S_ROW_FINED0 =>

        i_vfr_new<='0';

        if i_vfr_mirror.row='1' then
          --//�������������� �� Y - ���������
          --//�������������� ������� �����
          i_vfr_row_cnt<=i_vfr_row_cnt-1;
        end if;

        fsm_state_cs <= S_ROW_FINED1;

      --//------------------------------------
      --//���� ������ ����� �����
      --//------------------------------------
      when S_ROW_FINED1 =>

        if i_vfr_subsampling="00" then
        --//��� ������������
          fsm_state_cs <= S_MEM_SET_ADR;

        elsif i_vfr_subsampling="01" then
        --//������������ x2
          if i_vfr_active_row_cnt(0)='1' then
            --//����� ������:
            fsm_state_cs <= S_MEM_SET_ADR;
          else
            --//����� ������:
            if i_vfr_mirror.row='1' then
              if i_vfr_active_row_cnt=(i_vfr_active_row_cnt'range =>'0') then
                  fsm_state_cs <= S_WAIT_HOST_ACK;
              else
                i_vfr_active_row_cnt<=i_vfr_active_row_cnt-1;
                i_vfr_row_cnt<=i_vfr_row_cnt-1;
              end if;
            else
              i_vfr_row_cnt<=i_vfr_row_cnt+1;
              i_vfr_active_row_cnt<=i_vfr_active_row_cnt+1;
            end if;
          end if;

        elsif i_vfr_subsampling="10" then
        --//������������ x4
          if i_vfr_active_row_cnt(1 downto 0)="11" then
            --//����� ������:
            fsm_state_cs <= S_MEM_SET_ADR;
          else
            --//����� ������:
            if i_vfr_mirror.row='1' then
              if i_vfr_active_row_cnt=(i_vfr_active_row_cnt'range =>'0') then
                  fsm_state_cs <= S_WAIT_HOST_ACK;
              else
                i_vfr_active_row_cnt<=i_vfr_active_row_cnt-1;
                i_vfr_row_cnt<=i_vfr_row_cnt-1;
              end if;
            else
              i_vfr_row_cnt<=i_vfr_row_cnt+1;
              i_vfr_active_row_cnt<=i_vfr_active_row_cnt+1;
            end if;
          end if;

        end if;

      --//------------------------------------
      --//��������� �������� ������ ���
      --//------------------------------------
      when S_MEM_SET_ADR =>

        if tst_dbg_rdTBUF='1' or tst_dbg_rdEBUF='1' then

            i_mem_ptr(i_mem_ptr'high downto G_MEM_VROW_MSB_BIT+1)<=(others=>'0');
            i_mem_ptr(G_MEM_VROW_MSB_BIT downto G_MEM_VROW_LSB_BIT)<=i_vfr_active_row_cnt(G_MEM_VROW_MSB_BIT-G_MEM_VROW_LSB_BIT downto 0);

        else
            i_mem_ptr(i_mem_ptr'high downto G_MEM_VCH_MSB_BIT+1)<=(others=>'0');
            i_mem_ptr(G_MEM_VCH_MSB_BIT downto G_MEM_VCH_LSB_BIT)<=i_vch_num(G_MEM_VCH_MSB_BIT-G_MEM_VCH_LSB_BIT downto 0);
            i_mem_ptr(G_MEM_VFRAME_MSB_BIT downto G_MEM_VFRAME_LSB_BIT)<=i_vfr_buf;
            i_mem_ptr(G_MEM_VROW_MSB_BIT downto G_MEM_VROW_LSB_BIT)<=i_vfr_row_cnt(G_MEM_VROW_MSB_BIT-G_MEM_VROW_LSB_BIT downto 0);

        end if;

        fsm_state_cs <= S_MEM_START;

      --//------------------------------------
      --//��������� �������� ������ ���
      --//------------------------------------
      when S_MEM_START =>

        i_mem_adr<=i_mem_rdbase + i_mem_ptr;
        i_mem_dir<=C_MEMCTRLCHWR_READ;
        i_mem_start<='1';
        fsm_state_cs <= S_MEM_RD;

      --//----------------------------------------------
      --//������ ������
      --//----------------------------------------------
      when S_MEM_RD =>

        i_mem_start<='0';

        if i_mem_done='1' then
        --//�������� ���������
          fsm_state_cs <= S_ROW_NXT;
        end if;

      --//----------------------------------------------
      --//���� ������� �� ������ ��������� ������
      --//----------------------------------------------
      when S_ROW_NXT =>

        if p_in_vfr_nrow='1' then

          if (i_vfr_mirror.row='0' and i_vfr_active_row_cnt=(i_vfr_active_row-1)) or
             (i_vfr_mirror.row='1' and i_vfr_active_row_cnt=(i_vfr_active_row_cnt'range =>'0'))then
              fsm_state_cs <= S_WAIT_HOST_ACK;
          else

            if i_vfr_mirror.row='1' then
              i_vfr_active_row_cnt<=i_vfr_active_row_cnt-1;
              i_vfr_row_cnt<=i_vfr_row_cnt-1;
            else
              i_vfr_active_row_cnt<=i_vfr_active_row_cnt+1;
              i_vfr_row_cnt<=i_vfr_row_cnt+1;
            end if;

            fsm_state_cs <= S_ROW_FINED1;
          end if;

        end if;

      --//----------------------------------------------
      --//���� ����� �� ����� - ������ ������
      --//----------------------------------------------
      when S_WAIT_HOST_ACK =>

        if p_in_hrd_done='1' then
          i_vfr_done<='1';
          fsm_state_cs <= S_IDLE;
        end if;

    end case;
  end if;
end process;


--//------------------------------------------------------
--//������ ������/������ ������ ��� (memory_ctrl.vhd)
--//------------------------------------------------------
m_mem_ctrl_wr : memory_ctrl_ch_wr
generic map(
G_MEM_BANK_MSB_BIT   => G_MEM_BANK_MSB_BIT,
G_MEM_BANK_LSB_BIT   => G_MEM_BANK_LSB_BIT
)
port map
(
-------------------------------
-- ����������������
-------------------------------
p_in_cfg_mem_adr           => i_mem_adr,
p_in_cfg_mem_trn_len       => i_mem_trn_len,
p_in_cfg_mem_dlen_rq       => i_mem_dlen_rq,
p_in_cfg_mem_wr            => i_mem_dir,
p_in_cfg_mem_start         => i_mem_start,
p_out_cfg_mem_done         => i_mem_done,

--//�������
p_out_memarb_req           => p_out_memarb_req,
p_in_memarb_en             => p_in_memarb_en,

-------------------------------
-- ����� � ����������������� ��������
-------------------------------
p_in_usr_txbuf_dout        => "00000000000000000000000000000000",
p_out_usr_txbuf_rd         => open,
p_in_usr_txbuf_empty       => '0',

p_out_usr_rxbuf_din        => p_out_upp_data,
p_out_usr_rxbuf_wd         => p_out_upp_data_wd,
p_in_usr_rxbuf_full        => p_in_upp_buf_full,

---------------------------------
-- ����� � memory_ctrl.vhd
---------------------------------
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
--System
-------------------------------
p_in_tst                   => p_in_tst,
p_out_tst                  => open,--tst_mem_ctrl_ch_wr_out,

p_in_clk            => p_in_clk,
p_in_rst            => p_in_rst
);



--END MAIN
end behavioral;


