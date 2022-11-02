library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_arith.all;
use IEEE.STD_LOGIC_unsigned.all;
use work.pack_ipv4_types.all;
use work.ipbus.all;
use work.wr_fabric_pkg.all;
--library unisim;
--use unisim.VComponents.all;

entity ipbus_wr is
    generic (
        IN_SIMULATION        : BOOLEAN                       := false;
        SIMUL_DST_MAC_NUMBER : STD_LOGIC_VECTOR(47 downto 0) := x"AAAA_BBBB_CCCC";
        CLOCK_FREQ           : INTEGER                       := 125000000; -- freq of data_in_clk -- needed to timout cntr
        DHCP_CLOCK_FREQ      : INTEGER                       := 125000000; -- freq of data_in_clk -- needed to timout cntr
        LEASE_TIME_TO_REQ    : INTEGER                       := 60;        -- lease time request (in sec)
        ARP_TIMEOUT          : INTEGER                       := 60;        -- ARP response timeout (s)
        ARP_MAX_PKT_TMO      : INTEGER                       := 5;         -- # wrong nwk pkts received before set error
        MAX_ARP_ENTRIES      : INTEGER                       := 255        -- max entries in the ARP store
    );
    port (
        clk125                  : in  STD_LOGIC; --Modif EP
        rst_125                 : in  STD_LOGIC; --Modif EP
        leds                    : out STD_LOGIC_VECTOR(3 downto 0);
        phy_rstb                : out STD_LOGIC;
        led_out                 : out STD_LOGIC;
        snk_i                   : in  t_wrf_sink_in;
        snk_o                   : out t_wrf_sink_out;
        src_o                   : out t_wrf_source_out;
        src_i                   : in  t_wrf_source_in;
        spi_bridge_address      : in  STD_LOGIC_VECTOR(26 downto 0);
        spi_bridge_byte_enable  : in  STD_LOGIC_VECTOR(3 downto 0);
        spi_bridge_read         : in  STD_LOGIC;
        spi_bridge_write        : in  STD_LOGIC;
        spi_bridge_write_data   : in  STD_LOGIC_VECTOR(31 downto 0) := (others => 'X');
        spi_bridge_acknowledge  : out STD_LOGIC;
        spi_bridge_read_data    : out STD_LOGIC_VECTOR(31 downto 0);
        uc_interrupt            : out STD_LOGIC
        -- rst_ipb        : in STD_LOGIC; --Modif E
        -- ipb_clk        : in STD_LOGIC; --Modif EP
    );
end ipbus_wr;

