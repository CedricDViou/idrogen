vlog -work work -stats=none ../modules/ipbus-1G/wr_monitor.v
vlog -work work -stats=none wr_monitoring_tb.v

vsim work.testbench

add wave -position insertpoint  \
sim:/testbench/AMC_REFCLK_1G \
sim:/testbench/UART_CLOCK \
sim:/testbench/nreset \
sim:/testbench/bridge_uart_acknowledge

add wave -position insertpoint -radix hexadecimal sim:/testbench/bridge_uart_read_data

add wave -position insertpoint \
sim:/testbench/bridge_uart_read \
sim:/testbench/bridge_uart_write

add wave -position insertpoint -radix hexadecimal \
sim:/testbench/bridge_uart_byte_enable \
sim:/testbench/bridge_uart_address \
sim:/testbench/bridge_uart_write_data

add wave -position insertpoint -radix unsigned \
sim:/testbench/wr_monitor_dut/fifo_shift \
sim:/testbench/wr_monitor_dut/reg_fstate

configure wave -timelineunits ns

run 7000 ns