#!/bin/bash

source ./scripts/util.sh
#cdir=$(pwd)

[[ "$1" == "clean" ]] && clean && exit 0


#================================================
# VGPU mask setting based on mdev_type user input
#================================================
#build_vm_directory
source scripts/setup-vm.sh

#==========================================================
# Create VM related run time files from user selected FW_VGPU
# Without FW, the guest OS will not boot. So use FW selection
# until find better way.
#==========================================================
function setup_main() {
  # grep strings between '_' and '='
  vgpuinfo=( $( grep "FW_VGPU" $idv_config_file | grep -oP '(?<=_).*(?==)' ) )

	build_create_vgpu

	for vgpu in ${vgpuinfo[@]}; do
	  create_files "$vgpu"
  done
}

setup_main
