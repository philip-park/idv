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

source scripts/util.sh
cdir=$(pwd)

[[ "$1" == "clean" ]] && clean && exit 0


#================================================
# VGPU mask setting based on mdev_type user input
#================================================
#source scripts/select-vgpu.sh
build_vm_directory
source scripts/setup-vm.sh

exit 0

