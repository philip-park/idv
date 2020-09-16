#!/bin/bash

#================================================
# text attributes ####
#================================================
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
blue=`tput setaf 4`
magenta=`tput setaf 5`
cyan=`tput setaf 6`
white=`tput setaf 7`
blink=`tput blink`
NC=`tput sgr0`

###################################################################
# version : version of the idv.sh file
# cdir    : pionts to current working directory where idv.sh file runs
# repo    : URL to kernel source repository
# kdir    : Directory where kernel will be pulled and saved from repo
# branch  : tag or branch of the kernel source
# patches : idv patch file name with our ".tar.gz" extention
###################################################################
version="0.7"
cdir=$(pwd)
echo "cdir : $0"
#================================================
# Clean the mess it made
#================================================
function clean() {
  [[ -d "$cdir/$kdir" && ! -z "$kdir" ]] && echo "kdir: $cdir/$kdir"
  [[ -d "$cdir/$patches" && ! -z "$patches.tar.gz" ]] && echo "patches: $cdir/$patches"
  [[ -d "$cdir/ubuntu-package" ]] && echo "ubuntu-package: $cdir/ubuntu-package"
  echo   "deb: $cdir/*.deb"

  return 0

  [[ -d "$cdir/$kdir" && ! -z "$kdir" ]] && rm -rf $cdir/$kdir
  [[ -d "$cdir/$patches" && ! -z "$patches.tar.gz" ]] && rm -rf $cdir/$patches
  [ -d "$cdir/ubuntu-package" ] && rm -rf $cdir/ubuntu-package
  rm -rf $cdir/*.deb
}
[[ "$1" == "clean" ]] && clean && exit 0

#================================================
# repo, branch, patches, kdir, krevision, kversion
#================================================
kdir="kernel"
krevision="3.0"
kversion="intelgvt"
source ./scripts/kernel-config.sh
echo "build: patches: $patches"

#================================================
# Pull Kernel and Compile
#================================================
#source ./.idv-config
source ./scripts/build-helper

#================================================
# Setup Kernel command line option in /etc/default/grub
#================================================
source scripts/grub-setup.sh
grub_setup

echo -en '\n'
echo "${green}To Install Kernel: \"sudo dpkg -i *.deb\"${NC}"

