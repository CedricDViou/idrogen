--
-- White Rabbit Core Hands-On Course
--
-- Lesson 03: Simplest functional WR core design
--
-- Objectives:
-- - Synchronize two SPEC boards. No user data transmission yet.
--
-- Brief description:
-- The firmware contains the simplest fully functional implementation of the WR core.
-- It's purpose is to show the WRPC talking to another WRPC and synchronizing
-- with each other
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.wrcore_pkg.all;
use work.pll_pkg.all;
use work.wr_fabric_pkg.all;
use work.wishbone_pkg.all;
--use work.wr_altera_pkg.all;
use work.etherbone_pkg.all;
use work.altera_networks_pkg.all;
--use work.build_id_pkg.all;
--use work.wishbone2avalon_pkg.all;

-- Use the General Cores package (for gc_extend_pulse)
use work.gencores_pkg.all;

entity idrogen_v3_wr_ref_design_top is
    --  generic (
    --    -- Simulation mode enable parameter. Set by default (synthesis) to 0, and
    --    -- changed to non-zero in the instantiation of the top level DUT in the testbench.
    --    -- Its purpose is to reduce some internal counters/timeouts to speed up simulations.
    --    g_simulation : integer := 0
    --    );
    port (
        -- FPGA Reset input, active low.
        DEV_CLRn : in STD_LOGIC;
        -- free-running 100 MHz oscillator, or SI5338A.  See R290 or R140 for selection
        CLKUSR : in STD_LOGIC;

        ---------------------------------------------------------------------------
        -- PCIe signals
        ---------------------------------------------------------------------------

        AMC_NPERSTL             :    in       STD_LOGIC ;
        AMC_PCIE_RX             :    in       STD_LOGIC_VECTOR(3 downto 0) ;
        AMC_PCIE_TX             :    out      STD_LOGIC_VECTOR(3 downto 0) ;
        AMC_PCI_CLK             :    in       STD_LOGIC ;
        
        ---------------------------------------------------------------------------
        -- Clock signals
        ---------------------------------------------------------------------------

        AMC_REFCLK_1G : in STD_LOGIC ;
    
        -- Reference clocks from LMK
        -- Local system clock (also from LMK, but could be a fixed Xtal)
        LMK_CLKREF_2 : in STD_LOGIC;

        -- Clock input: 125 MHz LVDS reference clock, coming from the CDCM61004 PLL.
        -- The reference oscillator is a 25 MHz VCTCXO (VM53S), tunable by the
        -- DAC connected to CS0 SPI line (dac_main output of the WR Core).
        LMK_CLKREF_12 : in STD_LOGIC;

        -- Dedicated clock for the transceiver. Same physical clock as
        -- clk_125m_pllref, just coming from another output of LKM04828 PLL.
        WR_REFCLK_125 : in STD_LOGIC;

        -- Clock input, used to derive the DDMTD clock (check out the general presentation
        -- of WR for explanation of its purpose). The clock is produced by the
        -- other VCXO, tuned by the second AD5662 DAC, (which is connected to
        -- dac_helper output of the WR Core)
        WR_CLK_DMTD : in STD_LOGIC;

        -------------------------------------------------------------------------
        -- SFP pins
        -------------------------------------------------------------------------

        -- RX/TX gigabit output
        WR_SFP_RX : in STD_LOGIC;
        WR_SFP_TX : out STD_LOGIC;

        -- SFP MOD_DEF0 pin (used as a tied-to-ground SFP insertion detect line)
        WR_SFP_DET_i : in STD_LOGIC;
        -- SFP MOD_DEF1 pin (SCL line of the I2C EEPROM inside the SFP)
        WR_SFP_scl_b : inout STD_LOGIC;
        -- SFP MOD_DEF2 pin (SDA line of the I2C EEPROM inside the SFP)
        WR_SFP_sda_b : inout STD_LOGIC;
        -- SFP RATE_SELECT pin. Unused for most SFPs, in our case tied to 0.
        WR_SFP_RATE_SELECT : inout STD_LOGIC;
        -- SFP laser fault detection pin. Unused in our design.
        WR_SFP_TXFAULT : in STD_LOGIC;
        -- SFP laser disable line. In our case, tied to GND.
        WR_SFP_TxDisable : out STD_LOGIC;
        -- SFP-provided loss-of-link detection. We don't use it as Ethernet PCS
        -- has its own loss-of-sync detection mechanism.
        WR_SFP_LOS : in STD_LOGIC;

        ---------------------------------------------------------------------------
        -- Oscillator control pins
        ---------------------------------------------------------------------------

        -- A typical SPI bus shared betwen two AD5662 DACs. The first one (CS1) tunes
        -- the clk_ref oscillator, the second (CS2) - the clk_dmtd VCXO.
        WR_DAC_SCLK   : out STD_LOGIC;
        WR_DAC_DIN    : out STD_LOGIC;
        WR_DAC1_SYNCn : out STD_LOGIC;
        WR_DAC2_SYNCn : out STD_LOGIC;

        ---------------------------------------------------------------------------
        -- Miscellanous WR Core pins
        ---------------------------------------------------------------------------

        -- I2C bus connected to the EEPROM on the DIO mezzanine. This EEPROM is used
        -- for storing WR Core's configuration parameters.
        WR_SCL_FLASH_b : inout STD_LOGIC;
        WR_SDA_FLASH_b : inout STD_LOGIC;

        -- One-wire interface to DS18B20 temperature sensor, which also provides an
        -- unique serial number, that WRPC uses to assign itself a unique MAC address.
        WR_SERNUM_b : inout STD_LOGIC;

        -- UART pins (connected to the mini-USB port)
        USB_TX : in  STD_LOGIC;
        USB_RX : out STD_LOGIC;

        PPS_IN  : in  STD_LOGIC;
        PPS_OUT : out STD_LOGIC; -- looped-back by default

        TRIGGER_IN  : in  STD_LOGIC;
        TRIGGER_OUT : out STD_LOGIC; -- looped-back by default

        -------------------------------------------------------------------------
        -- leds onboard
        -------------------------------------------------------------------------
        LEDn : out STD_LOGIC_VECTOR(3 downto 0) := (others => '0')
    );
