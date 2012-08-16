-------------------------------------------------------------------------------
-- Title      : Virtex-5 Ethernet MAC Wrapper Top Level
-- Project    : Virtex-5 Embedded Tri-Mode Ethernet MAC Wrapper
-- File       : emac_core_block.vhd
-- Version    : 1.8
-------------------------------------------------------------------------------
--
-- (c) Copyright 2004-2010 Xilinx, Inc. All rights reserved.
--
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
--
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
--
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
--
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
--
-------------------------------------------------------------------------------
-- Description:  This is the EMAC block level VHDL design for the Virtex-5
--               Embedded Ethernet MAC Example Design.  It is intended that
--               this example design can be quickly adapted and downloaded onto
--               an FPGA to provide a real hardware test environment.
--
--               The block level:
--
--               * instantiates all clock management logic required (BUFGs,
--                 DCMs) to operate the EMAC and its example design;
--
--               * instantiates appropriate PHY interface modules (GMII, MII,
--                 RGMII, SGMII or 1000BASE-X) as required based on the user
--                 configuration.
--
--
--               Please refer to the Datasheet, Getting Started Guide, and
--               the Virtex-5 Embedded Tri-Mode Ethernet MAC User Gude for
--               further information.
-------------------------------------------------------------------------------


library unisim;
use unisim.vcomponents.all;

library ieee;
use ieee.std_logic_1164.all;



-------------------------------------------------------------------------------
-- The entity declaration for the top level design.
-------------------------------------------------------------------------------
entity emac_core_block is
   port(
      p_in_drp_ctrl                   : in  std_logic_vector(31 downto 0);
      p_out_gtp_plllkdet              : out std_logic;
      p_out_ust_tst                   : out std_logic_vector(31 downto 0);

      -- EMAC0 Clocking
      -- 125MHz clock output from transceiver
      CLK125_OUT                      : out std_logic;
      -- 125MHz clock input from BUFG
      CLK125                          : in  std_logic;
      -- 250MHz clock input from DCM
      CLK250                          : in  std_logic;
      CLK250_DCM_LOCKED               : in  std_logic;

      -- Client Receiver Interface - EMAC0
      EMAC0CLIENTRXD                  : out std_logic_vector(15 downto 0);
      EMAC0CLIENTRXDVLD               : out std_logic;
      EMAC0CLIENTRXDVLDMSW            : out std_logic;
      EMAC0CLIENTRXGOODFRAME          : out std_logic;
      EMAC0CLIENTRXBADFRAME           : out std_logic;
      EMAC0CLIENTRXFRAMEDROP          : out std_logic;
      EMAC0CLIENTRXSTATS              : out std_logic_vector(6 downto 0);
      EMAC0CLIENTRXSTATSVLD           : out std_logic;
      EMAC0CLIENTRXSTATSBYTEVLD       : out std_logic;

      -- Client Transmitter Interface - EMAC0
      CLIENTEMAC0TXD                  : in  std_logic_vector(15 downto 0);
      CLIENTEMAC0TXDVLD               : in  std_logic;
      CLIENTEMAC0TXDVLDMSW            : in  std_logic;
      EMAC0CLIENTTXACK                : out std_logic;
      CLIENTEMAC0TXFIRSTBYTE          : in  std_logic;
      CLIENTEMAC0TXUNDERRUN           : in  std_logic;
      EMAC0CLIENTTXCOLLISION          : out std_logic;
      EMAC0CLIENTTXRETRANSMIT         : out std_logic;
      CLIENTEMAC0TXIFGDELAY           : in  std_logic_vector(7 downto 0);
      EMAC0CLIENTTXSTATS              : out std_logic;
      EMAC0CLIENTTXSTATSVLD           : out std_logic;
      EMAC0CLIENTTXSTATSBYTEVLD       : out std_logic;

      -- MAC Control Interface - EMAC0
      CLIENTEMAC0PAUSEREQ             : in  std_logic;
      CLIENTEMAC0PAUSEVAL             : in  std_logic_vector(15 downto 0);

      --EMAC-MGT link status
      EMAC0CLIENTSYNCACQSTATUS        : out std_logic;
      -- EMAC0 Interrupt
      EMAC0ANINTERRUPT                : out std_logic;


      -- Clock Signals - EMAC0
      -- 1000BASE-X PCS/PMA Interface - EMAC0
      TXP_0                           : out std_logic;
      TXN_0                           : out std_logic;
      RXP_0                           : in  std_logic;
      RXN_0                           : in  std_logic;
      PHYAD_0                         : in  std_logic_vector(4 downto 0);
      RESETDONE_0                     : out std_logic;

      -- EMAC1 Clocking

      -- Client Receiver Interface - EMAC1
      EMAC1CLIENTRXD                  : out std_logic_vector(15 downto 0);
      EMAC1CLIENTRXDVLD               : out std_logic;
      EMAC1CLIENTRXDVLDMSW            : out std_logic;
      EMAC1CLIENTRXGOODFRAME          : out std_logic;
      EMAC1CLIENTRXBADFRAME           : out std_logic;
      EMAC1CLIENTRXFRAMEDROP          : out std_logic;
      EMAC1CLIENTRXSTATS              : out std_logic_vector(6 downto 0);
      EMAC1CLIENTRXSTATSVLD           : out std_logic;
      EMAC1CLIENTRXSTATSBYTEVLD       : out std_logic;

      -- Client Transmitter Interface - EMAC1
      CLIENTEMAC1TXD                  : in  std_logic_vector(15 downto 0);
      CLIENTEMAC1TXDVLD               : in  std_logic;
      CLIENTEMAC1TXDVLDMSW            : in  std_logic;
      EMAC1CLIENTTXACK                : out std_logic;
      CLIENTEMAC1TXFIRSTBYTE          : in  std_logic;
      CLIENTEMAC1TXUNDERRUN           : in  std_logic;
      EMAC1CLIENTTXCOLLISION          : out std_logic;
      EMAC1CLIENTTXRETRANSMIT         : out std_logic;
      CLIENTEMAC1TXIFGDELAY           : in  std_logic_vector(7 downto 0);
      EMAC1CLIENTTXSTATS              : out std_logic;
      EMAC1CLIENTTXSTATSVLD           : out std_logic;
      EMAC1CLIENTTXSTATSBYTEVLD       : out std_logic;

      -- MAC Control Interface - EMAC1
      CLIENTEMAC1PAUSEREQ             : in  std_logic;
      CLIENTEMAC1PAUSEVAL             : in  std_logic_vector(15 downto 0);

      --EMAC-MGT link status
      EMAC1CLIENTSYNCACQSTATUS        : out std_logic;
      -- EMAC1 Interrupt
      EMAC1ANINTERRUPT                : out std_logic;


      -- Clock Signals - EMAC1
      -- 1000BASE-X PCS/PMA Interface - EMAC1
      TXP_1                           : out std_logic;
      TXN_1                           : out std_logic;
      RXP_1                           : in  std_logic;
      RXN_1                           : in  std_logic;
      PHYAD_1                         : in  std_logic_vector(4 downto 0);
      RESETDONE_1                     : out std_logic;

      -- 1000BASE-X PCS/PMA RocketIO Reference Clock buffer inputs
      CLK_DS                          : in  std_logic;

      -- RocketIO Reset input
      GTRESET                         : in  std_logic;



      -- Asynchronous Reset
      RESET                           : in  std_logic
   );
