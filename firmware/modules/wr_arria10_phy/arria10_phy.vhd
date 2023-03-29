
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity arria10_phy is
	port (
		clk_reconf_i                : in  std_logic;
		clk_reconf_rst_i            : in  std_logic;
		tx_ready                    : out std_logic;                                         --                    tx_ready.export
		rx_ready                    : out std_logic;                                         --                    rx_ready.export
		pll_ref_clk                 : in  std_logic_vector(0 downto 0)   := (others => '0'); --                 pll_ref_clk.clk
		tx_serial_data              : out std_logic_vector(0 downto 0);                      --              tx_serial_data.export
		tx_bitslipboundaryselect    : in  std_logic_vector(4 downto 0)   := (others => '0'); --    tx_bitslipboundaryselect.export
		pll_locked                  : out std_logic_vector(0 downto 0);                      --                  pll_locked.export
		rx_serial_data              : in  std_logic_vector(0 downto 0)   := (others => '0'); --              rx_serial_data.export
		rx_bitslipboundaryselectout : out std_logic_vector(4 downto 0);                      -- rx_bitslipboundaryselectout.export
		tx_clkout                   : out std_logic_vector(0 downto 0);                      --                   tx_clkout.export
		rx_clkout                   : out std_logic_vector(0 downto 0);                      --                   rx_clkout.export
		tx_parallel_data            : in  std_logic_vector(9 downto 0)   := (others => '0'); --            tx_parallel_data.export
		rx_parallel_data            : out std_logic_vector(9 downto 0)                      --            rx_parallel_data.export
	);
end entity arria10_phy;

