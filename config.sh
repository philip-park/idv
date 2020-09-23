#!/bin/bash

source scripts/util.sh
###################################################################
# 
###################################################################


[[ "$1" == "clean" ]] && clean && exit 0
function run_all() {
#install_packages
#build_vm_directory

#source scripts/config-kernel.sh
#================================================
# VGPU mask setting based on mdev_type user input
#================================================
#source scripts/config-select-vgpu.sh
source $cdir/scripts/config-mdev-type.sh
#source scripts/config-qemu-setup.sh
}
function config_main() {

# Detect GFX port and update VGPU, GFX_PORT, port_mask
source $cdir/scripts/config-select-vgpu.sh
gfx_port=$(grep GFX_PORT $idv_config_file)
vgpu_port=$(grep VGPU $idv_config_file)

echo "gfx: ${gfx_port[0]}, vgpu: ${vgpu_port[0]}"

list+=( 1 "Kernel option config (for Kernel build.sh)" )
#for i in ${#gfx_port[@]}; do
for (( i=0; i<${#gfx_port[@]}; i++ )); do
  list+=( $((i+2)) "GFX ${gfx_port[$i]##*=} as ${vgpu_port[$i]}" )
done
  list+=( $((i+2)) "Exit config menu" )

while true ; do

  # display the option to user
  option=$(dialog --keep-tite --menu "Select configuration options" 20 80 10 \
            "${list[@]}" \
            3>&1 1>&2 2>&3 )

  [[ $? -eq 1 ]] && break

  echo "option: $option, cmd: $?"

  case $option in

    1) echo "source ./scripts/config-kernel.sh" ;;
    2) echo "source ./scripts/config-qemu-setup.sh"
            echo "Second Option"
            ;;
    3)        echo "third Option"
        break
            ;;
  esac

done
}
config_main
