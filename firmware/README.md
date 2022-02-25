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
$ git clone https://gitlab.in2p3.fr/NEBULA/idrogen.git --recursive  
$ cd idrogen  
$ git submodule update
$ cd firmware
$ make idrogen_v3
```
