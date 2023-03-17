# PREFIX  controls where programs and libraries get installed
# STAGING can be used to store 'install' output into a staging folder
# Note: during compile (all), PREFIX must be set to the final installation path
# Example usage:
#   make PREFIX=/usr all
#   make STAGING=/tmp/package PREFIX=/usr install
#   ... will compile the programs to expect installation into /usr, but
#       will actually install them into /tmp/package/usr for zipping.
STAGING     ?=
PREFIX      ?= /usr/local
EXTRA_FLAGS ?=
PWD         := $(shell pwd)

all::		etherbone eca tlu sdbfs toolchain firmware driver

gateware:	all idrogen_v3_ref_design

install::	etherbone-install tools-install eca-install tlu-install driver-install

clean::		etherbone-clean tools-clean eca-clean tlu-clean sdbfs-clean driver-clean toolchain-clean firmware-clean idrogen_v3_wr_ref_design-clean

distclean::	clean
	git clean -xfd .
	for i in etherbone-core fpga-config-space general-cores wr-cores wrpc-sw; do cd ip_cores/$$i; git clean -xfd .; cd ../..; done

etherbone::
	test -f ip_cores/etherbone-core/api/Makefile.in || ./ip_cores/etherbone-core/api/autogen.sh
	cd ip_cores/etherbone-core/api; test -f Makefile || ./configure --enable-maintainer-mode --prefix=$(PREFIX)
	$(MAKE) -C ip_cores/etherbone-core/api EXTRA_FLAGS="$(EXTRA_FLAGS)" all

etherbone-clean::
	$(MAKE) -C ip_cores/etherbone-core/api EXTRA_FLAGS="$(EXTRA_FLAGS)" distclean

etherbone-install::
	$(MAKE) -C ip_cores/etherbone-core/api EXTRA_FLAGS="$(EXTRA_FLAGS)" DESTDIR=$(STAGING) install

tools::		etherbone eca tlu
	$(MAKE) -C tools ECA=$(PWD)/ip_cores/wr-cores/modules/wr_eca TLU=$(PWD)/ip_cores/wr-cores/modules/wr_tlu EB=$(PWD)/ip_cores/etherbone-core/api EXTRA_FLAGS="$(EXTRA_FLAGS)" all

tools-clean::
	$(MAKE) -C tools ECA=$(PWD)/ip_cores/wr-cores/modules/wr_eca TLU=$(PWD)/ip_cores/wr-cores/modules/wr_tlu EB=$(PWD)/ip_cores/etherbone-core/api EXTRA_FLAGS="$(EXTRA_FLAGS)" clean

tools-install::
	$(MAKE) -C tools ECA=$(PWD)/ip_cores/wr-cores/modules/wr_eca TLU=$(PWD)/ip_cores/wr-cores/modules/wr_tlu EB=$(PWD)/ip_cores/etherbone-core/api EXTRA_FLAGS="$(EXTRA_FLAGS)" install

eca::		etherbone
	$(MAKE) -C ip_cores/wr-cores/modules/wr_eca EB=$(PWD)/ip_cores/etherbone-core/api EXTRA_FLAGS="$(EXTRA_FLAGS)" all

eca-clean::
	$(MAKE) -C ip_cores/wr-cores/modules/wr_eca EB=$(PWD)/ip_cores/etherbone-core/api EXTRA_FLAGS="$(EXTRA_FLAGS)" clean

eca-install::
	$(MAKE) -C ip_cores/wr-cores/modules/wr_eca EB=$(PWD)/ip_cores/etherbone-core/api EXTRA_FLAGS="$(EXTRA_FLAGS)" install

tlu::		etherbone
	$(MAKE) -C ip_cores/wr-cores/modules/wr_tlu EB=$(PWD)/ip_cores/etherbone-core/api EXTRA_FLAGS="$(EXTRA_FLAGS)" all

tlu-clean::
	$(MAKE) -C ip_cores/wr-cores/modules/wr_tlu EB=$(PWD)/ip_cores/etherbone-core/api EXTRA_FLAGS="$(EXTRA_FLAGS)" clean

