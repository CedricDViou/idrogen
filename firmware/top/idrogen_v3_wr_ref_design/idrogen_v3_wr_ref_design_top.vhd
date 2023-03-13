-------------------------------------------------------------------------------
-- Title      : WRPC reference design for idrogen_v3
-- Project    : IDROGEN
-- URL        : https://gitlab.in2p3.fr/NEBULA/idrogen
-------------------------------------------------------------------------------
-- File       : idrogen_v3_wr_ref_design.vhd
-- Author(s)  : Cedric Viou <Cedric.Viou@obs-nancay.fr>
-- Company    : Observatoire Radioastronomique de NanÃ§ay
-- Created    : 2022-09-05
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Top-level file for the WRPC reference design on the IDROGEN_v3.
--
-- This is a reference top HDL that instanciates the WR PTP Core together with
-- its peripherals to be run on an IDROGEN_v3 card.
--
-- There are two main usecases for this HDL file:
-- * let new users easily synthesize a WR PTP Core bitstream that can be run on
--   reference hardware
-- * provide a reference top HDL file showing how the WRPC can be instantiated
--   in HDL projects.
--
-------------------------------------------------------------------------------
-- Copyright (c) 2022 Observatoire Radioastronomique de Nancay
-- Observatoire de Paris, PSL Research University, CNRS, Univ. Orleans, OSUC
-------------------------------------------------------------------------------
-- GNU LESSER GENERAL PUBLIC LICENSE
--
-- This source file is free software; you can redistribute it   
-- and/or modify it under the terms of the GNU Lesser General   
-- Public License as published by the Free Software Foundation; 
-- either version 2.1 of the License, or (at your option) any   
-- later version.                                               
--
-- This source is distributed in the hope that it will be       
-- useful, but WITHOUT ANY WARRANTY; without even the implied   
-- warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      
-- PURPOSE.  See the GNU Lesser General Public License for more 
-- details.                                                     
--
-- You should have received a copy of the GNU Lesser General    
-- Public License along with this source; if not, download it   
-- from http://www.gnu.org/licenses/lgpl-2.1.html
-- 
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--use work.build_id_pkg.all;
--use work.wishbone2avalon_pkg.all;

use work.wrcore_pkg.all;
use work.gencores_pkg.all;
use work.wishbone_pkg.all;
use work.wr_board_pkg.all;
use work.wr_idrogen_v3_pkg.all;



