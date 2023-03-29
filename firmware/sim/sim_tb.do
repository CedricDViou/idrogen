# Set hierarchy variables used in the IP-generated files
set TOP_LEVEL_NAME "arria10_phy_tb"
set QSYS_SIMDIR "modelsim"

# Source generated simulation script which defines aliases used below
source $QSYS_SIMDIR/mentor/msim_setup.tcl

# dev_com alias compiles simulation libraries for device library files
dev_com

# com alias compiles IP simulation or Platform Designer model files and/or
com

vlog -work work /home/intelFPGA_pro/19.3/quartus/eda/sim_lib/twentynm_hip_atoms.v
vlog -work work /home/intelFPGA_pro/19.3/quartus/eda/sim_lib/twentynm_hssi_atoms.v
vlog -work work /home/intelFPGA_pro/19.3/quartus/eda/sim_lib/twentynm_atoms.v


# Compile top level testbench that instantiates your IP
vcom -work work ../modules/wr_arria10_phy/arria10_phy.vhd
vcom -work work ./arria10_phy_tb.vhd


# elab alias elaborates testbench
# to solve "recompile work.alt_xcrv_pll_avmm_csr beacuse a.avmm.h package has changed" error
vlog -work ./libraries/work/ -refresh -force_refresh

#elab
# to solve verilog fs timescale issue
elab -t 1ns -L ./libraries/work/

# List of signals to display

#add wave -position insertpoint  \
#sim:/arria10_phy_tb/clk_reconf
#sim:/arria10_phy_tb/clk_reconf_rst
