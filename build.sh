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
echo "${green}Current working directory : $cdir${NC}"
kdir="kernel"
krevision="3.0"
kversion="intelgvt"


default_config=./scripts/idv-config-default
idv_config_file=./.idv-config
[[ -f "./.idv-config" ]] && default_config="./.idv-config" || touch ./.idv-config

function set_global_variables() {
while IFS=$'\n' read -r line; do
  case $line in
    repo=*) repo=${line##*=} ;;
    branch=*) branch=${line##*=} ;;
    patches=*) patches=${line##*=} ;;
  esac
done < "$default_config"
}

#================================================
# Clean the mess it made
#================================================

function remove_packages() {
sudo -s <<RUNASSUDO_PACKAGE
  apt-get autoremove -y &>/dev/null
  apt-get install -y liblz4-tool kernel-package libelf-dev build-essential libfdt-dev libpixman-1-dev libssl-dev bc socat libsdl1.2-dev libspice-server-dev autoconf libtool xtightvncviewer tightvncserver x11vnc uuid-runtime uuid uml-utilities bridge-utils python-dev liblzma-dev libc6-dev libegl1-mesa-dev libepoxy-dev libdrm-dev libgbm-dev spice-client-gtk libgtk2.0-dev libusb-1.0-0-dev bison flex openssh-server net-tools kernel-package 
#&>/dev/null
RUNASSUDO_PACKAGE
}


function clean() {

  set_global_variables
  remove_packages

  [[ -d $cdir/$kdir && ! -z "$kdir" ]] && find $kdir -type d -name "$kdir" -exec rm -rf {} +
  [[ -d "$cdir/${patches%.tar.gz}" && ! -z "$patches" ]] && find ${patches%.tar.gz} -type d -name "${patches%.tar.gz}" -exec rm -rf {} +
  [[ -d "$cdir/ubuntu-package" ]] && find ubuntu-package -type d -name "ubuntu-package" -exec rm -rf {} +
  find *.deb -type f -name "*.deb" -exec rm -rf {} +
  echo   "deb: $cdir/*.deb"
}

[[ "$1" == "clean" ]] && clean && exit 0

#================================================
# repo, branch, patches, kdir, krevision, kversion
#================================================
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

sudo -s <<RUNASSUDO_PACKAGE
  apt-get install -y qemu-system-x86
RUNASSUDO_PACKAGE

