#!/bin/bash

source scripts/util.sh

[[ "$1" == "clean" ]] && clean && exit 0


#===============================================
# Fixed Kernel repo supported by IDV solution
#===============================================
kernel_repo+=("CCG-repo" "https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git" off "v5.4.54")
kernel_repo+=("IOTG-repo" "https://github.com/intel/linux-intel-lts.git" off "lts-v5.4.57-yocto-200819T072823Z")


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

  echo "gfx: count: (${#gfx_port[@]}), vgpu: ${vgpu_port[0]}"

  mainlist+=( 1 "Kernel option config (for Kernel build.sh)" )
  for (( i=0; i<${#gfx_port[@]}; i++ )); do
    mainlist+=( $((i+2)) "GFX ${gfx_port[$i]##*=} as ${vgpu_port[$i]}" )
  done
  mainlist+=( $((i+2)) "Exit config menu" )

  while true ; do
    opt=$(dialog --keep-tite --menu "Select configuration options" 20 80 10 \
            "${mainlist[@]}" 3>&1 1>&2 2>&3 )

    [[ $? -eq 1 ]] && break

    echo "option: $opt, cmd: $?"

    case $opt in

      1)  source ./scripts/config-kernel.sh ;;
      2)  echo "source ./scripts/config-qemu-setup.sh"
            echo "Second Option"
            ;;
      3)  break ;;
    esac
  done
}
config_main
