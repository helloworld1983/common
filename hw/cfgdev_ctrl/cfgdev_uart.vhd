-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 14.07.2011 11:49:04
-- Module Name : cfgdev_uart
--
-- ����������/�������� :
--  ���������� ��������� ������/������ ������ ������� FPGA ����� ���������� FTDI (USB)
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

use work.cfgdev_pkg.all;

entity cfgdev_uart is
generic(
G_BAUDCNT_VAL: integer:=64 --//G_BAUDCNT_VAL = Fuart_refclk/(16 * UART_BAUDRATE)
                           --//��������: Fuart_refclk=40MHz, UART_BAUDRATE=115200
                           --//
                           --// 40000000/(16 *115200)=21,701 - ��������� �� ���������� �����, �.� = 22
);
port
(
-------------------------------
--����� � UART
-------------------------------
p_out_uart_tx        : out    std_logic;                    --//
p_in_uart_rx         : in     std_logic;                    --//
p_in_uart_refclk     : in     std_logic;                    --//

-------------------------------
--
-------------------------------
p_out_module_rdy     : out    std_logic;                    --//
p_out_module_error   : out    std_logic;                    --//

-------------------------------
--������/������ ���������������� ���������� ���-��
-------------------------------
p_out_dev_adr        : out    std_logic_vector(7 downto 0); --//����� ������
p_out_cfg_adr        : out    std_logic_vector(7 downto 0); --//����� ���������� ��������
p_out_cfg_adr_ld     : out    std_logic;                    --//�������� ������ ��������
p_out_cfg_adr_fifo   : out    std_logic;                    --//��� ���������
p_out_cfg_wd         : out    std_logic;                    --//����� ������
p_out_cfg_rd         : out    std_logic;                    --//����� ������
p_out_cfg_txdata     : out    std_logic_vector(15 downto 0);--//
p_in_cfg_rxdata      : in     std_logic_vector(15 downto 0);--//
p_in_cfg_txrdy       : in     std_logic;                    --//���������� ��������� ������
p_in_cfg_rxrdy       : in     std_logic;                    --//���������� ����������� ������

--p_out_cfg_rx_set_irq : out    std_logic;                    --//
p_out_cfg_done       : out    std_logic;                    --//
p_in_cfg_clk         : in     std_logic;

-------------------------------
--���������������
-------------------------------
p_in_tst             : in     std_logic_vector(31 downto 0);
p_out_tst            : out    std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_rst             : in     std_logic
);
end cfgdev_uart;

architecture behavioral of cfgdev_uart is

component uart_rev01 is
generic(
G_BAUDCNT_VAL: integer:=64
);
port
(
-------------------------------
--����� � UART
-------------------------------
p_out_uart_tx    : out    std_logic;                    --//
p_in_uart_rx     : in     std_logic;                    --//

-------------------------------
--USR IF
-------------------------------
p_out_usr_rxd    : out    std_logic_vector(7 downto 0); --//
p_out_usr_rxrdy  : out    std_logic;                    --//
p_in_usr_rd      : in     std_logic;                    --//

p_in_usr_txd     : in     std_logic_vector(7 downto 0); --//
p_out_usr_txrdy  : out    std_logic;                    --//
p_in_usr_wr      : in     std_logic;                    --//

-------------------------------
--���������������
-------------------------------
p_in_tst         : in    std_logic_vector(31 downto 0);
p_out_tst        : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk         : in    std_logic;
p_in_rst         : in    std_logic
);
end component;

type fsm_state is
(
S_DEV_WAIT_RXRDY,
S_DEV_RXD,
S_DEV_WAIT_TXRDY,
S_DEV_TXD,
S_PKTH_RXCHK,
S_PKTH_TXCHK,
S_CFG_WAIT_TXRDY,
S_CFG_TXD,
S_CFG_WAIT_RXRDY,
S_CFG_RXD1,
S_CFG_RXD2
);
signal fsm_state_cs                     : fsm_state;

