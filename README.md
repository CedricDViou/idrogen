# Git repository for Idrogen

Firmware for Idrogen Board of DAC-GEN project.

## Command line instructions

### Git global setup

```bash
git config --local user.name "Cedric Viou"
git config --local user.email "cedric.dumez-viou@obs-nancay.fr"
```

### Download repository and start building a firmware

```bash
git clone https://gitlab.in2p3.fr/NEBULA/idrogen.git
cd idrogen
git submodule init
git submodule update
cd firmware
more README.md  -> to install dependencies and start compiling designs
```

### Setup script

Bash ```script.sh``` file can be launched when repository is clonned, this script will init and update submodules and add missing file in **general-cores** manifest.

```bash
sh setup.sh
```

### Modify and contribute

```bash
git add monfichier_a_versionner
git commit -m "commentaire de commit"
git push -u origin master
```
