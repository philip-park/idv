#!/bin/bash

source scripts/util.sh
###################################################################
# 
###################################################################

#default_config=./scripts/idv-config-default
#idv_config_file=./.idv-config
#[[ -f "./.idv-config" ]] && default_config="./.idv-config" || touch ./.idv-config


#================================================
# Clean the mess it made
#================================================
#vmroot=/var
#vmdir=vm

[[ "$1" == "clean" ]] && clean && exit 0
install_packages
build_vm_directory

#================================================
# VGPU mask setting based on mdev_type user input
#================================================
source scripts/config-select-vgpu.sh
#source scripts/setup-vm.sh
source scripts/config-qemu-setup.sh


