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

    wire        spi_interface_read         ;
    wire        spi_interface_write        ;
    wire        spi_interface_acknowledge  ;
    wire [ 3:0] spi_interface_byte_enable  ;
    wire [31:0] spi_interface_address      ;
    wire [31:0] spi_interface_read_data    ;
    wire [31:0] spi_interface_write_data   ;

    ipbus_1G ipbus_1G_inst (
        .clk10                      (clk10),
        .clk125                     (refclk_1G),
        .rst_125                    (~nreset),
        .rx_gbt                     (rx_gbt), //! Configure pour passer par le fond de panier (AMC_1GbE_RX[0]) mais peut être remplace par QSFP_RX[0]
        .tx_gbt                     (tx_gbt), //! Configure pour passer par le fond de panier (AMC_1GbE_TX[0]) mais peut être remplace par QSFP_TX[0]
        .spi_interface_address      (spi_interface_address),
        .spi_interface_byte_enable  (spi_interface_byte_enable),
        .spi_interface_read         (spi_interface_read),
        .spi_interface_write        (spi_interface_write),
        .spi_interface_write_data   (spi_interface_write_data),
        .spi_interface_acknowledge  (spi_interface_acknowledge),
        .spi_interface_read_data    (spi_interface_read_data),
        .uc_interrupt               (interrupt),
        .ipbus_uart_rxd             (ipbus_uart_rxd),
        .ipbus_uart_txd             (ipbus_uart_txd)
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