NEBuLA
======


Procedure for compiling a NEBuLA firmware:

$ export LM_LICENSE_FILE=  ...  
$ which quartus  
/opt/altera/19.3_pro/quartus/bin/quartus
$ sudo ln -sf /opt/altera/19.3_pro/quartus/bin/quartus /opt/quartus

$ git clone https://gitlab.in2p3.fr/NEBULA/idrogen.git --recursive  
$ cd idrogen  
$ git submodule update --recursive  
$ cd firmware  
$ make  

$ make idrogen_v3