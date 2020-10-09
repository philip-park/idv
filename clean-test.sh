#!/bin/bash

source scripts/util.sh

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
  run_as_root "apt-get autoremove -y &>/dev/null"
  run_as_root "apt-get remove -y qemu-system-x86 liblz4-tool kernel-package libelf-dev build-essential libfdt-dev libpixman-1-dev libssl-dev bc socat libsdl1.2-dev libspice-server-dev autoconf libtool xtightvncviewer tightvncserver x11vnc uuid-runtime uuid uml-utilities bridge-utils python-dev liblzma-dev libc6-dev libegl1-mesa-dev libepoxy-dev libdrm-dev libgbm-dev spice-client-gtk libgtk2.0-dev libusb-1.0-0-dev bison flex  kernel-package"
  run_as_root "apt-get purge -y qemu-system-x86 liblz4-tool kernel-package libelf-dev build-essential libfdt-dev libpixman-1-dev libssl-dev bc socat libsdl1.2-dev libspice-server-dev autoconf libtool xtightvncviewer tightvncserver x11vnc uuid-runtime uuid uml-utilities bridge-utils python-dev liblzma-dev libc6-dev libegl1-mesa-dev libepoxy-dev libdrm-dev libgbm-dev spice-client-gtk libgtk2.0-dev libusb-1.0-0-dev bison flex  kernel-package"
#&>/dev/null
}


function clean() {

  set_global_variables
  remove_packages


  run_as_root "find /var -type d -name \"vm\" -exec sudo rm -rf {} +"
  run_as_root "find . -type d -name $kdir -exec rm -rf {} +"
  find . -type d -name "${patches%.tar.gz}" -exec rm -rf {} +
  find . -type d -name "ubuntu-package" -exec rm -rf {} +
  #[[ -d $cdir/$kdir && ! -z "$kdir" ]] && find $kdir -type d -name "$kdir" -exec rm -rf {} +
  #[[ -d "$cdir/${patches%.tar.gz}" && ! -z "$patches" ]] && find ${patches%.tar.gz} -type d -name "${patches%.tar.gz}" -exec rm -rf {} +
  #[[ -d "$cdir/ubuntu-package" ]] && find ubuntu-package -type d -name "ubuntu-package" -exec rm -rf {} +
  find . -type f -name "*.deb" -exec rm -rf {} +
  echo   "deb: $cdir/*.deb"
}

clean



