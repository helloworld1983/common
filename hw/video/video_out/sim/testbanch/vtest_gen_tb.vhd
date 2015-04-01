
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.reduce_pack.all;

entity vtest_gen_tb is
generic(
G_DBG : string := "OFF";
G_VD_WIDTH : integer := 64;
G_VSYN_ACTIVE : std_logic := '1'
);
port(
p_out_vden    : out  std_logic;
p_out_vd      : out  std_logic_vector(G_VD_WIDTH - 1 downto 0);
p_out_vs      : out  std_logic;
p_out_hs      : out  std_logic;

p_out_tst     : out  std_logic_vector(31 downto 0)
);
end entity vtest_gen_tb;

architecture behavior of vtest_gen_tb is

--  ���������� ������� ����������� �� �����:
constant period_sys_clk       : time := 56.388 ns;--17,733990147783251231527093596059 mhz

component vtest_gen is
generic(
G_DBG : string := "off";
G_VD_WIDTH : integer := 80;
G_VSYN_ACTIVE : std_logic := '1'
);
port(
--cfg
p_in_cfg      : in   std_logic_vector(15 downto 0);
p_in_vpix     : in   std_logic_vector(15 downto 0);--���-�� pix
p_in_vrow     : in   std_logic_vector(15 downto 0);--���-�� �����
p_in_syn_h    : in   std_logic_vector(15 downto 0);--������ hs (���-�� ������)
p_in_syn_v    : in   std_logic_vector(15 downto 0);--������ vs (���-�� ������)

--test video
p_out_vd      : out  std_logic_vector(G_VD_WIDTH - 1 downto 0);
p_out_vs      : out  std_logic;
p_out_hs      : out  std_logic;

--���������������
p_in_tst      : in   std_logic_vector(31 downto 0);
p_out_tst     : out  std_logic_vector(31 downto 0);

--system
p_in_clk_en   : in   std_logic;
p_in_clk      : in   std_logic;
p_in_rst      : in   std_logic
);
end component vtest_gen;

for uut : vtest_gen use entity work.vtest_gen(test_gen_2);

signal i_rst :  std_logic;
signal i_clk :  std_logic;

signal tst_vfr_pixcount  : unsigned(15 downto 0);
signal tst_vfr_rowcount  : unsigned(15 downto 0);
signal tst_vfr_cfg       : unsigned(15 downto 0);
signal tst_vfr_hs_width  : unsigned(15 downto 0);
signal tst_vfr_vs_width  : unsigned(15 downto 0);

signal i_video_den       : std_logic;
signal i_video_d         : std_logic_vector(G_VD_WIDTH - 1 downto 0);
signal i_video_vs        : std_logic;
signal i_video_hs        : std_logic;
signal i_video_pixen     : std_logic;

signal sr_video_vs       : std_logic_vector(0 to 7);
signal sr_video_hs       : std_logic_vector(0 to 7);
signal i_trs             : std_logic;
signal i_sav             : std_logic;
signal i_eav             : std_logic;
Type TSRbus2 is array (0 to 3) of unsigned(15 downto 0);
signal i_sdi_txd         : TSRbus2;

Type TSRbus is array (0 to 3) of unsigned(G_VD_WIDTH - 1 downto 0);
signal sr_video_d        : TSRbus;
signal i_linecnt_clr     : std_logic;
signal i_linecnt_inc     : std_logic;
signal i_linecnt         : unsigned(10 downto 0);


begin --architecture behavior

i_rst <='1', '0'after 500 ns;

board_clk : process
begin
  i_clk<='0';
  wait for period_sys_clk/2;
  i_clk<='1';
  wait for period_sys_clk/2;
end process;


uut : vtest_gen
generic map(
G_DBG => G_DBG,
G_VD_WIDTH => G_VD_WIDTH,
G_VSYN_ACTIVE => G_VSYN_ACTIVE
)
port map(
--CFG
p_in_cfg      => std_logic_vector(tst_vfr_cfg),
p_in_vpix     => std_logic_vector(tst_vfr_pixcount),
p_in_vrow     => std_logic_vector(tst_vfr_rowcount),
p_in_syn_h    => std_logic_vector(tst_vfr_hs_width),
p_in_syn_v    => std_logic_vector(tst_vfr_vs_width),

--Test Video
p_out_vd      => i_video_d,
p_out_vs      => i_video_vs,
p_out_hs      => i_video_hs,

--���������������
p_in_tst      => (others => '0'),
p_out_tst     => open,

--System
p_in_clk_en   => '1',
p_in_clk      => i_clk,
p_in_rst      => i_rst
);


