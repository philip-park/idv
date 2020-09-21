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
function clean() {
  find "$vmroot" -name "$vmdir" -type d -exec rm -r {} +
}

[[ "$1" == "clean" ]] && clean && exit 0


#================================================
# VGPU mask setting based on mdev_type user input
#================================================
source scripts/setup-vm.sh
source scripts/qemu-setup.sh

exit 0