end idrogen_v3_wr_ref_design_top;

architecture rtl of idrogen_v3_wr_ref_design_top is

    -----------------------------------------------------------------------------
    -- Function declarations
    -----------------------------------------------------------------------------
    function f_pick(x : BOOLEAN; y : INTEGER; z : INTEGER) return NATURAL is
    begin
        if x
            then
            return y;
        else return z;
        end if;
    end f_pick;

    constant c_is_arria10 : BOOLEAN := True;

    -----------------------------------------------------------------------------
    -- Signals declarations
    -----------------------------------------------------------------------------
    ----------------------------------------------------------------------------------
    -- Clock networks ----------------------------------------------------------------
    ----------------------------------------------------------------------------------

    signal core_clk_25m_vcxo_i    : STD_LOGIC;
    signal core_clk_125m_pllref_i : STD_LOGIC;
    signal core_clk_125m_sfpref_i : STD_LOGIC;
    signal core_clk_125m_local_i  : STD_LOGIC;
    signal core_rstn_i            : STD_LOGIC;

    -- Non-PLL reset stuff
    signal clk_free   : STD_LOGIC;
    signal rstn_free  : STD_LOGIC;
    signal gxb_locked : STD_LOGIC;
    signal pll_rst    : STD_LOGIC;

    -- Sys PLL from clk_125m_local_i
    signal sys_locked : STD_LOGIC;
    signal clk_sys0   : STD_LOGIC;
    signal clk_sys1   : STD_LOGIC;
    signal clk_sys2   : STD_LOGIC;
    signal clk_sys3   : STD_LOGIC;
    signal clk_sys4   : STD_LOGIC;
    signal clk_sys5   : STD_LOGIC;

    signal clk_sys    : STD_LOGIC;
    signal clk_reconf : STD_LOGIC; -- 50MHz on arrai2, 100MHz on arria5, 100MHz on arria10
    signal rstn_sys   : STD_LOGIC;

    -- Ref PLL from clk_125m_pllref_i
    signal ref_locked : STD_LOGIC;
    signal clk_ref0   : STD_LOGIC;
    signal clk_ref1   : STD_LOGIC;
    signal clk_ref2   : STD_LOGIC;
    signal clk_ref3   : STD_LOGIC;
    signal clk_ref4   : STD_LOGIC;

    signal clk_ref  : STD_LOGIC;
    signal rstn_ref : STD_LOGIC;

    -- DMTD PLL from clk_20m_vcxo_i
    signal dmtd_locked : STD_LOGIC;
    signal clk_dmtd0   : STD_LOGIC;
    signal clk_dmtd    : STD_LOGIC;

    -- END OF Clock networks
    ----------------------------------------------------------------------------------
    ----------------------------------------------------------------------------------
    -- White Rabbit signals ----------------------------------------------------------
    ----------------------------------------------------------------------------------

    -- Oscillator control DAC wiring
    signal dac_hpll_load_p1 : STD_LOGIC;
    signal dac_dpll_load_p1 : STD_LOGIC;
    signal dac_hpll_data    : STD_LOGIC_VECTOR(15 downto 0);
    signal dac_dpll_data    : STD_LOGIC_VECTOR(15 downto 0);

    -- PHY wiring
    signal phy_tx_clk       : STD_LOGIC;
    signal phy_rdy          : STD_LOGIC;
    signal phy_tx_data      : STD_LOGIC_VECTOR(7 downto 0);
    signal phy_tx_k         : STD_LOGIC;
    signal phy_tx_disparity : STD_LOGIC;
    signal phy_tx_enc_err   : STD_LOGIC;
    signal phy_rx_data      : STD_LOGIC_VECTOR(7 downto 0);
    signal phy_rx_rbclk     : STD_LOGIC;
    signal phy_rx_k         : STD_LOGIC;
    signal phy_rx_enc_err   : STD_LOGIC;
    signal phy_rx_bitslide  : STD_LOGIC_VECTOR(3 downto 0);
    signal phy_rst          : STD_LOGIC;
    signal phy_loopen       : STD_LOGIC;

    signal link_act : STD_LOGIC;
    signal link_up  : STD_LOGIC;
    signal pps      : STD_LOGIC;
    signal ext_pps  : STD_LOGIC;

    signal tm_valid  : STD_LOGIC;
    signal tm_tai    : STD_LOGIC_VECTOR(39 downto 0);
    signal tm_cycles : STD_LOGIC_VECTOR(27 downto 0);

    -- END of White Rabbit signals --------------------------------------------------
    ----------------------------------------------------------------------------------

    ----------------------------------------------------------------------------------
    -- Master signals ----------------------------------------------------------------
    ----------------------------------------------------------------------------------
    signal wrc_slave_i  : t_wishbone_slave_in;
    signal wrc_slave_o  : t_wishbone_slave_out;
    signal wrc_master_i : t_wishbone_master_in;
    signal wrc_master_o : t_wishbone_master_out;
    signal eb_src_out   : t_wrf_source_out;
    signal eb_src_in    : t_wrf_source_in;
    signal eb_snk_out   : t_wrf_sink_out;
    signal eb_snk_in    : t_wrf_sink_in;

    constant c_top_masters : NATURAL := 1;
    constant c_topm_ebs    : NATURAL := 0;

    --  constant c_top_slaves     : natural := 3;
    --  constant c_tops_wrc       : natural := 0;
    --  constant c_tops_build_id  : natural := 1;
    --  constant c_tops_ebm       : natural := 2;
    constant c_top_slaves : NATURAL := 2;
    constant c_tops_wrc   : NATURAL := 0;
    constant c_tops_ebm   : NATURAL := 1;
    -- We have to specify the values for WRC as there is no generic out in vhdl
    constant c_wrcore_bridge_sdb : t_sdb_bridge := f_xwb_bridge_manual_sdb(x"0003ffff", x"00030000");

    constant c_top_layout_req : t_sdb_record_array(c_top_slaves - 1 downto 0) := (
        c_tops_wrc => f_sdb_auto_bridge(c_wrcore_bridge_sdb, true),
        c_tops_ebm => f_sdb_auto_device(c_ebm_sdb, true)
        --    c_tops_build_id  => f_sdb_auto_device(c_build_id_sdb,                      true),
    );

    constant c_top_layout : t_sdb_record_array(c_top_slaves - 1 downto 0)
    := f_sdb_auto_layout(c_top_layout_req);
    constant c_top_sdb_address : t_wishbone_address := f_sdb_auto_sdb(c_top_layout_req);
    constant c_top_bridge_sdb  : t_sdb_bridge       := f_xwb_bridge_layout_sdb(true, c_top_layout, c_top_sdb_address);

    signal top_cbar_slave_i  : t_wishbone_slave_in_array (c_top_masters - 1 downto 0);
    signal top_cbar_slave_o  : t_wishbone_slave_out_array(c_top_masters - 1 downto 0);
    signal top_cbar_master_i : t_wishbone_master_in_array(c_top_slaves - 1 downto 0);
    signal top_cbar_master_o : t_wishbone_master_out_array(c_top_slaves - 1 downto 0);
    ----------------------------------------------------------------------------------
    -- END of Master signals ---------------------------------------------------------
    ----------------------------------------------------------------------------------
    -- Misc signals
    signal pps_p    : STD_LOGIC;
    signal pps_long : STD_LOGIC;

    signal sfp_scl_o, sfp_sda_o : STD_LOGIC;
    signal fmc_scl_o, fmc_sda_o : STD_LOGIC;
    signal owr_pwren            : STD_LOGIC_VECTOR(1 downto 0);
    signal owr_en               : STD_LOGIC_VECTOR(1 downto 0);
    signal owr_in               : STD_LOGIC_VECTOR(1 downto 0);

    -- timer for leds
    signal tick_1s  : STD_LOGIC;
    signal pulse_1s : STD_LOGIC;
    signal cnt      : unsigned(31 downto 0);

    signal tick_1s2  : STD_LOGIC;
    signal pulse_1s2 : STD_LOGIC;
    signal cnt2      : unsigned(31 downto 0);

    signal tick_1s3  : STD_LOGIC;
    signal pulse_1s3 : STD_LOGIC;
    signal cnt3      : unsigned(31 downto 0);

    signal tick_1s4  : STD_LOGIC;
    signal pulse_1s4 : STD_LOGIC;
    signal cnt4      : unsigned(31 downto 0);

    component ISSP is
        port (
            source : out STD_LOGIC_VECTOR(0 downto 0);                  -- source
            probe  : in STD_LOGIC_VECTOR(8 downto 0) := (others => 'X') -- probe
        );
    end component ISSP;

    signal probe : STD_LOGIC_VECTOR(8 downto 0);

    ----------------------------------------------------------------------------------
    -- PCIe Qsys signals -------------------------------------------------------------
    ----------------------------------------------------------------------------------

    signal PCIE_RX          : STD_LOGIC;
    signal PCIE_TX          : STD_LOGIC;
    signal WR_RX            : STD_LOGIC;
    signal WR_TX            : STD_LOGIC;
    signal pio_port         : STD_LOGIC_VECTOR(31 downto 0);
    signal hip_ctrl_test_in : STD_LOGIC_VECTOR(31 downto 0);
    

    component pcie_qsys is
		port (
			pcie_refclk_clk                  : in  STD_LOGIC                     := 'X';             -- clk
			pcie_npor_npor                   : in  STD_LOGIC                     := 'X';             -- npor
			pcie_npor_pin_perst              : in  STD_LOGIC                     := 'X';             -- pin_perst
			pcie_hip_serial_rx_in0           : in  STD_LOGIC                     := 'X';             -- rx_in0
			pcie_hip_serial_rx_in1           : in  STD_LOGIC                     := 'X';             -- rx_in1
			pcie_hip_serial_rx_in2           : in  STD_LOGIC                     := 'X';             -- rx_in2
			pcie_hip_serial_rx_in3           : in  STD_LOGIC                     := 'X';             -- rx_in3
			pcie_hip_serial_tx_out0          : out STD_LOGIC;                                        -- tx_out0
			pcie_hip_serial_tx_out1          : out STD_LOGIC;                                        -- tx_out1
			pcie_hip_serial_tx_out2          : out STD_LOGIC;                                        -- tx_out2
			pcie_hip_serial_tx_out3          : out STD_LOGIC;                                        -- tx_out3
            pcie_hip_ctrl_test_in            : in  STD_LOGIC_VECTOR(31 downto 0) := (others => 'X'); -- test_in
            pio_external_connection_export   : out STD_LOGIC_VECTOR(31 downto 0);                    -- out_port
			uart_external_connection_rxd     : in  STD_LOGIC                     := 'X';             -- rxd
			uart_external_connection_txd     : out STD_LOGIC                                         -- txd
		);
	end component pcie_qsys;

    ----------------------------------------------------------------------------------
    -- JTAG to UART ------------------------------------------------------------------
    ----------------------------------------------------------------------------------

    signal JTAG_RX          : STD_LOGIC;
    signal JTAG_TX          : STD_LOGIC;

    component jtag_uart_qsys is
		port (
			clk_clk       : in  std_logic := 'X'; -- clk
			jtag_uart_rxd : in  std_logic := 'X'; -- rxd
			jtag_uart_txd : out std_logic;        -- txd
			reset_reset_n : in  std_logic := 'X'  -- reset
		);
	end component jtag_uart_qsys;