architecture RTL of ipbus_wr is

    constant nb_src : NATURAL := 2;

    component UDP_Uncomplete is
        generic (
            USE_RX_FIFO          : BOOLEAN                       := true; --only if gmii_rx_clk /= clk125
            IN_SIMULATION        : BOOLEAN                       := false;
            SIMUL_DST_MAC_NUMBER : STD_LOGIC_VECTOR(47 downto 0) := x"AAAA_BBBB_CCCC";
            CLOCK_FREQ           : INTEGER                       := 125000000; -- freq of data_in_clk -- needed to timout cntr
            ARP_TIMEOUT          : INTEGER                       := 60;        -- ARP response timeout (s)
            ARP_MAX_PKT_TMO      : INTEGER                       := 5;         -- # wrong nwk pkts received before set error
            MAX_ARP_ENTRIES      : INTEGER                       := 255        -- max entries in the ARP store
        );
        port (
            -- UDP TX signals
            udp_tx_start          : in STD_LOGIC;   -- indicates req to tx UDP
            udp_txi               : in udp_tx_type; -- UDP tx cxns
            udp_tx_result         : out STD_LOGIC_VECTOR (1 downto 0);-- tx status (changes during transmission)
            udp_tx_data_out_ready : out STD_LOGIC; -- indicates udp_tx is ready to take data

            -- UDP RX signals
            udp_rx_start : out STD_LOGIC; -- indicates receipt of udp header
            udp_rxo      : out udp_rx_type;

            -- IP RX signals
            ip_rx_hdr : out ipv4_rx_header_type;

            -- system signals
            clk125          : in STD_LOGIC;
            reset           : in STD_LOGIC;
            our_ip_address  : in STD_LOGIC_VECTOR (31 downto 0);
            our_mac_address : in STD_LOGIC_VECTOR (47 downto 0);
            gateway         : in STD_LOGIC_VECTOR(31 downto 0);
            netmask         : in STD_LOGIC_VECTOR(31 downto 0);
            control         : in udp_control_type;

            -- status signals
            arp_pkt_count : out STD_LOGIC_VECTOR(7 downto 0); -- count of arp pkts received
            ip_pkt_count  : out STD_LOGIC_VECTOR(7 downto 0); -- number of IP pkts received for us

            -- WR TX interface
            src_o : out t_wrf_source_out;
            src_i : in t_wrf_source_in;

            -- WR RX interface
            snk_i : in t_wrf_sink_in;
            snk_o : out t_wrf_sink_out
        );
    end component;

    component dhcp_client_4_wr
        generic (
            CLOCK_FREQ        : INTEGER := 125000000; -- freq of data_in_clk -- needed to timout cntr
            LEASE_TIME_TO_REQ : INTEGER := 3600       -- lease time request (in sec)
        );
        port (
            -- system signals
            clk             : in STD_LOGIC;
            reset           : in STD_LOGIC;
            our_mac_address : in STD_LOGIC_VECTOR (47 downto 0);

            -- UDP TX signals
            udp_tx_start          : out STD_LOGIC;   -- indicates req to tx UDP
            udp_txi               : out udp_tx_type; -- UDP tx cxns
            udp_tx_result         : in  STD_LOGIC_VECTOR (1 downto 0);-- tx status (changes during transmission)
            udp_tx_data_out_ready : in  STD_LOGIC; -- indicates udp_tx is ready to take data

            -- UDP RX signals
            udp_rx_start : in STD_LOGIC; -- indicates receipt of udp header
            udp_rxo      : in udp_rx_type;

            gateway              : out STD_LOGIC_VECTOR(31 downto 0);
            netmask              : out STD_LOGIC_VECTOR(31 downto 0);
            allocated_ip_address : out STD_LOGIC_VECTOR (31 downto 0);
            result               : out STD_LOGIC
        );
    end component;

    signal mac_address_pio : STD_LOGIC_VECTOR(7 downto 0);

    component ipbus_qsys is
        port (
            clk_clk                                                 : in  STD_LOGIC                      := 'X';             -- clk
            reset_reset                                             : in  STD_LOGIC := 'X';                                  -- reset
            ipbus_avallon_master_ipbread_ipbus_read_readdata        : out STD_LOGIC_VECTOR(31 downto 0)  := (others => 'X'); -- ipbus_read_readdata
            ipbus_avallon_master_ipbread_ipbus_read_ack             : out STD_LOGIC                      := 'X';             -- ipbus_read_ack
            ipbus_avallon_master_ipbread_ipbus_read_err             : out STD_LOGIC                      := 'X';             -- ipbus_read_err
            ipbus_avallon_master_ipbuswrite_ipbus_write_addr        : in  STD_LOGIC_VECTOR(31 downto 0)  := (others => 'X'); -- ipbus_write_addr
            ipbus_avallon_master_ipbuswrite_ipbus_write_writedata   : in  STD_LOGIC_VECTOR(31 downto 0)  := (others => 'X'); -- ipbus_write_writedata
            ipbus_avallon_master_ipbuswrite_ipbus_write_strobe      : in  STD_LOGIC                      := 'X';             -- ipbus_write_strobe
            ipbus_avallon_master_ipbuswrite_ipbus_write_write       : in  STD_LOGIC                      := 'X';             -- ipbus_write_write
            pio_external_connection_export                          : out STD_LOGIC_VECTOR(31 downto 0);                     -- export
            mac_address_pio_export                                  : out STD_LOGIC_VECTOR(7 downto 0);                      -- export
            spi_bridge_address                                      : in  STD_LOGIC_VECTOR(26 downto 0) := (others => 'X');  -- address
            spi_bridge_byte_enable                                  : in  STD_LOGIC_VECTOR(3 downto 0)  := (others => 'X');  -- byte_enable
            spi_bridge_read                                         : in  STD_LOGIC                     := 'X';              -- read
            spi_bridge_write                                        : in  STD_LOGIC                     := 'X';              -- write
            spi_bridge_write_data                                   : in  STD_LOGIC_VECTOR(31 downto 0) := (others => 'X');  -- write_data
            spi_bridge_acknowledge                                  : out STD_LOGIC;                                         -- acknowledge
            spi_bridge_read_data                                    : out STD_LOGIC_VECTOR(31 downto 0)                      -- read_data
        );
    end component ipbus_qsys;

    component ipbus_main_4_wr
        generic (
            -- Number of RX and TX buffers is 2**BUFWIDTH
            BUFWIDTH : NATURAL := 4;
            -- Number of address bits within each buffer in UDP I/F
            -- Size of each buffer is 2**ADDRWIDTH --MAXIMUM is 14 bit
            ADDRWIDTH : NATURAL := 9;
            -- UDP port for IPbus traffic in this instance of UDP I/F
            IPBUSPORT : STD_LOGIC_VECTOR(15 downto 0) := x"C351"
        );
        port (
            mac_clk    : in STD_LOGIC; -- Ethernet MAC clock (125MHz)
            rst_macclk : in STD_LOGIC; -- MAC clock domain sync reset

            -- UDP RX signals
            udp_rx_start : in STD_LOGIC; -- indicates receipt of udp header
            udp_rxo      : in udp_rx_type;

            -- UDP TX signals
            udp_tx_start          : out STD_LOGIC;                    -- indicates req to tx UDP
            udp_txi               : out udp_tx_type;                  -- UDP tx cxns
            udp_tx_result         : in  STD_LOGIC_VECTOR (1 downto 0); -- tx status (changes during transmission)
            udp_tx_data_out_ready : in  STD_LOGIC;                     -- indicates udp_tx is ready to take data

            -- ipb interface
            ipb_clk : in  STD_LOGIC; -- IPbus clock
            rst_ipb : in  STD_LOGIC; -- IPbus clock domain sync reset
            ipb_out : out ipb_wbus;
            ipb_in  : in  ipb_rbus;
            bidon   : out STD_LOGIC
        );
    end component;

    component udp_tx_arbitrer
        generic (
            nb_src : NATURAL
        );
        port (
            mac_clk    : in STD_LOGIC; -- Ethernet MAC clock (125MHz)
            rst_macclk : in STD_LOGIC; -- MAC clock domain sync reset

            -- UDP result TX signals
            src_udp_tx_start          : in  STD_LOGIC_VECTOR(0 to nb_src - 1);
            src_udp_tx                : in  udp_tx_vect_type(0 to nb_src - 1);
            src_udp_tx_result         : out Array2bit_ip(0 to nb_src - 1);     -- tx status (changes during transmission)
            src_udp_tx_data_out_ready : out STD_LOGIC_VECTOR(0 to nb_src - 1); -- indicates udp_tx is ready to take data

            -- UDP result TX signals
            arb_udp_tx_start          : out STD_LOGIC; -- indicates req to tx UDP
            arb_udp_txi               : out udp_tx_type;
            arb_udp_tx_result         : in  STD_LOGIC_VECTOR (1 downto 0); -- tx status (changes during transmission)
            arb_udp_tx_data_out_ready : in  STD_LOGIC                      -- indicates udp_tx is ready to take data
        );
    end component udp_tx_arbitrer;

    --UDP/IPBUS interconnection
    signal udp_tx_start          : STD_LOGIC; -- indicates req to tx UDP
    signal udp_txi               : udp_tx_type;
    signal udp_tx_result         : STD_LOGIC_VECTOR (1 downto 0);-- tx status (changes during transmission)
    signal udp_tx_data_out_ready : STD_LOGIC; -- indicates udp_tx is ready to take data

    signal udp_tx_start_ipbus          : STD_LOGIC; -- indicates req to tx UDP
    signal udp_txi_ipbus               : udp_tx_type;
    signal udp_tx_result_ipbus         : STD_LOGIC_VECTOR (1 downto 0);-- tx status (changes during transmission)
    signal udp_tx_data_out_ready_ipbus : STD_LOGIC; -- indicates udp_tx is ready to take data

    signal udp_rx_start : STD_LOGIC; -- indicates receipt of udp header
    signal udp_rxo      : udp_rx_type;

    signal control : udp_control_type;

    --GMII interfacing    
    --    signal clk125: std_logic; --Modif EP
    --    signal rst_125: std_logic; --Modif EP
    --    signal rst_ipb: std_logic; --Modif EP
    --    signal ipb_clk: std_logic; --Modif EP
    signal rx_clk, rx_clk_io : STD_LOGIC;
    signal txd_e, rxd_r      : STD_LOGIC_VECTOR(7 downto 0);
    signal tx_en_e, tx_er_e  : STD_LOGIC;
    signal rx_dv_r, rx_er_r  : STD_LOGIC;
    signal gmii_rxd_del      : STD_LOGIC_VECTOR(7 downto 0);
    signal gmii_rx_dv_del    : STD_LOGIC;
    signal gmii_rx_er_del    : STD_LOGIC;
    signal our_ip_address    : STD_LOGIC_VECTOR (31 downto 0);
    signal our_mac_address   : STD_LOGIC_VECTOR (47 downto 0);

    -- IPBUS connection
    signal ipb_out     : ipb_wbus;
    signal ipb_in      : ipb_rbus;
    signal gmii_tx_clk : STD_LOGIC;
    signal gmii_rx_clk : STD_LOGIC;
    signal gateway     : STD_LOGIC_VECTOR(31 downto 0);
    signal netmask     : STD_LOGIC_VECTOR(31 downto 0);

    -- gmii TX interface
    signal gmii_tx_en : STD_LOGIC;
    signal gmii_tx_er : STD_LOGIC;
    signal gmii_txd   : STD_LOGIC_VECTOR(7 downto 0);

    -- gmii RX interface
    signal gmii_rx_dv                 : STD_LOGIC;
    signal gmii_rx_er                 : STD_LOGIC;
    signal gmii_rxd                   : STD_LOGIC_VECTOR(7 downto 0);
    signal led_out_int, result        : STD_LOGIC;
    signal udp_tx_start_dhcp          : STD_LOGIC;
    signal udp_txi_dhcp               : udp_tx_type;
    signal udp_tx_result_dhcp         : STD_LOGIC_VECTOR (1 downto 0);
    signal udp_tx_data_out_ready_dhcp : STD_LOGIC;

    signal udp_tx_start_arb          : STD_LOGIC;
    signal udp_txi_arb               : udp_tx_type;
    signal udp_tx_result_arb         : STD_LOGIC_VECTOR (1 downto 0);
    signal udp_tx_data_out_ready_arb : STD_LOGIC;

    signal src_udp_tx_start          : STD_LOGIC_VECTOR(0 to nb_src - 1);
    signal src_udp_tx                : udp_tx_vect_type(0 to nb_src - 1);
    signal src_udp_tx_result         : Array2bit_ip(0 to nb_src - 1);     -- tx status (changes during transmission)
    signal src_udp_tx_data_out_ready : STD_LOGIC_VECTOR(0 to nb_src - 1); -- indicates udp_tx is ready to take data
    signal bidon                     : STD_LOGIC;
    signal pio_0_export              : STD_LOGIC_VECTOR (31 downto 0);
    -- signal out_pio                   : STD_LOGIC;

