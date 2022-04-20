# Git repository for Idrogen

Firmware for Igrogen Board of the DAC-GEN project.


# Command line instructions
## Git global setup
```
git config --local user.name "Cedric Viou"
git config --local user.email "cedric.dumez-viou@obs-nancay.fr"
```

## Download repository and start building a firmware
```
git clone https://gitlab.in2p3.fr/NEBULA/idrogen.git
cd idrogen
git submodule init
git submodule update
cd firmware
more README.md  -> to install dependencies and start compiling designs
```

## Modify and contribute
```
git add monfichier_a_versionner
git commit -m "commentaire de commit"
git push -u origin master
```
