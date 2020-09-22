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
vmroot=/var
vmdir=vm
function clean_deleteme() {
  echo "cleaning.. "
  run_as_root "find $vmroot -name $vmdir -type d -exec rm -r {} +"
  run_as_root "find /var -type d -name "vm" -exec rm -rf {} +"
#  run_as_root "find . -type d -name "$kdir" -exec rm -rf {} +"
#  run_as_root "find . -type d -name "${patches%.tar.gz}" -exec rm -rf {} +"
  run_as_root "find . -type d -name "ubuntu-package" -exec rm -rf {} +"
  run_as_root "find . -type f -name "*.deb" -exec rm -rf {} +"


}

[[ "$1" == "clean" ]] && clean && exit 0
install_packages
make_var_vm
#================================================
# VGPU mask setting based on mdev_type user input
#================================================
source scripts/select-vgpu.sh
#source scripts/setup-vm.sh
source scripts/qemu-setup.sh


