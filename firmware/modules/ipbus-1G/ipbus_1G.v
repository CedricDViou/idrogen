module ipbus_1G #(
    parameter IN_SIMULATION        = 0,
    parameter SIMUL_DST_MAC_NUMBER = 'hAAAABBBBCCCC,
    parameter CLOCK_FREQ           = 125000000,
    parameter DHCP_CLOCK_FREQ      = 125000000,
    parameter LEASE_TIME_TO_REQ    = 60,
    parameter ARP_TIMEOUT          = 60,
    parameter ARP_MAX_PKT_TMO      = 5,
    parameter MAX_ARP_ENTRIES      = 255
)(
    input  wire        clk125,
    input  wire        rst_125,
    input  wire        rx_gbt,
    input  wire        ipbus_uart_rxd,
    input  wire        bridge_external_interface_read,
    input  wire        bridge_external_interface_write,
    input  wire [ 3:0] bridge_external_interface_byte_enable,
    input  wire [31:0] bridge_external_interface_address,
    input  wire [31:0] bridge_external_interface_write_data,
    output             phy_rstb,
    output             tx_gbt,
    output             bridge_external_interface_acknowledge,
    output      [31:0] bridge_external_interface_read_data,
    output             uc_interrupt,
    output             ipbus_uart_txd
);

    parameter nb_src = 2;

    wire        udp_tx_start_ipbus;
    udp_tx_type udp_txi_ipbus;

    wire        udp_tx_data_out_ready_ipbus;
    wire [1:0]  udp_tx_result_ipbus;

    wire        udp_rx_start;
    udp_rx_type udp_rxo;

    reg         rx_er_r;
    reg         rx_dv_r;
    reg  [ 7:0] rxd_r;
    wire        rx_clk;
    wire        rx_clk_io;
    wire        tx_en_e;
    wire        tx_er_e;
    wire        gmii_rx_dv_del;
    wire        gmii_rx_er_del;
    wire [ 7:0] txd_e;
    wire [ 7:0] gmii_rxd_del;
    wire [31:0] our_ip_address;

    ipb_wbus    ipb_out;
    ipb_rbus    ipb_in;
    wire        gmii_rx_clk;
    wire [31:0] gateway;
    wire [31:0] netmask;

    reg        gmii_tx_en;
    reg        gmii_tx_er;
    reg  [7:0] gmii_txd;
    wire       gmii_rx_dv;


    udp_tx_type udp_txi_dhcp;
    wire        udp_tx_start_dhcp;
    wire        udp_tx_data_out_ready_dhcp;
    wire [1:0]  udp_tx_result_dhcp;

    udp_tx_type udp_txi_arb;
    wire        udp_tx_start_arb;
    wire        udp_tx_data_out_ready_arb;
    wire [1:0]  udp_tx_result_arb;

    udp_tx_vect_type [0:nb_src-1] src_udp_tx;
    Array2bit_ip     [0:nb_src-1] src_udp_tx_result;
    
    wire [0:nb_src-1] src_udp_tx_start;
    wire [0:nb_src-1] src_udp_tx_data_out_ready;


    reg  [47:0] our_mac_address = 48'h0022_8f03_0001;
    wire [31:0] pio_0_export;

    udp_control_type control;
    assign control.ip_controls.arp_controls.clear_cache = 0;

    // UDP result TX signals (ipbus)
    assign src_udp_tx_start[0]         = udp_tx_start_ipbus;
    assign src_udp_tx[0]               = udp_txi_ipbus;
    assign udp_tx_result_ipbus         = src_udp_tx_result[0];
    assign udp_tx_data_out_ready_ipbus = src_udp_tx_data_out_ready[0];

    // UDP result TX signals (dhcp)
    assign src_udp_tx_start[1]        = udp_tx_start_dhcp;
    assign src_udp_tx[1]              = udp_txi_dhcp;
    assign udp_tx_result_dhcp         = src_udp_tx_result[1];
    assign udp_tx_data_out_ready_dhcp = src_udp_tx_data_out_ready[1];

    assign uc_interrupt = pio_0_export[0];

    assign phy_rstb  = 1;

    assign rx_clk_io = gmii_rx_clk;
    assign rx_clk    = gmii_rx_clk;

    UDP_Complete #(
        .IN_SIMULATION       (IN_SIMULATION),
        .SIMUL_DST_MAC_NUMBER(SIMUL_DST_MAC_NUMBER),
        .CLOCK_FREQ          (CLOCK_FREQ),
        .ARP_TIMEOUT         (ARP_TIMEOUT),
        .ARP_MAX_PKT_TMO     (ARP_MAX_PKT_TMO),
        .MAX_ARP_ENTRIES     (MAX_ARP_ENTRIES)  
    ) UDP_Complete_inst (
        .udp_tx_start         (udp_tx_start_arb),
        .udp_txi              (udp_txi_arb),
        .udp_tx_result        (udp_tx_result_arb),
        .udp_tx_data_out_ready(udp_tx_data_out_ready_arb),
        .udp_rx_start         (udp_rx_start),
        .udp_rxo              (udp_rxo),
        .clk125               (clk125),
        .reset                (rst_125),
        .our_ip_address       (our_ip_address),
        .our_mac_address      (our_mac_address),
        .gateway              (gateway),
        .netmask              (netmask),
        .control              (control),
        .gmii_txd             (txd_e),
        .gmii_tx_en           (tx_en_e),
        .gmii_tx_er           (tx_er_e),
        .gmii_rx_clk          (rx_clk),
        .gmii_rx_dv           (rx_dv_r),
        .gmii_rx_er           (0),
        .gmii_rxd             (rxd_r)
    );

    dhcp_client #(
        .CLOCK_FREQ       (DHCP_CLOCK_FREQ),
        .LEASE_TIME_TO_REQ(LEASE_TIME_TO_REQ)  
    ) dhcp_client_inst (
        .clk                  (clk),
        .reset                (rst_125),
        .our_mac_address      (our_mac_address),
        .udp_tx_start         (udp_tx_start_dhcp),
        .udp_txi              (udp_txi_dhcp),
        .udp_tx_result        (udp_tx_result_dhcp),
        .udp_tx_data_out_ready(udp_tx_data_out_ready_dhcp),
        .udp_rx_start         (udp_rx_start),
        .udp_rxo              (udp_rxo),
        .gateway              (gateway),
        .netmask              (netmask),
        .allocated_ip_address (our_ip_address)
    );

    ipbus_main #(
        .BUFWIDTH (4),
        .ADDRWIDTH(9),
        .IPBUSPORT('hC351)  
    ) ipbus_main_inst (
        .mac_clk              (clk125),
        .rst_macclk           (rst_125),
        .udp_rx_start         (udp_rx_start),
        .udp_rxo              (udp_rxo),
        .udp_tx_start         (udp_tx_start_ipbus),
        .udp_txi              (udp_txi_ipbus),
        .udp_tx_result        (udp_tx_result_ipbus),
        .udp_tx_data_out_ready(udp_tx_data_out_ready_ipbus),
        .ipb_clk              (clk125),
        .rst_ipb              (rst_125),
        .ipb_out              (ipb_out),
        .ipb_in               (ipb_in)
    );

    udp_tx_arbitrer #(.nb_src(nb_src)) udp_tx_arbitrer_inst (
        .mac_clk                  (clk125),
        .rst_macclk               (rst_125),
        .src_udp_tx_start         (src_udp_tx_start),
        .src_udp_tx               (src_udp_tx),
        .src_udp_tx_result        (src_udp_tx_result),
        .src_udp_tx_data_out_ready(src_udp_tx_data_out_ready),
        .arb_udp_tx_start         (udp_tx_start_arb),
        .arb_udp_txi              (udp_txi_arb),
        .arb_udp_tx_result        (udp_tx_result_arb),
        .arb_udp_tx_data_out_ready(udp_tx_data_out_ready_arb)
    );

    ipbus_qsys ipbus_qsys_inst (
        .external_interface_address                             (bridge_external_interface_address), 
        .external_interface_byte_enable                         (bridge_external_interface_byte_enable), 
        .external_interface_read                                (bridge_external_interface_read), 
        .external_interface_write                               (bridge_external_interface_write), 
        .external_interface_write_data                          (bridge_external_interface_write_data), 
        .external_interface_acknowledge                         (bridge_external_interface_acknowledge), 
        .external_interface_read_data                           (bridge_external_interface_read_data), 
        .clk_clk                                                (clk125), 
        .ipbus_avallon_master_1_ipbread_ipbus_read_readdata     (ipb_in.ipb_rdata), 
        .ipbus_avallon_master_1_ipbread_ipbus_read_ack          (ipb_in.ipb_ack), 
        .ipbus_avallon_master_1_ipbread_ipbus_read_err          (ipb_in.ipb_err), 
        .ipbus_avallon_master_1_ipbuswrite_ipbus_write_addr     (ipb_out.ipb_addr), 
        .ipbus_avallon_master_1_ipbuswrite_ipbus_write_writedata(ipb_out.ipb_wdata), 
        .ipbus_avallon_master_1_ipbuswrite_ipbus_write_strobe   (ipb_out.ipb_strobe), 
        .ipbus_avallon_master_1_ipbuswrite_ipbus_write_write    (ipb_out.ipb_write), 
        .pio_0_external_connection_export                       (pio_0_export), 
        .reset_reset                                            (rst_125), 
        .ipbus_qsys_uart_rxd                                    (ipbus_uart_rxd), 
        .ipbus_qsys_uart_txd                                    (ipbus_uart_txd)  
    );

    MyGbt MyGbt_inst (
        .pll_refclk       (clk125),
        .reset            (rst_125),
        .rx_gbt           (rx_gbt),
        .tx_gbt           (tx_gbt),
        .rx_parallel_data (gmii_rxd_del),
        .tx_parallel_data (gmii_txd),
        .rx_datak         (gmii_rx_dv_del),
        .tx_datak         (gmii_tx_en),
        .rx_clk           (gmii_rx_clk)
    );

    always @(posedge rx_clk_io) begin
        rxd_r   <= gmii_rxd_del;
        rx_dv_r <= gmii_rx_dv_del;
        rx_er_r <= gmii_rx_er_del; // Que faire de ce signal?
    end

    always @(posedge clk125) begin
        gmii_txd   <= txd_e;
        gmii_tx_en <= tx_en_e;
        gmii_tx_er <= tx_er_e;
    end

endmodule