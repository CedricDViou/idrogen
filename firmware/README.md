# idrogen_v3

Procedure for compiling an idrogen firmware:

## Simlink for Quartus

```$ export LM_LICENSE_FILE=  ...  
$ which quartus  
/opt/altera/19.3_pro/quartus/bin/quartus
$ sudo ln -sf /opt/altera/19.3_pro/quartus/bin/quartus /opt/quartus
```

## Dependencies and tools

```bash
$ sudo apt install docbook-utils libreadline-dev
or
$ yum install docbook-utils readline-devel.x86_64 glibs.i686 zlib.i686

$ pip install hdlmake
```

## Missing file in **general-cores**

- Add "matrix_pkg.vhd," in ```ip_cores/general-cores/modules/common/Manifest.py```, line 3

## Compile

```bash
make idrogen_v3_wr_ref_design
```

## Harware setup

- During the first use of a FPGA running the WhiteRabbit core, we need to format the EEPROM at the wrpc-sw prompt: ```wrc# sdb fs 1 0 80```

## Programming command

- List of available devices

```bash
$ quartus_pgm -l

1) USB-Blaster [1-7.1]
```

- Programm FPGA

```bash
quartus_pgm -m JTAG -c USB-Blaster -o "p;file.sof"
```
