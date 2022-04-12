post_message "Assigning pinout"

# Load Quartus II Tcl Project package
package require ::quartus::project

project_open -revision idrogen_v3_ref_design idrogen_v3_ref_design 


# set_instance_assignment -name IO_STANDARD "1.8 V" -to FPGA2UC_PWRDWN  # not connected anymore
set_instance_assignment -name IO_STANDARD "1.8 V" -to DEV_CLRn
set_instance_assignment -name IO_STANDARD "1.8 V" -to CLKUSR


set_instance_assignment -name IO_STANDARD "1.8 V" -to USB_RESETn
set_instance_assignment -name IO_STANDARD "1.8 V" -to USB_CLK
# Missing connection to MAX10
# set_instance_assignment -name IO_STANDARD "1.8 V" -to USB_SCL
# set_instance_assignment -name IO_STANDARD "1.8 V" -to USB_SDA
set_instance_assignment -name IO_STANDARD "1.8 V" -to USB_ADDR
set_instance_assignment -name IO_STANDARD "1.8 V" -to USB_DATA
set_instance_assignment -name IO_STANDARD "1.8 V" -to USB_OEn
set_instance_assignment -name IO_STANDARD "1.8 V" -to USB_RDn
set_instance_assignment -name IO_STANDARD "1.8 V" -to USB_WRn
set_instance_assignment -name IO_STANDARD "1.8 V" -to USB_EMPTY
set_instance_assignment -name IO_STANDARD "1.8 V" -to USB_FULL

set_instance_assignment -name IO_STANDARD "1.8 V" -to SYNC_LMK
set_instance_assignment -name IO_STANDARD LVDS -to FPGA_CLK_2_SI5338

set_instance_assignment -name IO_STANDARD "1.8 V" -to uC_RST
set_instance_assignment -name IO_STANDARD "1.8 V" -to uC_SPI_A10_IS_MASTER
set_instance_assignment -name IO_STANDARD "1.8 V" -to uC_INT
set_instance_assignment -name IO_STANDARD "1.8 V" -to uC_MISO
set_instance_assignment -name IO_STANDARD "1.8 V" -to uC_MOSI
set_instance_assignment -name IO_STANDARD "1.8 V" -to uC_SCLK
set_instance_assignment -name IO_STANDARD "1.8 V" -to uC_CSn

set_instance_assignment -name IO_STANDARD "1.8 V" -to LEDn

set_instance_assignment -name IO_STANDARD LVDS -to LMK_CLKREF_2
set_instance_assignment -name IO_STANDARD LVDS -to LMK_CLKREF_4
set_instance_assignment -name IO_STANDARD LVDS -to LMK_SYSREF_5
set_instance_assignment -name IO_STANDARD LVDS -to LMK_CLKREF_12

set_instance_assignment -name IO_STANDARD "HIGH SPEED DIFFERENTIAL I/O" -to AMC_1GbE_RX
set_instance_assignment -name IO_STANDARD "HIGH SPEED DIFFERENTIAL I/O" -to AMC_1GbE_TX
set_instance_assignment -name IO_STANDARD LVDS -to AMC_CLK1
set_instance_assignment -name IO_STANDARD LVDS -to AMC_CLK2
set_instance_assignment -name IO_STANDARD "1.8 V" -to PWR_RSTn
set_instance_assignment -name IO_STANDARD "HIGH SPEED DIFFERENTIAL I/O" -to AMC_PCIE_RX
set_instance_assignment -name IO_STANDARD "HIGH SPEED DIFFERENTIAL I/O" -to AMC_PCIE_TX
set_instance_assignment -name IO_STANDARD HCSL -to AMC_PCI_CLK
set_instance_assignment -name IO_STANDARD LVDS -to AMC_REFCLK_1G
set_instance_assignment -name IO_STANDARD LVDS -to AMC_TRIGA_0
set_instance_assignment -name IO_STANDARD LVDS -to AMC_TRIGA_1

set_instance_assignment -name IO_STANDARD LVDS -to RTM30_P0
set_instance_assignment -name IO_STANDARD LVDS -to RTM30_P1
set_instance_assignment -name IO_STANDARD LVDS -to RTM30_P2

