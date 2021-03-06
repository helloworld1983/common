-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 05.02.2011 14:15:28
-- Module Name : sata_player_tx
--
-- ����������/�������� :
--   ������ ������ ��� ����������� RocketIO:
--     - �������� SATA ���������� �� ������� � ������ p_in_txreq ��� p_in_d10_2_send_dis
--     - �������� ���������������� ���������� � ����� p_in_txd
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
use work.sata_glob_pkg.all;
use work.sata_pkg.all;
use work.sata_sim_lite_pkg.all;
use work.sata_unit_pkg.all;

entity sata_player_tx is
generic(
G_SATAH_NUM : integer:=0;--������ ������ sata_host
G_GT_CH_NUM : integer:=0;--������ ������ gt
G_GT_DBUS : integer:=16;
G_DBG     : string :="OFF";
G_SIM     : string :="OFF"
);
port(
--------------------------------------------------
--
--------------------------------------------------
--p_in_rxalign        : in    std_logic;
p_in_linkup         : in    std_logic;
p_in_dev_detect     : in    std_logic;
p_in_d10_2_send_dis : in    std_logic;                    --//���������� �������� ���� D10.2
p_in_sync           : in    std_logic;                    --//
p_in_txreq          : in    std_logic_vector(7 downto 0); --//������ �� �������� SATA
p_in_txd            : in    std_logic_vector(31 downto 0);--//������ ��� ����������� (�������� ��������, � �� ��������� SATA)
p_out_rdy_n         : out   std_logic;                    --//����� � �������� ������ ��� ��������

--------------------------------------------------
--RocketIO Transmiter (���������� ������ ��. sata_player_gt.vhd)
--------------------------------------------------
p_out_gt_txdata     : out   std_logic_vector(31 downto 0);
p_out_gt_txcharisk  : out   std_logic_vector(3 downto 0);

p_out_gt_txreset    : out   std_logic;
p_in_gt_txbufstatus : in    std_logic_vector(1 downto 0);

--------------------------------------------------
--��������������� �������
--------------------------------------------------
p_in_tst            : in    std_logic_vector(31 downto 0);
p_out_tst           : out   std_logic_vector(31 downto 0);
p_out_dbg           : out   TPLtx_dbgport;

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk            : in    std_logic;
p_in_rst            : in    std_logic
);
end sata_player_tx;

architecture behavioral of sata_player_tx is

constant CI_ALIGN_TMR   : integer:=selval(C_ALIGN_TMR, C_SIM_SATAHOST_TMR_ALIGN, strcmp(G_SIM,"OFF"));--//� DW

type TScramblerInitVal is array (0 to 7) of integer;
constant CI_SCRAMBLER_INIT_ARRAY : TScramblerInitVal:=(
16#A015#,
16#E244#,
16#8090#,
16#31AA#,
16#C98B#,
16#1234#,
16#0670#,
16#BD46#
);
constant CI_SCRAMBLER_INIT : integer:=CI_SCRAMBLER_INIT_ARRAY(2*G_SATAH_NUM + G_GT_CH_NUM);--16#F0F6#;--

signal i_tmr_rst                  : std_logic_vector(1 downto 0);
signal i_tmr_rst_en               : std_logic;

signal i_gt_txreset              : std_logic;

signal i_align_tmr                : std_logic_vector(10 downto 0);--
signal i_align_txen               : std_logic;
signal i_align_burst_cnt          : std_logic_vector(log2(C_ALIGN_BURST)-1 downto 0);

signal i_suspend                  : std_logic_vector(C_THOLD downto C_TSOF);

signal i_srambler_init            : std_logic;
signal i_srambler_out             : std_logic_vector(31 downto 0);

signal sr_txdata                  : std_logic_vector(31 downto 0);
signal sr_txdtype                 : std_logic_vector(3 downto 0);

type TDly1SrD is array (0 to 3) of std_logic_vector(7 downto 0);
signal sr_ddly                    : TDly1SrD:=("00000000","00000000","00000000","00000000");
type TDly1SrT is array (0 to 3) of std_logic;
signal sr_tdly                    : TDly1SrT:=(others=>'0');

