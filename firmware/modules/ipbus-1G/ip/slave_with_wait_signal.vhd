-- new_component.vhd

-- This file was auto-generated as a prototype implementation of a module
-- created in component editor.  It ties off all outputs to ground and
-- ignores all inputs.  It needs to be edited to make it do something
-- useful.
-- 
-- This file will not be automatically regenerated.  You should check it in
-- to your version control system if you want to keep it.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity slave_with_wait_signal is
	port (
		avalon_slave_address     : in  std_logic_vector(1 downto 0) := (others => '0'); -- avalon_slave.address
		avalon_slave_read        : in  std_logic                     := '0';             --             .read
		avalon_slave_readdata    : out std_logic_vector(31 downto 0);                    --             .readdata
		avalon_slave_waitrequest : out std_logic;                                        --             .waitrequest
		avalon_slave_write       : in  std_logic                     := '0';             --             .write
		avalon_slave_writedata   : in  std_logic_vector(31 downto 0) := (others => '0'); --             .writedata
		clock                    : in  std_logic                     := '0';             --        clock.clk
		reset                    : in  std_logic                     := '0'              --        reset.reset
	);
end entity slave_with_wait_signal;

architecture rtl of slave_with_wait_signal is

	signal reg1, reg2, reg3, reg4 : std_logic_vector(31 downto 0) := (others => '0');
	signal wait_state : integer range 0 to 3;
	constant param_wait : integer := 2;
	
begin	

	process (clock,reset)
	begin
	   if reset = '1' then
			reg1 <= (others => '0');
			reg2 <= (others => '0');
			reg3 <= (others => '0');
			reg4 <= (others => '0');
		   wait_state <= 0;
		elsif (rising_edge (clock)) then 
			if avalon_slave_write = '1' then
				reg1 <= avalon_slave_writedata;
				reg2 <= reg1;
				reg3 <= reg2;
				reg4 <= reg3;
			elsif avalon_slave_read = '1' then
				if avalon_slave_waitrequest = '0' then
					reg1 <= (others => '0');
					reg2 <= reg1;
					reg3 <= reg2;
					reg4 <= reg3;
					wait_state <= 0;
				else wait_state <= wait_state + 1;
				end if;
			end if;
		end if;
	end process;
	
	process (wait_state, avalon_slave_read)
	begin
		if avalon_slave_read = '1' then
			if wait_state /= param_wait then
				avalon_slave_waitrequest <= '1';
				avalon_slave_readdata <= (others => '0');
			else 
				avalon_slave_waitrequest <= '0';
				avalon_slave_readdata <= reg4;
			end if;
		else
			avalon_slave_waitrequest <= '0';
			avalon_slave_readdata <= (others => '0');
		end if;
	end process;
		
end architecture rtl; -- of new_component
