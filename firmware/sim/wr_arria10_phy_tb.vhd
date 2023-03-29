-------------------------------------------------------------------------------
-- Title      : Deterministic Altera PHY wrapper - Arria 10 testbench
-- Project    : R&T Timed
-------------------------------------------------------------------------------
-- File       : wr_arria10_phy_tb.vhd
-- Author     : C.Soulet
-- Company    : IJCLab
-- Created    : 2023-01-26
-- Last update: 2023-01-26
-- Platform   : FPGA-generic
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: test bench for single channel wrapper for deterministic PHY
-------------------------------------------------------------------------------



library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--library work;
--use work.gencores_pkg.all;
--use work.disparity_gen_pkg.all;
--use work.altera_networks_pkg.all;

entity wr_arria10_phy_tb is
end wr_arria10_phy_tb;

architecture behavioral of wr_arria10_phy_tb is 

component wr_arria10_phy
  generic (
    g_tx_latch_edge : std_logic := '1';
    g_rx_latch_edge : std_logic := '0');
  port (
    clk_reconf_i : in  std_logic; -- 100 MHz
    clk_phy_i    : in  std_logic; -- feeds transmitter CMU and CRU
    ready_o      : out std_logic; -- Is the rx_rbclk valid?
    loopen_i     : in  std_logic;  -- local loopback enable (Tx->Rx), active hi
    drop_link_i  : in  std_logic; -- Kill the link?

    tx_clk_o       : out std_logic;  -- clock used for TX data;
    tx_data_i      : in  std_logic_vector(7 downto 0);   -- data input (8 bits, not 8b10b-encoded)
    tx_k_i         : in  std_logic;  -- 1 when tx_data_i contains a control code, 0 when it's a data byte
    tx_disparity_o : out std_logic;  -- disparity of the currently transmitted 8b10b code (1 = plus, 0 = minus).
    tx_enc_err_o   : out std_logic;  -- error encoding

    rx_rbclk_o    : out std_logic;  -- RX recovered clock
    rx_data_o     : out std_logic_vector(7 downto 0);  -- 8b10b-decoded data output.
    rx_k_o        : out std_logic;   -- 1 when the byte on rx_data_o is a control code
    rx_enc_err_o  : out std_logic;   -- encoding error indication
    rx_bitslide_o : out std_logic_vector(3 downto 0); -- RX bitslide indication, indicating the delay of the RX path of the transceiver (in UIs). Must be valid when rx_data_o is valid.

    pad_txp_o : out std_logic;
    pad_rxp_i : in std_logic := '0');

end component wr_arria10_phy;

  -- generic constants
constant g_tx_latch_edge : std_logic := '1';
constant g_rx_latch_edge : std_logic := '0';
      
  -- input signals
signal clk_reconf_i : std_logic:= '0';
signal clk_phy      : std_logic:= '0'; 
signal loopen_i     : std_logic:= '0';
signal drop_link_i  : std_logic:= '0';
signal tx_data_i    : std_logic_vector(7 downto 0):= (others=>'0');  
signal tx_k_i       : std_logic:= '0';
signal pad_rxp_i    : std_logic := '0';

  -- output signals
signal ready_o        : std_logic;  
signal tx_clk_o       : std_logic;
signal tx_disparity_o : std_logic;  
signal tx_enc_err_o   : std_logic;      
signal rx_rbclk_o     : std_logic;  
signal rx_data_o      : std_logic_vector(7 downto 0);  
signal rx_k_o         : std_logic; 
signal rx_enc_err_o   : std_logic; 
signal rx_bitslide_o  : std_logic_vector(3 downto 0); 
signal pad_txp_o      : std_logic;

   -- Clock period definitions
   constant CLKPHY_period     : time := 2 ns;

begin 

  DUT0: wr_arria10_phy
     generic map (
        g_tx_latch_edge => g_tx_latch_edge,
        g_rx_latch_edge => g_rx_latch_edge
     )
     port map(
        clk_reconf_i   => clk_reconf_i,
        clk_phy_i      => clk_phy,  
        ready_o        => ready_o,  
        loopen_i       => loopen_i,
        drop_link_i    => drop_link_i,

        tx_clk_o       => tx_clk_o,   
        tx_data_i      => tx_data_i,    
        tx_k_i         => tx_k_i,     
        tx_disparity_o => tx_disparity_o,
        tx_enc_err_o   => tx_enc_err_o, 

        rx_rbclk_o     =>  rx_rbclk_o, 
        rx_data_o      =>  rx_data_o,
        rx_k_o         =>  rx_k_o,    
        rx_enc_err_o   =>  rx_enc_err_o,
        rx_bitslide_o  =>  rx_bitslide_o,

        pad_txp_o      => pad_txp_o,
        pad_rxp_i      => pad_rxp_i
     ); 
 
    -- Clock process
   clk_phy_process : process
   begin
      clk_phy <= '0';
      wait for CLKPHY_period/2;
      clk_phy <= '1';
      wait for CLKPHY_period/2;
   end process;     
 end behavioral; 
