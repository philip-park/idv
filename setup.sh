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
vmroot=/var
vmdir=vm
function clean() {

#  [[ -d $vmdir ]] && find ${vmroot//\//\\/} -type d -name "${vmdir}" -exec rm -rf {} +
#  [[ -d $vmdir ]] && find $vmroot -type d -name "$vmdir" -exec rm -rf {} +


find "$vmroot" -name vm -type d -exec rm -r {} +

}

[[ "$1" == "clean" ]] && clean && exit 0


#================================================
# VGPU mask setting based on mdev_type user input
#================================================
source scripts/setup-vm.sh

exit 0

