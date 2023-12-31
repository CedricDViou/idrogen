
set_time_format -unit ns -decimal_places 3


# free running clock 100MHz
create_clock -name CLKUSR         -period 10.0 [get_ports CLKUSR]
create_clock -name AMC_PCI_CLK    -period 10.0 [get_ports AMC_PCI_CLK]
create_clock -name REFCLK_40G     -period 156.25MHz [get_ports REFCLK_40G]
create_clock -name WR_REFCLK_125  -period  8.0 [get_ports WR_REFCLK_125]
create_clock -name WR_CLK_DMTD    -period  8.0 [get_ports WR_CLK_DMTD]
create_clock -name LMK_CLKREF_12  -period  8.0 [get_ports LMK_CLKREF_12] 
create_clock -name TRIGGER_IN     -period 100.0 [get_ports TRIGGER_IN]

derive_pll_clocks -create_base_clocks
derive_clock_uncertainty



# Cut the clock domains from each other
set_clock_groups -asynchronous                                                         \
    -group { CLKUSR                             }                                      \
    -group { AMC_PCI_CLK                        }                                      \
    -group { REFCLK_40G                         }                                      \
    -group { TRIGGER_IN                                                                \
             cmp_xwrc_board_idrogen_v3|cmp_ext_ref_pll|*outclk0 }                      \
    -group { WR_REFCLK_125                                                             \
             cmp_xwrc_board_idrogen_v3|cmp_sys_clk_pll|*outclk1 }                      \
    -group { cmp_xwrc_board_idrogen_v3|cmp_sys_clk_pll|*outclk0 }                      \
    -group { WR_CLK_DMTD                                                               \
             cmp_xwrc_board_idrogen_v3|cmp_dmtd_clk_pll|* }                            \
    -group { cmp_xwrc_board_idrogen_v3|cmp_xwrc_platform|*cmp_phy|*rx_clkout           \
             cmp_xwrc_board_idrogen_v3|cmp_xwrc_platform|*cmp_phy|*avmmclk             \
             cmp_xwrc_board_idrogen_v3|cmp_xwrc_platform|*cmp_phy|*tx_pma_clk          \
             cmp_xwrc_board_idrogen_v3|cmp_xwrc_platform|*cmp_phy|*rx_pma_clk          \
             cmp_xwrc_board_idrogen_v3|cmp_xwrc_platform|*cmp_phy|*tx_clkout           \
            }
 
#  -group { my_10G|IOPLL_half_clk_inst|iopll_0|outclk0 } \
# -group { my_10G|wrapper_inst|baser_inst|xcvr_native_a10_0|rx_clkout } \
# -group { my_10G|wrapper_inst|baser_inst|xcvr_native_a10_0|tx_clkout } \

set_false_path -to [get_ports LEDn[*]]
set_false_path -from [get_ports DEV_CLRn]

# False paths from/to all otherwise unconstrained I/
set_false_path -from [get_ports *]
set_false_path -to [get_ports *]