set_instance_assignment -name IO_STANDARD "HIGH SPEED DIFFERENTIAL I/O" -to QSFP_RX
set_instance_assignment -name IO_STANDARD "HIGH SPEED DIFFERENTIAL I/O" -to QSFP_TX

set_instance_assignment -name IO_STANDARD LVDS -to VIta57_CLK0_M2C
set_instance_assignment -name IO_STANDARD LVDS -to VIta57_CLK1_M2C
set_instance_assignment -name IO_STANDARD LVDS -to VIta57_CLK2_BIDIR
set_instance_assignment -name IO_STANDARD "HIGH SPEED DIFFERENTIAL I/O" -to VIta57_DP_C2M
set_instance_assignment -name IO_STANDARD "HIGH SPEED DIFFERENTIAL I/O" -to VIta57_DP_M2C
set_instance_assignment -name IO_STANDARD LVDS -to VIta57_GBTCLK0_M2C
set_instance_assignment -name IO_STANDARD LVDS -to VIta57_GBTCLK1_M2C
set_instance_assignment -name IO_STANDARD LVDS -to VIta57_HA_CC[0]
set_instance_assignment -name IO_STANDARD LVDS -to VIta57_HA
set_instance_assignment -name IO_STANDARD LVDS -to VIta57_HB_CC[0]
set_instance_assignment -name IO_STANDARD LVDS -to VIta57_HB
set_instance_assignment -name IO_STANDARD LVDS -to VIta57_LA_CC[0]
set_instance_assignment -name IO_STANDARD LVDS -to VIta57_LA

set_instance_assignment -name IO_STANDARD "1.8 V" -to QSFP_ModIntL
set_instance_assignment -name IO_STANDARD "1.8 V" -to QSFP_ModLP
set_instance_assignment -name IO_STANDARD "1.8 V" -to QSFP_ModPrsL
set_instance_assignment -name IO_STANDARD "1.8 V" -to QSFP_ModRtL
set_instance_assignment -name IO_STANDARD "1.8 V" -to QSFP_ModSelL
set_instance_assignment -name IO_STANDARD "1.8 V" -to QSFP_SCL_b
set_instance_assignment -name IO_STANDARD "1.8 V" -to QSFP_SDA_b
set_instance_assignment -name IO_STANDARD LVDS -to REFCLK_40G


# Do not use
set_instance_assignment -name IO_STANDARD "1.8 V" -to SPARE_UC
set_instance_assignment -name IO_STANDARD "1.8 V" -to SW_USER



set_instance_assignment -name IO_STANDARD "1.8 V" -to WR_DAC_SCLK
set_instance_assignment -name IO_STANDARD "1.8 V" -to WR_DAC1_SYNCn
set_instance_assignment -name IO_STANDARD "1.8 V" -to WR_DAC2_SYNCn
set_instance_assignment -name IO_STANDARD "1.8 V" -to WR_DAC_DIN
set_instance_assignment -name IO_STANDARD "1.8 V" -to WR_CLK_DMTD
set_instance_assignment -name IO_STANDARD LVDS -to WR_REFCLK_125
set_instance_assignment -name IO_STANDARD "1.8 V" -to WR_SCL_FLASH_b
set_instance_assignment -name IO_STANDARD "1.8 V" -to WR_SDA_FLASH_b
set_instance_assignment -name IO_STANDARD "1.8 V" -to WR_SERNUM_b
set_instance_assignment -name IO_STANDARD "1.8 V" -to WR_SFP_LOS
set_instance_assignment -name IO_STANDARD "1.8 V" -to WR_SFP_DET_i
set_instance_assignment -name IO_STANDARD "1.8 V" -to WR_SFP_TXFAULT
set_instance_assignment -name IO_STANDARD "1.8 V" -to WR_SFP_TxDisable
set_instance_assignment -name IO_STANDARD "1.8 V" -to WR_SFP_scl_b
set_instance_assignment -name IO_STANDARD "1.8 V" -to WR_SFP_sda_b
set_instance_assignment -name IO_STANDARD "1.8 V" -to WR_SFP_RATE_SELECT
set_instance_assignment -name IO_STANDARD "HIGH SPEED DIFFERENTIAL I/O" -to WR_SFP_RX
set_instance_assignment -name IO_STANDARD "HIGH SPEED DIFFERENTIAL I/O" -to WR_SFP_TX
set_instance_assignment -name IO_STANDARD "1.8 V" -to WR_RX_to_UART
set_instance_assignment -name IO_STANDARD "1.8 V" -to WR_TX_from_UART

