
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity ipbus_avallon_master_0 is
	generic (
		AUTO_INR_IRQ0_INTERRUPTS_USED : string := "-1";
		clockrate : string := "125 MHz"
	);
	port (
	-- Interface avallon
		avm_m0_address       : out std_logic_vector(31 downto 0);                     --   avm_m0.address
		avm_m0_read          : out std_logic;                                        --         .read
		avm_m0_waitrequest   : in  std_logic                     := '0';             --         .waitrequest
		avm_m0_readdata      : in  std_logic_vector(31 downto 0) := (others => '0'); --         .readdata
		avm_m0_readdatavalid : in  std_logic                     := '0';             --   A10_SI5345A10_SI5345      .readdatavalid
		avm_m0_write         : out std_logic;                                        --         .write
		avm_m0_writedata     : out std_logic_vector(31 downto 0);                    --         .writedata
		clock_clk            : in  std_logic                     := '0';             --    clock.clk
		reset_reset          : in  std_logic                     := '0';             --    reset.reset
		inr_irq0_irq         : in  std_logic_vector(31 downto 0) := (others => '0');		-- inr_irq0.irq
	--Interface Ibbus
		-- Write bus
  		ipb_addr					: in std_logic_vector(31 downto 0);
      ipb_wdata				: in std_logic_vector(31 downto 0);
      ipb_strobe				: in std_logic;
      ipb_write				: in std_logic;
		-- Read bus	
		ipb_rdata				: out std_logic_vector(31 downto 0);
		ipb_ack					: out std_logic;
		ipb_err					: out std_logic
	);
end entity ipbus_avallon_master_0;

architecture rtl of ipbus_avallon_master_0 is

	signal avm_m0_write_e0,avm_m0_read_e0	: std_logic;
	signal avm_m0_readdatavalid_e0			: std_logic;
	signal ipb_strobe_e0, rising_ipb_strobe: std_logic;
	signal latch_enable							: std_logic;
	
begin

	avm_m0_address(1 downto 0)	<= "00"; 
	avm_m0_write 	<= ipb_strobe and ipb_write and not (avm_m0_write_e0); 
	avm_m0_read 	<= ipb_strobe and not ipb_write and not avm_m0_read_e0;
	ipb_ack 			<= avm_m0_write_e0 or (avm_m0_read_e0 and avm_m0_readdatavalid);
	ipb_rdata		<= avm_m0_readdata;		 

	latch_enable <= avm_m0_waitrequest and not rising_ipb_strobe;
	
	process(latch_enable, ipb_wdata, ipb_addr)
	begin
		if (latch_enable = '0') then
			avm_m0_writedata 					<= ipb_wdata;
			avm_m0_address(31 downto 2)	<= ipb_addr(29 downto 0);
		end if;
	end process;	

	process(clock_clk,reset_reset)
	begin
		if reset_reset = '1' then
			avm_m0_write_e0			<= '0';
			avm_m0_read_e0				<= '0';
			avm_m0_readdatavalid_e0	<= '0';
			ipb_strobe_e0				<= '0';
		elsif (rising_edge (clock_clk)) then
			avm_m0_write_e0			<= avm_m0_write and not avm_m0_waitrequest;
			avm_m0_read_e0 			<= (avm_m0_read and not avm_m0_waitrequest) or (not avm_m0_readdatavalid_e0 and avm_m0_read_e0);
			avm_m0_readdatavalid_e0 <= avm_m0_readdatavalid and avm_m0_read_e0;
			ipb_strobe_e0				<= ipb_strobe;
		end if;
	end process;
	
	rising_ipb_strobe <= ipb_strobe and not ipb_strobe_e0;
	
end architecture rtl; 
