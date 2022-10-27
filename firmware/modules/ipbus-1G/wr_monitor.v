module  wr_monitor(
    input  wire         clock,
    input  wire         nreset,
    input  wire         bridge_uart_acknowledge,
    input  wire [31:0]  bridge_uart_read_data,
    output reg          bridge_uart_read        = 0,
    output reg          bridge_uart_write       = 0,
    output reg  [ 3:0]  bridge_uart_byte_enable = 0,
    output reg  [ 5:0]  bridge_uart_address     = 0,
    output reg  [31:0]  bridge_uart_write_data  = 0
);

    localparam FIFO_ADDRESS         = 6'h10;
    localparam UART_ADDRESS_READ    = 6'h20;
    localparam UART_ADDRESS_STATUS  = 6'h28;

    localparam WAIT_READ   = 0;
    localparam READ_UART   = 1;
    localparam WRITE_FIFO  = 2;
    localparam RESET_ERROR = 4;

    reg [1:0] fifo_shift   = 0;
    reg [2:0] reg_fstate   = 0;

    always @(posedge clock or negedge nreset)
        begin : state_machine
            if (~nreset) begin
                reg_fstate              <= 0;
                bridge_uart_read        <= 0;
                bridge_uart_write       <= 0;
                bridge_uart_byte_enable <= 0;
                bridge_uart_address     <= 0;
                bridge_uart_write_data  <= 0;            
            end
            else begin
                case (reg_fstate)
                    WAIT_READ: begin
                        bridge_uart_read        <= 1;
                        bridge_uart_byte_enable <= 3;
                        bridge_uart_address     <= UART_ADDRESS_STATUS;
                        
                        if (bridge_uart_read_data[8]) begin
                            reg_fstate              <= RESET_ERROR;
                            bridge_uart_read        <= 0;
                            bridge_uart_byte_enable <= 0;
                        end
                        else if (bridge_uart_read_data[7]) begin
                            reg_fstate              <= READ_UART;
                            bridge_uart_read        <= 0;
                            bridge_uart_byte_enable <= 0;
                        end
                        else begin
                            reg_fstate <= WAIT_READ;
                        end
                    end
                    READ_UART: begin
                        bridge_uart_read        <= 1;
                        bridge_uart_byte_enable <= 1;
                        bridge_uart_address     <= UART_ADDRESS_READ;

                        if (bridge_uart_acknowledge) begin
                            bridge_uart_read        <= 0;
                            bridge_uart_byte_enable <= 0;
                            fifo_shift              <= fifo_shift + 1;
                            bridge_uart_write_data  <= {bridge_uart_write_data[23:0], bridge_uart_read_data[7:0]};

                            if (fifo_shift==3)
                                reg_fstate          <= WRITE_FIFO;
                            else
                                reg_fstate          <= WAIT_READ;
                        end
                        else begin
                            reg_fstate <= READ_UART;
                        end

                        
                    end
                    WRITE_FIFO: begin
                        bridge_uart_write       <= 1;
                        bridge_uart_byte_enable <= 4'hF;
                        bridge_uart_address     <= FIFO_ADDRESS;

                        if (bridge_uart_acknowledge) begin
                            reg_fstate              <= WAIT_READ;
                            bridge_uart_write       <= 0;
                            bridge_uart_write_data  <= 0;
                            bridge_uart_byte_enable <= 0;
                        end
                        else begin
                            reg_fstate <= WRITE_FIFO;
                        end
                    end
                    RESET_ERROR: begin
                        bridge_uart_write       <= 1;
                        bridge_uart_write_data  <= 0;
                        bridge_uart_byte_enable <= 3;
                        bridge_uart_address     <= UART_ADDRESS_STATUS;

                        if (bridge_uart_acknowledge) begin
                            reg_fstate              <= WAIT_READ;
                            bridge_uart_write       <= 0;
                            bridge_uart_byte_enable <= 0;
                        end
                        else begin
                            reg_fstate <= RESET_ERROR;
                        end
                    end
                    'd8: begin

                    end
                endcase
            end
        end
endmodule