set_instance_assignment -name IO_STANDARD LVDS -to PPS_IN
set_instance_assignment -name IO_STANDARD LVDS -to PPS_OUT
set_instance_assignment -name IO_STANDARD LVDS -to TRIGGER_IN_P
set_instance_assignment -name IO_STANDARD LVDS -to TRIGGER_OUT_P


############## LOCATION - NET ##################

set_location_assignment PIN_AC17 -to DEV_CLRn
set_location_assignment PIN_AK16 -to CLKUSR
set_global_assignment -name AUTO_RESERVE_CLKUSR_FOR_CALIBRATION OFF

set_location_assignment PIN_AC24 -to USB_RESETn
set_location_assignment PIN_AN24 -to USB_CLK
# Missing connection to MAX10
# set_location_assignment PIN_ -to USB_SCL
# set_location_assignment PIN_ -to USB_SDA
set_location_assignment PIN_AP27 -to USB_ADDR[0]
set_location_assignment PIN_AK26 -to USB_ADDR[1]
set_location_assignment PIN_AE24 -to USB_DATA[0]
set_location_assignment PIN_AM27 -to USB_DATA[1]
set_location_assignment PIN_AJ26 -to USB_DATA[2]
set_location_assignment PIN_AH25 -to USB_DATA[3]
set_location_assignment PIN_AD25 -to USB_DATA[4]
set_location_assignment PIN_AM26 -to USB_DATA[5]
set_location_assignment PIN_AH27 -to USB_DATA[6]
set_location_assignment PIN_AG25 -to USB_DATA[7]
set_location_assignment PIN_AH26 -to USB_OEn
set_location_assignment PIN_AF24 -to USB_RDn
set_location_assignment PIN_AJ27 -to USB_WRn
set_location_assignment PIN_AD24 -to USB_EMPTY
set_location_assignment PIN_AK27 -to USB_FULL

set_location_assignment PIN_AP24 -to SYNC_LMK
set_location_assignment PIN_AL16 -to FPGA_CLK_2_SI5338

set_location_assignment PIN_AP26 -to uC_RST
set_location_assignment PIN_AL25 -to uC_SPI_A10_IS_MASTER
set_location_assignment PIN_AF25 -to uC_INT
set_location_assignment PIN_AM23 -to uC_MISO
set_location_assignment PIN_AJ25 -to uC_MOSI
set_location_assignment PIN_AN23 -to uC_SCLK
set_location_assignment PIN_AL24 -to uC_CSn

set_location_assignment PIN_AN13 -to LEDn[0]
set_location_assignment PIN_AP14 -to LEDn[1]
set_location_assignment PIN_AN14 -to LEDn[2]
set_location_assignment PIN_AP9 -to LEDn[3]

set_location_assignment PIN_E23 -to LMK_CLKREF_2
set_location_assignment PIN_AL27 -to LMK_CLKREF_4
set_location_assignment PIN_AJ22 -to LMK_SYSREF_5
set_location_assignment PIN_T28 -to LMK_CLKREF_12

set_location_assignment PIN_AJ30 -to AMC_1GbE_RX[0]
set_location_assignment PIN_AL30 -to AMC_1GbE_RX[1]
set_location_assignment PIN_AM32 -to AMC_1GbE_TX[0]
set_location_assignment PIN_AP32 -to AMC_1GbE_TX[1]
set_location_assignment PIN_AD28 -to AMC_CLK1
set_location_assignment PIN_AM3 -to AMC_CLK2
set_location_assignment PIN_AE16 -to AMC_NPERSTL
set_location_assignment PIN_AE30 -to AMC_PCIE_RX[0]
set_location_assignment PIN_AD32 -to AMC_PCIE_RX[1]
set_location_assignment PIN_AC30 -to AMC_PCIE_RX[2]
set_location_assignment PIN_AB32 -to AMC_PCIE_RX[3]
set_location_assignment PIN_AN34 -to AMC_PCIE_TX[0]
set_location_assignment PIN_AL34 -to AMC_PCIE_TX[1]
set_location_assignment PIN_AJ34 -to AMC_PCIE_TX[2]
set_location_assignment PIN_AG34 -to AMC_PCIE_TX[3]
set_location_assignment PIN_AB28 -to AMC_PCI_CLK
set_location_assignment PIN_AF28 -to AMC_REFCLK_1G
set_location_assignment PIN_AL23 -to AMC_TRIGA_0
set_location_assignment PIN_AJ24 -to AMC_TRIGA_1