architecture rtl of arria10_phy is

	component xcvr_phy_reset_controller is
		port (
			clock              : in  std_logic                    := 'X';             -- clk
			reset              : in  std_logic                    := 'X';             -- reset
			pll_powerdown      : out std_logic_vector(0 downto 0);                    -- pll_powerdown
			tx_analogreset     : out std_logic_vector(0 downto 0);                    -- tx_analogreset
			tx_digitalreset    : out std_logic_vector(0 downto 0);                    -- tx_digitalreset
			tx_ready           : out std_logic_vector(0 downto 0);                    -- tx_ready
			pll_locked         : in  std_logic_vector(0 downto 0) := (others => 'X'); -- pll_locked
			pll_select         : in  std_logic_vector(0 downto 0) := (others => 'X'); -- pll_select
			tx_cal_busy        : in  std_logic_vector(0 downto 0) := (others => 'X'); -- tx_cal_busy
			rx_analogreset     : out std_logic_vector(0 downto 0);                    -- rx_analogreset
			rx_digitalreset    : out std_logic_vector(0 downto 0);                    -- rx_digitalreset
			rx_ready           : out std_logic_vector(0 downto 0);                    -- rx_ready
			rx_is_lockedtodata : in  std_logic_vector(0 downto 0) := (others => 'X'); -- rx_is_lockedtodata
			rx_cal_busy        : in  std_logic_vector(0 downto 0) := (others => 'X'); -- rx_cal_busy
			pll_cal_busy       : in  std_logic_vector(0 downto 0) := (others => 'X')  -- pll_cal_busy
		);
	end component xcvr_phy_reset_controller;

   component altera_xcvr_native_phy_a10 is
      port (
            reconfig_write            : in  std_logic_vector(0 downto 0)   := (others => 'X'); -- write
            reconfig_read             : in  std_logic_vector(0 downto 0)   := (others => 'X'); -- read
            reconfig_address          : in  std_logic_vector(9 downto 0)   := (others => 'X'); -- address
            reconfig_writedata        : in  std_logic_vector(31 downto 0)  := (others => 'X'); -- writedata
            reconfig_readdata         : out std_logic_vector(31 downto 0);                     -- readdata
            reconfig_waitrequest      : out std_logic_vector(0 downto 0);                      -- waitrequest
            reconfig_clk              : in  std_logic_vector(0 downto 0)   := (others => 'X'); -- clk
            reconfig_reset            : in  std_logic_vector(0 downto 0)   := (others => 'X'); -- reset
            rx_analogreset            : in  std_logic_vector(0 downto 0)   := (others => 'X'); -- rx_analogreset
            rx_cal_busy               : out std_logic_vector(0 downto 0);                      -- rx_cal_busy
            rx_cdr_refclk0            : in  std_logic                      := 'X';             -- clk
            rx_clkout                 : out std_logic_vector(0 downto 0);                      -- clk
            rx_coreclkin              : in  std_logic_vector(0 downto 0)   := (others => 'X'); -- clk
            rx_digitalreset           : in  std_logic_vector(0 downto 0)   := (others => 'X'); -- rx_digitalreset
            rx_is_lockedtodata        : out std_logic_vector(0 downto 0);                      -- rx_is_lockedtodata
            rx_parallel_data          : out std_logic_vector(9 downto 0);                      -- rx_parallel_data
            rx_patterndetect          : out std_logic;                                         -- rx_patterndetect
            rx_serial_data            : in  std_logic_vector(0 downto 0)   := (others => 'X'); -- rx_serial_data
            rx_std_bitslipboundarysel : out std_logic_vector(4 downto 0);                      -- rx_std_bitslipboundarysel
            rx_syncstatus             : out std_logic;                                         -- rx_syncstatus
            tx_analogreset            : in  std_logic_vector(0 downto 0)   := (others => 'X'); -- tx_analogreset
            tx_cal_busy               : out std_logic_vector(0 downto 0);                      -- tx_cal_busy
            tx_clkout                 : out std_logic_vector(0 downto 0);                      -- clk
            tx_coreclkin              : in  std_logic_vector(0 downto 0)   := (others => 'X'); -- clk
            tx_digitalreset           : in  std_logic_vector(0 downto 0)   := (others => 'X'); -- tx_digitalreset
            tx_parallel_data          : in  std_logic_vector(9 downto 0)   := (others => 'X'); -- tx_parallel_data
            tx_serial_clk0            : in  std_logic_vector(0 downto 0)   := (others => 'X'); -- clk
            tx_serial_data            : out std_logic_vector(0 downto 0);                      -- tx_serial_data
            tx_std_bitslipboundarysel : in  std_logic_vector(4 downto 0)   := (others => 'X'); -- tx_std_bitslipboundarysel
            unused_rx_parallel_data   : out std_logic_vector(115 downto 0);                    -- unused_rx_parallel_data
            unused_tx_parallel_data   : in  std_logic_vector(117 downto 0) := (others => 'X')  -- unused_tx_parallel_data
        );
    end component altera_xcvr_native_phy_a10;


	
	
	component ATX_pll_125_to_625 is
			port (
					pll_powerdown : in  std_logic := 'X'; -- pll_powerdown
					pll_refclk0   : in  std_logic := 'X'; -- clk
					tx_serial_clk : out std_logic;        -- clk
					pll_locked    : out std_logic;        -- pll_locked
					pll_cal_busy  : out std_logic;        -- pll_cal_busy
					reconfig_clk0         : in  std_logic                     := 'X';             -- clk
					reconfig_reset0       : in  std_logic                     := 'X';             -- reset
					reconfig_write0       : in  std_logic                     := 'X';             -- write
					reconfig_read0        : in  std_logic                     := 'X';             -- read
					reconfig_address0     : in  std_logic_vector(9 downto 0)  := (others => 'X'); -- address
					reconfig_writedata0   : in  std_logic_vector(31 downto 0) := (others => 'X')  -- writedata
			);
	end component ATX_pll_125_to_625;

	
	component altera_a10_xcvr_clock_module is
			port (
					clk_in : in  std_logic := 'X'
			);
	end component altera_a10_xcvr_clock_module;

	
	
  signal rx_analogreset     : std_logic_vector(0 downto 0);
  signal rx_digitalreset    : std_logic_vector(0 downto 0);
  signal tx_analogreset     : std_logic_vector(0 downto 0);
  signal tx_digitalreset    : std_logic_vector(0 downto 0);
  signal rx_is_lockedtodata : std_logic_vector(0 downto 0);
  signal rx_cal_busy        : std_logic_vector(0 downto 0);
  signal tx_cal_busy        : std_logic_vector(0 downto 0);

  signal tx_serial_clk    : std_logic_vector(0 downto 0);
  signal pll_powerdown    : std_logic_vector(0 downto 0);
  signal pll_locked_i     : std_logic_vector(0 downto 0);
  signal pll_cal_busy     : std_logic_vector(0 downto 0);

  signal rx_clkout_i      : std_logic_vector(0 downto 0);
  signal tx_clkout_i      : std_logic_vector(0 downto 0);
  
