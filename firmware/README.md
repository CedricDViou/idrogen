# idrogen_v3

Procedure for compiling an idrogen firmware:


## Simlink for Quartus 
```$ export LM_LICENSE_FILE=  ...  
$ export PATH=${QUARTUS_ROOTDIR}/bin:${QSYS_ROOTDIR}:${PATH}
$ which quartus  
/opt/altera/19.3_pro/quartus/bin/quartus
$ sudo ln -sf /opt/altera/19.3_pro/quartus/bin/quartus /opt/quartus
```


## Dependencies and tools:
```
$ sudo apt install docbook-utils libreadline-dev autotools-dev automake libtool

$ cd firmware/ip_cores/hdl-make
$ python setup.py install
```


## Compile
```
$ make idrogen_v3_wr_ref_design
```


## Harware setup
  - During the first use of a FPGA running the WhiteRabbit core, we need to format the EEPROM at the wrpc-sw prompt:
  ```wrc# sdb fs 1 0 80```
  - Configure MAC address
  ```mac setp <your mac>```