tlu-install::
	$(MAKE) -C ip_cores/wr-cores/modules/wr_tlu EB=$(PWD)/ip_cores/etherbone-core/api EXTRA_FLAGS="$(EXTRA_FLAGS)" install

driver::
	$(MAKE) -C ip_cores/fpga-config-space/pcie-wb all
	$(MAKE) -C ip_cores/fpga-config-space/vme-wb all

driver-clean::
	$(MAKE) -C ip_cores/fpga-config-space/pcie-wb clean
	$(MAKE) -C ip_cores/fpga-config-space/vme-wb clean

driver-install::
	$(MAKE) -C ip_cores/fpga-config-space/pcie-wb install
	$(MAKE) -C ip_cores/fpga-config-space/vme-wb install

sdbfs::
	$(MAKE) -C ip_cores/fpga-config-space/sdbfs DIRS="lib userspace" all

sdbfs-clean::
	$(MAKE) -C ip_cores/fpga-config-space/sdbfs DIRS="lib userspace" clean

gcc-4.5.3-lm32.tar.xz:
	wget http://www.ohwr.org/attachments/1301/gcc-4.5.3-lm32.tar.xz

toolchain:	gcc-4.5.3-lm32.tar.xz
	tar xvJf gcc-4.5.3-lm32.tar.xz
	mv lm32 toolchain
	touch toolchain

toolchain-clean::
	rm -rf toolchain

ip_cores/wrpc-sw/.config:
	$(MAKE) -C ip_cores/wrpc-sw/ gsi_defconfig

firmware::	sdbfs etherbone toolchain ip_cores/wrpc-sw/.config
	$(MAKE) -C ip_cores/wrpc-sw EB=$(PWD)/ip_cores/etherbone-core/api SDBFS=$(PWD)/ip_cores/fpga-config-space/sdbfs/userspace PATH=$(PWD)/toolchain/bin:$(PATH) all

firmware-clean::
	$(MAKE) -C ip_cores/wrpc-sw EB=$(PWD)/ip_cores/etherbone-core/api SDBFS=$(PWD)/ip_cores/fpga-config-space/sdbfs/userspace PATH=$(PWD)/toolchain/bin:$(PATH) clean

idrogen_v3_wr_ref_design:	firmware
	cd syn/idrogen_v3_wr_ref_design && hdlmake makefile
	$(MAKE) -C syn/idrogen_v3_wr_ref_design PATH=$(PWD)/toolchain/bin:$(PATH) all

idrogen_v3_wr_ref_design-clean::
	rm -f syn/idrogen_v3_wr_ref_design/Makefile
	rm -rf $(PWD)/ip_cores/wr-cores/platform/altera/wr_arria10_phy/wr_arria10_idrogen_phy/wr_arria10_idrogen_rst_ctl/wr_arria10_idrogen_rst_ctl
	rm -rf $(PWD)/ip_cores/wr-cores/platform/altera/wr_arria10_phy/wr_arria10_idrogen_phy/wr_arria10_idrogen_det_phy/wr_arria10_idrogen_det_phy
	rm -rf $(PWD)/ip_cores/wr-cores/platform/altera/wr_arria10_phy/wr_arria10_idrogen_phy/wr_arria10_idrogen_cmu_pll/wr_arria10_idrogen_cmu_pll
	rm -rf $(PWD)/ip_cores/wr-cores/platform/altera/wr_arria10_phy/wr_arria10_idrogen_phy/wr_arria10_idrogen_atx_pll/wr_arria10_idrogen_atx_pll
	rm -rf $(PWD)/ip_cores/wr-cores/platform/altera/wr_arria10_phy/wr_arria10_idrogen_phy/wr_arria10_idrogen_f_pll/wr_arria10_idrogen_f_pll
	$(MAKE) -C syn/idrogen_v3_wr_ref_design PATH=$(PWD)/toolchain/bin:$(PATH) clean