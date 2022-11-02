-------------------------------------------------------------------------------
-- Title      : WRPC Wrapper for idrogen_v3
-- Project    : IDROGEN
-------------------------------------------------------------------------------
-- File       : wrc_board_idrogen_v3_pkg.vhd
-- Author(s)  : Cedric Viou <Cedric.Viou@obs-nancay.fr>
-- Company    : Observatoire Radioastronomique de NanÃ§ay
-- Created    : 2022-09-05
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Top-level wrapper for WR PTP core including all the modules
-- needed to operate the core on the idrogen_v3 board.
-- https://gitlab.in2p3.fr/NEBULA/idrogen
-------------------------------------------------------------------------------
-- Copyright (c) 2022 Observatoire Radioastronomique de NanÃ§ay
-- Observatoire de Paris, PSL Research University, CNRS, Univ. OrlÃ©ans, OSUC
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

library work;
use work.gencores_pkg.all;
use work.wrcore_pkg.all;
use work.wishbone_pkg.all;
use work.etherbone_pkg.all;
use work.wr_fabric_pkg.all;
use work.endpoint_pkg.all;
use work.streamers_pkg.all;
use work.wr_altera_pkg.all;
use work.wr_board_pkg.all;
use work.wr_idrogen_v3_pkg.all;
use work.pll_pkg_idg.all;

-- clock buffer
library twentynm;
use twentynm.twentynm_components.all;