entity idrogen_v3_wr_ref_design_top is
  generic (
    g_dpram_initf : string := "../../../ip_cores/wrpc-sw/wrc.mif"; 
    -- Simulation mode enable parameter. Set by default (synthesis) to 0, and
    -- changed to non-zero in the instantiation of the top level DUT in the testbench.
    -- Its purpose is to reduce some internal counters/timeouts to speed up simulations.
    g_simulation : integer := 0
    );
  port (


  -- FPGA Reset input, active low.
  DEV_CLRn                :    in       STD_LOGIC ;
  -- free-running 100 MHz oscillator, or SI5338A.  But should NOT be used for fabric if transceivers or ActiveSerial are used
  -- see https://www.intel.com/content/www/us/en/docs/programmable/683814/current/transceiver-pins.html
  -- CLKUSR                  :    in       STD_LOGIC ;

  -- reference clocks from LMK
  LMK_CLKREF_2            :    in       STD_LOGIC ;
--  LMK_CLKREF_4            :    in       STD_LOGIC ;
  LMK_CLKREF_12           :    in       STD_LOGIC ;

  -- JESD204B
  --SYNC_LMK                :    out      STD_LOGIC := '0' ;  -- SYNC/SYSREF LMK
  --DCLK_RST                :    in       STD_LOGIC ;  -- Dclk_Rst_pn SDCLKOUT5 from LMK

  -- Potential reference for SI5338
  --FPGA_CLK                :    out      STD_LOGIC := '0' ;

  -- Onboard USB Blaster II
  --USB_RESETn              :    in       STD_LOGIC ;
  --USB_CLK                 :    in       STD_LOGIC ;
  --USB_ADDR                :    in       STD_LOGIC_VECTOR(1 downto 0) ;
  --USB_DATA                :    inout    STD_LOGIC_VECTOR(7 downto 0) := (others => 'Z') ;
  --USB_OEn                 :    in       STD_LOGIC ;
  --USB_RDn                 :    in       STD_LOGIC ;
  --USB_WRn                 :    in       STD_LOGIC ;
  --USB_EMPTY               :    out      STD_LOGIC := '0' ;
  --USB_FULL                :    out      STD_LOGIC := '0' ;

  -- SPI interface to AtMega
  --uC_INT                  :    out      STD_LOGIC := '0' ;  -- Interruption to µC
  --uC_MISO                 :    inout    STD_LOGIC := 'Z' ;
  --uC_MOSI                 :    inout    STD_LOGIC := 'Z' ;
  --uC_SCLK                 :    inout    STD_LOGIC := 'Z' ;
  --uC_CSn                  :    inout    STD_LOGIC := 'Z' ;

  -- AMC backplane connector
  --AMC_REFCLK_1G           :    in       STD_LOGIC ;  -- from SI5338, 125 MHz
  --AMC_1GbE_RX             :    in       STD_LOGIC_VECTOR(1 downto 0) ;
  --AMC_1GbE_TX             :    out      STD_LOGIC_VECTOR(1 downto 0) ;
  --AMC_CLK1                :    in       STD_LOGIC ;
  --AMC_CLK2                :    out      STD_LOGIC ;
  --AMC_PCIE_RX             :    in       STD_LOGIC_VECTOR(3 downto 0) ;
  --AMC_PCIE_TX             :    out      STD_LOGIC_VECTOR(3 downto 0) ;
  --AMC_PCI_CLK             :    in       STD_LOGIC ;
  --AMC_TRIGA_0             :    in       STD_LOGIC ;
  --AMC_TRIGA_1             :    out      STD_LOGIC := '0' ;

  -- RTM30 Connector
  --RTM30_P0                :    inout    STD_LOGIC_VECTOR(7 downto 0) ;
  --RTM30_P1                :    inout    STD_LOGIC_VECTOR(7 downto 0) ;
  --RTM30_P2                :    inout    STD_LOGIC_VECTOR(7 downto 2) ;

  -- FMC connector
  --VIta57_CLK0_M2C         :    in       STD_LOGIC ;
  --VIta57_CLK1_M2C         :    in       STD_LOGIC ;
  --VIta57_CLK2_BIDIR       :    out      STD_LOGIC ;
  --VIta57_DP_C2M           :    out      STD_LOGIC_VECTOR(9 downto 0) ;
  --VIta57_DP_M2C           :    in       STD_LOGIC_VECTOR(9 downto 0) ;
  --VIta57_GBTCLK0_M2C      :    in       STD_LOGIC ;
  --VIta57_GBTCLK1_M2C      :    in       STD_LOGIC ;
  --VIta57_HA_CC            :    in       STD_LOGIC_VECTOR(0 downto 0) ;
  ----VIta57_HA               :    inout    STD_LOGIC_VECTOR(23 downto 1) ;
  --VIta57_HB_CC            :    in       STD_LOGIC_VECTOR(0 downto 0) ;
  ----VIta57_HB               :    inout    STD_LOGIC_VECTOR(21 downto 1) ;
  ------VIta57_LA_CC            :    in       STD_LOGIC_VECTOR(0 downto 0) ;  -- not connected
  ----VIta57_LA               :    inout    STD_LOGIC_VECTOR(33 downto 1) ;

  -- QSFP+
  --REFCLK_40G              :    in       STD_LOGIC ;  -- from SI5338, 156.25 MHz
  --QSFP_RX                 :    in       STD_LOGIC_VECTOR(3 downto 0) ;
  --QSFP_TX                 :    out      STD_LOGIC_VECTOR(3 downto 0) ;
  --QSFP_ModIntL            :    inout    STD_LOGIC := 'Z' ;
  --QSFP_ModLP              :    inout    STD_LOGIC := 'Z' ;
  --QSFP_ModPrsL            :    inout    STD_LOGIC := 'Z' ;
  --QSFP_ModRtL             :    inout    STD_LOGIC := 'Z' ;
  --QSFP_ModSelL            :    inout    STD_LOGIC := 'Z' ;
  --QSFP_SCL                :    out      STD_LOGIC := 'Z' ;
  --QSFP_SDA                :    out      STD_LOGIC := 'Z' ;
    ---------------------------------------------------------------------------
    -- Clock signals
    ---------------------------------------------------------------------------
    -- Clock input: 125 MHz LVDS reference clock, coming from the CDCM61004
    -- PLL. The reference oscillator is a 25 MHz VCTCXO (VM53S), tunable by the
    -- DAC connected to CS0 SPI line (dac_main output of the WR Core).
    --LMK_CLKREF_12   : in std_logic;

    -- Local system clock (also from LMK, but could be a fixed Xtal)
    --LMK_CLKREF_2  : in std_logic;


    -- Dedicated clock for the transceiver. Same physical clock as
    -- clk_125m_pllref, just coming from another output of LKM04828 PLL.
    WR_REFCLK_125     : in std_logic;


    -- Clock input, used to derive the DDMTD clock (check out the general presentation
    -- of WR for explanation of its purpose). The clock is produced by the
    -- other 125MHz VCXO, tuned by the second AD5662 DAC, (which is connected to
    -- dac_helper output of the WR Core)
    WR_CLK_DMTD   : in std_logic;

    -------------------------------------------------------------------------
    -- SFP pins
    -------------------------------------------------------------------------

    -- RX/TX gigabit output
    WR_SFP_RX         : in std_logic;
    WR_SFP_TX         : out std_logic;

    -- SFP MOD_DEF0 pin (used as a tied-to-ground SFP insertion detect line)
    WR_SFP_DET_i        : in    std_logic;
    -- SFP MOD_DEF1 pin (SCL line of the I2C EEPROM inside the SFP)
    WR_SFP_scl_b        : inout std_logic;
    -- SFP MOD_DEF2 pin (SDA line of the I2C EEPROM inside the SFP)
    WR_SFP_sda_b        : inout std_logic;
    -- SFP RATE_SELECT pin. Unused for most SFPs, in our case tied to 0.
    WR_SFP_RATE_SELECT: inout std_logic;
    -- SFP laser fault detection pin. Unused in our design.
    WR_SFP_TXFAULT   : in    std_logic;
    -- SFP laser disable line. In our case, tied to GND.
    WR_SFP_TxDisable : out   std_logic;
    -- SFP-provided loss-of-link detection. We don't use it as Ethernet PCS
    -- has its own loss-of-sync detection mechanism.
    WR_SFP_LOS        : in    std_logic;

   ---------------------------------------------------------------------------
    -- Oscillator control pins
    ---------------------------------------------------------------------------

    -- A typical SPI bus shared betwen two AD5662 DACs. The first one (CS1) tunes
    -- the clk_ref oscillator, the second (CS2) - the clk_dmtd VCXO.
    WR_DAC_SCLK  : out std_logic;
    WR_DAC_DIN   : out std_logic;
    WR_DAC1_SYNCn : out std_logic;
    WR_DAC2_SYNCn : out std_logic;

    ---------------------------------------------------------------------------
    -- Miscellanous WR Core pins
    ---------------------------------------------------------------------------

    -- I2C bus connected to the EEPROM on the DIO mezzanine. This EEPROM is used
    -- for storing WR Core's configuration parameters.
    WR_SCL_FLASH_b : inout std_logic;
    WR_SDA_FLASH_b : inout std_logic;

    -- One-wire interface to DS18B20 temperature sensor, which also provides an
    -- unique serial number, that WRPC uses to assign itself a unique MAC address.
    WR_SERNUM_b : inout std_logic;

    -- UART pins (connected to the mini-USB port)
    WR_RX_to_UART : out std_logic;
    WR_TX_from_UART : in  std_logic;

    PPS_IN                  :    in       STD_LOGIC ;
    PPS_OUT                 :    out      STD_LOGIC ;           -- looped-back by default

    TRIGGER_IN              :    in       STD_LOGIC ;
    TRIGGER_OUT             :    out      STD_LOGIC ;           -- looped-back by default


    -- Spare IOs
    --SPARE_UC                :    inout    STD_LOGIC_VECTOR(3 downto 0) := (others => 'Z') ;
    --SPARE_TEST              :    inout    STD_LOGIC_VECTOR(8 downto 4) := (others => 'Z') ;

    -------------------------------------------------------------------------
    -- leds onboard
    -------------------------------------------------------------------------
     LEDn  :    out      STD_LOGIC_VECTOR(3 downto 0) := (others => '0')
    );
