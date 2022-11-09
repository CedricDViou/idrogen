module jtag_2_uart (
    input  wire clk,
    input  wire nreset,
    input  wire jtag_uart_rxd,
    output wire jtag_uart_txd
);

    wire        bridge_uart_read;
    wire        bridge_uart_write;
    wire        bridge_uart_acknowledge;
    wire [ 3:0] bridge_uart_byte_enable;
    wire [ 8:0] bridge_uart_address;
    wire [31:0] bridge_uart_read_data;
    wire [31:0] bridge_uart_write_data;

    jtag_uart_qsys jtag_uart_qsys_inst (
        .clk_clk            (clk),                      //   input,   width = 1,       clk.clk
        .reset_reset_n      (nreset),                   //   input,   width = 1,     reset.reset_n
        .bridge_read        (bridge_uart_read),         //   input,   width = 1,          .read
        .bridge_write       (bridge_uart_write),        //   input,   width = 1,          .write
        .bridge_byte_enable (bridge_uart_byte_enable),  //   input,   width = 4,          .byte_enable
        .bridge_address     (bridge_uart_address),      //   input,   width = 9,    bridge.address
        .bridge_acknowledge (bridge_uart_acknowledge),  //  output,   width = 1,          .acknowledge
        .bridge_read_data   (bridge_uart_read_data),    //  output,  width = 32,          .read_data
        .bridge_write_data  (bridge_uart_write_data),   //   input,  width = 32,          .write_data
        .jtag_uart_rxd      (jtag_uart_rxd),            //   input,   width = 1, jtag_uart.rxd
        .jtag_uart_txd      (jtag_uart_txd)             //  output,   width = 1,          .txd
    );

    wr_monitor wr_monitor_inst (
        .clock                   (clk),
        .nreset                  (nreset),
        .bridge_uart_read        (bridge_uart_read),
        .bridge_uart_write       (bridge_uart_write),
        .bridge_uart_byte_enable (bridge_uart_byte_enable),
        .bridge_uart_address     (bridge_uart_address),
        .bridge_uart_acknowledge (bridge_uart_acknowledge),
        .bridge_uart_read_data   (bridge_uart_read_data),
        .bridge_uart_write_data  (bridge_uart_write_data)
    );

endmodule