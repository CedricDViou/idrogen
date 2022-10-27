`timescale 1 ns/10 ps

module testbench ();

    localparam clk_period  = 8  ;
    localparam uart_period = 80 ;

    reg         AMC_REFCLK_1G = 0;
    reg         UART_CLOCK    = 0;
    reg         nreset        = 1;

    reg         bridge_uart_acknowledge = 0 ;
    reg  [31:0] bridge_uart_read_data   = 0 ;
    wire        bridge_uart_read            ;
    wire        bridge_uart_write           ;
    wire [ 3:0] bridge_uart_byte_enable     ;
    wire [ 5:0] bridge_uart_address         ;
    wire [31:0] bridge_uart_write_data      ;

      wr_monitor wr_monitor_dut (
        .clock                      (AMC_REFCLK_1G),
        .nreset                     (nreset),
        .bridge_uart_acknowledge    (bridge_uart_acknowledge),
        .bridge_uart_read           (bridge_uart_read),
        .bridge_uart_read_data      (bridge_uart_read_data),
        .bridge_uart_write          (bridge_uart_write),
        .bridge_uart_byte_enable    (bridge_uart_byte_enable),
        .bridge_uart_address        (bridge_uart_address),
        .bridge_uart_write_data     (bridge_uart_write_data)
    );


    initial begin
        begin
            $dumpfile("output.vcd");

            #(clk_period/2);
            nreset = 0;
            #(2*clk_period);
            nreset = 1;
            #(clk_period/2);

            // Reset status
            @(posedge bridge_uart_read);
            bridge_uart_read_data   = 32'h168;
            bridge_uart_acknowledge = 1;
            @(negedge bridge_uart_read);
            bridge_uart_read_data   = 32'h0;
            bridge_uart_acknowledge = 0;

            @(posedge bridge_uart_write);
            bridge_uart_acknowledge = 1;
            @(negedge bridge_uart_write);
            bridge_uart_acknowledge = 0;

            // Read char "g"
            @(posedge bridge_uart_read);
            bridge_uart_acknowledge = 1;
            @(posedge UART_CLOCK);
            bridge_uart_read_data   = 32'h80;
            @(negedge bridge_uart_read);
            bridge_uart_acknowledge = 0;
            bridge_uart_read_data   = 32'h0;

            @(posedge bridge_uart_read);
            bridge_uart_read_data   = 32'h67;
            bridge_uart_acknowledge = 1;
            @(negedge bridge_uart_read);
            bridge_uart_acknowledge = 0;
            bridge_uart_read_data   = 32'h0;

            // Read char "u"
            @(posedge bridge_uart_read);
            bridge_uart_acknowledge = 1;
            @(posedge UART_CLOCK);
            bridge_uart_read_data   = 32'h80;
            @(negedge bridge_uart_read);
            bridge_uart_acknowledge = 0;
            bridge_uart_read_data   = 32'h0;

            @(posedge bridge_uart_read);
            bridge_uart_read_data   = 32'h75;
            bridge_uart_acknowledge = 1;
            @(negedge bridge_uart_read);
            bridge_uart_acknowledge = 0;
            bridge_uart_read_data   = 32'h0;

            // Read char "i"
            @(posedge bridge_uart_read);
            bridge_uart_acknowledge = 1;
            @(posedge UART_CLOCK);
            bridge_uart_read_data   = 32'h80;
            @(negedge bridge_uart_read);
            bridge_uart_acknowledge = 0;
            bridge_uart_read_data   = 32'h0;

            @(posedge bridge_uart_read);
            bridge_uart_read_data   = 32'h69;
            bridge_uart_acknowledge = 1;
            @(negedge bridge_uart_read);
            bridge_uart_acknowledge = 0;
            bridge_uart_read_data   = 32'h0;

            // Read char "\r"
            @(posedge bridge_uart_read);
            bridge_uart_acknowledge = 1;
            @(posedge UART_CLOCK);
            bridge_uart_read_data   = 32'h80;
            @(negedge bridge_uart_read);
            bridge_uart_acknowledge = 0;
            bridge_uart_read_data   = 32'h0;

            @(posedge bridge_uart_read);
            bridge_uart_read_data   = 32'hA;
            bridge_uart_acknowledge = 1;
            @(negedge bridge_uart_read);
            bridge_uart_acknowledge = 0;
            bridge_uart_read_data   = 32'h0;

            //Write in FIFO
            @(posedge bridge_uart_write);
            bridge_uart_acknowledge = 1;
            @(negedge bridge_uart_write);
            bridge_uart_acknowledge = 0;

            #(10*clk_period)

            $dumpvars;
            $finish;
        end
    end

    always begin
        #(clk_period);
	    AMC_REFCLK_1G = !AMC_REFCLK_1G;
    end

    always begin
        #(uart_period);
	    UART_CLOCK = !UART_CLOCK;
    end
        
endmodule
