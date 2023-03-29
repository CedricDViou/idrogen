
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity arria10_phy_tb is
end arria10_phy_tb;

architecture behavioral of arria10_phy_tb is 

    component arria10_phy is
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
    end component arria10_phy;

    -- input signals
    signal	clk_reconf                  : std_logic:= '0';
    signal	clk_reconf_rst              : std_logic:= '0'; 
    signal	pll_ref_clk                 : std_logic_vector(0 downto 0)   := (others => '0'); 
    signal	tx_bitslipboundaryselect    : std_logic_vector(4 downto 0)   := (others => '0'); 
    signal	rx_serial_data              : std_logic_vector(0 downto 0)   := (others => '0');             				
    signal	tx_parallel_data            : std_logic_vector(9 downto 0)   := (others => '0'); 
		
    -- output signals	

    signal	tx_ready                    : std_logic;                                         
    signal	rx_ready                    : std_logic;    
    signal	tx_serial_data              : std_logic_vector(0 downto 0);  
    signal	pll_locked                  : std_logic_vector(0 downto 0); 
    signal	rx_bitslipboundaryselectout : std_logic_vector(4 downto 0);                      
    signal	tx_clkout                   : std_logic_vector(0 downto 0);                      
    signal	rx_clkout                   : std_logic_vector(0 downto 0);                      
    signal	rx_parallel_data            : std_logic_vector(9 downto 0); 

    -- Clock period definitions
    constant CLKUSR_period     : time := 2 ns;    

    begin

    DUT: arria10_phy
	port map(
		clk_reconf_i                => clk_reconf,
		clk_reconf_rst_i            => clk_reconf_rst,
		tx_ready                    => tx_ready,                                        
		rx_ready                    => rx_ready,                                         
		pll_ref_clk                 => pll_ref_clk, 
		tx_serial_data              => tx_serial_data,                      
		tx_bitslipboundaryselect    => tx_bitslipboundaryselect, 
		pll_locked                  => pll_locked,                      
		rx_serial_data              => rx_serial_data, 
		rx_bitslipboundaryselectout => rx_bitslipboundaryselectout,                      
		tx_clkout                   => tx_clkout,                      
		rx_clkout                   => rx_clkout,                      
		tx_parallel_data            => tx_parallel_data, 
		rx_parallel_data            => rx_parallel_data                     
	);     
				
    -- Clock process
    clk_usr_process : process
    begin
      clk_reconf <= '0';
      wait for CLKUSR_period/2;
      clk_reconf <= '1';
      wait for CLKUSR_period/2;
    end process;  
    
        -- Clock process
    clk_ref_process : process
    begin
      pll_ref_clk(0) <= '0';
      wait for CLKUSR_period/2;
      pll_ref_clk(0)<= '1';
      wait for CLKUSR_period/2;
    end process;  		
					
						
end behavioral; 