end emac_core_block;


architecture TOP_LEVEL of emac_core_block is

-------------------------------------------------------------------------------
-- Component Declarations for lower hierarchial level entities
-------------------------------------------------------------------------------
  -- Component Declaration for the main EMAC wrapper
  component emac_core is
    port(
      -- Client Receiver Interface - EMAC0
      EMAC0CLIENTRXCLIENTCLKOUT       : out std_logic;
      CLIENTEMAC0RXCLIENTCLKIN        : in  std_logic;
      CLIENTEMAC0RXCLIENTCLKINDIV2    : in  std_logic;
      EMAC0CLIENTRXD                  : out std_logic_vector(15 downto 0);
      EMAC0CLIENTRXDVLD               : out std_logic;
      EMAC0CLIENTRXDVLDMSW            : out std_logic;
      EMAC0CLIENTRXGOODFRAME          : out std_logic;
      EMAC0CLIENTRXBADFRAME           : out std_logic;
      EMAC0CLIENTRXFRAMEDROP          : out std_logic;
      EMAC0CLIENTRXSTATS              : out std_logic_vector(6 downto 0);
      EMAC0CLIENTRXSTATSVLD           : out std_logic;
      EMAC0CLIENTRXSTATSBYTEVLD       : out std_logic;

      -- Client Transmitter Interface - EMAC0
      EMAC0CLIENTTXCLIENTCLKOUT       : out std_logic;
      CLIENTEMAC0TXCLIENTCLKIN        : in  std_logic;
      CLIENTEMAC0TXCLIENTCLKINDIV2    : in  std_logic;
      CLIENTEMAC0TXD                  : in  std_logic_vector(15 downto 0);
      CLIENTEMAC0TXDVLD               : in  std_logic;
      CLIENTEMAC0TXDVLDMSW            : in  std_logic;
      EMAC0CLIENTTXACK                : out std_logic;
      CLIENTEMAC0TXFIRSTBYTE          : in  std_logic;
      CLIENTEMAC0TXUNDERRUN           : in  std_logic;
      EMAC0CLIENTTXCOLLISION          : out std_logic;
      EMAC0CLIENTTXRETRANSMIT         : out std_logic;
      CLIENTEMAC0TXIFGDELAY           : in  std_logic_vector(7 downto 0);
      EMAC0CLIENTTXSTATS              : out std_logic;
      EMAC0CLIENTTXSTATSVLD           : out std_logic;
      EMAC0CLIENTTXSTATSBYTEVLD       : out std_logic;

      -- MAC Control Interface - EMAC0
      CLIENTEMAC0PAUSEREQ             : in  std_logic;
      CLIENTEMAC0PAUSEVAL             : in  std_logic_vector(15 downto 0);

      -- Clock Signals - EMAC0
      GTX_CLK_0                       : in  std_logic;
      PHYEMAC0TXGMIIMIICLKIN          : in  std_logic;
      EMAC0PHYTXGMIIMIICLKOUT         : out std_logic;

      -- 1000BASE-X PCS/PMA Interface - EMAC0
      RXDATA_0                        : in  std_logic_vector(7 downto 0);
      TXDATA_0                        : out std_logic_vector(7 downto 0);
      DCM_LOCKED_0                    : in  std_logic;
      AN_INTERRUPT_0                  : out std_logic;
      SIGNAL_DETECT_0                 : in  std_logic;
      PHYAD_0                         : in  std_logic_vector(4 downto 0);
      ENCOMMAALIGN_0                  : out std_logic;
      LOOPBACKMSB_0                   : out std_logic;
      MGTRXRESET_0                    : out std_logic;
      MGTTXRESET_0                    : out std_logic;
      POWERDOWN_0                     : out std_logic;
      SYNCACQSTATUS_0                 : out std_logic;
      RXCLKCORCNT_0                   : in  std_logic_vector(2 downto 0);
      RXBUFSTATUS_0                   : in  std_logic_vector(1 downto 0);
      RXCHARISCOMMA_0                 : in  std_logic;
      RXCHARISK_0                     : in  std_logic;
      RXDISPERR_0                     : in  std_logic;
      RXNOTINTABLE_0                  : in  std_logic;
      RXREALIGN_0                     : in  std_logic;
      RXRUNDISP_0                     : in  std_logic;
      TXBUFERR_0                      : in  std_logic;
      TXCHARDISPMODE_0                : out std_logic;
      TXCHARDISPVAL_0                 : out std_logic;
      TXCHARISK_0                     : out std_logic;
      TXRUNDISP_0                     : in std_logic;

      -- Client Receiver Interface - EMAC1
      EMAC1CLIENTRXCLIENTCLKOUT       : out std_logic;
      CLIENTEMAC1RXCLIENTCLKIN        : in  std_logic;
      CLIENTEMAC1RXCLIENTCLKINDIV2    : in  std_logic;
      EMAC1CLIENTRXD                  : out std_logic_vector(15 downto 0);
      EMAC1CLIENTRXDVLD               : out std_logic;
      EMAC1CLIENTRXDVLDMSW            : out std_logic;
      EMAC1CLIENTRXGOODFRAME          : out std_logic;
      EMAC1CLIENTRXBADFRAME           : out std_logic;
      EMAC1CLIENTRXFRAMEDROP          : out std_logic;
      EMAC1CLIENTRXSTATS              : out std_logic_vector(6 downto 0);
      EMAC1CLIENTRXSTATSVLD           : out std_logic;
      EMAC1CLIENTRXSTATSBYTEVLD       : out std_logic;

      -- Client Transmitter Interface - EMAC1
      EMAC1CLIENTTXCLIENTCLKOUT       : out std_logic;
      CLIENTEMAC1TXCLIENTCLKIN        : in  std_logic;
      CLIENTEMAC1TXCLIENTCLKINDIV2    : in  std_logic;
      CLIENTEMAC1TXD                  : in  std_logic_vector(15 downto 0);
      CLIENTEMAC1TXDVLD               : in  std_logic;
      CLIENTEMAC1TXDVLDMSW            : in  std_logic;
      EMAC1CLIENTTXACK                : out std_logic;
      CLIENTEMAC1TXFIRSTBYTE          : in  std_logic;
      CLIENTEMAC1TXUNDERRUN           : in  std_logic;
      EMAC1CLIENTTXCOLLISION          : out std_logic;
      EMAC1CLIENTTXRETRANSMIT         : out std_logic;
      CLIENTEMAC1TXIFGDELAY           : in  std_logic_vector(7 downto 0);
      EMAC1CLIENTTXSTATS              : out std_logic;
      EMAC1CLIENTTXSTATSVLD           : out std_logic;
      EMAC1CLIENTTXSTATSBYTEVLD       : out std_logic;

      -- MAC Control Interface - EMAC1
      CLIENTEMAC1PAUSEREQ             : in  std_logic;
      CLIENTEMAC1PAUSEVAL             : in  std_logic_vector(15 downto 0);

      -- Clock Signals - EMAC1
      GTX_CLK_1                       : in  std_logic;
      PHYEMAC1TXGMIIMIICLKIN          : in  std_logic;
      EMAC1PHYTXGMIIMIICLKOUT         : out std_logic;

      -- 1000BASE-X PCS/PMA Interface - EMAC1
      RXDATA_1                        : in  std_logic_vector(7 downto 0);
      TXDATA_1                        : out std_logic_vector(7 downto 0);
      DCM_LOCKED_1                    : in  std_logic;
      AN_INTERRUPT_1                  : out std_logic;
      SIGNAL_DETECT_1                 : in  std_logic;
      PHYAD_1                         : in  std_logic_vector(4 downto 0);
      ENCOMMAALIGN_1                  : out std_logic;
      LOOPBACKMSB_1                   : out std_logic;
      MGTRXRESET_1                    : out std_logic;
      MGTTXRESET_1                    : out std_logic;
      POWERDOWN_1                     : out std_logic;
      SYNCACQSTATUS_1                 : out std_logic;
      RXCLKCORCNT_1                   : in  std_logic_vector(2 downto 0);
      RXBUFSTATUS_1                   : in  std_logic_vector(1 downto 0);
      RXCHARISCOMMA_1                 : in  std_logic;
      RXCHARISK_1                     : in  std_logic;
      RXDISPERR_1                     : in  std_logic;
      RXNOTINTABLE_1                  : in  std_logic;
      RXREALIGN_1                     : in  std_logic;
      RXRUNDISP_1                     : in  std_logic;
      TXBUFERR_1                      : in  std_logic;
      TXCHARDISPMODE_1                : out std_logic;
      TXCHARDISPVAL_1                 : out std_logic;
      TXCHARISK_1                     : out std_logic;
      TXRUNDISP_1                     : in std_logic;



      -- Asynchronous Reset
      RESET                           : in  std_logic
    );
  end component;



  -- Component Declaration for the RocketIO wrapper
    component GTP_dual_1000X
   port (
          RESETDONE_0           : out   std_logic;
          ENMCOMMAALIGN_0       : in    std_logic;
          ENPCOMMAALIGN_0       : in    std_logic;
          LOOPBACK_0            : in    std_logic;
          POWERDOWN_0           : in    std_logic;
          RXUSRCLK_0            : in    std_logic;
          RXUSRCLK2_0           : in    std_logic;
          RXRESET_0             : in    std_logic;
          TXCHARDISPMODE_0      : in    std_logic;
          TXCHARDISPVAL_0       : in    std_logic;
          TXCHARISK_0           : in    std_logic;
          TXDATA_0              : in    std_logic_vector (7 downto 0);
          TXUSRCLK_0            : in    std_logic;
          TXUSRCLK2_0           : in    std_logic;
          TXRESET_0             : in    std_logic;
          RXCHARISCOMMA_0       : out   std_logic;
          RXCHARISK_0           : out   std_logic;
          RXCLKCORCNT_0         : out   std_logic_vector (2 downto 0);
          RXDATA_0              : out   std_logic_vector (7 downto 0);
          RXDISPERR_0           : out   std_logic;
          RXNOTINTABLE_0        : out   std_logic;
          RXRUNDISP_0           : out   std_logic;
          RXBUFERR_0            : out   std_logic;
          TXBUFERR_0            : out   std_logic;
          PLLLKDET_0            : out   std_logic;
          TXOUTCLK_0            : out   std_logic;
          RXELECIDLE_0    	: out   std_logic;
          TX1N_0                : out   std_logic;
          TX1P_0                : out   std_logic;
          RX1N_0                : in    std_logic;
          RX1P_0                : in    std_logic;

          RESETDONE_1           : out   std_logic;
          ENMCOMMAALIGN_1       : in    std_logic;
          ENPCOMMAALIGN_1       : in    std_logic;
          LOOPBACK_1            : in    std_logic;
          POWERDOWN_1           : in    std_logic;
          RXUSRCLK_1            : in    std_logic;
          RXUSRCLK2_1           : in    std_logic;
          RXRESET_1             : in    std_logic;
          TXCHARDISPMODE_1      : in    std_logic;
          TXCHARDISPVAL_1       : in    std_logic;
          TXCHARISK_1           : in    std_logic;
          TXDATA_1              : in    std_logic_vector (7 downto 0);
          TXUSRCLK_1            : in    std_logic;
          TXUSRCLK2_1           : in    std_logic;
          TXRESET_1             : in    std_logic;
          RXCHARISCOMMA_1       : out   std_logic;
          RXCHARISK_1           : out   std_logic;
          RXCLKCORCNT_1         : out   std_logic_vector (2 downto 0);
          RXDATA_1              : out   std_logic_vector (7 downto 0);
          RXDISPERR_1           : out   std_logic;
          RXNOTINTABLE_1        : out   std_logic;
          RXRUNDISP_1           : out   std_logic;
          RXBUFERR_1            : out   std_logic;
          TXBUFERR_1            : out   std_logic;
          PLLLKDET_1            : out   std_logic;
          TXOUTCLK_1            : out   std_logic;
          RXELECIDLE_1    	: out   std_logic;
          TX1N_1                : out   std_logic;
          TX1P_1                : out   std_logic;
          RX1N_1                : in    std_logic;
          RX1P_1                : in    std_logic;


          CLK_DS                : in    std_logic;
          GTRESET               : in    std_logic;
          REFCLKOUT             : out   std_logic;
          PMARESET              : in    std_logic;
          DCM_LOCKED            : in    std_logic
          );
  end component;




