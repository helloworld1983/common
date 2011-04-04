-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 2010.06
-- Module Name : memory_ctrl_ch_wr
--
-- ����������/�������� :
--  ������/������ ������ ���
--
--
-- Revision:
-- Revision 0.01 - File Created
-- Revision 0.02 - ���������� ������ � ������ ������ (add 2010.09.12)
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.vicg_common_pkg.all;
use work.prj_def.all;
use work.memory_ctrl_pkg.all;

entity memory_ctrl_ch_wr is
generic(
G_MEM_BANK_MSB_BIT   : integer:=29;--//����(��. ��.) ������������ ���� ���. ��������� � ����� p_in_cfg_mem_adr
G_MEM_BANK_LSB_BIT   : integer:=28
);
port
(
-------------------------------
-- ����������������
-------------------------------
p_in_cfg_mem_adr           : in    std_logic_vector(31 downto 0);--//����� ��� (� BYTE)
p_in_cfg_mem_trn_len       : in    std_logic_vector(15 downto 0);--//������ ��������� MEM_TRN (� DWORD)
p_in_cfg_mem_dlen_rq       : in    std_logic_vector(15 downto 0);--//������ ������������� ������ ������/������ (� DWORD)
p_in_cfg_mem_wr            : in    std_logic;                    --//��� �������� (1/0 - ������/������)
p_in_cfg_mem_start         : in    std_logic;                    --//�����: ���� ��������
p_out_cfg_mem_done         : out   std_logic;                    --//�����: �������� ���������

-------------------------------
-- ����� � ����������������� ��������
-------------------------------
--//user_buf->mem
p_in_usr_txbuf_dout        : in    std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);
p_out_usr_txbuf_rd         : out   std_logic;
p_in_usr_txbuf_empty       : in    std_logic;

--//user_buf<-mem
p_out_usr_rxbuf_din        : out   std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);
p_out_usr_rxbuf_wd         : out   std_logic;
p_in_usr_rxbuf_full        : in    std_logic;

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
--System
-------------------------------
p_in_tst                   : in    std_logic_vector(31 downto 0);--//��������������� ���������� (��� ������� ������ ��� �������� ����������)
p_out_tst                  : out   std_logic_vector(31 downto 0);--//��������������� ������

p_in_clk            : in    std_logic;
p_in_rst            : in    std_logic
);
end memory_ctrl_ch_wr;

architecture behavioral of memory_ctrl_ch_wr is

type fsm_state is
(
S_IDLE,
S_MEM_REMAIN_SIZE_CALC,
S_MEM_TRN_LEN_CALC,
S_MEM_WAIT_RQ_EN,
S_MEM_TRN_START,
S_MEM_TRN_START_DONE,
S_MEM_TRN,
S_MEM_TRN_END,
S_WAIT,
S_EXIT
);
signal fsm_state_cs: fsm_state;

signal i_mem_bank1h_out            : std_logic_vector(pwr((G_MEM_BANK_MSB_BIT-G_MEM_BANK_LSB_BIT+1), 2)-1 downto 0);
signal i_mem_adr_out               : std_logic_vector(G_MEM_BANK_LSB_BIT-1 downto 0);
signal i_mem_ce_out                : std_logic;
signal i_mem_cw_out                : std_logic;
signal i_mem_wr_out                : std_logic;
signal i_mem_rd_out                : std_logic;
signal i_mem_term_out              : std_logic;

signal i_mem_ce                    : std_logic;
signal i_mem_wr                    : std_logic;
signal i_memarb_req                : std_logic;

