# idrogen_v3

Procedure for compiling an idrogen firmware:


## Simlink for Quartus 
```$ export LM_LICENSE_FILE=  ...  
$ which quartus  
/opt/altera/19.3_pro/quartus/bin/quartus
$ sudo ln -sf /opt/altera/19.3_pro/quartus/bin/quartus /opt/quartus
```


## Dependencies and tools:
```
$ sudo apt install docbook-utils libreadline-dev
or
$ yum install docbook-utils readline-devel.x86_64 glibs.i686 zlib.i686

$ pip install hdlmake
```


## Modify ip-cores
  - Copy/merge ```firmware/modules/ip_cores/platform/altera/*``` to ```firmware/ip_cores/wr-cores/platform/altera/```


## Compile
```
$ make idrogen_v3_wr_ref_design
```


## Harware setup
  - During the first use of a FPGA running the WhiteRabbit core, we need to format the EEPROM at the wrpc-sw prompt:
  ```wrc# sdb fs 1 0 80```