end idrogen_v3_wr_ref_design_top;

architecture rtl of idrogen_v3_wr_ref_design_top is

  -----------------------------------------------------------------------------
  -- Function declarations
  -----------------------------------------------------------------------------
  function f_pick(x : boolean; y : integer; z : integer) return natural is
  begin
    if x
    then return y;
    else return z;
    end if;
  end f_pick;

  constant c_is_arria10    : boolean := True;

  -----------------------------------------------------------------------------
  -- Signals declarations
  -----------------------------------------------------------------------------

  -- clock and reset
  signal clk_sys_62m5   : std_logic;
  --signal rst_sys_62m5   : std_logic;
  signal rst_sys_62m5_n : std_logic;
  signal clk_ref_125m   : std_logic;
  --signal clk_ref_div2   : std_logic;
  --signal clk_ext_ref    : std_logic;

  -- I2C EEPROM
  signal eeprom_scl_o      : std_logic;
  signal eeprom_scl_i      : std_logic;
  signal eeprom_sda_o      : std_logic;
  signal eeprom_sda_i      : std_logic;

  -- OneWire
  signal onewire_i         : std_logic;
  signal onewire_oen_o     : std_logic;

  -- SFP
  signal sfp_scl_i        : std_logic;
  signal sfp_scl_o        : std_logic;
  signal sfp_sda_i        : std_logic;
  signal sfp_sda_o        : std_logic;

  ----------------------------------------------------------------------------------
  -- Clock networks ----------------------------------------------------------------
  ----------------------------------------------------------------------------------

  signal core_clk_25m_vcxo_i    : std_logic;
  signal core_clk_125m_pllref_i : std_logic;
  signal core_clk_125m_sfpref_i : std_logic;
  signal core_clk_125m_local_i  : std_logic;
  signal core_rstn_i            : std_logic;

  -- Non-PLL reset stuff
  signal rstn_free        : std_logic;

  
  ----------------------------------------------------------------------------------
  -- White Rabbit signals ----------------------------------------------------------
  ----------------------------------------------------------------------------------

  -- Oscillator control DAC wiring
  signal dac_hpll_load_p1 : std_logic;
  signal dac_dpll_load_p1 : std_logic;
  signal dac_hpll_data    : std_logic_vector(15 downto 0);
  signal dac_dpll_data    : std_logic_vector(15 downto 0);

  signal link_act : std_logic;
  signal link_up  : std_logic;
  signal pps      : std_logic;
  signal ext_pps  : std_logic;

  signal tm_valid  : std_logic;
  signal tm_tai    : std_logic_vector(39 downto 0);
  signal tm_cycles : std_logic_vector(27 downto 0);

   -- END of White Rabbit signals --------------------------------------------------
  ----------------------------------------------------------------------------------
 
  -- Wishbone buse(s) from masters attached to crossbar
  signal cnx_master_out : t_wishbone_master_out_array(0 downto 0);
  signal cnx_master_in  : t_wishbone_master_in_array(0 downto 0);
  -- Wishbone buse(s) to slaves attached to crossbar
  signal cnx_slave_out : t_wishbone_slave_out_array(0 downto 0);
  signal cnx_slave_in  : t_wishbone_slave_in_array(0 downto 0);

  
  -- Misc signals

  signal pps_p        : std_logic;
  signal pps_long     : std_logic;
  

  -- timer for leds
  signal tick_1s              : std_logic;
  signal pulse_1s             : std_logic;
  signal cnt                  : unsigned(31 downto 0);

  signal tick_1s2             : std_logic;
  signal pulse_1s2            : std_logic;
  signal cnt2                 : unsigned(31 downto 0);

  signal tick_1s3             : std_logic;
  signal pulse_1s3            : std_logic;
  signal cnt3                 : unsigned(31 downto 0);

  signal tick_1s4             : std_logic;
  signal pulse_1s4            : std_logic;
  signal cnt4                 : unsigned(31 downto 0);