set_location_assignment PIN_AF1 -to RTM30_P0[0]
set_location_assignment PIN_AC4 -to RTM30_P0[1]
set_location_assignment PIN_AJ1 -to RTM30_P0[2]
set_location_assignment PIN_AH3 -to RTM30_P0[3]
set_location_assignment PIN_AL1 -to RTM30_P0[4]
set_location_assignment PIN_AK2 -to RTM30_P0[5]
set_location_assignment PIN_AG5 -to RTM30_P0[6]
set_location_assignment PIN_AG6 -to RTM30_P0[7]
set_location_assignment PIN_AM1 -to RTM30_P1[0]
set_location_assignment PIN_AH7 -to RTM30_P1[1]
set_location_assignment PIN_AL5 -to RTM30_P1[2]
set_location_assignment PIN_AK7 -to RTM30_P1[3]
set_location_assignment PIN_AM6 -to RTM30_P1[4]
set_location_assignment PIN_AH10 -to RTM30_P1[5]
set_location_assignment PIN_AP5 -to RTM30_P1[6]
set_location_assignment PIN_AL9 -to RTM30_P1[7]
set_location_assignment PIN_AB1 -to RTM30_P2[2]
set_location_assignment PIN_AC3 -to RTM30_P2[3]
set_location_assignment PIN_AL13 -to RTM30_P2[4]
set_location_assignment PIN_AN7 -to RTM30_P2[5]
set_location_assignment PIN_AL14 -to RTM30_P2[6]
set_location_assignment PIN_AN8 -to RTM30_P2[7]

set_location_assignment PIN_J30 -to QSFP_RX[0]
set_location_assignment PIN_G30 -to QSFP_RX[1]
set_location_assignment PIN_L30 -to QSFP_RX[2]
set_location_assignment PIN_K32 -to QSFP_RX[3]
set_location_assignment PIN_H32 -to QSFP_TX[0]
set_location_assignment PIN_F32 -to QSFP_TX[1]
set_location_assignment PIN_E34 -to QSFP_TX[2]
set_location_assignment PIN_C34 -to QSFP_TX[3]