entity xwrc_board_idrogen_v3 is
    generic (
        -- set to 1 to speed up some initialization processes during simulation
        g_simulation : INTEGER := 0;
        -- Select whether to include external ref clock input
        g_with_external_clock_input : BOOLEAN := FALSE;
        -- Number of aux clocks syntonized by WRPC to WR timebase
        g_aux_clks : INTEGER := 0;
        -- set to TRUE to use 16bit PCS (instead of default 8bit PCS)
        g_pcs_16bit : BOOLEAN := FALSE;
        -- plain     = expose WRC fabric interface
        -- streamers = attach WRC streamers to fabric interface
        -- etherbone = attach Etherbone slave to fabric interface
        g_fabric_iface : t_board_fabric_iface := plain;
        -- parameters configuration when g_fabric_iface = "streamers" (otherwise ignored)
        g_streamers_op_mode  : t_streamers_op_mode  := TX_AND_RX;
        g_tx_streamer_params : t_tx_streamer_params := c_tx_streamer_params_defaut;
        g_rx_streamer_params : t_rx_streamer_params := c_rx_streamer_params_defaut;
        -- memory initialisation file for embedded CPU
        g_dpram_initf : STRING := "default_altera";
        -- identification (id and ver) of the layout of words in the generic diag interface
        g_diag_id  : INTEGER := 0;
        g_diag_ver : INTEGER := 0;
        -- size the generic diag interface
        g_diag_ro_size : INTEGER := 0;
        g_diag_rw_size : INTEGER := 0
    );
    port (
        ---------------------------------------------------------------------------
        -- Clocks/resets
        ---------------------------------------------------------------------------
        -- Clock inputs from the board
        clk_125m_pllref_i : in STD_LOGIC;
        clk_125m_vcxo_i   : in STD_LOGIC;
        -- Aux clocks, which can be disciplined by the WR Core
        clk_aux_i : in STD_LOGIC_VECTOR(g_aux_clks - 1 downto 0) := (others => '0');
        -- 10MHz ext ref clock input (g_with_external_clock_input = TRUE)
        clk_10m_ext_i : in STD_LOGIC := '0';
        -- External PPS input (g_with_external_clock_input = TRUE)
        pps_ext_i : in STD_LOGIC := '0';
        -- Reset input (active low, can be async)
        areset_n_i : in STD_LOGIC;
        -- Optional reset input active low with rising edge detection. Does not
        -- reset PLLs.
        areset_edge_n_i : in STD_LOGIC := '1';
        -- 62.5MHz sys clock output
        clk_sys_62m5_o : out STD_LOGIC;
        -- 125MHz ref clock output
        clk_ref_125m_o : out STD_LOGIC;
        -- active low reset outputs, synchronous to 62m5 and 125m clocks
        rst_sys_62m5_n_o : out STD_LOGIC;
        rst_ref_125m_n_o : out STD_LOGIC;

        ---------------------------------------------------------------------------
        -- SPI interfaces to DACs
        ---------------------------------------------------------------------------
        dac_ref_sync_n_o  : out STD_LOGIC;
        dac_dmtd_sync_n_o : out STD_LOGIC;
        dac_din_o         : out STD_LOGIC;
        dac_sclk_o        : out STD_LOGIC;

        ---------------------------------------------------------------------------
        -- SFP I/O for transceiver and SFP management info from VFC-HD
        ---------------------------------------------------------------------------
        sfp_tx_o          : out STD_LOGIC;
        sfp_rx_i          : in STD_LOGIC;
        sfp_det_i         : in STD_LOGIC := '0';
        sfp_scl_i         : in STD_LOGIC := '1';
        sfp_scl_o         : out STD_LOGIC;
        sfp_sda_i         : in STD_LOGIC := '1';
        sfp_sda_o         : out STD_LOGIC;
        sfp_rate_select_o : out STD_LOGIC;
        sfp_tx_fault_i    : in STD_LOGIC := '0';
        sfp_tx_disable_o  : out STD_LOGIC;
        sfp_los_i         : in STD_LOGIC := '0';

        ---------------------------------------------------------------------------
        -- I2C EEPROM
        ---------------------------------------------------------------------------
        eeprom_sda_i : in STD_LOGIC;
        eeprom_sda_o : out STD_LOGIC;
        eeprom_scl_i : in STD_LOGIC;
        eeprom_scl_o : out STD_LOGIC;

        ---------------------------------------------------------------------------
        -- Onewire interface
        ---------------------------------------------------------------------------
        onewire_i     : in STD_LOGIC;
        onewire_oen_o : out STD_LOGIC;

        ---------------------------------------------------------------------------
        -- UART
        ---------------------------------------------------------------------------
        uart_rxd_i : in STD_LOGIC;
        uart_txd_o : out STD_LOGIC;

        ---------------------------------------------------------------------------
        -- External WB interface
        ---------------------------------------------------------------------------
        wb_slave_o : out t_wishbone_slave_out;
        wb_slave_i : in t_wishbone_slave_in := cc_dummy_slave_in;

        aux_master_o : out t_wishbone_master_out;
        aux_master_i : in t_wishbone_master_in := cc_dummy_master_in;

        ---------------------------------------------------------------------------
        -- WR fabric interface (when g_fabric_iface = "plain")
        ---------------------------------------------------------------------------
        wrf_src_o : out t_wrf_source_out;
        wrf_src_i : in t_wrf_source_in := c_dummy_src_in;
        wrf_snk_o : out t_wrf_sink_out;
        wrf_snk_i : in t_wrf_sink_in := c_dummy_snk_in;

        ---------------------------------------------------------------------------
        -- WR streamers (when g_fabric_iface = "streamers")
        ---------------------------------------------------------------------------
        wrs_tx_data_i  : in STD_LOGIC_VECTOR(g_tx_streamer_params.data_width - 1 downto 0) := (others => '0');
        wrs_tx_valid_i : in STD_LOGIC                                                      := '0';
        wrs_tx_dreq_o  : out STD_LOGIC;
        wrs_tx_last_i  : in STD_LOGIC         := '1';
        wrs_tx_flush_i : in STD_LOGIC         := '0';
        wrs_tx_cfg_i   : in t_tx_streamer_cfg := c_tx_streamer_cfg_default;
        wrs_rx_first_o : out STD_LOGIC;
        wrs_rx_last_o  : out STD_LOGIC;
        wrs_rx_data_o  : out STD_LOGIC_VECTOR(g_rx_streamer_params.data_width - 1 downto 0);
        wrs_rx_valid_o : out STD_LOGIC;
        wrs_rx_dreq_i  : in STD_LOGIC         := '0';
        wrs_rx_cfg_i   : in t_rx_streamer_cfg := c_rx_streamer_cfg_default;
        ---------------------------------------------------------------------------
        -- Etherbone WB master interface (when g_fabric_iface = "etherbone")
        ---------------------------------------------------------------------------
        wb_eth_master_o : out t_wishbone_master_out;
        wb_eth_master_i : in t_wishbone_master_in := cc_dummy_master_in;

        ---------------------------------------------------------------------------
        -- Generic diagnostics interface (access from WRPC via SNMP or uart console
        ---------------------------------------------------------------------------
        aux_diag_i : in t_generic_word_array(g_diag_ro_size - 1 downto 0) := (others => (others => '0'));
        aux_diag_o : out t_generic_word_array(g_diag_rw_size - 1 downto 0);

        ---------------------------------------------------------------------------
        -- Aux clocks control
        ---------------------------------------------------------------------------
        tm_dac_value_o       : out STD_LOGIC_VECTOR(23 downto 0);
        tm_dac_wr_o          : out STD_LOGIC_VECTOR(g_aux_clks - 1 downto 0);
        tm_clk_aux_lock_en_i : in STD_LOGIC_VECTOR(g_aux_clks - 1 downto 0) := (others => '0');
        tm_clk_aux_locked_o  : out STD_LOGIC_VECTOR(g_aux_clks - 1 downto 0);

        ---------------------------------------------------------------------------
        -- External Tx Timestamping I/F
        ---------------------------------------------------------------------------
        timestamps_o     : out t_txtsu_timestamp;
        timestamps_ack_i : in STD_LOGIC := '1';

        ---------------------------------------------------------------------------
        -- Pause Frame Control
        ---------------------------------------------------------------------------
        fc_tx_pause_req_i   : in STD_LOGIC                     := '0';
        fc_tx_pause_delay_i : in STD_LOGIC_VECTOR(15 downto 0) := x"0000";
        fc_tx_pause_ready_o : out STD_LOGIC;

        ---------------------------------------------------------------------------
        -- Timecode I/F
        ---------------------------------------------------------------------------
        tm_link_up_o    : out STD_LOGIC;
        tm_time_valid_o : out STD_LOGIC;
        tm_tai_o        : out STD_LOGIC_VECTOR(39 downto 0);
        tm_cycles_o     : out STD_LOGIC_VECTOR(27 downto 0);

        ---------------------------------------------------------------------------
        -- Buttons, LEDs and PPS output
        ---------------------------------------------------------------------------
        led_act_o  : out STD_LOGIC;
        led_link_o : out STD_LOGIC;
        btn1_i     : in STD_LOGIC := '1';
        btn2_i     : in STD_LOGIC := '1';
        -- 1PPS output
        pps_p_o   : out STD_LOGIC;
        pps_led_o : out STD_LOGIC;
        -- Link ok indication
        link_ok_o : out STD_LOGIC
    );

end entity xwrc_board_idrogen_v3;
architecture struct of xwrc_board_idrogen_v3 is

    -----------------------------------------------------------------------------
    -- Signals
    -----------------------------------------------------------------------------

    -- PLLs
    signal clk_pll_dmtd_gen       : STD_LOGIC;
    signal clk_dmtd_locked        : STD_LOGIC;
    signal clk_pll_sys            : STD_LOGIC;
    signal pll_sys_locked         : STD_LOGIC;
    signal clk_pll_ref_local      : STD_LOGIC;
    signal clk_pll_ref            : STD_LOGIC;
    signal clk_pll_reconf         : STD_LOGIC;
    signal ext_ref_mul_gen        : STD_LOGIC;
    signal ext_ref_mul_gen_locked : STD_LOGIC;
    signal pll_arst               : STD_LOGIC;

    signal clk_pll_62m5 : STD_LOGIC;
    signal clk_pll_125m : STD_LOGIC;
    signal clk_pll_dmtd : STD_LOGIC;
    signal pll_locked   : STD_LOGIC;
    signal clk_10m_ext  : STD_LOGIC;

    -- Reset logic
    signal areset_edge_ppulse : STD_LOGIC;
    signal rst_62m5_n         : STD_LOGIC;
    signal rstlogic_arst_n    : STD_LOGIC;
    signal rstlogic_clk_in    : STD_LOGIC_VECTOR(1 downto 0);
    signal rstlogic_rst_out   : STD_LOGIC_VECTOR(1 downto 0);

    -- PLL DAC ARB
    signal dac_sync_n       : STD_LOGIC_VECTOR(1 downto 0);
    signal dac_hpll_load_p1 : STD_LOGIC;
    signal dac_hpll_data    : STD_LOGIC_VECTOR(15 downto 0);
    signal dac_dpll_load_p1 : STD_LOGIC;
    signal dac_dpll_data    : STD_LOGIC_VECTOR(15 downto 0);

    -- OneWire
    signal onewire_in : STD_LOGIC_VECTOR(1 downto 0);
    signal onewire_en : STD_LOGIC_VECTOR(1 downto 0);

    -- PHY
    signal phy8_to_wrc    : t_phy_8bits_to_wrc;
    signal phy8_from_wrc  : t_phy_8bits_from_wrc;
    signal phy16_to_wrc   : t_phy_16bits_to_wrc;
    signal phy16_from_wrc : t_phy_16bits_from_wrc;

    -- SFP I2C adapter
    signal sfp_i2c_scl_in : STD_LOGIC;
    signal sfp_i2c_sda_in : STD_LOGIC;
    signal sfp_i2c_sda_en : STD_LOGIC;

    -- External reference
    signal ext_ref_mul        : STD_LOGIC;
    signal ext_ref_mul_locked : STD_LOGIC;
    signal ext_ref_rst        : STD_LOGIC;
begin -- architecture struct

    -----------------------------------------------------------------------------
    -- Platform-dependent part (PHY, PLLs, etc)
    -----------------------------------------------------------------------------
    pll_arst <= not areset_n_i;

    cmp_sys_clk_pll : sys_pll10_idg 
        port map (
            rst      => pll_arst,
            refclk   => clk_125m_pllref_i, -- 125  Mhz
            outclk_0 => clk_pll_sys,       --  62.5MHz
            outclk_1 => clk_pll_ref_local, -- 125  Mhz
            locked   => pll_sys_locked
        );

    -- Clock buffer required to allow IOPLL cmp_sys_clk_pll to feed clk_pll_ref_local to PHY refclock (PMA or CMU)
    -- This is not possible:
    -- clk_pll_ref <= clk_pll_ref_local;

    clk_buffer : twentynm_clkena
        generic map (clock_type => "Auto")
    --    generic map ( clock_type => "Global Clock")
    --    generic map ( clock_type => "Regional Clock")
    --	  generic map ( clock_type => "Periphery Clock")
    --    generic map ( clock_type => "Large Periphery Clock")
        port map (
            inclk  => clk_pll_ref_local,
            outclk => clk_pll_ref
        );

    cmp_dmtd_clk_pll : dmtd_pll10_hydrogen_idg 
        port map (
            rst      => pll_arst,
            refclk   => clk_125m_vcxo_i,  --  125  MHz
            outclk_0 => clk_pll_dmtd_gen, --  62.5MHz
            locked   => clk_dmtd_locked
        );

    gen_arria5_ext_ref_pll : if (g_with_external_clock_input = TRUE) generate

    signal pll_ext_rst : STD_LOGIC;

    begin --gen_arria5_ext_ref_pll 
        cmp_ext_ref_pll : ref_pll10_idg
            port map (
                refclk   => clk_10m_ext_i,
                rst      => pll_ext_rst,
                outclk_0 => ext_ref_mul_gen,
                locked   => ext_ref_mul_gen_locked
            );

        cmp_extend_ext_reset : gc_extend_pulse
            generic map (g_width => 1000)
            port map (
                clk_i      => clk_pll_sys,
                rst_n_i    => pll_sys_locked,
                pulse_i    => ext_ref_rst,
                extended_o => pll_ext_rst
            );

    end generate gen_arria5_ext_ref_pll;

    gen_arria5_no_ext_ref_pll : if (g_with_external_clock_input = FALSE) generate
        ext_ref_mul_gen        <= '0';
        ext_ref_mul_gen_locked <= '1';
    end generate gen_arria5_no_ext_ref_pll;

    sfp_rate_select_o <= '0';

    cmp_xwrc_platform : xwrc_platform_altera
        generic map (
            g_fpga_family               => "arria10",
            g_with_external_clock_input => g_with_external_clock_input,
            g_use_default_plls          => FALSE,
            g_pcs_16bit                 => g_pcs_16bit
        )
        port map (
            areset_n_i     => areset_n_i,
            clk_10m_ext_i  => clk_10m_ext_i,
            clk_20m_vcxo_i => open,
            --clk_125m_sfpref_i    => clk_125m_sfpref_i,
            clk_125m_pllref_i    => open,
            clk_62m5_dmtd_i      => clk_pll_dmtd_gen,
            clk_dmtd_locked_i    => clk_dmtd_locked,
            clk_62m5_sys_i       => clk_pll_sys,
            clk_sys_locked_i     => pll_sys_locked,
            clk_125m_ref_i       => clk_pll_ref,
            clk_125m_ext_i       => ext_ref_mul_gen,
            clk_ext_locked_i     => ext_ref_mul_gen_locked,
            clk_ext_stopped_i    => '0',
            clk_ext_rst_o        => open,
            sfp_tx_o             => sfp_tx_o,
            sfp_rx_i             => sfp_rx_i,
            sfp_tx_fault_i       => sfp_tx_fault_i,
            sfp_los_i            => sfp_los_i,
            sfp_tx_disable_o     => sfp_tx_disable_o,
            clk_62m5_sys_o       => clk_pll_62m5,
            clk_125m_ref_o       => clk_pll_125m,
            clk_62m5_dmtd_o      => clk_pll_dmtd,
            pll_locked_o         => pll_locked,
            clk_10m_ext_o        => clk_10m_ext,
            phy8_o               => phy8_to_wrc,
            phy8_i               => phy8_from_wrc,
            phy16_o              => phy16_to_wrc,
            phy16_i              => phy16_from_wrc,
            ext_ref_mul_o        => ext_ref_mul,
            ext_ref_mul_locked_o => ext_ref_mul_locked,
            ext_ref_rst_i        => ext_ref_rst
        );

    clk_sys_62m5_o <= clk_pll_62m5;
    clk_ref_125m_o <= clk_pll_125m;

    -----------------------------------------------------------------------------
    -- Reset logic
    -----------------------------------------------------------------------------
    -- Detect when areset_edge_n_i goes high (end of reset) and use this edge to
    -- generate rstlogic_arst_n. This is needed to connect optional reset like PCIe
    -- reset. When baord runs standalone, we need to ignore PCIe reset being
    -- constantly low.
    cmp_arst_edge : gc_sync_ffs
        generic map (g_sync_edge => "positive")
        port map (
            clk_i    => clk_pll_62m5,
            rst_n_i  => '1',
            data_i   => areset_edge_n_i,
            ppulse_o => areset_edge_ppulse
        );

    -- logic AND of all async reset sources (active low)
    rstlogic_arst_n <= pll_locked and areset_n_i and (not areset_edge_ppulse);

    -- concatenation of all clocks required to have synced resets
    rstlogic_clk_in(0) <= clk_pll_62m5;
    rstlogic_clk_in(1) <= clk_pll_125m;

    cmp_rstlogic_reset : gc_reset
        generic map (
            g_clocks    => 2, -- 62.5MHz, 125MHz
            g_logdelay  => 4, -- 16 clock cycles
            g_syncdepth => 3  -- length of sync chains
        )
        port map (
            free_clk_i => clk_125m_pllref_i,
            locked_i   => rstlogic_arst_n,
            clks_i     => rstlogic_clk_in,
            rstn_o     => rstlogic_rst_out
        );

    -- distribution of resets (already synchronized to their clock domains)
    rst_62m5_n <= rstlogic_rst_out(0);

    rst_sys_62m5_n_o <= rst_62m5_n;
    rst_ref_125m_n_o <= rstlogic_rst_out(1);

    -----------------------------------------------------------------------------
    -- SPI DAC (2-channel)
    -----------------------------------------------------------------------------

    cmp_spi_dac : spec_serial_dac_arb
        generic map (
            g_invert_sclk    => FALSE,
            g_num_extra_bits => 8
        )
        port map (
            clk_i       => clk_pll_62m5,
            rst_n_i     => rst_62m5_n,
            val1_i      => dac_dpll_data,
            load1_i     => dac_dpll_load_p1,
            val2_i      => dac_hpll_data,
            load2_i     => dac_hpll_load_p1,
            dac_clr_n_o => open,
            dac_cs_n_o  => dac_sync_n,
            dac_sclk_o  => dac_sclk_o,
            dac_din_o   => dac_din_o
        );

    dac_ref_sync_n_o  <= dac_sync_n(0);
    dac_dmtd_sync_n_o <= dac_sync_n(1);

    -----------------------------------------------------------------------------
    -- OneWire
    -----------------------------------------------------------------------------

    onewire_oen_o <= onewire_en(0);
    onewire_in(0) <= onewire_i;
    onewire_in(1) <= '1';

    -----------------------------------------------------------------------------
    -- The WR PTP core with optional fabric interface attached
    -----------------------------------------------------------------------------

    cmp_board_common : xwrc_board_common
        generic map (
            g_simulation                => g_simulation,
            g_with_external_clock_input => g_with_external_clock_input,
            g_board_name                => "IDRO",
            -- temporary, without it vuart receives but is not able to transmit
            g_phys_uart               => TRUE,
            g_virtual_uart            => TRUE,
            g_aux_clks                => g_aux_clks,
            g_ep_rxbuf_size           => 1024,
            g_tx_runt_padding         => TRUE,
            g_dpram_initf             => g_dpram_initf,
            g_dpram_size              => 131072/4,
            g_interface_mode          => PIPELINED,
            g_address_granularity     => BYTE,
            g_aux_sdb                 => c_etherbone_sdb,
            g_softpll_enable_debugger => FALSE,
            g_vuart_fifo_size         => 1024,
            g_pcs_16bit               => g_pcs_16bit,
            g_diag_id                 => g_diag_id,
            g_diag_ver                => g_diag_ver,
            g_diag_ro_size            => g_diag_ro_size,
            g_diag_rw_size            => g_diag_rw_size,
            g_streamers_op_mode       => g_streamers_op_mode,
            g_tx_streamer_params      => g_tx_streamer_params,
            g_rx_streamer_params      => g_rx_streamer_params,
            g_fabric_iface            => g_fabric_iface
        )
        port map (
            clk_sys_i            => clk_pll_62m5,
            clk_dmtd_i           => clk_pll_dmtd,
            clk_ref_i            => clk_pll_125m,
            clk_aux_i            => clk_aux_i,
            clk_10m_ext_i        => clk_10m_ext,
            clk_ext_mul_i        => ext_ref_mul,
            clk_ext_mul_locked_i => ext_ref_mul_locked,
            clk_ext_stopped_i    => '0',
            clk_ext_rst_o        => ext_ref_rst,
            pps_ext_i            => pps_ext_i,
            rst_n_i              => rst_62m5_n,
            dac_hpll_load_p1_o   => dac_hpll_load_p1,
            dac_hpll_data_o      => dac_hpll_data,
            dac_dpll_load_p1_o   => dac_dpll_load_p1,
            dac_dpll_data_o      => dac_dpll_data,
            phy8_o               => phy8_from_wrc,
            phy8_i               => phy8_to_wrc,
            phy16_o              => phy16_from_wrc,
            phy16_i              => phy16_to_wrc,
            scl_o                => eeprom_scl_o,
            scl_i                => eeprom_scl_i,
            sda_o                => eeprom_sda_o,
            sda_i                => eeprom_sda_i,
            sfp_scl_o            => sfp_scl_o,
            sfp_scl_i            => sfp_scl_i,
            sfp_sda_o            => sfp_sda_o,
            sfp_sda_i            => sfp_sda_i,
            sfp_det_i            => sfp_det_i,
            spi_sclk_o           => open,
            spi_ncs_o            => open,
            spi_mosi_o           => open,
            spi_miso_i           => '0',
            uart_rxd_i           => uart_rxd_i,
            uart_txd_o           => uart_txd_o,
            owr_pwren_o          => open,
            owr_en_o             => onewire_en,
            owr_i                => onewire_in,
            wb_slave_i           => wb_slave_i,
            wb_slave_o           => wb_slave_o,
            aux_master_o         => aux_master_o,
            aux_master_i         => aux_master_i,
            wrf_src_o            => wrf_src_o,
            wrf_src_i            => wrf_src_i,
            wrf_snk_o            => wrf_snk_o,
            wrf_snk_i            => wrf_snk_i,
            wrs_tx_data_i        => wrs_tx_data_i,
            wrs_tx_valid_i       => wrs_tx_valid_i,
            wrs_tx_dreq_o        => wrs_tx_dreq_o,
            wrs_tx_last_i        => wrs_tx_last_i,
            wrs_tx_flush_i       => wrs_tx_flush_i,
            wrs_tx_cfg_i         => wrs_tx_cfg_i,
            wrs_rx_first_o       => wrs_rx_first_o,
            wrs_rx_last_o        => wrs_rx_last_o,
            wrs_rx_data_o        => wrs_rx_data_o,
            wrs_rx_valid_o       => wrs_rx_valid_o,
            wrs_rx_dreq_i        => wrs_rx_dreq_i,
            wrs_rx_cfg_i         => wrs_rx_cfg_i,
            wb_eth_master_o      => wb_eth_master_o,
            wb_eth_master_i      => wb_eth_master_i,
            aux_diag_i           => aux_diag_i,
            aux_diag_o           => aux_diag_o,
            tm_dac_value_o       => tm_dac_value_o,
            tm_dac_wr_o          => tm_dac_wr_o,
            tm_clk_aux_lock_en_i => tm_clk_aux_lock_en_i,
            tm_clk_aux_locked_o  => tm_clk_aux_locked_o,
            timestamps_o         => timestamps_o,
            timestamps_ack_i     => timestamps_ack_i,
            fc_tx_pause_req_i    => fc_tx_pause_req_i,
            fc_tx_pause_delay_i  => fc_tx_pause_delay_i,
            fc_tx_pause_ready_o  => fc_tx_pause_ready_o,
            tm_link_up_o         => tm_link_up_o,
            tm_time_valid_o      => tm_time_valid_o,
            tm_tai_o             => tm_tai_o,
            tm_cycles_o          => tm_cycles_o,
            led_act_o            => led_act_o,
            led_link_o           => led_link_o,
            btn1_i               => btn1_i,
            btn2_i               => btn2_i,
            pps_p_o              => pps_p_o,
            pps_led_o            => pps_led_o,
            link_ok_o            => link_ok_o
        );

end architecture struct;