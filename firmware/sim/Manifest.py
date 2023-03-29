
target = "altera"
action = "synthesis"

syn_tool = "quartus"
syn_family = "Arria 10"
syn_device = "10AX027H4"
syn_grade = "I3SG"
syn_package = "F34"
syn_top = "arria10_phy_tb"
syn_project = "arria10_phy_sim"
syn_properties = [
	{"name": "VHDL_INPUT_VERSION", "value": "VHDL_2008"},
	{"name": "PHYSICAL_SYNTHESIS_EFFORT", "value": "NORMAL"}
]

files = [
	"../modules/wr_arria10_phy/xcvr_phy_reset_controller.qsys",
	"../modules/wr_arria10_phy/altera_xcvr_native_phy_a10.qsys",
	"../modules/wr_arria10_phy/ATX_pll_125_to_625.qsys",
	"../modules/wr_arria10_phy/arria10_phy.vhd",
	"arria10_phy_tb.vhd"
]
