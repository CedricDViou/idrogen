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
```


- Fetch sources and compile
```
$ git submodule init
$ git submodule update
$ cd firmware/idrogen_v3_ref_design
$ hdlmake
$ make
```
