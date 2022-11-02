`include "../../ip_cores/wr-cores/modules/fabric/wr_fabric_pkg.vhd"

module top_ipbus_wr (
    input  wire             refclk_1G,
    input  wire             nreset,
    input  wire             spi_clk,
    input  wire             csn,
    input  wire             mosi,
    input  t_wrf_sink_in    snk_i,
    input  t_wrf_source_in  src_i,
    output wire             uc_interrupt,
    output wire             phy_rstb,
    output wire             led_out,
    output wire             miso,
    output wire [3:0]       leds,
    output t_wrf_sink_out   snk_o,
    output t_wrf_source_out src_o
);

    wire        spi_interface_read         ;
    wire        spi_interface_write        ;
    wire        spi_interface_acknowledge  ;
    wire [ 3:0] spi_interface_byte_enable  ;
    wire [31:0] spi_interface_address      ;
    wire [31:0] spi_interface_read_data    ;
    wire [31:0] spi_interface_write_data   ;

    ipbus_wr #(
        .IN_SIMULATION       (0),
        .SIMUL_DST_MAC_NUMBER('hAAAABBBBCCCC),
        .CLOCK_FREQ          (125000000),
        .ARP_TIMEOUT         (60),
        .ARP_MAX_PKT_TMO     (5),
        .MAX_ARP_ENTRIES     (255)  
    ) ipbus_wr_dut (
        .clk125                (refclk_1G),
        .rst_125               (~nreset),
        .leds                  (leds),
        .phy_rstb              (phy_rstb),
        .led_out               (led_out),
        .snk_i                 (snk_i),
        .snk_o                 (snk_o),
        .src_o                 (src_o),
        .src_i                 (src_i),
        .spi_bridge_address    (spi_interface_address),
        .spi_bridge_byte_enable(spi_interface_byte_enable),
        .spi_bridge_read       (spi_interface_read),
        .spi_bridge_write      (spi_interface_write),
        .spi_bridge_write_data (spi_interface_write_data),
        .spi_bridge_acknowledge(spi_interface_acknowledge),
        .spi_bridge_read_data  (spi_interface_read_data),
        .uc_interrupt          (uc_interrupt)
    );

    SPI_interface SPI_interface_inst (
        .clk                    (refclk_1G),	                //! Signal d'horloge
        .nreset                 (nreset), 		                //! Signal de Reset (actif a l'etat bas)
        .spi_clk                (spi_clk),		                //! Horloge SPI
        .csn                    (csn),			                //! Chip select
        .mosi                   (mosi),			                //! Signal SPI mosi
        .miso                   (miso),			                //! Signal SPI miso
        .avallon_read           (spi_interface_read),           //! Signal positionne a "1" pour indiquer au bus avallon que l'on souhaite realiser une operation de lecture
        .avallon_write          (spi_interface_write),          //! Signal positionne a "1" pour indiquer au bus avallon que l'on souhaite realiser une operation d'ecriture
        .address                (spi_interface_address),		//! Adresse de lecture/ecriture sur le bus avallon
        .read_data_from_avallon (spi_interface_read_data),      //! Donnee de lecture a transmettre au processus SPI
        .write_data_to_avallon  (spi_interface_write_data),     //! Donnee d'ecriture a transmettre a l'interface avallon
        .acknowledge            (spi_interface_acknowledge),    //! Signal d'acknoledge provenant du bus avalon pour signaler que l'operation de lecture/ecriture est terminee.
        .byte_enable            (spi_interface_byte_enable)     //! Indique les octets a lire/ecrire dans le mot de 32 bits
    );

endmodule
