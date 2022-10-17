module top_ipbus (
    input  logic refclk_1G,
    input  logic nreset,
    // SPI interface
    input  logic spi_clk,
    input  logic csn,
    input  logic mosi,
    output logic miso,
    // IpBus interface
    input  logic rx_gbt,
    output logic tx_gbt,
    output logic interrupt,
    // UART interface
    input  logic ipbus_uart_rxd,
    output logic ipbus_uart_txd
);

    logic        bridge_external_interface_read         ;
    logic        bridge_external_interface_write        ;
    logic        bridge_external_interface_acknowledge  ;
    logic [ 3:0] bridge_external_interface_byte_enable  ;
    logic [31:0] bridge_external_interface_address      ;
    logic [31:0] bridge_external_interface_read_data    ;
    logic [31:0] bridge_external_interface_write_data   ;

    ipbus_1G ipbus_1G_inst (
        .clk12                                  (refclk_1G),
        .rst_125                                (~nreset),
        .rx_gbt                                 (rx_gbt), //! Configure pour passer par le fond de panier (AMC_1GbE_RX[0]) mais peut être remplace par QSFP_RX[0]
        .tx_gbt                                 (tx_gbt), //! Configure pour passer par le fond de panier (AMC_1GbE_TX[0]) mais peut être remplace par QSFP_TX[0]
        .bridge_external_interface_address      (bridge_external_interface_address),
        .bridge_external_interface_byte_enable  (bridge_external_interface_byte_enable),
        .bridge_external_interface_read         (bridge_external_interface_read),
        .bridge_external_interface_write        (bridge_external_interface_write),
        .bridge_external_interface_write_data   (bridge_external_interface_write_data),
        .bridge_external_interface_acknowledge  (bridge_external_interface_acknowledge),
        .bridge_external_interface_read_data    (bridge_external_interface_read_data),
        .uc_interrupt                           (interrupt),
        .ipbus_uart_rxd                         (ipbus_uart_rxd),
		.ipbus_uart_txd                         (ipbus_uart_txd)
    );

    SPI_interface SPI_interface_inst (
        .clk                    (refclk_1G),	                            //! Signal d'horloge
        .nreset                 (nreset), 		                            //! Signal de Reset (actif a l'etat bas)
        .spi_clk                (spi_clk),		                            //! Horloge SPI
        .csn                    (csn),			                            //! Chip select
        .mosi                   (mosi),			                            //! Signal SPI mosi
        .miso                   (miso),			                            //! Signal SPI miso
        .avallon_read           (bridge_external_interface_read),           //! Signal positionne a "1" pour indiquer au bus avallon que l'on souhaite realiser une operation de lecture
        .avallon_write          (bridge_external_interface_write),          //! Signal positionne a "1" pour indiquer au bus avallon que l'on souhaite realiser une operation d'ecriture
        .address                (bridge_external_interface_address),		//! Adresse de lecture/ecriture sur le bus avallon
        .read_data_from_avallon (bridge_external_interface_read_data),      //! Donnee de lecture a transmettre au processus SPI
        .write_data_to_avallon  (bridge_external_interface_write_data)      //! Donnee d'ecriture a transmettre a l'interface avallon
        .acknowledge            (bridge_external_interface_acknowledge),    //! Signal d'acknoledge provenant du bus avalon pour signaler que l'operation de lecture/ecriture est terminee.
        .byte_enable            (bridge_external_interface_byte_enable),    //! Indique les octets a lire/ecrire dans le mot de 32 bits
    );

endmodule