begin

  pll_locked <= pll_locked_i;
  rx_clkout  <= rx_clkout_i;
  tx_clkout  <= tx_clkout_i;

  
  -- Error (18108): Can't place multiple pins assigned to pin location Pin_&lt;pin_name&gt;
  -- If you want to use CLKUSR for Transceiver IP and/or EMIF IPs calibration as well as user IO, the following qsf assignment lifts the restriction
  -- set_global_assignment -name AUTO_RESERVE_CLKUSR_FOR_CALIBRATION OFF
  -- A 100-125MHz clock must be supplied to the pin for successful calibration of the respective IP.
  -- Additionally if using the Transceiver Reset Sequencer and the CLKUSR pin in user mode, you will need to instantiate the altera_a10_xcvr_clock_module.
  -- Refer to Arria 10 Transceiver PHY User Guide (PDF) for more details:
  -- altera_a10_xcvr_clock_module reset_clock (.clk_in(mgmt_clk));
  --reset_clock : component altera_a10_xcvr_clock_module
  --    port map (
  --       clk_in => clk_reconf_i
	--   );
	 
  
	U_rst_ctrl : component xcvr_phy_reset_controller
		port map (
			clock              => clk_reconf_i,
			reset              => clk_reconf_rst_i,
			pll_powerdown      => pll_powerdown,
			tx_analogreset     => tx_analogreset,
			tx_digitalreset    => tx_digitalreset,
			tx_ready(0)        => tx_ready,
			pll_locked         => pll_locked_i,
			pll_select         => "0",
			tx_cal_busy        => tx_cal_busy,
			rx_analogreset     => rx_analogreset,
			rx_digitalreset    => rx_digitalreset,
			rx_ready(0)        => rx_ready,
			rx_is_lockedtodata => rx_is_lockedtodata,
			rx_cal_busy        => rx_cal_busy,
			pll_cal_busy       => pll_cal_busy
		);


		U_ATX_PLL : component ATX_pll_125_to_625
				port map (
						pll_powerdown => pll_powerdown(0),
						pll_refclk0   => pll_ref_clk(0),
						tx_serial_clk => tx_serial_clk(0),
						pll_locked    => pll_locked_i(0),
						pll_cal_busy  => pll_cal_busy(0),
						reconfig_clk0         => clk_reconf_i,
						reconfig_reset0       => clk_reconf_rst_i,
						reconfig_write0       => '0',
						reconfig_read0        => '0',
						reconfig_address0     => (others => '0'),
						reconfig_writedata0   => (others => '0')
				);


		U_The_PHY : component altera_xcvr_native_phy_a10
			port map (
            reconfig_write            => "0",
            reconfig_read             => "0",
            reconfig_address          => (others => '0'),
            reconfig_writedata        => (others => '0'),
            reconfig_readdata         => open,
            reconfig_waitrequest      => open,
            reconfig_clk(0)           => clk_reconf_i,
            reconfig_reset(0)         => clk_reconf_rst_i,
				rx_analogreset            => rx_analogreset,
				rx_cal_busy               => rx_cal_busy,
				rx_cdr_refclk0            => pll_ref_clk(0),
				rx_clkout                 => rx_clkout_i,
				rx_coreclkin              => rx_clkout_i,
				rx_digitalreset           => rx_digitalreset,
            rx_is_lockedtodata        => rx_is_lockedtodata,
				rx_parallel_data          => rx_parallel_data,
				rx_patterndetect          => open,
				rx_serial_data            => rx_serial_data,
				rx_std_bitslipboundarysel => rx_bitslipboundaryselectout,
				rx_syncstatus             => open,
				tx_analogreset            => tx_analogreset,
				tx_cal_busy               => tx_cal_busy,
				tx_clkout                 => tx_clkout_i,
				tx_coreclkin              => tx_clkout_i,
				tx_digitalreset           => tx_digitalreset,
				tx_parallel_data          => tx_parallel_data,
				tx_serial_clk0            => tx_serial_clk,
				tx_serial_data            => tx_serial_data,
				tx_std_bitslipboundarysel => tx_bitslipboundaryselect,
				unused_rx_parallel_data   => open,
				unused_tx_parallel_data   => open
			);
			
			
			
			
end architecture rtl; -- of arria10_phy