begin --rtl


  -----------------------------------------------------------------------------
  -- The WR PTP core board package (WB Slave + WB Master #2 (Etherbone))
  -----------------------------------------------------------------------------

  cmp_xwrc_board_idrogen_v3 : xwrc_board_idrogen_v3
    generic map (
      g_simulation                => g_simulation,
      g_with_external_clock_input => False,
      g_aux_clks                  => 0,
      g_pcs_16bit                 => false,
      g_dpram_initf               => g_dpram_initf,
      g_fabric_iface              => ETHERBONE)
    port map (
      clk_125m_pllref_i => WR_REFCLK_125,
      clk_125m_vcxo_i   => WR_CLK_DMTD,
      --clk_10m_ext_i     => TRIGGER_IN,
      --pps_ext_i         => PPS_IN,
      areset_n_i        => DEV_CLRn,
      clk_sys_62m5_o    => clk_sys_62m5,
      clk_ref_125m_o    => clk_ref_125m,
      rst_sys_62m5_n_o  => rst_sys_62m5_n,

      dac_ref_sync_n_o  => WR_DAC1_SYNCn,
      dac_dmtd_sync_n_o => WR_DAC2_SYNCn,
      dac_din_o         => WR_DAC_DIN,
      dac_sclk_o        => WR_DAC_SCLK,

      sfp_tx_o          => WR_SFP_TX,
      sfp_rx_i          => WR_SFP_RX,
      sfp_det_i         => WR_SFP_DET_i,
      sfp_scl_i         => sfp_scl_i,
      sfp_scl_o         => sfp_scl_o,
      sfp_sda_i         => sfp_sda_i,
      sfp_sda_o         => sfp_sda_o,
      sfp_rate_select_o => WR_SFP_RATE_SELECT,
      sfp_tx_fault_i    => WR_SFP_TXFAULT,
      sfp_tx_disable_o  => WR_SFP_TxDisable,
      sfp_los_i         => WR_SFP_LOS,

      eeprom_sda_i      => eeprom_sda_i,
      eeprom_sda_o      => eeprom_sda_o,
      eeprom_scl_i      => eeprom_scl_i,
      eeprom_scl_o      => eeprom_scl_o,

      onewire_i         => onewire_i,
      onewire_oen_o     => onewire_oen_o,

      uart_rxd_i          => WR_TX_from_UART,
      uart_txd_o          => WR_RX_to_UART,
  
      wb_slave_o        => cnx_slave_out(0),
      wb_slave_i        => cnx_slave_in(0),

      wb_eth_master_o   => cnx_master_out(0),
      wb_eth_master_i   => cnx_master_in(0),

      pps_p_o           => PPS_OUT,
      pps_led_o         => pps_long,
      led_link_o        => link_up,
      led_act_o         => link_act);
      

  cnx_slave_in <= cnx_master_out;
  cnx_master_in <= cnx_slave_out;

  -- Tristates for configuration EEPROM
  WR_SCL_FLASH_b  <= '0' when eeprom_scl_o = '0' else 'Z';
  WR_SDA_FLASH_b  <= '0' when eeprom_sda_o = '0' else 'Z';
  eeprom_scl_i  <= WR_SCL_FLASH_b;
  eeprom_sda_i  <= WR_SDA_FLASH_b;

  -- Tristates for SFP EEPROM
  WR_SFP_scl_b <= '0' when sfp_scl_o = '0' else 'Z';
  WR_SFP_sda_b <= '0' when sfp_sda_o = '0' else 'Z';
  sfp_scl_i <= WR_SFP_scl_b;
  sfp_sda_i <= WR_SFP_sda_b;

  -- Tristates for Onewire
  WR_SERNUM_b <= '0' when onewire_oen_o = '1' else 'Z';
  onewire_i  <= WR_SERNUM_b;
  
 
  LEDn(0) <= not pulse_1s;  -- led D21
  LEDn(1) <= not link_up;   -- led D21
  LEDn(2) <= not link_act;  -- led D20
  LEDn(3) <= not pps_long;  -- led D19

end rtl;
