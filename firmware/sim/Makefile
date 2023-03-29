
PROJECT ?= arria10_phy_sim

IPs = \
	../modules/wr_arria10_phy/xcvr_phy_reset_controller.qsys \
	../modules/wr_arria10_phy/altera_xcvr_native_phy_a10.qsys \
	../modules/wr_arria10_phy/ATX_pll_125_to_625.qsys

$(PROJECT).qpf:
	@hdlmake makefile -f Makefile.sim
	@make -f Makefile.sim project

project: $(PROJECT).qpf

qsys_gen: project
	@- $(foreach file, $(IPs), \
		qsys-generate --quartus-project=$(PROJECT).qpf --simulation=Verilog $(file); \
	)
	@touch $@

sim_setup: qsys_gen
	@ip-setup-simulation --quartus-project=$(PROJECT).qpf --output-directory=./modelsim --use-relative-paths --compile-to-work
	@touch $@

sim: sim_setup
	@vsim -do sim_tb.do

clean:
	@make -f Makefile.sim clean 
	@rm -rf Makefile.sim qdb modelsim output_files sim_setup libraries modelsim.ini transcript qsys_gen
