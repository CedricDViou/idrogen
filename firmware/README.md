idrogen_v3
==========


Procedure for compiling an idrogen firmware:

- Simlink for Quartus 
```$ export LM_LICENSE_FILE=  ...  
$ which quartus  
/opt/altera/19.3_pro/quartus/bin/quartus
$ sudo ln -sf /opt/altera/19.3_pro/quartus/bin/quartus /opt/quartus
```

- Dependencies and tools:
```
$ sudo apt install docbook-utils libreadline-dev
$ yum install docbook-utils readline-devel.x86_64 glibs.i686 zlib.i686
$ pip install hdlmake
```


- Fetch sources and compile
```
$ git submodule init
$ git submodule update
$ cd firmware/
$ make idrogen_v3_ref_design   -> Fail in firmware/syn/idrogen_v3_ref_design because hdlmake has not created a Makefile there
$ cd syn/idrogen_v3_ref_design/
Add "matrix_pkg.vhd", in ip_cores/general-cores/modules/common/Manifest.py, l.3
$ hdlmake makefile
$ make idrogen_v3_ref_design
```

- Harware setup
  - During the first use of a FPGA running the WhiteRabbit core, we need to format the EEPROM at the wrpc-sw prompt:
  ```wrc# sdb fs 1 0 80```