set_location_assignment PIN_K6 -to VIta57_CLK0_M2C
set_location_assignment PIN_K25 -to VIta57_CLK1_M2C
set_location_assignment PIN_M6 -to VIta57_CLK2_BIDIR
set_location_assignment PIN_G34 -to VIta57_DP_C2M[0]
set_location_assignment PIN_J34 -to VIta57_DP_C2M[1]
set_location_assignment PIN_N34 -to VIta57_DP_C2M[2]
set_location_assignment PIN_U34 -to VIta57_DP_C2M[3]
set_location_assignment PIN_AA34 -to VIta57_DP_C2M[4]
set_location_assignment PIN_AC34 -to VIta57_DP_C2M[5]
set_location_assignment PIN_W34 -to VIta57_DP_C2M[6]
set_location_assignment PIN_R34 -to VIta57_DP_C2M[7]
set_location_assignment PIN_L34 -to VIta57_DP_C2M[8]
set_location_assignment PIN_AE34 -to VIta57_DP_C2M[9]
set_location_assignment PIN_M32 -to VIta57_DP_M2C[0]
set_location_assignment PIN_N30 -to VIta57_DP_M2C[1]
set_location_assignment PIN_R30 -to VIta57_DP_M2C[2]
set_location_assignment PIN_U30 -to VIta57_DP_M2C[3]
set_location_assignment PIN_W30 -to VIta57_DP_M2C[4]
set_location_assignment PIN_Y32 -to VIta57_DP_M2C[5]
set_location_assignment PIN_V32 -to VIta57_DP_M2C[6]
set_location_assignment PIN_T32 -to VIta57_DP_M2C[7]
set_location_assignment PIN_P32 -to VIta57_DP_M2C[8]
set_location_assignment PIN_AA30 -to VIta57_DP_M2C[9]
set_location_assignment PIN_Y28 -to VIta57_GBTCLK0_M2C
set_location_assignment PIN_V28 -to VIta57_GBTCLK1_M2C
set_location_assignment PIN_B23 -to VIta57_HA[1]
set_location_assignment PIN_C27 -to VIta57_HA[2]
set_location_assignment PIN_AB10 -to VIta57_HA[3]
set_location_assignment PIN_J4 -to VIta57_HA[4]
set_location_assignment PIN_N8 -to VIta57_HA[5]
set_location_assignment PIN_C24 -to VIta57_HA[6]
set_location_assignment PIN_N9 -to VIta57_HA[7]
set_location_assignment PIN_M5 -to VIta57_HA[8]
set_location_assignment PIN_R8 -to VIta57_HA[9]
set_location_assignment PIN_N7 -to VIta57_HA[10]
set_location_assignment PIN_U6 -to VIta57_HA[11]
set_location_assignment PIN_T5 -to VIta57_HA[12]
set_location_assignment PIN_Y8 -to VIta57_HA[13]
set_location_assignment PIN_K1 -to VIta57_HA[14]
set_location_assignment PIN_U3 -to VIta57_HA[15]
set_location_assignment PIN_T4 -to VIta57_HA[16]
set_location_assignment PIN_J1 -to VIta57_HA[17]
set_location_assignment PIN_W6 -to VIta57_HA[18]
set_location_assignment PIN_Y3 -to VIta57_HA[19]
set_location_assignment PIN_R1 -to VIta57_HA[20]
set_location_assignment PIN_M2 -to VIta57_HA[21]
set_location_assignment PIN_U1 -to VIta57_HA[22]
set_location_assignment PIN_P4 -to VIta57_HA[23]
set_location_assignment PIN_R6 -to VIta57_HA_CC[0]
set_location_assignment PIN_E27 -to VIta57_HB[1]
set_location_assignment PIN_AB8 -to VIta57_HB[2]
set_location_assignment PIN_AC9 -to VIta57_HB[3]
set_location_assignment PIN_AD5 -to VIta57_HB[4]
set_location_assignment PIN_AF8 -to VIta57_HB[5]
set_location_assignment PIN_E26 -to VIta57_HB[6]
set_location_assignment PIN_AG10 -to VIta57_HB[7]
set_location_assignment PIN_AE4 -to VIta57_HB[8]
set_location_assignment PIN_AB2 -to VIta57_HB[9]
set_location_assignment PIN_F25 -to VIta57_HB[10]
set_location_assignment PIN_G26 -to VIta57_HB[11]
set_location_assignment PIN_AL6 -to VIta57_HB[12]
set_location_assignment PIN_AJ5 -to VIta57_HB[13]
set_location_assignment PIN_E22 -to VIta57_HB[14]
set_location_assignment PIN_D25 -to VIta57_HB[15]
set_location_assignment PIN_AK4 -to VIta57_HB[16]
set_location_assignment PIN_H25 -to VIta57_HB[17]
set_location_assignment PIN_H24 -to VIta57_HB[18]
set_location_assignment PIN_AJ4 -to VIta57_HB[19]
set_location_assignment PIN_K23 -to VIta57_HB[20]
set_location_assignment PIN_L23 -to VIta57_HB[21]
set_location_assignment PIN_AE2 -to VIta57_HB_CC[0]
set_location_assignment PIN_V7 -to VIta57_LA[1]
set_location_assignment PIN_T9 -to VIta57_LA[2]
set_location_assignment PIN_L3 -to VIta57_LA[3]
set_location_assignment PIN_N4 -to VIta57_LA[4]
set_location_assignment PIN_G23 -to VIta57_LA[5]
set_location_assignment PIN_H22 -to VIta57_LA[6]
set_location_assignment PIN_P2 -to VIta57_LA[7]
set_location_assignment PIN_V5 -to VIta57_LA[8]
set_location_assignment PIN_U10 -to VIta57_LA[9]
set_location_assignment PIN_W10 -to VIta57_LA[10]
set_location_assignment PIN_K24 -to VIta57_LA[11]
set_location_assignment PIN_L4 -to VIta57_LA[12]
set_location_assignment PIN_M1 -to VIta57_LA[13]
set_location_assignment PIN_AA8 -to VIta57_LA[14]
set_location_assignment PIN_U8 -to VIta57_LA[15]
set_location_assignment PIN_V9 -to VIta57_LA[16]
set_location_assignment PIN_AE12 -to VIta57_LA[17]
set_location_assignment PIN_AA5 -to VIta57_LA[18]
set_location_assignment PIN_N2 -to VIta57_LA[19]
set_location_assignment PIN_T3 -to VIta57_LA[20]
set_location_assignment PIN_AD10 -to VIta57_LA[21]
set_location_assignment PIN_W4 -to VIta57_LA[22]
set_location_assignment PIN_AF11 -to VIta57_LA[23]
set_location_assignment PIN_AB6 -to VIta57_LA[24]
set_location_assignment PIN_AD7 -to VIta57_LA[25]
set_location_assignment PIN_W1 -to VIta57_LA[26]
set_location_assignment PIN_Y1 -to VIta57_LA[27]
set_location_assignment PIN_AF9 -to VIta57_LA[28]
set_location_assignment PIN_AA3 -to VIta57_LA[29]
set_location_assignment PIN_AH8 -to VIta57_LA[30]
set_location_assignment PIN_AD2 -to VIta57_LA[31]
set_location_assignment PIN_AF4 -to VIta57_LA[32]
set_location_assignment PIN_AG1 -to VIta57_LA[33]
set_location_assignment PIN_Y6 -to VIta57_LA_CC[0]