-------------------------------------------------------------------------------
-- Signal Declarations
-------------------------------------------------------------------------------

    --  Power and ground signals
    signal gnd_i                          : std_logic;
    signal vcc_i                          : std_logic;

    -- Asynchronous reset signals
    signal reset_ibuf_i                   : std_logic;
    signal reset_i                        : std_logic;
    signal reset_r                        : std_logic_vector(3 downto 0);

    -- EMAC0 Client Clocking Signals
    signal rx_client_clk_out_0_i          : std_logic;
    signal rx_client_clk_in_0_i           : std_logic;
    signal tx_client_clk_out_0_i          : std_logic;
    signal tx_client_clk_in_0_i           : std_logic;
    signal rx_client_clk_in_div2_0_i      : std_logic;
    signal tx_client_clk_in_div2_0_i      : std_logic;
    -- EMAC0 Physical Interface Signals
    signal emac_locked_0_i                : std_logic;
    signal mgt_rx_data_0_i                : std_logic_vector(7 downto 0);
    signal mgt_tx_data_0_i                : std_logic_vector(7 downto 0);
    signal signal_detect_0_i              : std_logic;
    signal elecidle_0_i                   : std_logic;
    signal encommaalign_0_i               : std_logic;
    signal loopback_0_i                   : std_logic;
    signal mgt_rx_reset_0_i               : std_logic;
    signal mgt_tx_reset_0_i               : std_logic;
    signal powerdown_0_i                  : std_logic;
    signal rxclkcorcnt_0_i                : std_logic_vector(2 downto 0);
    signal rxbuferr_0_i                   : std_logic;
    signal rxchariscomma_0_i              : std_logic;
    signal rxcharisk_0_i                  : std_logic;
    signal rxdisperr_0_i                  : std_logic;
    signal rxlossofsync_0_i               : std_logic_vector(1 downto 0);
    signal rxnotintable_0_i               : std_logic;
    signal rxrundisp_0_i                  : std_logic;
    signal txbuferr_0_i                   : std_logic;
    signal txchardispmode_0_i             : std_logic;
    signal txchardispval_0_i              : std_logic;
    signal txcharisk_0_i                  : std_logic;
    signal gtx_clk_ibufg_0_i              : std_logic;
    signal resetdone_0_i                  : std_logic;
    signal rxbufstatus_0_i                : std_logic_vector(1 downto 0);
    signal rxchariscomma_0_r              : std_logic;
    signal rxcharisk_0_r                  : std_logic;
    signal rxclkcorcnt_0_r                : std_logic_vector(2 downto 0);
    signal mgt_rx_data_0_r                : std_logic_vector(7 downto 0);
    signal rxdisperr_0_r                  : std_logic;
    signal rxnotintable_0_r               : std_logic;
    signal rxrundisp_0_r                  : std_logic;
    signal rxbuferr_0_r                   : std_logic;
    signal txchardispmode_0_r             : std_logic;
    signal txchardispval_0_r              : std_logic;
    signal txcharisk_0_r                  : std_logic;
    signal mgt_tx_data_0_r                : std_logic_vector(7 downto 0);
    signal txbuferr_0_r                   : std_logic;

    -- EMAC1 Client Clocking Signals
    signal rx_client_clk_out_1_i          : std_logic;
    signal rx_client_clk_in_1_i           : std_logic;
    signal tx_client_clk_out_1_i          : std_logic;
    signal tx_client_clk_in_1_i           : std_logic;
    signal rx_client_clk_in_div2_1_i      : std_logic;
    signal tx_client_clk_in_div2_1_i      : std_logic;
    -- EMAC1 Physical Interface Signals
    signal emac_locked_1_i                : std_logic;
    signal mgt_rx_data_1_i                : std_logic_vector(7 downto 0);
    signal mgt_tx_data_1_i                : std_logic_vector(7 downto 0);
    signal signal_detect_1_i              : std_logic;
    signal elecidle_1_i                   : std_logic;
    signal encommaalign_1_i               : std_logic;
    signal loopback_1_i                   : std_logic;
    signal mgt_rx_reset_1_i               : std_logic;
    signal mgt_tx_reset_1_i               : std_logic;
    signal powerdown_1_i                  : std_logic;
    signal rxclkcorcnt_1_i                : std_logic_vector(2 downto 0);
    signal rxbuferr_1_i                   : std_logic;
    signal rxchariscomma_1_i              : std_logic;
    signal rxcharisk_1_i                  : std_logic;
    signal rxdisperr_1_i                  : std_logic;
    signal rxlossofsync_1_i               : std_logic_vector(1 downto 0);
    signal rxnotintable_1_i               : std_logic;
    signal rxrundisp_1_i                  : std_logic;
    signal txbuferr_1_i                   : std_logic;
    signal txchardispmode_1_i             : std_logic;
    signal txchardispval_1_i              : std_logic;
    signal txcharisk_1_i                  : std_logic;
    signal gtx_clk_ibufg_1_i              : std_logic;
    signal resetdone_1_i                  : std_logic;
    signal rxbufstatus_1_i                : std_logic_vector(1 downto 0);
    signal rxchariscomma_1_r              : std_logic;
    signal rxcharisk_1_r                  : std_logic;
    signal rxclkcorcnt_1_r                : std_logic_vector(2 downto 0);
    signal mgt_rx_data_1_r                : std_logic_vector(7 downto 0);
    signal rxdisperr_1_r                  : std_logic;
    signal rxnotintable_1_r               : std_logic;
    signal rxrundisp_1_r                  : std_logic;
    signal rxbuferr_1_r                   : std_logic;
    signal txchardispmode_1_r             : std_logic;
    signal txchardispval_1_r              : std_logic;
    signal txcharisk_1_r                  : std_logic;
    signal mgt_tx_data_1_r                : std_logic_vector(7 downto 0);
    signal txbuferr_1_r                   : std_logic;

    signal usrclk2                        : std_logic;

    signal refclkout                      : std_logic;
    signal dcm_locked_gtp                 : std_logic;
    signal plllock_0_i                    : std_logic;
    signal plllock_1_i                    : std_logic;



