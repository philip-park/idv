#!/bin/bash

source scripts/util.sh
cdir=$(pwd)

[[ "$1" == "clean" ]] && clean && exit 0


#================================================
# VGPU mask setting based on mdev_type user input
#================================================
#build_vm_directory
source scripts/setup-vm.sh


function setup_main() {
#  vgpuinfo=( $( grep "FW_VGPU" $idv_config_file ) )
  vgpuinfo=( $( grep "FW_VGPU" $idv_config_file | grep -oP '(?<=_).*(?==)' ) )

	for vgpu in ${vgpuinfo[@]}; do
		echo "i in loop: $vgpu"

#  create_vm_dir
	  get_user_option 
	  create_files "$vgpu"
  done
}

setup_main