set_location_assignment PIN_A21 -to QSFP_ModIntL
set_location_assignment PIN_A18 -to QSFP_ModLP
set_location_assignment PIN_A23 -to QSFP_ModPrsL
set_location_assignment PIN_A20 -to QSFP_ModRtL
set_location_assignment PIN_A19 -to QSFP_ModSelL
set_location_assignment PIN_B21 -to QSFP_SCL_b
set_location_assignment PIN_A24 -to QSFP_SDA_b
set_location_assignment PIN_P28 -to REFCLK_40G

set_location_assignment PIN_AN27 -to SPARE_UC[0]
set_location_assignment PIN_AN25 -to SPARE_UC[1]
set_location_assignment PIN_AP15 -to SW_USER



set_location_assignment PIN_AP17 -to WR_DAC_SCLK
set_location_assignment PIN_AN18 -to WR_DAC1_SYNCn
set_location_assignment PIN_AP21 -to WR_DAC2_SYNCn
set_location_assignment PIN_AM22 -to WR_DAC_DIN
set_location_assignment PIN_AH19 -to WR_CLK_DMTD
set_location_assignment PIN_M28 -to WR_REFCLK_125
set_location_assignment PIN_AP22 -to WR_SCL_FLASH_b
set_location_assignment PIN_AN22 -to WR_SDA_FLASH_b
set_location_assignment PIN_AP20 -to WR_SERNUM_b
set_location_assignment PIN_B22 -to WR_SFP_LOS
set_location_assignment PIN_C20 -to WR_SFP_DET_i
set_location_assignment PIN_D17 -to WR_SFP_TXFAULT
set_location_assignment PIN_C18 -to WR_SFP_TxDisable
set_location_assignment PIN_C19 -to WR_SFP_scl_b
set_location_assignment PIN_B18 -to WR_SFP_sda_b
set_location_assignment PIN_B20 -to WR_SFP_RATE_SELECT
set_location_assignment PIN_C30 -to WR_SFP_RX
set_location_assignment PIN_B32 -to WR_SFP_TX
set_location_assignment PIN_AP16 -to WR_RX_to_UART
set_location_assignment PIN_AN20 -to WR_TX_from_UART

set_location_assignment PIN_J27 -to PPS_IN
set_location_assignment PIN_AF23 -to PPS_OUT
set_location_assignment PIN_H27 -to TRIGGER_IN
set_location_assignment PIN_AH23 -to TRIGGER_OUT

