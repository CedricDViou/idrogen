module top_ipbus (
    input  wire clk10,
    input  wire refclk_1G,
    input  wire nreset,
    // SPI interface
    input  wire spi_clk,
    input  wire csn,
    input  wire mosi,
    output wire miso,
    // IpBus interface
    input  wire rx_gbt,
    output wire tx_gbt,
    output wire interrupt,
    // UART interface
    input  wire ipbus_uart_rxd,
    output wire ipbus_uart_txd
);

    typedef struct {
        logic        ipb_write;
        logic        ipb_strobe;
        logic [31:0] ipb_addr;
        logic [31:0] ipb_wdata;
    } ipb_wbus;

    typedef struct {
        logic        ipb_ack;
        logic        ipb_err;
        logic [31:0] ipb_rdata;
    } ipb_rbus;

    ipb_rbus ipb_in;
    ipb_wbus ipb_out;

    wire [ 7:0] spi_export;                    //! 8-bits register controled with SPI for uC interrupt
    wire [ 8:0] mac_address_export;            //! 8-bits register controled with SPI to control MAC address value

    wire        bridge_uart_read;              //! Avalon master interface for White Rabbit UART interface: read request
    wire        bridge_uart_write;             //! Avalon master interface for White Rabbit UART interface: write request
    wire        bridge_uart_acknowledge;       //! Avalon master interface for White Rabbit UART interface: acknowledge
    wire [ 3:0] bridge_uart_byte_enable;       //! Avalon master interface for White Rabbit UART interface: byte_enable
    wire [ 8:0] bridge_uart_address;           //! Avalon master interface for White Rabbit UART interface: address
    wire [31:0] bridge_uart_read_data;         //! Avalon master interface for White Rabbit UART interface: read data
    wire [31:0] bridge_uart_write_data;        //! Avalon master interface for White Rabbit UART interface: write data

    wire        spi_interface_read;
    wire        spi_interface_write;
    wire        spi_interface_acknowledge;
    wire [ 3:0] spi_interface_byte_enable;
    wire [31:0] spi_interface_address;
    wire [31:0] spi_interface_read_data;
    wire [31:0] spi_interface_write_data;


    assign interrupt = spi_export[0];

    top_ipbus_lpsc_extphy top_ipbus_lpsc_extphy_inst (
        .clk125   (refclk_1G),
        .rst_125  (!nreset),
        .rx_gbt   (rx_gbt),
        .tx_gbt   (tx_gbt),
        .ipb_out  (ipb_out),
        .ipb_in   (ipb_in),
        .mac_addr (mac_address_export)
    );

    ipbus_qsys ipbus_qsys_inst (
        .spi_interface_address                                   (spi_interface_address),
        .spi_interface_byte_enable                               (spi_interface_byte_enable),
        .spi_interface_read                                      (spi_interface_read),
        .spi_interface_write                                     (spi_interface_write),
        .spi_interface_write_data                                (spi_interface_write_data),
        .spi_interface_acknowledge                               (spi_interface_acknowledge),
        .spi_interface_read_data                                 (spi_interface_read_data),
        .bridge_uart_address                                     (bridge_uart_address),
        .bridge_uart_byte_enable                                 (bridge_uart_byte_enable),
        .bridge_uart_read                                        (bridge_uart_read),
        .bridge_uart_write                                       (bridge_uart_write),
        .bridge_uart_write_data                                  (bridge_uart_write_data),
        .bridge_uart_acknowledge                                 (bridge_uart_acknowledge),
        .bridge_uart_read_data                                   (bridge_uart_read_data),
        .clk10_clk                                               (clk10),
        .clk125_clk                                              (refclk_1G),
        .ipbus_avallon_master_1_ipbread_ipbus_read_readdata      (ipb_in.ipb_rdata),
        .ipbus_avallon_master_1_ipbread_ipbus_read_ack           (ipb_in.ipb_ack),
        .ipbus_avallon_master_1_ipbread_ipbus_read_err           (ipb_in.ipb_err),
        .ipbus_avallon_master_1_ipbuswrite_ipbus_write_addr      (ipb_out.ipb_addr),
        .ipbus_avallon_master_1_ipbuswrite_ipbus_write_writedata (ipb_out.ipb_wdata),
        .ipbus_avallon_master_1_ipbuswrite_ipbus_write_strobe    (ipb_out.ipb_strobe),
        .ipbus_avallon_master_1_ipbuswrite_ipbus_write_write     (ipb_out.ipb_write),
        .mac_address_export                                      (mac_address_export),
        .spi_export                                              (spi_export),
        .reset_reset                                             (!nreset),
        .ipbus_to_uart_rxd                                       (ipbus_uart_rxd),
        .ipbus_to_uart_txd                                       (ipbus_uart_txd)
    );

    wr_monitor wr_monitor_inst (
        .clock                   (clk10),
        .nreset                  (nreset),
        .bridge_uart_acknowledge (bridge_uart_acknowledge),
        .bridge_uart_read_data   (bridge_uart_read_data),
        .bridge_uart_read        (bridge_uart_read),
        .bridge_uart_write       (bridge_uart_write),
        .bridge_uart_byte_enable (bridge_uart_byte_enable),
        .bridge_uart_address     (bridge_uart_address),
        .bridge_uart_write_data  (bridge_uart_write_data)
    );

    SPI_interface SPI_interface_inst (
        .clk                    (clk10),                        //! Signal d'horloge
        .nreset                 (nreset),                       //! Signal de Reset (actif a l'etat bas)
        .spi_clk                (spi_clk),                      //! Horloge SPI
        .csn                    (csn),                          //! Chip select
        .mosi                   (mosi),                         //! Signal SPI mosi
        .miso                   (miso),                         //! Signal SPI miso
        .avallon_read           (spi_interface_read),           //! Signal positionne a "1" pour indiquer au bus avallon que l'on souhaite realiser une operation de lecture
        .avallon_write          (spi_interface_write),          //! Signal positionne a "1" pour indiquer au bus avallon que l'on souhaite realiser une operation d'ecriture
        .address                (spi_interface_address),        //! Adresse de lecture/ecriture sur le bus avallon
        .read_data_from_avallon (spi_interface_read_data),      //! Donnee de lecture a transmettre au processus SPI
        .write_data_to_avallon  (spi_interface_write_data),     //! Donnee d'ecriture a transmettre a l'interface avallon
        .acknowledge            (spi_interface_acknowledge),    //! Signal d'acknoledge provenant du bus avalon pour signaler que l'operation de lecture/ecriture est terminee.
        .byte_enable            (spi_interface_byte_enable)     //! Indique les octets a lire/ecrire dans le mot de 32 bits
    );

endmodule