# Summary of QSYS IP addresses

## PCIe

| **Register**      |  **Base** |  **End**  |
|-------------------|:---------:|:---------:|
| PCIe rd_dts_slave | 8000_0000 | 8000_1FFF |
| PCIe wr_dts_slave | 8000_2000 | 8000_3FFF |
| SysId             |      A000 |      A007 |
| Pio               |      8000 |      800F |
| UART              |      2000 |      201F |

## Ipbus 1G

| **Register**        | **Base** | **End** |
|---------------------|:--------:|:-------:|
| SysId               |     0040 |    0047 |
| Pio for SPI         |     0080 |    008F |
| UART                |     1040 |    105F |
| Pio for MAC Address |     1080 |    108F |