--signal i_dv_rdy                         : std_logic;
signal i_dv_din                         : std_logic_vector(7 downto 0);
signal i_dv_dout                        : std_logic_vector(i_dv_din'range);
--signal i_dv_oe                          : std_logic;
signal i_dv_rd                          : std_logic;
signal i_dv_wr                          : std_logic;
signal i_dv_txrdy                       : std_logic;
signal i_dv_rxrdy                       : std_logic;

--signal i_dv_tmr_en                      : std_logic;
--signal i_dv_tmr                         : std_logic_vector(6 downto 0);

signal i_cfg_dbyte_init                 : std_logic_vector(1 downto 0);
signal i_cfg_dbyte                      : std_logic_vector(i_cfg_dbyte_init'range);
signal i_cfg_rgadr_ld                   : std_logic;
signal i_cfg_d                          : std_logic_vector(p_out_cfg_txdata'range);
signal i_cfg_wr                         : std_logic;
signal i_cfg_rd                         : std_logic;
signal i_cfg_done                       : std_logic;

signal i_pkt_dvadr                      : std_logic_vector(C_CFGPKT_NUMDEV_MSB_BIT-C_CFGPKT_NUMDEV_LSB_BIT downto 0);
signal i_pkt_rgadr                      : std_logic_vector(C_CFGPKT_NUMREG_MSB_BIT-C_CFGPKT_NUMREG_LSB_BIT downto 0);
signal i_pkt_rgfifo                     : std_logic;
type TDevCfg_PktHeader is array (0 to C_CFGPKT_HEADER_DW_COUNT-1) of std_logic_vector(i_cfg_d'range);
signal i_pkt_dheader                    : TDevCfg_PktHeader;

signal i_cntd_pkt                       : std_logic_vector(7 downto 0);
signal i_flag_pktdata                   : std_logic;

signal i_uart_din                       : std_logic_vector(7 downto 0);
signal i_uart_rxrdy                     : std_logic;
signal i_uart_rd                        : std_logic;
signal i_uart_dout                      : std_logic_vector(7 downto 0);
signal i_uart_txrdy                     : std_logic;
signal i_uart_wr                        : std_logic;

signal i_rxbuf_dout                     : std_logic_vector(31 downto 0);
signal i_rxbuf_din                      : std_logic_vector(31 downto 0);
signal i_rxbuf_empty                    : std_logic;
signal i_rxbuf_full                     : std_logic;
signal i_txbuf_din                      : std_logic_vector(31 downto 0);
signal i_txbuf_dout                     : std_logic_vector(31 downto 0);
signal i_txbuf_rd                       : std_logic;
signal i_txbuf_empty                    : std_logic;
signal i_txbuf_full                     : std_logic;


signal tst_fsm_cs                       : std_logic_vector(3 downto 0);
signal tst_fsm_cs_dly                   : std_logic_vector(tst_fsm_cs'range);
signal tst_uart_rev01_out               : std_logic_vector(31 downto 0);



--MAIN
begin

--//----------------------------------
--//��������������� �������
--//----------------------------------
p_out_tst(31 downto 0)<=(others=>'0');
--process(p_in_rst,p_in_cfg_clk)
--begin
--  if p_in_rst='1' then
--    p_out_tst(0)<='0';
--    tst_fsm_cs_dly<=(others=>'0');
--
--  elsif p_in_cfg_clk'event and p_in_cfg_clk='1' then
--
--    tst_fsm_cs_dly<=tst_fsm_cs;
--    p_out_tst(0)<=OR_reduce(tst_fsm_cs_dly) or tst_uart_rev01_out(0);
--
--  end if;
--end process;
--p_out_tst(31 downto 1)<=(others=>'0');
--
--tst_fsm_cs<=CONV_STD_LOGIC_VECTOR(16#01#, tst_fsm_cs'length) when fsm_state_cs=S_DEV_WAIT_RXRDY else
--            CONV_STD_LOGIC_VECTOR(16#02#, tst_fsm_cs'length) when fsm_state_cs=S_DEV_RXD        else
--            CONV_STD_LOGIC_VECTOR(16#03#, tst_fsm_cs'length) when fsm_state_cs=S_DEV_WAIT_TXRDY else
--            CONV_STD_LOGIC_VECTOR(16#04#, tst_fsm_cs'length) when fsm_state_cs=S_DEV_TXD        else
--            CONV_STD_LOGIC_VECTOR(16#05#, tst_fsm_cs'length) when fsm_state_cs=S_PKTH_RXCHK     else
--            CONV_STD_LOGIC_VECTOR(16#06#, tst_fsm_cs'length) when fsm_state_cs=S_PKTH_TXCHK     else
--            CONV_STD_LOGIC_VECTOR(16#07#, tst_fsm_cs'length) when fsm_state_cs=S_CFG_WAIT_TXRDY else
--            CONV_STD_LOGIC_VECTOR(16#08#, tst_fsm_cs'length) when fsm_state_cs=S_CFG_TXD        else
--            CONV_STD_LOGIC_VECTOR(16#09#, tst_fsm_cs'length) when fsm_state_cs=S_CFG_WAIT_RXRDY else
--            CONV_STD_LOGIC_VECTOR(16#0A#, tst_fsm_cs'length) when fsm_state_cs=S_CFG_RXD1       else
--            CONV_STD_LOGIC_VECTOR(16#00#, tst_fsm_cs'length);
----            CONV_STD_LOGIC_VECTOR(16#00#, tst_fsm_cs'length) when fsm_state_cs=S_CFG_RXD2       else




--------------------------------------------------
--�������
--------------------------------------------------
p_out_module_rdy<=not p_in_rst;
p_out_module_error<='0';


--------------------------------------------------
--����� � UART
--------------------------------------------------
m_uart: uart_rev01
generic map(
G_BAUDCNT_VAL => G_BAUDCNT_VAL
)
port map
(
-------------------------------
--����� � UART
-------------------------------
p_out_uart_tx    => p_out_uart_tx,
p_in_uart_rx     => p_in_uart_rx,

-------------------------------
--USR IF
-------------------------------
p_out_usr_rxd    => i_uart_dout,
p_out_usr_rxrdy  => i_uart_rxrdy,
p_in_usr_rd      => i_uart_rd,

p_in_usr_txd     => i_uart_din,
p_out_usr_txrdy  => i_uart_txrdy,
p_in_usr_wr      => i_uart_wr,

-------------------------------
--���������������
-------------------------------
p_in_tst         => "00000000000000000000000000000000",
p_out_tst        => tst_uart_rev01_out,

-------------------------------
--System
-------------------------------
p_in_clk         => p_in_uart_refclk,
p_in_rst         => p_in_rst
);


--------------------------------------------------
--�������� ������(p_in_uart_refclk/p_in_cfg_clk), ����� ����������� ������
--------------------------------------------------
--//UART->FPGA
i_rxbuf_din<=EXT(i_uart_dout, i_rxbuf_din'length);
i_uart_rd<=i_uart_rxrdy and not i_rxbuf_full;

i_dv_din<=i_rxbuf_dout(i_dv_din'range);
i_dv_rxrdy<=not i_rxbuf_empty;--//���������� RxBUF

m_rxbuf : cfgdev_rxfifo
port map
(
din         => i_rxbuf_din,
wr_en       => i_uart_rd,
wr_clk      => p_in_uart_refclk,

dout        => i_rxbuf_dout,
rd_en       => i_dv_rd,
rd_clk      => p_in_cfg_clk,

empty       => i_rxbuf_empty,
full        => i_rxbuf_full,

--clk         : IN  std_logic;
rst         => p_in_rst
);

--//UART<-FPGA
i_txbuf_din<=EXT(i_dv_dout, i_txbuf_din'length);

i_uart_din<=i_txbuf_dout(i_uart_din'range);
--i_uart_wr<=i_txbuf_rd;--//��� FWFT FIFO
process(p_in_uart_refclk)
begin
  if p_in_uart_refclk'event and p_in_uart_refclk='1' then
    i_uart_wr<=i_txbuf_rd;--//��� Standart FIFO
  end if;
end process;

i_txbuf_rd<=i_uart_txrdy and not i_txbuf_empty;

i_dv_txrdy<=not i_txbuf_full;--//���������� TxBUF

m_txbuf : cfgdev_txfifo
port map
(
din         => i_txbuf_din,
wr_en       => i_dv_wr,
wr_clk      => p_in_cfg_clk,

dout        => i_txbuf_dout,
rd_en       => i_txbuf_rd,
rd_clk      => p_in_uart_refclk,

empty       => i_txbuf_empty,
full        => i_txbuf_full,

--clk         : IN  std_logic;
rst         => p_in_rst
);



--------------------------------------------------
--����� � �������� FPGA
--------------------------------------------------
--p_out_cfg_rx_set_irq<='0';

p_out_dev_adr     <=i_pkt_dvadr;
p_out_cfg_adr     <=i_pkt_rgadr;
p_out_cfg_adr_ld  <=i_cfg_rgadr_ld;
p_out_cfg_adr_fifo<=i_pkt_rgfifo;
p_out_cfg_rd      <=i_cfg_rd;
p_out_cfg_wd      <=i_cfg_wr;
p_out_cfg_txdata  <=i_cfg_d;

p_out_cfg_done    <=i_cfg_done;


----------------------------------------------------
----//Timer
----------------------------------------------------
--process(p_in_rst,p_in_cfg_clk)
--begin
--  if p_in_rst='1' then
--    i_dv_tmr<=(others=>'0');
--
--  elsif p_in_cfg_clk'event and p_in_cfg_clk='1' then
--
--    if i_dv_tmr_en='0' then
--      i_dv_tmr<=(others=>'0');
--    else
--      i_dv_tmr<=i_dv_tmr + 1;
--    end if;
--
--  end if;
--end process;


--------------------------------------------------
--//������� ����������
--------------------------------------------------
i_cfg_dbyte_init<=(others=>'0');

process(p_in_rst,p_in_cfg_clk)
  variable pkt_write : std_logic;
  variable pkt_dlen  : std_logic_vector(i_cntd_pkt'range);
begin

if p_in_rst='1' then

  fsm_state_cs <= S_DEV_WAIT_RXRDY;

--  i_dv_oe<='0';
  i_dv_rd<='0';
  i_dv_wr<='0';
  i_dv_dout<=(others=>'0');

--  i_dv_tmr_en<='0';

  i_cfg_dbyte<=i_cfg_dbyte_init;
  i_cfg_rgadr_ld<='0';
  i_cfg_d<=(others=>'0');
  i_cfg_wr<='0';
  i_cfg_rd<='0';
  i_cfg_done<='0';

    pkt_write:='0';
    pkt_dlen :=(others=>'0');
  i_pkt_dvadr <=(others=>'0');
  i_pkt_rgfifo<='0';
  i_pkt_rgadr <=(others=>'0');

  for i in 0 to C_CFGPKT_HEADER_DW_COUNT-1 loop
  i_pkt_dheader(i)<=(others=>'0');
  end loop;

  i_cntd_pkt<=(others=>'0');
  i_flag_pktdata<='0';

elsif p_in_cfg_clk'event and p_in_cfg_clk='1' then
--  if p_in_clken='1' then

  case fsm_state_cs is

    --//################################
    --//����� ������
    --//################################
    --//--------------------------------
    --//���� ����� � ���-�� �������� ������
    --//--------------------------------
    when S_DEV_WAIT_RXRDY =>

      i_cfg_rgadr_ld<='0';
      i_cfg_done<='0';

      if i_dv_rxrdy='1' then
        i_dv_rd<='1';
--        i_dv_tmr_en<='1';

        for i in 0 to i_cfg_d'length/8-1 loop
          if i_cfg_dbyte=i then
            i_cfg_d(8*(i+1)-1 downto 8*i)<=i_dv_din(7 downto 0);
          end if;
        end loop;

        fsm_state_cs <= S_DEV_RXD;
      end if;

    --//--------------------------------
    --//����� ������ �� ���-��
    --//--------------------------------
    when S_DEV_RXD =>

--      if i_dv_tmr=CONV_STD_LOGIC_VECTOR(16, i_dv_tmr'length) then
--        i_dv_rd<='1';
--        i_dv_tmr_en<='0';
--
--        if i_cfg_dbyte=CONV_STD_LOGIC_VECTOR(i_cfg_d'length/8-1, i_cfg_dbyte'length) then
--          i_cfg_dbyte<=(others=>'0');
--
--          if i_flag_pktdata='1' then
--              --//��������� � ������ ������ � ������ FPGA
--              fsm_state_cs <= S_CFG_WAIT_TXRDY;
--
--          else
--            --//�������� ������ USR_PKT/HEADER
--            for i in 0 to C_CFGPKT_HEADER_DW_COUNT-1 loop
--              if i_cntd_pkt(2 downto 0)=i then
--                i_pkt_dheader(i)<=i_cfg_d;
--              end if;
--            end loop;
--            fsm_state_cs <= S_PKTH_RXCHK;
--
--          end if;
--
--        else
--          i_cfg_dbyte<=i_cfg_dbyte + 1;
--          fsm_state_cs <= S_DEV_WAIT_RXRDY;
--        end if;
--
--      elsif i_dv_tmr=CONV_STD_LOGIC_VECTOR(10, i_dv_tmr'length) then
--        i_dv_rd<='1';
--
--      elsif i_dv_tmr=CONV_STD_LOGIC_VECTOR(8, i_dv_tmr'length) then
--        for i in 0 to i_cfg_d'length/8-1 loop
--          if i_cfg_dbyte=i then
--            i_cfg_d(8*(i+1)-1 downto 8*i)<=i_dv_din(7 downto 0);
--          end if;
--        end loop;
--
--      end if;

      i_dv_rd<='0';

      if i_cfg_dbyte=CONV_STD_LOGIC_VECTOR(i_cfg_d'length/8-1, i_cfg_dbyte'length) then
        i_cfg_dbyte<=(others=>'0');

        if i_flag_pktdata='1' then
            --//��������� � ������ ������ � ������ FPGA
            fsm_state_cs <= S_CFG_WAIT_TXRDY;

        else
          --//�������� ������ USR_PKT/HEADER
          for i in 0 to C_CFGPKT_HEADER_DW_COUNT-1 loop
            if i_cntd_pkt(2 downto 0)=i then
              i_pkt_dheader(i)<=i_cfg_d;
            end if;
          end loop;
          fsm_state_cs <= S_PKTH_RXCHK;

        end if;

      else
        i_cfg_dbyte<=i_cfg_dbyte + 1;
        fsm_state_cs <= S_DEV_WAIT_RXRDY;
      end if;

--      for i in 0 to i_cfg_d'length/8-1 loop
--        if i_cfg_dbyte=i then
--          i_cfg_d(8*(i+1)-1 downto 8*i)<=i_dv_din(7 downto 0);
--        end if;
--      end loop;



    --//--------------------------------
    --//�������� ���������� ������ USR_PKT/HEADER
    --//--------------------------------
    when S_PKTH_RXCHK =>

      if i_cntd_pkt(1 downto 0)=CONV_STD_LOGIC_VECTOR(C_CFGPKT_HEADER_DW_COUNT-1, 2) then

          i_cfg_rgadr_ld<='1';

          i_pkt_dvadr <=i_pkt_dheader(0)(C_CFGPKT_NUMDEV_MSB_BIT downto C_CFGPKT_NUMDEV_LSB_BIT);
            pkt_write :=i_pkt_dheader(0)(C_CFGPKT_WR_BIT);
          i_pkt_rgfifo<=i_pkt_dheader(0)(C_CFGPKT_FIFO_BIT);
          i_pkt_rgadr <=i_pkt_dheader(1)(C_CFGPKT_NUMREG_MSB_BIT downto C_CFGPKT_NUMREG_LSB_BIT);
            pkt_dlen  :=i_pkt_dheader(1)(15 downto 8)-1;

          if pkt_write=C_CFGPKT_ACT_WD then
            i_cntd_pkt<=pkt_dlen;
            i_flag_pktdata<='1';
            fsm_state_cs <= S_DEV_WAIT_RXRDY;
          else
            i_cntd_pkt<=(others=>'0');
            fsm_state_cs <= S_PKTH_TXCHK;
          end if;

      else
        i_cntd_pkt<=i_cntd_pkt + 1;
        fsm_state_cs <= S_DEV_WAIT_RXRDY;
      end if;


    --//--------------------------------
    --//������ ������ � FPGA ������
    --//--------------------------------
    when S_CFG_WAIT_TXRDY =>

      if p_in_cfg_txrdy='1' then
        i_cfg_wr<='1';
        fsm_state_cs <= S_CFG_TXD;
      end if;

    when S_CFG_TXD =>

      i_cfg_wr<='0';

      if i_cntd_pkt=(i_cntd_pkt'range => '0') then
        i_flag_pktdata<='0';
        i_cfg_done<='1';
      else
        i_cntd_pkt<=i_cntd_pkt - 1;
      end if;

      fsm_state_cs <= S_DEV_WAIT_RXRDY;




    --//################################
    --//�������� ������
    --//################################
    --//--------------------------------
    --//�������� ���������� ��������� USR_PKT/HEADER
    --//--------------------------------
    when S_PKTH_TXCHK =>

      i_cfg_rgadr_ld<='0';

      if i_cntd_pkt(2 downto 0)=CONV_STD_LOGIC_VECTOR(C_CFGPKT_HEADER_DW_COUNT, 3) then
      --//��������� ���������, ��������� � ������ ������ �� ������ FPGA
        i_cntd_pkt<=pkt_dlen;
        i_flag_pktdata<='1';
        fsm_state_cs <= S_CFG_WAIT_RXRDY;
      else
        i_cntd_pkt<=i_cntd_pkt + 1;
        fsm_state_cs <= S_DEV_WAIT_TXRDY;
      end if;

      for i in 0 to C_CFGPKT_HEADER_DW_COUNT-1 loop
        if i_cntd_pkt(1 downto 0)=i then
          i_cfg_d<=i_pkt_dheader(i);
        end if;
      end loop;


    --//--------------------------------
    --//���� ����� ���-�� ����� �������� ��� ������
    --//--------------------------------
    when S_DEV_WAIT_TXRDY =>

      if i_dv_txrdy='1' then
        i_dv_wr<='1';
--        i_dv_tmr_en<='1';
----        i_dv_oe<='1';

        for i in 0 to i_cfg_d'length/8-1 loop
          if i_cfg_dbyte=i then
            i_dv_dout<=i_cfg_d(8*(i+1)-1 downto 8*i);
          end if;
        end loop;

        fsm_state_cs <= S_DEV_TXD;
      end if;

    --//--------------------------------
    --//�������� ������ � ���-��
    --//--------------------------------
    when S_DEV_TXD =>

--      if i_dv_tmr=CONV_STD_LOGIC_VECTOR(16, i_dv_tmr'length) then
--        i_dv_wr<='1';
--        i_dv_tmr_en<='0';
--        i_dv_oe<='0';
--
--        if i_cfg_dbyte=CONV_STD_LOGIC_VECTOR(i_cfg_d'length/8-1, i_cfg_dbyte'length) then
--          i_cfg_dbyte<=(others=>'0');
--
--          if i_flag_pktdata='1' then
--
--            if i_cntd_pkt=(i_cntd_pkt'range => '0') then
--              i_cfg_done<='1';
--              i_flag_pktdata<='0';
--              fsm_state_cs <= S_DEV_WAIT_RXRDY;
--
--            else
--              i_cntd_pkt<=i_cntd_pkt - 1;
--              fsm_state_cs <= S_CFG_WAIT_RXRDY;
--            end if;
--
--          else
--            fsm_state_cs <= S_PKTH_TXCHK;
--          end if;
--
--        else
--          i_cfg_dbyte<=i_cfg_dbyte + 1;
--          fsm_state_cs <= S_DEV_WAIT_TXRDY;
--        end if;
--
--      elsif i_dv_tmr=CONV_STD_LOGIC_VECTOR(10, i_dv_tmr'length) then
--        i_dv_wr<='0';
--
--      elsif i_dv_tmr=CONV_STD_LOGIC_VECTOR(8, i_dv_tmr'length) then
--        for i in 0 to i_cfg_d'length/8-1 loop
--          if i_cfg_dbyte=i then
--            i_dv_dout<=i_cfg_d(8*(i+1)-1 downto 8*i);
--          end if;
--        end loop;
--        i_dv_oe<='1';
--
--      end if;

        i_dv_wr<='0';

        if i_cfg_dbyte=CONV_STD_LOGIC_VECTOR(i_cfg_d'length/8-1, i_cfg_dbyte'length) then
          i_cfg_dbyte<=(others=>'0');

          if i_flag_pktdata='1' then

            if i_cntd_pkt=(i_cntd_pkt'range => '0') then
              i_cfg_done<='1';
              i_flag_pktdata<='0';
              fsm_state_cs <= S_DEV_WAIT_RXRDY;

            else
              i_cntd_pkt<=i_cntd_pkt - 1;
              fsm_state_cs <= S_CFG_WAIT_RXRDY;
            end if;

          else
            fsm_state_cs <= S_PKTH_TXCHK;
          end if;

        else
          i_cfg_dbyte<=i_cfg_dbyte + 1;
          fsm_state_cs <= S_DEV_WAIT_TXRDY;
        end if;

--      for i in 0 to i_cfg_d'length/8-1 loop
--        if i_cfg_dbyte=i then
--          i_dv_dout<=i_cfg_d(8*(i+1)-1 downto 8*i);
--        end if;
--      end loop;

    --//--------------------------------
    --//������ ������ �� FPGA ������
    --//--------------------------------
    when S_CFG_WAIT_RXRDY =>

      if p_in_cfg_rxrdy='1' then
        i_cfg_rd<='1';
        fsm_state_cs <= S_CFG_RXD1;
      end if;

    when S_CFG_RXD1 =>

      i_cfg_rd<='0';
      fsm_state_cs <= S_CFG_RXD2;

    when S_CFG_RXD2 =>

      i_cfg_d<=p_in_cfg_rxdata;
      fsm_state_cs <= S_DEV_WAIT_TXRDY;


  end case;
--  end if;--//if p_in_clken='1' then
end if;
end process;



--END MAIN
end behavioral;