-------------------------------------------------------------------------------
-- Attribute Declarations
-------------------------------------------------------------------------------

  attribute ASYNC_REG : string;
  attribute ASYNC_REG of reset_r : signal is "TRUE";


-------------------------------------------------------------------------------
-- Main Body of Code
-------------------------------------------------------------------------------

begin

    gnd_i     <= '0';
    vcc_i     <= '1';

    ---------------------------------------------------------------------------
    -- Main Reset Circuitry
    ---------------------------------------------------------------------------
    reset_ibuf_i <= RESET;

    -- Asserting the reset of the EMAC for four clock cycles
    process(tx_client_clk_in_div2_0_i, reset_ibuf_i)
    begin
        if (reset_ibuf_i = '1') then
            reset_r <= "1111";
        elsif tx_client_clk_in_div2_0_i'event and tx_client_clk_in_div2_0_i = '1' then
          if (plllock_0_i = '1' and plllock_1_i = '1') then
            reset_r <= reset_r(2 downto 0) & reset_ibuf_i;
          end if;
        end if;
    end process;

    -- The reset pulse is now several clock cycles in duration
    reset_i <= reset_r(3);



    ---------------------------------------------------------------------------
    -- Instantiate RocketIO tile for SGMII or 1000BASE-X PCS/PMA Physical I/F
    ---------------------------------------------------------------------------


    --EMAC0 and EMAC1 instances
    GTP_DUAL_1000X_inst : GTP_dual_1000X

      PORT MAP (
         RESETDONE_0           =>   RESETDONE_0,
         ENMCOMMAALIGN_0       =>   encommaalign_0_i,
         ENPCOMMAALIGN_0       =>   encommaalign_0_i,
         LOOPBACK_0            =>   loopback_0_i,
         POWERDOWN_0           =>   powerdown_0_i,
         RXUSRCLK_0            =>   tx_client_clk_in_0_i,
         RXUSRCLK2_0           =>   tx_client_clk_in_0_i,
         RXRESET_0             =>   mgt_rx_reset_0_i,
         TXCHARDISPMODE_0      =>   txchardispmode_0_r,
         TXCHARDISPVAL_0       =>   txchardispval_0_r,
         TXCHARISK_0           =>   txcharisk_0_r,
         TXDATA_0              =>   mgt_tx_data_0_r,
         TXUSRCLK_0            =>   tx_client_clk_in_0_i,
         TXUSRCLK2_0           =>   tx_client_clk_in_0_i,
         TXRESET_0             =>   mgt_tx_reset_0_i,
         RXCHARISCOMMA_0       =>   rxchariscomma_0_i,
         RXCHARISK_0           =>   rxcharisk_0_i,
         RXCLKCORCNT_0         =>   rxclkcorcnt_0_i,
         RXDATA_0              =>   mgt_rx_data_0_i,
         RXDISPERR_0           =>   rxdisperr_0_i,
         RXNOTINTABLE_0        =>   rxnotintable_0_i,
         RXRUNDISP_0           =>   rxrundisp_0_i,
         RXBUFERR_0            =>   rxbuferr_0_i,
         TXBUFERR_0            =>   txbuferr_0_i,
         PLLLKDET_0            =>   plllock_0_i,
         RXELECIDLE_0          =>   elecidle_0_i,
         RX1P_0                =>   RXP_0,
         RX1N_0                =>   RXN_0,
         TX1N_0                =>   TXN_0,
         TX1P_0                =>   TXP_0,

         RESETDONE_1           =>   RESETDONE_1,
         ENMCOMMAALIGN_1       =>   encommaalign_1_i,
         ENPCOMMAALIGN_1       =>   encommaalign_1_i,
         LOOPBACK_1            =>   loopback_1_i,
         POWERDOWN_1           =>   powerdown_1_i,
         RXUSRCLK_1            =>   tx_client_clk_in_1_i,
         RXUSRCLK2_1           =>   tx_client_clk_in_1_i,
         RXRESET_1             =>   mgt_rx_reset_1_i,
         TXCHARDISPMODE_1      =>   txchardispmode_1_r,
         TXCHARDISPVAL_1       =>   txchardispval_1_r,
         TXCHARISK_1           =>   txcharisk_1_r,
         TXDATA_1              =>   mgt_tx_data_1_r,
         TXUSRCLK_1            =>   tx_client_clk_in_1_i,
         TXUSRCLK2_1           =>   tx_client_clk_in_1_i,
         TXRESET_1             =>   mgt_tx_reset_1_i,
         RXCHARISCOMMA_1       =>   rxchariscomma_1_i,
         RXCHARISK_1           =>   rxcharisk_1_i,
         RXCLKCORCNT_1         =>   rxclkcorcnt_1_i,
         RXDATA_1              =>   mgt_rx_data_1_i,
         RXDISPERR_1           =>   rxdisperr_1_i,
         RXNOTINTABLE_1        =>   rxnotintable_1_i,
         RXRUNDISP_1           =>   rxrundisp_1_i,
         RXBUFERR_1            =>   rxbuferr_1_i,
         TXBUFERR_1            =>   txbuferr_1_i,
         PLLLKDET_1            =>   plllock_1_i,
         TXOUTCLK_1            =>   open,
         RXELECIDLE_1          =>   elecidle_1_i,
         RX1P_1                =>   RXP_1,
         RX1N_1                =>   RXN_1,
         TX1N_1                =>   TXN_1,
         TX1P_1                =>   TXP_1,
         CLK_DS                =>   CLK_DS,
         REFCLKOUT             =>   refclkout,
         GTRESET               =>   GTRESET,
         TXOUTCLK_0            =>   open,
         PMARESET              =>   reset_ibuf_i,
         DCM_LOCKED            =>   dcm_locked_gtp
    );

   --------------------------------------------------------------------------
   -- Register the signals between EMAC0 and the GTP for timing
   -- purposes.
   --------------------------------------------------------------------------
   regrx0 : process (tx_client_clk_in_0_i, reset_i)
   begin
        if reset_i = '1' then
            rxchariscomma_0_r  <= '0';
            rxcharisk_0_r      <= '0';
            rxclkcorcnt_0_r    <= (others => '0');
            mgt_rx_data_0_r    <= (others => '0');
            rxdisperr_0_r      <= '0';
            rxnotintable_0_r   <= '0';
            rxrundisp_0_r      <= '0';
            rxbuferr_0_r       <= '0';
            txchardispmode_0_r <= '0';
            txchardispval_0_r  <= '0';
            txcharisk_0_r      <= '0';
            mgt_tx_data_0_r    <= (others => '0');
            txbuferr_0_r       <= '0';
        elsif tx_client_clk_in_0_i'event and tx_client_clk_in_0_i = '1' then
            rxchariscomma_0_r  <= rxchariscomma_0_i;
            rxcharisk_0_r      <= rxcharisk_0_i;
            rxclkcorcnt_0_r    <= rxclkcorcnt_0_i;
            mgt_rx_data_0_r    <= mgt_rx_data_0_i;
            rxdisperr_0_r      <= rxdisperr_0_i;
            rxnotintable_0_r   <= rxnotintable_0_i;
            rxrundisp_0_r      <= rxrundisp_0_i;
            rxbuferr_0_r       <= rxbuferr_0_i;
            txchardispmode_0_r <= txchardispmode_0_i after 1 ns;
            txchardispval_0_r  <= txchardispval_0_i after 1 ns;
            txcharisk_0_r      <= txcharisk_0_i after 1 ns;
            mgt_tx_data_0_r    <= mgt_tx_data_0_i after 1 ns;
            txbuferr_0_r       <= txbuferr_0_i after 1 ns;
        end if;
   end process regrx0;


   --------------------------------------------------------------------------
   -- Register the signals between EMAC1 and the GTP for timing
   -- purposes.
   --------------------------------------------------------------------------
   regrx1 : process (tx_client_clk_in_1_i, reset_i)
   begin
        if reset_i = '1' then
            rxchariscomma_1_r  <= '0';
            rxcharisk_1_r      <= '0';
            rxclkcorcnt_1_r    <= (others => '0');
            mgt_rx_data_1_r    <= (others => '0');
            rxdisperr_1_r      <= '0';
            rxnotintable_1_r   <= '0';
            rxrundisp_1_r      <= '0';
            rxbuferr_1_r       <= '0';
            txchardispmode_1_r <= '0';
            txchardispval_1_r  <= '0';
            txcharisk_1_r      <= '0';
            mgt_tx_data_1_r    <= (others => '0');
            txbuferr_1_r       <= '0';
        elsif tx_client_clk_in_1_i'event and tx_client_clk_in_1_i = '1' then
            rxchariscomma_1_r  <= rxchariscomma_1_i;
            rxcharisk_1_r      <= rxcharisk_1_i;
            rxclkcorcnt_1_r    <= rxclkcorcnt_1_i;
            mgt_rx_data_1_r    <= mgt_rx_data_1_i;
            rxdisperr_1_r      <= rxdisperr_1_i;
            rxnotintable_1_r   <= rxnotintable_1_i;
            rxrundisp_1_r      <= rxrundisp_1_i;
            rxbuferr_1_r       <= rxbuferr_1_i;
            txchardispmode_1_r <= txchardispmode_1_i after 1 ns;
            txchardispval_1_r  <= txchardispval_1_i after 1 ns;
            txcharisk_1_r      <= txcharisk_1_i after 1 ns;
            mgt_tx_data_1_r    <= mgt_tx_data_1_i after 1 ns;
            txbuferr_1_r       <= txbuferr_1_i after 1 ns;
        end if;
   end process regrx1;


    ---------------------------------------------------------------------------
    -- Generate the buffer status input to the EMAC0 from the buffer error
    -- output of the transceiver
    ---------------------------------------------------------------------------
    rxbufstatus_0_i(1) <= rxbuferr_0_r;

    ---------------------------------------------------------------------------
    -- Detect when there has been a disconnect
    ---------------------------------------------------------------------------
    signal_detect_0_i <= not(elecidle_0_i);


    ---------------------------------------------------------------------------
    -- Generate the buffer status input to the EMAC1 from the buffer error
    -- output of the transceiver
    ---------------------------------------------------------------------------
    rxbufstatus_1_i(1) <= rxbuferr_1_r;

    ---------------------------------------------------------------------------
    -- Detect when there has been a disconnect
    ---------------------------------------------------------------------------
    signal_detect_1_i <= not(elecidle_1_i);





    --------------------------------------------------------------------
    -- Virtex5 Rocket I/O Clock Management
    --------------------------------------------------------------------

    -- The RocketIO transceivers are available in pairs with shared
    -- clock resources
    -- 125MHz clock is used for GTP user clocks and used
    -- to clock all Ethernet core logic.
    usrclk2                   <= CLK125;

    dcm_locked_gtp            <= '1';

    -- EMAC0: PLL locks
    emac_locked_0_i           <= plllock_0_i and CLK250_DCM_LOCKED;

    emac_locked_1_i           <= plllock_1_i and CLK250_DCM_LOCKED;


    ------------------------------------------------------------------------
    -- GTX_CLK Clock Management for EMAC1
    -- (Connected to PHYEMAC0GTXCLK of the EMAC primitive)
    ------------------------------------------------------------------------
    gtx_clk_ibufg_0_i         <= CLK125;


    ------------------------------------------------------------------------
    -- GTX_CLK Clock Management for EMAC1
    -- (Connected to PHYEMAC1GTXCLK of the EMAC primitive)
    ------------------------------------------------------------------------
    gtx_clk_ibufg_1_i         <= CLK125;


    ------------------------------------------------------------------------
    -- Receive and Transmit Client Clock Management when configured in
    -- 16-bit mode
    ------------------------------------------------------------------------
    tx_client_clk_in_div2_0_i <= usrclk2;

    tx_client_clk_in_0_i      <= CLK250;

    tx_client_clk_in_1_i      <= tx_client_clk_in_0_i;
    tx_client_clk_in_div2_1_i <= tx_client_clk_in_div2_0_i;

    rx_client_clk_in_div2_0_i <= tx_client_clk_in_div2_0_i;
    rx_client_clk_in_0_i      <= tx_client_clk_in_0_i;

    rx_client_clk_in_div2_1_i <= rx_client_clk_in_div2_0_i;
    rx_client_clk_in_1_i      <= rx_client_clk_in_0_i;


    ------------------------------------------------------------------------
    -- Connect previously derived client clocks to example design output ports
    ------------------------------------------------------------------------
    -- EMAC0 Clocking
    -- 125MHz clock output from transceiver
    CLK125_OUT                <= refclkout;

    -- EMAC1 Clocking



    --------------------------------------------------------------------------
    -- Instantiate the EMAC Wrapper (emac_core.vhd)
    --------------------------------------------------------------------------
    v5_emac_wrapper_inst : emac_core
    port map (
        -- Client Receiver Interface - EMAC0
        EMAC0CLIENTRXCLIENTCLKOUT       => rx_client_clk_out_0_i,
        CLIENTEMAC0RXCLIENTCLKIN        => rx_client_clk_in_0_i,
        CLIENTEMAC0RXCLIENTCLKINDIV2    => rx_client_clk_in_div2_0_i,
        EMAC0CLIENTRXD                  => EMAC0CLIENTRXD,
        EMAC0CLIENTRXDVLD               => EMAC0CLIENTRXDVLD,
        EMAC0CLIENTRXDVLDMSW            => EMAC0CLIENTRXDVLDMSW,
        EMAC0CLIENTRXGOODFRAME          => EMAC0CLIENTRXGOODFRAME,
        EMAC0CLIENTRXBADFRAME           => EMAC0CLIENTRXBADFRAME,
        EMAC0CLIENTRXFRAMEDROP          => EMAC0CLIENTRXFRAMEDROP,
        EMAC0CLIENTRXSTATS              => EMAC0CLIENTRXSTATS,
        EMAC0CLIENTRXSTATSVLD           => EMAC0CLIENTRXSTATSVLD,
        EMAC0CLIENTRXSTATSBYTEVLD       => EMAC0CLIENTRXSTATSBYTEVLD,

        -- Client Transmitter Interface - EMAC0
        EMAC0CLIENTTXCLIENTCLKOUT       => tx_client_clk_out_0_i,
        CLIENTEMAC0TXCLIENTCLKIN        => tx_client_clk_in_0_i,
        CLIENTEMAC0TXCLIENTCLKINDIV2    => tx_client_clk_in_div2_0_i,
        CLIENTEMAC0TXD                  => CLIENTEMAC0TXD,
        CLIENTEMAC0TXDVLD               => CLIENTEMAC0TXDVLD,
        CLIENTEMAC0TXDVLDMSW            => CLIENTEMAC0TXDVLDMSW,
        EMAC0CLIENTTXACK                => EMAC0CLIENTTXACK,
        CLIENTEMAC0TXFIRSTBYTE          => CLIENTEMAC0TXFIRSTBYTE,
        CLIENTEMAC0TXUNDERRUN           => CLIENTEMAC0TXUNDERRUN,
        EMAC0CLIENTTXCOLLISION          => EMAC0CLIENTTXCOLLISION,
        EMAC0CLIENTTXRETRANSMIT         => EMAC0CLIENTTXRETRANSMIT,
        CLIENTEMAC0TXIFGDELAY           => CLIENTEMAC0TXIFGDELAY,
        EMAC0CLIENTTXSTATS              => EMAC0CLIENTTXSTATS,
        EMAC0CLIENTTXSTATSVLD           => EMAC0CLIENTTXSTATSVLD,
        EMAC0CLIENTTXSTATSBYTEVLD       => EMAC0CLIENTTXSTATSBYTEVLD,

        -- MAC Control Interface - EMAC0
        CLIENTEMAC0PAUSEREQ             => CLIENTEMAC0PAUSEREQ,
        CLIENTEMAC0PAUSEVAL             => CLIENTEMAC0PAUSEVAL,

        -- Clock Signals - EMAC0
        GTX_CLK_0                       => tx_client_clk_in_0_i,
        EMAC0PHYTXGMIIMIICLKOUT         => open,
        PHYEMAC0TXGMIIMIICLKIN          => gnd_i,

        -- 1000BASE-X PCS/PMA Interface - EMAC0
        RXDATA_0                        => mgt_rx_data_0_r,
        TXDATA_0                        => mgt_tx_data_0_i,
        DCM_LOCKED_0                    => emac_locked_0_i,
        AN_INTERRUPT_0                  => EMAC0ANINTERRUPT,
        SIGNAL_DETECT_0                 => signal_detect_0_i,
        PHYAD_0                         => PHYAD_0,
        ENCOMMAALIGN_0                  => encommaalign_0_i,
        LOOPBACKMSB_0                   => loopback_0_i,
        MGTRXRESET_0                    => mgt_rx_reset_0_i,
        MGTTXRESET_0                    => mgt_tx_reset_0_i,
        POWERDOWN_0                     => powerdown_0_i,
        SYNCACQSTATUS_0                 => EMAC0CLIENTSYNCACQSTATUS,
        RXCLKCORCNT_0                   => rxclkcorcnt_0_r,
        RXBUFSTATUS_0                   => rxbufstatus_0_i,
        RXCHARISCOMMA_0                 => rxchariscomma_0_r,
        RXCHARISK_0                     => rxcharisk_0_r,
        RXDISPERR_0                     => rxdisperr_0_r,
        RXNOTINTABLE_0                  => rxnotintable_0_r,
        RXREALIGN_0                     => '0',
        RXRUNDISP_0                     => rxrundisp_0_r,
        TXBUFERR_0                      => txbuferr_0_r,
        TXRUNDISP_0                     => '0',
        TXCHARDISPMODE_0                => txchardispmode_0_i,
        TXCHARDISPVAL_0                 => txchardispval_0_i,
        TXCHARISK_0                     => txcharisk_0_i,

        -- Client Receiver Interface - EMAC1
        EMAC1CLIENTRXCLIENTCLKOUT       => rx_client_clk_out_1_i,
        CLIENTEMAC1RXCLIENTCLKIN        => rx_client_clk_in_1_i,
        CLIENTEMAC1RXCLIENTCLKINDIV2    => rx_client_clk_in_div2_1_i,
        EMAC1CLIENTRXD                  => EMAC1CLIENTRXD,
        EMAC1CLIENTRXDVLD               => EMAC1CLIENTRXDVLD,
        EMAC1CLIENTRXDVLDMSW            => EMAC1CLIENTRXDVLDMSW,
        EMAC1CLIENTRXGOODFRAME          => EMAC1CLIENTRXGOODFRAME,
        EMAC1CLIENTRXBADFRAME           => EMAC1CLIENTRXBADFRAME,
        EMAC1CLIENTRXFRAMEDROP          => EMAC1CLIENTRXFRAMEDROP,
        EMAC1CLIENTRXSTATS              => EMAC1CLIENTRXSTATS,
        EMAC1CLIENTRXSTATSVLD           => EMAC1CLIENTRXSTATSVLD,
        EMAC1CLIENTRXSTATSBYTEVLD       => EMAC1CLIENTRXSTATSBYTEVLD,

        -- Client Transmitter Interface - EMAC1
        EMAC1CLIENTTXCLIENTCLKOUT       => tx_client_clk_out_1_i,
        CLIENTEMAC1TXCLIENTCLKIN        => tx_client_clk_in_1_i,
        CLIENTEMAC1TXCLIENTCLKINDIV2    => tx_client_clk_in_div2_1_i,
        CLIENTEMAC1TXD                  => CLIENTEMAC1TXD,
        CLIENTEMAC1TXDVLD               => CLIENTEMAC1TXDVLD,
        CLIENTEMAC1TXDVLDMSW            => CLIENTEMAC1TXDVLDMSW,
        EMAC1CLIENTTXACK                => EMAC1CLIENTTXACK,
        CLIENTEMAC1TXFIRSTBYTE          => CLIENTEMAC1TXFIRSTBYTE,
        CLIENTEMAC1TXUNDERRUN           => CLIENTEMAC1TXUNDERRUN,
        EMAC1CLIENTTXCOLLISION          => EMAC1CLIENTTXCOLLISION,
        EMAC1CLIENTTXRETRANSMIT         => EMAC1CLIENTTXRETRANSMIT,
        CLIENTEMAC1TXIFGDELAY           => CLIENTEMAC1TXIFGDELAY,
        EMAC1CLIENTTXSTATS              => EMAC1CLIENTTXSTATS,
        EMAC1CLIENTTXSTATSVLD           => EMAC1CLIENTTXSTATSVLD,
        EMAC1CLIENTTXSTATSBYTEVLD       => EMAC1CLIENTTXSTATSBYTEVLD,

        -- MAC Control Interface - EMAC1
        CLIENTEMAC1PAUSEREQ             => CLIENTEMAC1PAUSEREQ,
        CLIENTEMAC1PAUSEVAL             => CLIENTEMAC1PAUSEVAL,

        -- Clock Signals - EMAC1
        GTX_CLK_1                       => tx_client_clk_in_1_i,
        EMAC1PHYTXGMIIMIICLKOUT         => open,
        PHYEMAC1TXGMIIMIICLKIN          => gnd_i,
        -- 1000BASE-X PCS/PMA Interface - EMAC1
        RXDATA_1                        => mgt_rx_data_1_r,
        TXDATA_1                        => mgt_tx_data_1_i,
        DCM_LOCKED_1                    => emac_locked_1_i,
        AN_INTERRUPT_1                  => EMAC1ANINTERRUPT,
        SIGNAL_DETECT_1                 => signal_detect_1_i,
        PHYAD_1                         => PHYAD_1,
        ENCOMMAALIGN_1                  => encommaalign_1_i,
        LOOPBACKMSB_1                   => loopback_1_i,
        MGTRXRESET_1                    => mgt_rx_reset_1_i,
        MGTTXRESET_1                    => mgt_tx_reset_1_i,
        POWERDOWN_1                     => powerdown_1_i,
        SYNCACQSTATUS_1                 => EMAC1CLIENTSYNCACQSTATUS,
        RXCLKCORCNT_1                   => rxclkcorcnt_1_r,
        RXBUFSTATUS_1                   => rxbufstatus_1_i,
        RXCHARISCOMMA_1                 => rxchariscomma_1_r,
        RXCHARISK_1                     => rxcharisk_1_r,
        RXDISPERR_1                     => rxdisperr_1_r,
        RXNOTINTABLE_1                  => rxnotintable_1_r,
        RXREALIGN_1                     => '0',
        RXRUNDISP_1                     => rxrundisp_1_r,
        TXBUFERR_1                      => txbuferr_1_r,
        TXRUNDISP_1                     => '0',
        TXCHARDISPMODE_1                => txchardispmode_1_i,
        TXCHARDISPVAL_1                 => txchardispval_1_i,
        TXCHARISK_1                     => txcharisk_1_i,



        -- Asynchronous Reset
        RESET                           => reset_i
        );






end TOP_LEVEL;