signal i_mem_dir                   : std_logic;
signal i_mem_dlen_remain           : std_logic_vector(p_in_cfg_mem_dlen_rq'length-1 downto 0);
signal i_mem_dlen_used             : std_logic_vector(p_in_cfg_mem_dlen_rq'length-1 downto 0);
signal i_mem_trn_work              : std_logic;
signal i_mem_trn_len               : std_logic_vector(p_in_cfg_mem_trn_len'length-1 downto 0);

signal i_mem_done                  : std_logic;

--MAIN
begin

--//----------------------------------
--//��������������� �������
--//----------------------------------
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    p_out_tst(1 downto 0)<=(others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then
    p_out_tst(0) <=p_in_mem_re;
    p_out_tst(1) <=p_in_mem_wpf;
    p_out_tst(2) <=p_in_mem_rpe;
    p_out_tst(3) <=p_in_mem_wf or p_in_mem_wpf or
                   p_in_mem_re or p_in_mem_rpe;
  end if;
end process;
p_out_tst(31 downto 4)<=(others=>'0');



p_out_memarb_req<=i_memarb_req;

-------------------------------
-- ����� � ����������������� ��������
-------------------------------
p_out_usr_txbuf_rd   <= i_mem_wr_out;

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    p_out_usr_rxbuf_wd  <= '0';
    p_out_usr_rxbuf_din <= (others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then
    p_out_usr_rxbuf_wd  <= i_mem_rd_out;
    p_out_usr_rxbuf_din <= p_in_mem_dout;
  end if;
end process;


--//----------------------------------------------
--//����� � ������������ ������
--//----------------------------------------------
p_out_mem_clk  <=p_in_clk;

p_out_mem_ce <=i_mem_ce_out;
p_out_mem_cw <=i_mem_cw_out;

p_out_mem_bank1h<=EXT(i_mem_bank1h_out, p_out_mem_bank1h'length);
p_out_mem_adr<=EXT(i_mem_adr_out(i_mem_adr_out'high downto 2), p_out_mem_adr'length);
p_out_mem_be <=(others=>'1');

p_out_mem_wr <=i_mem_wr_out;
p_out_mem_rd <=i_mem_rd_out;

p_out_mem_term<=i_mem_term_out;

p_out_mem_din <=p_in_usr_txbuf_dout;--add 2010.09.12

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
--    p_out_mem_din  <=(others=>'0');

    i_mem_ce_out <='0';
    i_mem_cw_out <='0';
    i_mem_wr_out <='0';
    i_mem_term_out<='0';

  elsif p_in_clk'event and p_in_clk='1' then

--    p_out_mem_din <=p_in_usr_txbuf_dout;

    i_mem_ce_out <=i_mem_ce;
    i_mem_cw_out <=i_mem_dir;
    i_mem_wr_out <=i_mem_wr;

    --//��������� ������ ��������� ������� ��������(write/read) ���
    if (i_mem_wr='1' or i_mem_rd_out='1') and i_mem_trn_len=(i_mem_trn_len'range => '0') then
      i_mem_term_out<='1';
    else
      i_mem_term_out<='0';
    end if;

  end if;
end process;


--//----------------------------------------------
--//������� ������/������ ������ ���
--//----------------------------------------------
--//���������� ������� ��������
p_out_cfg_mem_done <=i_mem_done;

--//���������� ������/������ ���
i_mem_rd_out <=i_mem_trn_work and not i_mem_dir and not p_in_mem_re  and not p_in_usr_rxbuf_full;
i_mem_wr     <=i_mem_trn_work and     i_mem_dir and not p_in_mem_wpf and not p_in_usr_txbuf_empty;

--//������ ������ ��������
process(p_in_rst,p_in_clk)
  variable var_update_addr: std_logic_vector(i_mem_trn_len'length+1 downto 0);
begin
  if p_in_rst='1' then

    fsm_state_cs <= S_IDLE;

    i_mem_bank1h_out<=(others=>'0');
    i_mem_adr_out<=(others=>'0');
    i_mem_ce<='0';
    i_mem_dir<='0';

    i_mem_dlen_remain<=(others=>'0');
    i_mem_dlen_used<=(others=>'0');
    i_mem_trn_len<=(others=>'0');
    i_mem_trn_work<='0';
    i_mem_done<='0';

    i_memarb_req<='0';

  elsif p_in_clk'event and p_in_clk='1' then
  --  if clk_en='1' then

    case fsm_state_cs is

      when S_IDLE =>

      i_mem_done<='0';

      --//------------------------------------
      --//���� ������� ������� ��������
      --//------------------------------------
        if p_in_cfg_mem_start='1' then
          i_mem_adr_out<=p_in_cfg_mem_adr(G_MEM_BANK_LSB_BIT-1 downto 0);
          i_mem_dir <=p_in_cfg_mem_wr;

          --//��������� ���� ���
          for i in 0 to i_mem_bank1h_out'high loop
            if p_in_cfg_mem_adr(G_MEM_BANK_MSB_BIT downto G_MEM_BANK_LSB_BIT)= i then
              i_mem_bank1h_out(i) <= '1';
            else
              i_mem_bank1h_out(i) <= '0';
            end if;
          end loop;

          fsm_state_cs <= S_MEM_REMAIN_SIZE_CALC;
        end if;

      --//------------------------------------
      --//����������� ������� ������ ������������� ������������� ��������
      --//------------------------------------
      when S_MEM_REMAIN_SIZE_CALC =>

        i_mem_dlen_remain <= EXT(p_in_cfg_mem_dlen_rq, p_in_cfg_mem_dlen_rq'length) - EXT(i_mem_dlen_used, p_in_cfg_mem_dlen_rq'length);
        fsm_state_cs <= S_MEM_TRN_LEN_CALC;

      --//------------------------------------
      --//��������� ������ ���������� write/read ���
      --//------------------------------------
      when S_MEM_TRN_LEN_CALC =>

        if i_mem_dlen_remain >= EXT(p_in_cfg_mem_trn_len, p_in_cfg_mem_dlen_rq'length) then
          i_mem_trn_len <= p_in_cfg_mem_trn_len;
        else
          i_mem_trn_len <= i_mem_dlen_remain(i_mem_trn_len'high downto 0);
        end if;

        i_memarb_req<='1';--//����������� ���������� � ������� �� ���������� ��������� � ���
        fsm_state_cs <= S_MEM_WAIT_RQ_EN;--S_MEM_TRN_START;

      --//------------------------------------
      --//���� ���������� �� �������
      --//------------------------------------
      when S_MEM_WAIT_RQ_EN =>

        if p_in_memarb_en='1' then
        --//�������� ���������� �� �������
          fsm_state_cs <= S_MEM_TRN_START;
        end if;

      --//------------------------------------
      --//��������� � ������/������ ���
      --//------------------------------------
      when S_MEM_TRN_START =>

        if i_mem_dir='1' then
        --������
          if p_in_mem_wpf='0'then
          --//���� ����� � TXBUF ����������� ������ ����� ����� ���������� ������
            i_mem_ce<='1';
            fsm_state_cs <= S_MEM_TRN_START_DONE;
          end if;
        else
        --������
          i_mem_ce<='1';
          fsm_state_cs <= S_MEM_TRN_START_DONE;
        end if;

      --//------------------------------------
      --//���� ���������� write/read ���
      --//------------------------------------
      when S_MEM_TRN_START_DONE =>

        i_mem_trn_len<=i_mem_trn_len-1;
        i_mem_ce<='0';
        i_mem_trn_work<='1';
        fsm_state_cs <= S_MEM_TRN;

      --//----------------------------------------------
      --//������/������ ������ ���
      --//----------------------------------------------
      when S_MEM_TRN =>

        if i_mem_wr='1' or i_mem_rd_out='1' then
          i_mem_dlen_used<=i_mem_dlen_used+1;

          if i_mem_trn_len=(i_mem_trn_len'range => '0') then
            i_mem_trn_work<='0';
            fsm_state_cs <= S_MEM_TRN_END;
          else
            i_mem_trn_len<=i_mem_trn_len-1;
          end if;
        end if;

      --//----------------------------------------------
      --//������ ���������� ������� �������� ���
      --//----------------------------------------------
      when S_MEM_TRN_END =>

        --//��������� �������� ��� ���������� ������ ���
        var_update_addr(1 downto 0) :=(others=>'0');--//���� p_in_cfg_mem_trn_len � DWORD
        var_update_addr(i_mem_trn_len'length+1 downto 2):=p_in_cfg_mem_trn_len;

        if p_in_cfg_mem_dlen_rq=i_mem_dlen_used then
          fsm_state_cs <= S_EXIT;
        else
          --//��������� ��������� ����� ���
          i_mem_adr_out<=i_mem_adr_out + EXT(var_update_addr, i_mem_adr_out'length);

          --//������� � ��������� ���������� write/read ���
          fsm_state_cs <= S_WAIT;--S_MEM_REMAIN_SIZE_CALC;
        end if;

      --//----------------------------------------------
      --//��������� � ���������� ��������� ��������
      --//----------------------------------------------
      when S_WAIT =>
        if i_mem_dir='0' then
        --������
          if p_in_mem_re='1'then
            i_memarb_req<='0';
            fsm_state_cs <= S_MEM_REMAIN_SIZE_CALC;
          end if;
        else
        --������
          i_memarb_req<='0';
          fsm_state_cs <= S_MEM_REMAIN_SIZE_CALC;
        end if;

      --//----------------------------------------------
      --//��������� � ���������� ��������� ��������
      --//----------------------------------------------
      when S_EXIT =>

        i_mem_dlen_used<=(others=>'0');

        if i_mem_dir='0' then
        --������
          if p_in_mem_re='1'then
            i_mem_done<='1';
            i_memarb_req<='0';
            fsm_state_cs <= S_IDLE;
          end if;
        else
        --������
          i_mem_done<='1';
          i_memarb_req<='0';
          fsm_state_cs <= S_IDLE;
        end if;


    end case;
  end if;
end process;

--END MAIN
end behavioral;