tst_vfr_pixcount <= TO_UNSIGNED(64, tst_vfr_pixcount'length);
tst_vfr_rowcount <= TO_UNSIGNED(32, tst_vfr_rowcount'length);

--3..0 --0/1/2/3/4 - 30fps/60fps/120fps/240fps/480fps/
--7..4 --0/1/2/    - Test picture: V+H Counter/ V Counter/ H Counter/
tst_vfr_cfg <= TO_UNSIGNED(16#10#, tst_vfr_cfg'length);

--tst_vfr_hs_width <= TO_UNSIGNED(384, tst_vfr_hs_width'length);-- for 30fps (dwith 256)
tst_vfr_hs_width <= TO_UNSIGNED(18, tst_vfr_hs_width'length);-- for 30fps (dwith 256)
tst_vfr_vs_width <= TO_UNSIGNED(4, tst_vfr_hs_width'length);-- for 30fps (dwith 256)

p_out_vden <= i_video_den;
p_out_vd   <= i_video_d;
p_out_vs   <= i_video_vs;
p_out_hs   <= i_video_hs;

i_video_den <= i_video_hs;

process(i_rst, i_clk)
begin
if rising_edge(i_clk) then
  if i_rst = '1' then
    sr_video_vs <= (others => '0');
    sr_video_hs <= (others => '0');
    for i in 0 to sr_video_d'length - 1 loop
    sr_video_d(i) <= (others => '0');
    end loop;

    i_linecnt_clr <= '0';
    i_linecnt_inc <= '0';
    i_linecnt <= (others => '0');

  else
    sr_video_vs <= i_video_vs & sr_video_vs(0 to 6);
    sr_video_hs <= i_video_hs & sr_video_hs(0 to 6);
    sr_video_d <= UNSIGNED(i_video_d) & sr_video_d(0 to 2);

    i_linecnt_clr <= not sr_video_vs(3) and sr_video_vs(4);
    i_linecnt_inc <= sr_video_hs(3) and not sr_video_hs(4);

    if i_linecnt_clr = '1' then
      i_linecnt <= TO_UNSIGNED(1, i_linecnt'length);
    elsif i_linecnt_inc = '1' then
      i_linecnt <= i_linecnt + 1;
    end if;

  end if;
end if;
end process;

gen_sdi_d : for i in 0 to i_sdi_txd'length - 1 generate
begin
i_sdi_txd(i) <= TO_UNSIGNED(16#3FF#, i_sdi_txd(i)'length) when (UNSIGNED(sr_video_hs) = TO_UNSIGNED(16#F0#, sr_video_hs'length)) or
                                                              ((UNSIGNED(sr_video_hs) = TO_UNSIGNED(16#FF#, sr_video_hs'length)) and i_video_hs = '0') else

             TO_UNSIGNED(16#000#, i_sdi_txd(i)'length) when (UNSIGNED(sr_video_hs) = TO_UNSIGNED(16#F8#, sr_video_hs'length)) or
                                                            (UNSIGNED(sr_video_hs) = TO_UNSIGNED(16#FC#, sr_video_hs'length)) or
                                                            (UNSIGNED(sr_video_hs) = TO_UNSIGNED(16#7F#, sr_video_hs'length)) or
                                                            (UNSIGNED(sr_video_hs) = TO_UNSIGNED(16#3F#, sr_video_hs'length)) else
             --HSYNC (EAV)
             TO_UNSIGNED(16#274#, i_sdi_txd(i)'length) when UNSIGNED(sr_video_hs) = TO_UNSIGNED(16#FE#, sr_video_hs'length) and i_video_vs = '0' else

             --HSYNC (SAV)
             TO_UNSIGNED(16#200#, i_sdi_txd(i)'length) when UNSIGNED(sr_video_hs) = TO_UNSIGNED(16#1F#, sr_video_hs'length) and i_video_vs = '0' else

             --VSYNC (EAV)
             TO_UNSIGNED(16#2D8#, i_sdi_txd(i)'length) when UNSIGNED(sr_video_hs) = TO_UNSIGNED(16#FE#, sr_video_hs'length) and i_video_vs = '1' else

             --VSYNC (SAV)
             TO_UNSIGNED(16#2AC#, i_sdi_txd(i)'length) when UNSIGNED(sr_video_hs) = TO_UNSIGNED(16#1F#, sr_video_hs'length) and i_video_vs = '1' else

             --DATA into SYNC strobe
             TO_UNSIGNED(16#200#, i_sdi_txd(i)'length) when (sr_video_hs(3) = '1' or sr_video_vs(3) = '1') else

             --Valid Data
             sr_video_d(3)((i_sdi_txd(i)'length * (i + 1) - 1) downto (i_sdi_txd(i)'length * i));

end generate gen_sdi_d;



i_eav <= sr_video_hs(3) and not sr_video_hs(7);
i_sav <= sr_video_hs(3) and not i_video_hs;

p_out_tst(0) <= i_sav or i_eav or i_linecnt_clr or i_linecnt_inc or OR_reduce(i_linecnt)
 or OR_reduce(std_logic_vector(i_sdi_txd(0)))
  or OR_reduce(std_logic_vector(i_sdi_txd(1)))
   or OR_reduce(std_logic_vector(i_sdi_txd(2)))
    or OR_reduce(std_logic_vector(i_sdi_txd(3)));


end architecture behavior;
