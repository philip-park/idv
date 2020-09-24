#!/bin/bash

source scripts/util.sh
cdir=$(pwd)

[[ "$1" == "clean" ]] && clean && exit 0


#================================================
# VGPU mask setting based on mdev_type user input
#================================================
build_vm_directory
source scripts/setup-vm.sh

setup_main