begin --rtl
    ----------------------------------------------------------------------------------
    -- Reset and PLLs ----------------------------------------------------------------
    ----------------------------------------------------------------------------------

    -- We need at least one off-chip free running clock to setup PLLs
    clk_free <= CLKUSR;

    core_clk_125m_pllref_i <= WR_REFCLK_125;
    core_clk_125m_sfpref_i <= WR_REFCLK_125;
    core_clk_125m_local_i  <= WR_REFCLK_125;
    core_rstn_i            <= DEV_CLRn;
    gxb_locked             <= '1';
    
    -- pcie_hip_ctrl_test_in  <= '392';

    reset : altera_reset
        generic map(
            g_plls   => 4,
            g_clocks => 3,
            g_areset => f_pick(c_is_arria10, 100, 1) * 1024,
            g_stable => f_pick(c_is_arria10, 100, 1) * 1024
        )
        port map(
            clk_free_i    => clk_free,
            rstn_i        => core_rstn_i,
            pll_lock_i(0) => dmtd_locked,
            pll_lock_i(1) => ref_locked,
            pll_lock_i(2) => sys_locked,
            pll_lock_i(3) => gxb_locked,
            pll_arst_o    => pll_rst,
            clocks_i(0)   => clk_free,
            clocks_i(1)   => clk_sys,
            clocks_i(2)   => clk_ref,
            rstn_o(0)     => rstn_free,
            rstn_o(1)     => rstn_sys,
            rstn_o(2)     => rstn_ref
        );

    u0 : component ISSP
        port map(
            source => open, -- sources.source
            probe  => probe --  probes.probe
        );

    probe <= core_rstn_i & pll_rst & rstn_ref & rstn_sys & rstn_free & pulse_1s4 & pulse_1s3 & pulse_1s2 & pulse_1s;

    dmtd_inst : dmtd_pll10_hydrogen
        port map(
            rst      => pll_rst,
            refclk   => WR_CLK_DMTD, --  125  MHz
            outclk_0 => clk_dmtd,    --  62.5MHz
            locked   => dmtd_locked
        );

    sys_inst : sys_pll10 
        port map(
            rst      => pll_rst,
            refclk   => core_clk_125m_local_i, -- 125  Mhz
            outclk_0 => clk_sys,               --  62.5MHz
            outclk_1 => clk_reconf,            -- 100  MHz +0   ns
            outclk_2 => clk_sys2,              --  20  MHz
            outclk_3 => clk_sys3,              --  10  MHz
            outclk_4 => clk_sys4,              -- 100  MHz +0.5 ns
            outclk_5 => clk_sys5,              -- 100  MHz +1.0 ns
            locked   => sys_locked
        );

    ref_inst : ref_pll10 
        port map(
            rst      => pll_rst,
            refclk   => core_clk_125m_pllref_i, -- 125 MHz
            outclk_0 => clk_ref,                -- 125 MHz
            locked   => ref_locked
        );

    -- END OF Reset and PLLs
    ----------------------------------------------------------------------------------
    -----------------------------------------------------------------------------
    -- The WR Core part. The simplest functional instantiation.
    -----------------------------------------------------------------------------

    U_The_WR_Core : xwr_core
        generic map(
            g_simulation                => 0,
            g_phys_uart                 => true,
            g_virtual_uart              => true,
            g_with_external_clock_input => true,
            g_aux_clks                  => 1,
            g_ep_rxbuf_size             => 1024,
            g_dpram_initf               => "../../../ip_cores/wrpc-sw/wrc.mif",
            g_dpram_size                => 131072/4,
            g_interface_mode            => PIPELINED,
            g_address_granularity       => BYTE,
            g_aux_sdb                   => c_etherbone_sdb
        )
        port map(
            -- Clocks & resets connections
            clk_sys_i  => clk_sys,
            clk_dmtd_i => clk_dmtd,
            clk_ref_i  => clk_ref,
            clk_ext_i  => TRIGGER_IN,
            pps_ext_i  => PPS_IN,
            rst_n_i    => rstn_sys,

            -- PHY connections
            phy_ref_clk_i      => phy_tx_clk,
            phy_rdy_i          => phy_rdy,
            phy_tx_data_o      => phy_tx_data,
            phy_tx_k_o(0)      => phy_tx_k,
            phy_tx_disparity_i => phy_tx_disparity,
            phy_tx_enc_err_i   => phy_tx_enc_err,
            phy_rx_data_i      => phy_rx_data,
            phy_rx_rbclk_i     => phy_rx_rbclk,
            phy_rx_k_i(0)      => phy_rx_k,
            phy_rx_enc_err_i   => phy_rx_enc_err,
            phy_rx_bitslide_i  => phy_rx_bitslide,
            phy_rst_o          => phy_rst,
            phy_loopen_o       => phy_loopen,

            -- Oscillator control DACs connections
            dac_hpll_load_p1_o => dac_hpll_load_p1,
            dac_hpll_data_o    => dac_hpll_data,
            dac_dpll_load_p1_o => dac_dpll_load_p1,
            dac_dpll_data_o    => dac_dpll_data,

            slave_i      => wrc_slave_i,
            slave_o      => wrc_slave_o,
            aux_master_o => wrc_master_o,
            aux_master_i => wrc_master_i,
            wrf_src_o    => eb_snk_in,
            wrf_src_i    => eb_snk_out,
            wrf_snk_o    => eb_src_in,
            wrf_snk_i    => eb_src_out,

            -- Miscellanous pins
            -- uart_rxd_i => WR_TX_from_UART,      -- WR UART RX (input)
            -- uart_txd_o => WR_RX_to_UART,        -- WR UART TX (output)
            uart_rxd_i => WR_RX,
            uart_txd_o => WR_TX,

            scl_o => fmc_scl_o,
            scl_i => WR_SCL_FLASH_b,
            sda_o => fmc_sda_o,
            sda_i => WR_SDA_FLASH_b,

            sfp_scl_o => sfp_scl_o,
            sfp_scl_i => WR_SFP_scl_b,
            sfp_sda_o => sfp_sda_o,
            sfp_sda_i => WR_SFP_sda_b,

            sfp_det_i => WR_SFP_DET_i,

            led_link_o => link_up,
            led_act_o  => link_act,

            owr_pwren_o => owr_pwren,
            owr_en_o    => owr_en,
            owr_i       => owr_in,

            -- The PPS output, which we'll drive to the DIO mezzanine channel 1.
            pps_p_o   => pps_p,
            pps_led_o => pps_long
        );

    eb : eb_master_slave_wrapper
        generic map(
            g_with_master     => false,
            g_ebs_sdb_address => (x"00000000" & c_top_sdb_address)
        )
        port map(
            clk_i           => clk_sys,
            nRst_i          => rstn_sys,
            snk_i           => eb_snk_in,
            snk_o           => eb_snk_out,
            src_o           => eb_src_out,
            src_i           => eb_src_in,
            ebs_cfg_slave_o => wrc_master_i,
            ebs_cfg_slave_i => wrc_master_o,
            ebs_wb_master_o => top_cbar_slave_i (c_topm_ebs),
            ebs_wb_master_i => top_cbar_slave_o (c_topm_ebs),
            ebm_wb_slave_i  => top_cbar_master_o(c_tops_ebm),
            ebm_wb_slave_o  => top_cbar_master_i(c_tops_ebm)
        );

    top_bar : xwb_sdb_crossbar
        generic map(
            g_num_masters => c_top_masters,
            g_num_slaves  => c_top_slaves,
            g_registered  => true,
            g_wraparound  => true,
            g_layout      => c_top_layout,
            g_sdb_addr    => c_top_sdb_address)
        port map(
            clk_sys_i => clk_sys,
            rst_n_i   => rstn_sys,
            slave_i   => top_cbar_slave_i,
            slave_o   => top_cbar_slave_o,
            master_i  => top_cbar_master_i,
            master_o  => top_cbar_master_o
        );
    
    top2wrc : xwb_register_link
        port map(
            clk_sys_i => clk_sys,
            rst_n_i   => rstn_sys,
            slave_i   => top_cbar_master_o(c_tops_wrc),
            slave_o   => top_cbar_master_i(c_tops_wrc),
            master_i  => wrc_slave_o,
            master_o  => wrc_slave_i
        );

    -----------------------------------------------------------------------------
    -- Dual channel SPI DAC driver
    -----------------------------------------------------------------------------

    U_DAC_ARB : spec_serial_dac_arb
        generic map(
            g_invert_sclk    => false, -- configured for 2xAD5662. Don't change the parameters.
            g_num_extra_bits => 8
        )
        port map(
            clk_i   => clk_sys,
            rst_n_i => rstn_sys,

            -- DAC 1 controls the main (clk_ref) oscillator
            val1_i  => dac_dpll_data,
            load1_i => dac_dpll_load_p1,

            -- DAC 2 controls the helper (clk_ddmtd) oscillator
            val2_i  => dac_hpll_data,
            load2_i => dac_hpll_load_p1,

            dac_cs_n_o(0) => WR_DAC1_SYNCn,
            dac_cs_n_o(1) => WR_DAC2_SYNCn,
            dac_sclk_o    => WR_DAC_SCLK,
            dac_din_o     => WR_DAC_DIN
        );

    -----------------------------------------------------------------------------
    -- Gigabit Ethernet PHY for Arria 10.
    -----------------------------------------------------------------------------

    phy : entity work.wr_arria10_phy
        port map(
            clk_reconf_i   => clk_free, -- clk_reconf,
            clk_phy_i      => core_clk_125m_sfpref_i,
            ready_o        => phy_rdy,
            loopen_i       => phy_loopen,
            drop_link_i    => phy_rst,
            tx_clk_o       => phy_tx_clk,
            tx_data_i      => phy_tx_data,
            tx_k_i         => phy_tx_k,
            tx_disparity_o => phy_tx_disparity,
            tx_enc_err_o   => phy_tx_enc_err,
            rx_rbclk_o     => phy_rx_rbclk,
            rx_data_o      => phy_rx_data,
            rx_k_o         => phy_rx_k,
            rx_enc_err_o   => phy_rx_enc_err,
            rx_bitslide_o  => phy_rx_bitslide,
            pad_txp_o      => WR_SFP_TX,
            pad_rxp_i      => WR_SFP_RX
        );

    -- The SFP is permanently enabled
    WR_SFP_TxDisable   <= '0';
    WR_SFP_RATE_SELECT <= '0';

    -- Open-drain driver for the Onewire bus
    WR_SERNUM_b <= owr_pwren(0) when (owr_pwren(0) = '1' or owr_en(0) = '1') else 'Z';
    owr_in(0)   <= WR_SERNUM_b;
    owr_in(1)   <= '0';

    -- Open-drain drivers for the I2C busses
    WR_SCL_FLASH_b <= '0' when fmc_scl_o = '0' else 'Z';
    WR_SDA_FLASH_b <= '0' when fmc_sda_o = '0' else 'Z';

    WR_SFP_scl_b <= '0' when sfp_scl_o = '0' else 'Z';
    WR_SFP_sda_b <= '0' when sfp_sda_o = '0' else 'Z';

    PPS_OUT <= pps_long;
    LEDn(0) <= not pulse_1s; -- led D21
    LEDn(1) <= not link_up;  -- led D21
    -- LEDn(2) <= not link_act; -- led D20
    LEDn(3) <= not pps_long; -- led D19
    --  LEDn(1) <= not pulse_1s2;  -- led D20
    --  LEDn(2) <= not pulse_1s3;  -- led D19
    --  LEDn(3) <= not pulse_1s4;  -- led D18
    --
    --
    -----------------------------------------------------------------------------------
    -- timer for leds
    -----------------------------------------------------------------------------------
    led_blink : process (clk_free, rstn_free)
    begin
        if rstn_free = '0' then
            cnt      <= (others => '0');
            tick_1s  <= '0';
            pulse_1s <= '0';
        elsif rising_edge(clk_free) then
            cnt     <= cnt + 1;
            tick_1s <= '0';
            if cnt = 100000000/2 - 1 then
                cnt     <= (others => '0');
                tick_1s <= '1';
            end if;
            if tick_1s = '1' then
                pulse_1s <= not pulse_1s;
            end if;
        end if;
    end process led_blink;


    -----------------------------------------------------------------------------------
    -- WR Uart to PCIe
    -----------------------------------------------------------------------------------

    -- U_The_WR_Core : xwr_core
    -- |__ uart_rxd_i (input)   => WR_RX
    -- |__ uart_txd_o (output)  => WR_TX

    -- pcie_qsys_inst : pcie_qsys
    -- |__ uart_external_connection_rxd (input)   => PCIE_RX
	-- |__ uart_external_connection_txd (output)  => PCIE_TX

    -- Mini-USB port UART
    -- |__ USB_TX (input)
    -- |__ USB_RX (output)

    -- PCIe settings 
    hip_ctrl_test_in    <= 32x"188";

    -- PIO turning on/off LED
    LEDn(2)             <= pio_port(0);
    
    -- UART connections between WR, PCIe and USB
    WR_RX   <=  USB_TX  when pio_port(1 downto 0) = "00" else
                PCIE_TX when pio_port(1 downto 0) = "01" else
                JTAG_TX when pio_port(1 downto 0) = "10";

    USB_RX              <= WR_TX;
    PCIE_RX             <= WR_TX;
    JTAG_RX             <= WR_TX;

    pcie_qsys_inst : component pcie_qsys
		port map (
			pcie_refclk_clk                  => AMC_PCI_CLK,        --              pcie_refclk.clk
			pcie_npor_npor                   => DEV_CLRn,           --                pcie_npor.npor
			pcie_npor_pin_perst              => AMC_NPERSTL,        --                         .pin_perst
			pcie_hip_ctrl_test_in            => hip_ctrl_test_in,   --            pcie_hip_ctrl.test_in
			pcie_hip_serial_rx_in0           => AMC_PCIE_RX(0),     --          pcie_hip_serial.rx_in0
			pcie_hip_serial_rx_in1           => AMC_PCIE_RX(1),     --                         .rx_in1
			pcie_hip_serial_rx_in2           => AMC_PCIE_RX(2),     --                         .rx_in2
			pcie_hip_serial_rx_in3           => AMC_PCIE_RX(3),     --                         .rx_in3
			pcie_hip_serial_tx_out0          => AMC_PCIE_TX(0),     --                         .tx_out0
			pcie_hip_serial_tx_out1          => AMC_PCIE_TX(1),     --                         .tx_out1
			pcie_hip_serial_tx_out2          => AMC_PCIE_TX(2),     --                         .tx_out2
			pcie_hip_serial_tx_out3          => AMC_PCIE_TX(3),     --                         .tx_out3
			pio_external_connection_export   => pio_port,           --  pio_external_connection.out_port
			uart_external_connection_rxd     => PCIE_RX,            -- uart_external_connection.rxd
			uart_external_connection_txd     => PCIE_TX             --                         .txd
		);

	jtag_uart_qsys_inst : component jtag_uart_qsys
		port map (
			clk_clk       => AMC_REFCLK_1G, --       clk.clk
			jtag_uart_rxd => JTAG_RX,       -- jtag_uart.rxd
			jtag_uart_txd => JTAG_TX,       --          .txd
			reset_reset_n => DEV_CLRn       --     reset.reset
		);

end rtl;