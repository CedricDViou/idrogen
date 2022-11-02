--Interface Ipbus Qsys développée par E. Plaige le 09/06/2021.
--Cette interface n'utilise pas les deux bits 0 et 1  de l'adressage, puique l'interface utilisateur Ipbus
--ne gère que les mots de 32 bits, attention donc à l'adresse utilisée dans l'Ipbus qui doit etre celle de Qsys
--divisée par 4. Cette interface ne gère pas le mode Pipelined, ni le mode Burst.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity ipbus_avallon_master_wr is
    generic (
        AUTO_INR_IRQ0_INTERRUPTS_USED : STRING := "-1";
        clockrate                     : STRING := "125 MHz"
    );
    port (
        -- Interface avallon
        avm_m0_address       : out STD_LOGIC_VECTOR(31 downto 0);                   --   avm_m0.address
        avm_m0_read          : out STD_LOGIC;                                       --         .read
        avm_m0_waitrequest   : in STD_LOGIC                     := '0';             --         .waitrequest
        avm_m0_readdata      : in STD_LOGIC_VECTOR(31 downto 0) := (others => '0'); --         .readdata
        avm_m0_readdatavalid : in STD_LOGIC                     := '0';             --   A10_SI5345A10_SI5345      .readdatavalid
        avm_m0_write         : out STD_LOGIC;                                       --         .write
        avm_m0_writedata     : out STD_LOGIC_VECTOR(31 downto 0);                   --         .writedata
        clock_clk            : in STD_LOGIC                     := '0';             --    clock.clk
        reset_reset          : in STD_LOGIC                     := '0';             --    reset.reset
        inr_irq0_irq         : in STD_LOGIC_VECTOR(31 downto 0) := (others => '0'); -- inr_irq0.irq
        --Interface Ibbus
        -- Write bus
        ipb_addr   : in STD_LOGIC_VECTOR(31 downto 0);
        ipb_wdata  : in STD_LOGIC_VECTOR(31 downto 0);
        ipb_strobe : in STD_LOGIC;
        ipb_write  : in STD_LOGIC;
        -- Read bus    
        ipb_rdata : out STD_LOGIC_VECTOR(31 downto 0);
        ipb_ack   : out STD_LOGIC;
        ipb_err   : out STD_LOGIC
    );
end entity ipbus_avallon_master_wr;

architecture rtl of ipbus_avallon_master_wr is
    signal rd_req                          : STD_LOGIC;
    signal avm_m0_write_e0, avm_m0_read_e0 : STD_LOGIC;
    signal ipb_strobe_e                    : STD_LOGIC;

begin

    avm_m0_address(1 downto 0) <= "00"; -- Pas d'adressage par byte via l'Ipbus
    rd_req                     <= ipb_strobe and not ipb_write;
    -- Decallage d'une période avec le signal "ipb_strobe_e", car sinon l'Ipbus stappe la 2° donnée. Le signal "avm_m0_write_e0" est là pour éviter de faire du pipelined
    avm_m0_write <= ipb_strobe and ipb_write and not avm_m0_write_e0 and ipb_strobe_e;
    -- Decallage d'une période avec le signal "ipb_strobe_e", car sinon l'Ipbus stappe la 2° donnée. Le signal "avm_m0_read_e0" est là pour éviter de faire du pipelined
    avm_m0_read <= rd_req and not avm_m0_read_e0 and ipb_strobe_e;
    ipb_ack     <= (avm_m0_write and not avm_m0_waitrequest) or (rd_req and avm_m0_readdatavalid);
    ipb_rdata   <= avm_m0_readdata;

    -- Les données et adresses fournies ne peuvent changer qu s'il n'y a pas de Wait
    process (reset_reset, avm_m0_waitrequest, ipb_wdata, ipb_addr)
    begin
        if (avm_m0_waitrequest = '0') then
            avm_m0_writedata            <= ipb_wdata;
            avm_m0_address(31 downto 2) <= ipb_addr(29 downto 0);
        end if;
    end process;

    -- On echantillone avm_m0_write et avm_m0_read pour eviter de faire des écritures ou lectures sur deux périodes consécutives (pas de mode pipelined).
    -- Les writes ou Read ne sont pris en compte par l'esclave que s'il n'y a pas de Wait
    process (clock_clk, reset_reset)
    begin
        if reset_reset = '1' then
            avm_m0_write_e0 <= '0';
            avm_m0_read_e0  <= '0';
            ipb_strobe_e    <= '0';
        elsif (rising_edge (clock_clk)) then
            ipb_strobe_e <= ipb_strobe;
            if avm_m0_write_e0 = '0' then
                if avm_m0_waitrequest = '0' then
                    avm_m0_write_e0 <= avm_m0_write;
                end if;
            else
                avm_m0_write_e0 <= '0';
            end if;
            if avm_m0_read_e0 = '0' then
                if avm_m0_waitrequest = '0' then
                    avm_m0_read_e0 <= avm_m0_read;
                end if;
            else
                avm_m0_read_e0 <= '0';
            end if;
        end if;
    end process;
end architecture rtl;