begin

    -------------------------------------------------------------------------------
    -- UDP connection
    -------------------------------------------------------------------------------
    UDP_Uncomplete_inst : UDP_Uncomplete
        generic map(
            IN_SIMULATION        => IN_SIMULATION,
            SIMUL_DST_MAC_NUMBER => SIMUL_DST_MAC_NUMBER,

            CLOCK_FREQ      => CLOCK_FREQ,
            ARP_TIMEOUT     => ARP_TIMEOUT,
            ARP_MAX_PKT_TMO => ARP_MAX_PKT_TMO,
            MAX_ARP_ENTRIES => MAX_ARP_ENTRIES
        )
        port map(
            -- UDP TX signals
            udp_tx_start          => udp_tx_start_arb,          -- udp_tx_start,
            udp_txi               => udp_txi_arb,               -- udp_txi,
            udp_tx_result         => udp_tx_result_arb,         -- udp_tx_result,
            udp_tx_data_out_ready => udp_tx_data_out_ready_arb, -- udp_tx_data_out_ready,

            -- UDP RX signals
            udp_rx_start => udp_rx_start,
            udp_rxo      => udp_rxo,

            -- IP RX signals
            ip_rx_hdr => open,

            -- system signals
            clk125          => clk125,
            reset           => rst_125,
            our_ip_address  => our_ip_address,
            our_mac_address => our_mac_address,
            gateway         => gateway,
            netmask         => netmask,
            control         => control,

            -- status signals
            arp_pkt_count => open,
            ip_pkt_count  => open,

            -- WR TX interface
            src_o => src_o,
            src_i => src_i,

            -- WR RX interface
            snk_i => snk_i,
            snk_o => snk_o
        );

    led_out <= led_out_int;

    -- for dlink switch pb
    our_mac_address <= x"00228f5555" & mac_address_pio;
    --    our_ip_address    <= X"c0a801" & X"11"; -- 192.168.001.17
    control.ip_controls.arp_controls.clear_cache <= '0';

    -------------------------------------------------------------------------------
    --    dhcp block
    -------------------------------------------------------------------------------
    lbl_dhcp : dhcp_client_4_wr
        generic map(
            CLOCK_FREQ        => DHCP_CLOCK_FREQ,
            LEASE_TIME_TO_REQ => LEASE_TIME_TO_REQ
        )
        port map(
            -- system signals
            clk             => clk125,
            reset           => rst_125,
            our_mac_address => our_mac_address,

            -- UDP TX signals
            udp_tx_start          => udp_tx_start_dhcp,          --udp_tx_start,
            udp_txi               => udp_txi_dhcp,               --udp_txi,
            udp_tx_result         => udp_tx_result_dhcp,         --udp_tx_result,
            udp_tx_data_out_ready => udp_tx_data_out_ready_dhcp, --udp_tx_data_out_ready,

            -- UDP RX signals
            udp_rx_start => udp_rx_start,
            udp_rxo      => udp_rxo,

            gateway              => gateway,
            netmask              => netmask,
            allocated_ip_address => our_ip_address,
            result               => led_out_int
        );

    -------------------------------------------------------------------------------
    --    IPBUS block
    -------------------------------------------------------------------------------
    lbl_ipbus : ipbus_main_4_wr 
        generic map(
            -- Number of RX and TX buffers is 2**BUFWIDTH
            BUFWIDTH => 4,
            -- Number of address bits within each buffer in UDP I/F
            -- Size of each buffer is 2**ADDRWIDTH --MAXIMUM is 14 bit
            ADDRWIDTH => 9,
            -- UDP port for IPbus traffic in this instance of UDP I/F
            IPBUSPORT => x"C351"
        )
        port map(
            mac_clk    => clk125,
            rst_macclk => rst_125,

            -- UDP RX signals
            udp_rx_start => udp_rx_start,
            udp_rxo      => udp_rxo,

            -- UDP TX signals
            udp_tx_start          => udp_tx_start_ipbus,          -- udp_tx_start, EP, modif DHCP 
            udp_txi               => udp_txi_ipbus,               --udp_txi,  EP, modif DHCP
            udp_tx_result         => udp_tx_result_ipbus,         -- udp_tx_result,  EP, modif DHCP
            udp_tx_data_out_ready => udp_tx_data_out_ready_ipbus, -- udp_tx_data_out_ready,   EP, modif DHCP

            -- ipb interface
            ipb_clk => clk125,
            rst_ipb => rst_125,
            ipb_out => ipb_out,
            ipb_in  => ipb_in,
            bidon   => bidon
        );

    -------------------------------------------------------------------------------
    --    IPBUS/UDP arbitrer
    -------------------------------------------------------------------------------
    lbl_udp_arb : udp_tx_arbitrer 
        generic map(nb_src)
        port map(
            mac_clk    => clk125,
            rst_macclk => rst_125,

            src_udp_tx_start          => src_udp_tx_start,
            src_udp_tx                => src_udp_tx,
            src_udp_tx_result         => src_udp_tx_result,
            src_udp_tx_data_out_ready => src_udp_tx_data_out_ready,

            -- UDP result TX signals
            arb_udp_tx_start          => udp_tx_start_arb,
            arb_udp_txi               => udp_txi_arb,
            arb_udp_tx_result         => udp_tx_result_arb,
            arb_udp_tx_data_out_ready => udp_tx_data_out_ready_arb
        );

    -- UDP result TX signals (ipbus)
    src_udp_tx_start(0)         <= udp_tx_start_ipbus;
    src_udp_tx(0)               <= udp_txi_ipbus;
    udp_tx_result_ipbus         <= src_udp_tx_result(0);
    udp_tx_data_out_ready_ipbus <= src_udp_tx_data_out_ready(0);

    -- UDP result TX signals (dhcp)
    src_udp_tx_start(1)        <= udp_tx_start_dhcp;
    src_udp_tx(1)              <= udp_txi_dhcp;
    udp_tx_result_dhcp         <= src_udp_tx_result(1);
    udp_tx_data_out_ready_dhcp <= src_udp_tx_data_out_ready(1);
    -------------------------------------------------------------------------------
    --    slaves block
    -------------------------------------------------------------------------------

    ipbus_qsys_inst : ipbus_qsys
        port map(
            clk_clk                                                 => clk125,                  --                               clk.clk
            reset_reset                                             => rst_125,                 --                             reset.reset
            ipbus_avallon_master_ipbread_ipbus_read_readdata        => ipb_in.ipb_rdata,        --    ipbus_avallon_master_0_ipbread.ipbus_read_readdata
            ipbus_avallon_master_ipbread_ipbus_read_ack             => ipb_in.ipb_ack,          --                                  .ipbus_read_ack
            ipbus_avallon_master_ipbread_ipbus_read_err             => ipb_in.ipb_err,          --                                  .ipbus_read_err
            ipbus_avallon_master_ipbuswrite_ipbus_write_addr        => ipb_out.ipb_addr,        -- ipbus_avallon_master_0_ipbuswrite.ipbus_write_addr
            ipbus_avallon_master_ipbuswrite_ipbus_write_writedata   => ipb_out.ipb_wdata,       --                                  .ipbus_write_writedata
            ipbus_avallon_master_ipbuswrite_ipbus_write_strobe      => ipb_out.ipb_strobe,      --                                  .ipbus_write_strobe
            ipbus_avallon_master_ipbuswrite_ipbus_write_write       => ipb_out.ipb_write,       --                                  .ipbus_write_write
            pio_external_connection_export                          => pio_0_export,            --         pio_0_external_connection.export
            mac_address_pio_export                                  => mac_address_pio,         --                   mac_address_pio.export
            spi_bridge_address                                      => spi_bridge_address,      --                        spi_bridge.address
            spi_bridge_byte_enable                                  => spi_bridge_byte_enable,  --                                  .byte_enable
            spi_bridge_read                                         => spi_bridge_read,         --                                  .read
            spi_bridge_write                                        => spi_bridge_write,        --                                  .write
            spi_bridge_write_data                                   => spi_bridge_write_data,   --                                  .write_data
            spi_bridge_acknowledge                                  => spi_bridge_acknowledge,  --                                  .acknowledge
            spi_bridge_read_data                                    => spi_bridge_read_data     --                                  .read_data
        );

    -- out_pio <= pio_0_export(3) and pio_0_export(2) and pio_0_export(1) and pio_0_export(0);
    uc_interrupt <= pio_0_export(0);

    -------------------------------------------------------------------------------
    -- IO interface
    -------------------------------------------------------------------------------
    phy_rstb <= '1';
    leds     <= "0000";

end RTL;