type TDly2SrD is array (0 to 3) of std_logic_vector(15 downto 0);
signal sr_ddly2                   : TDly2SrD:=("0000000000000000","0000000000000000","0000000000000000","0000000000000000");
type TDly2SrT is array (0 to 3) of std_logic_vector(1 downto 0);
signal sr_tdly2                   : TDly2SrT:=("00","00","00","00");


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



--//-------------------------------------
--//�������� ������������ ������ ����������� GT
--//-------------------------------------
tmr_rst:process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_tmr_rst<=(others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then
    if i_tmr_rst_en='1' then
      i_tmr_rst<=i_tmr_rst+1;
    else
      i_tmr_rst<=(others=>'0');
    end if;
  end if;
end process;

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_tmr_rst_en<='0';
    i_gt_txreset<='0';

  elsif p_in_clk'event and p_in_clk='1' then
    if p_in_dev_detect='0' then
      i_tmr_rst_en<='0';
      i_gt_txreset<='0';
    else
      if i_tmr_rst_en='0' then
        i_gt_txreset<='0';
        if p_in_gt_txbufstatus(1)='1' then
        --//gtp_txbufstatus(1)-'1'-����� ��� ���������� ��� ���������
        --�������� �����
          i_tmr_rst_en<='1';
        end if;
      else
        i_gt_txreset<='1';
        if i_tmr_rst=CONV_STD_LOGIC_VECTOR(16#02#, i_tmr_rst'length) then
          i_tmr_rst_en<='0';
        end if;
      end if;
    end if;--//if p_in_dev_detect='0' then
  end if;
end process;

p_out_gt_txreset<=i_gt_txreset;


--//-------------------------------------
--//TMR/BURST ALIGN
--//-------------------------------------
lalign:process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_align_tmr<=(others=>'0');
    i_align_burst_cnt<=(others=>'0');
    i_align_txen<='0';
  elsif p_in_clk'event and p_in_clk='1' then
    if p_in_sync='1' then
        --//TMR
        if p_in_linkup='0' or i_align_tmr=CONV_STD_LOGIC_VECTOR(CI_ALIGN_TMR-1, i_align_tmr'length) then -- or p_in_rxalign='1' then
          i_align_tmr<=(others=>'0');
        else
          i_align_tmr<=i_align_tmr+1;
        end if;

        --//ALIGN send enable
        if i_align_tmr=CONV_STD_LOGIC_VECTOR(CI_ALIGN_TMR-1, i_align_tmr'length) then --or p_in_rxalign='1' then
          i_align_txen<='1';
        elsif i_align_txen='1' and i_align_burst_cnt=CONV_STD_LOGIC_VECTOR(C_ALIGN_BURST-1, i_align_burst_cnt'length) then
          i_align_txen<='0';
        end if;

        --//BURST
        if p_in_linkup='0' or (i_align_txen='1' and i_align_burst_cnt=CONV_STD_LOGIC_VECTOR(C_ALIGN_BURST-1, i_align_burst_cnt'length)) then
          i_align_burst_cnt<=(others=>'0');
        else
          if i_align_txen='1' then
            i_align_burst_cnt<=i_align_burst_cnt+1;
          end if;
        end if;

    end if;--//if p_in_sync='1' then
  end if;
end process lalign;

p_out_rdy_n<=i_align_txen;

--//-------------------------------------
--//��������� ��������� �����.
--//������������ ����� �������� ��������� CONT
--//-------------------------------------
i_srambler_init<=not p_in_d10_2_send_dis;

m_scrambler : sata_scrambler
generic map(
G_INIT_VAL   => CI_SCRAMBLER_INIT
)
port map(
p_in_SOF     => i_srambler_init,
p_in_en      => p_in_sync,
p_out_result => i_srambler_out,

--------------------------------------------------
--System
--------------------------------------------------
--p_in_clk_en  => '1',
p_in_clk     => p_in_clk,
p_in_rst     => p_in_rst
);

--//���� ����� ���������� ��������� �������� ���������
lsuspend:process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_suspend<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then
    if p_in_sync='1' then
    --//
        if i_align_txen='1' then
            if i_align_burst_cnt=(i_align_burst_cnt'range =>'0') then

                  --//������ �� �������� ��������� ������ � �������� ������ ��������� ALIGN (BURST ALIGN)
                  --//� ���� ������ ������ �� ������ ��������� ����������� �� ����� ������ (BURST ALIGN)
                  --//�.�. ����� ��������� �������� ���������
                  if    CONV_INTEGER(p_in_txreq)=C_THOLD  then i_suspend(C_THOLD)<='1';
                  elsif CONV_INTEGER(p_in_txreq)=C_THOLDA then i_suspend(C_THOLDA)<='1';
                  elsif CONV_INTEGER(p_in_txreq)=C_TSOF   then i_suspend(C_TSOF)<='1';
--                  elsif CONV_INTEGER(p_in_txreq)=C_TEOF   then i_suspend(C_TEOF)<='1';

                  end if;

            end if;

        else
          i_suspend<=(others=>'0');

        end if;

    end if;
  end if;
end process lsuspend;

--//�������� ������/����������
ltxd:process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    sr_txdata<=C_D10_2&C_D10_2&C_D10_2&C_D10_2;
    sr_txdtype<=C_PDAT_TDATA;

  elsif p_in_clk'event and p_in_clk='1' then
    if p_in_sync='1' then
    --//�������� ������ ��� ��������:
      if p_in_d10_2_send_dis='0' then
      --//�������� D10.2
          sr_txdata<=C_D10_2&C_D10_2&C_D10_2&C_D10_2; sr_txdtype<=C_PDAT_TDATA;

      elsif i_align_txen='1' then
      --//�������� ALIGN
          sr_txdata<=C_PDAT_ALIGN; sr_txdtype<=C_PDAT_TPRM;

      elsif i_suspend/=(i_suspend'range =>'0') then
      --//�������� ��������� ��������
          if i_suspend(C_THOLD)='1' then
            sr_txdata<=C_PDAT_HOLD; sr_txdtype<=C_PDAT_TPRM;

          elsif i_suspend(C_THOLDA)='1' then
            sr_txdata<=C_PDAT_HOLDA; sr_txdtype<=C_PDAT_TPRM;

          elsif i_suspend(C_TSOF)='1' then
            sr_txdata<=C_PDAT_SOF; sr_txdtype<=C_PDAT_TPRM;

--          else --if i_suspend(C_TEOF)='1' then
--            sr_txdata<=C_PDAT_EOF; sr_txdtype<=C_PDAT_TPRM;

          end if;

      else
      --//�������� �� ������� �� Link Layer
          case CONV_INTEGER(p_in_txreq) is
            when C_TALIGN   => sr_txdata<=C_PDAT_ALIGN;   sr_txdtype<=C_PDAT_TPRM;
            when C_TSOF     => sr_txdata<=C_PDAT_SOF;     sr_txdtype<=C_PDAT_TPRM;
            when C_TEOF     => sr_txdata<=C_PDAT_EOF;     sr_txdtype<=C_PDAT_TPRM;
            when C_TDMAT    => sr_txdata<=C_PDAT_DMAT;    sr_txdtype<=C_PDAT_TPRM;
            when C_TCONT    => sr_txdata<=C_PDAT_CONT;    sr_txdtype<=C_PDAT_TPRM;
            when C_TSYNC    => sr_txdata<=C_PDAT_SYNC;    sr_txdtype<=C_PDAT_TPRM;
            when C_THOLD    => sr_txdata<=C_PDAT_HOLD;    sr_txdtype<=C_PDAT_TPRM;
            when C_THOLDA   => sr_txdata<=C_PDAT_HOLDA;   sr_txdtype<=C_PDAT_TPRM;
            when C_TX_RDY   => sr_txdata<=C_PDAT_X_RDY;   sr_txdtype<=C_PDAT_TPRM;
            when C_TR_RDY   => sr_txdata<=C_PDAT_R_RDY;   sr_txdtype<=C_PDAT_TPRM;
            when C_TR_IP    => sr_txdata<=C_PDAT_R_IP;    sr_txdtype<=C_PDAT_TPRM;
            when C_TR_OK    => sr_txdata<=C_PDAT_R_OK;    sr_txdtype<=C_PDAT_TPRM;
            when C_TR_ERR   => sr_txdata<=C_PDAT_R_ERR;   sr_txdtype<=C_PDAT_TPRM;
            when C_TWTRM    => sr_txdata<=C_PDAT_WTRM;    sr_txdtype<=C_PDAT_TPRM;
--            when C_TPMREQ_P => sr_txdata<=C_PDAT_PMREQ_P; sr_txdtype<=C_PDAT_TPRM;
--            when C_TPMREQ_S => sr_txdata<=C_PDAT_PMREQ_S; sr_txdtype<=C_PDAT_TPRM;
--            when C_TPMACK   => sr_txdata<=C_PDAT_PMACK;   sr_txdtype<=C_PDAT_TPRM;
--            when C_TPMNAK   => sr_txdata<=C_PDAT_PMNAK;   sr_txdtype<=C_PDAT_TPRM;

            when C_TDATA_EN => sr_txdata<=p_in_txd; sr_txdtype<=C_PDAT_TDATA;--�������� ������ FRAME

            when others => sr_txdata<=i_srambler_out; sr_txdtype<=C_PDAT_TDATA;--//�������� ��������� - � ������ ���� ���� �� ������
                                                                               --//�� ���� ������������ �������� �������� ������
          end case;
      end if;
    else
      if G_GT_DBUS/=32 then
        sr_txdata<=sr_txdata(G_GT_DBUS-1 downto 0) & sr_txdata(31 downto G_GT_DBUS);
        sr_txdtype<=sr_txdtype(G_GT_DBUS/8-1 downto 0) & sr_txdtype(3 downto G_GT_DBUS/8);
      end if;
    end if;
  end if;
end process ltxd;


--//------------------------------
--//GT: ���� �����=8bit
--//------------------------------
gen_dbus8 : if G_GT_DBUS=8 generate

p_out_gt_txdata(7 downto 0)<=sr_txdata(7 downto 0);
p_out_gt_txcharisk(0)<=sr_txdtype(0);

p_out_gt_txdata(15 downto 8)<=(others=>'0');
p_out_gt_txcharisk(1)<='0';

p_out_gt_txdata(31 downto 16)<=(others=>'0');
p_out_gt_txcharisk(3 downto 2)<=(others=>'0');

end generate gen_dbus8;


--//------------------------------
--//GT: ���� �����=16bit
--//------------------------------
gen_dbus16 : if G_GT_DBUS=16 generate

p_out_gt_txdata(15 downto 0)<=sr_txdata(15 downto 0);
p_out_gt_txcharisk(1 downto 0)<=sr_txdtype(1 downto 0);

p_out_gt_txdata(31 downto 16)<=(others=>'0');
p_out_gt_txcharisk(3 downto 2)<=(others=>'0');

end generate gen_dbus16;


--//------------------------------
--//GT: ���� �����=32bit
--//------------------------------
gen_dbus32 : if G_GT_DBUS=32 generate

p_out_gt_txdata(31 downto 0)<=sr_txdata(31 downto 0);
p_out_gt_txcharisk(3 downto 0)<=sr_txdtype(3 downto 0);

end generate gen_dbus32;




--//-----------------------------------
--//Debug/Sim
--//-----------------------------------
gen_sim_off : if strcmp(G_SIM,"OFF") generate
p_out_dbg.req_name<=(others=>'0');
end generate gen_sim_off;

--//������ ��� ������������� (�������� ������� ������ ��� ������������)
gen_sim_on : if strcmp(G_SIM,"ON") generate
p_out_dbg.req_name<=C_PNAME_STR(CONV_INTEGER(p_in_txreq));
end generate gen_sim_on;

p_out_dbg.stat.suspend_phold<=i_suspend(C_THOLD);
p_out_dbg.stat.suspend_pholda<=i_suspend(C_THOLDA);
p_out_dbg.stat.suspend_psof<=i_suspend(C_TSOF);
p_out_dbg.stat.suspend_peof<=i_suspend(C_TEOF);
p_out_dbg.txalign<=i_align_txen;
p_out_dbg.txd<=sr_txdata;



--END MAIN
end behavioral;

