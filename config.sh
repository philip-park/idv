#!/bin/bash

source scripts/util.sh

[[ "$1" == "clean" ]] && clean && exit 0


#===============================================
# Fixed Kernel repo supported by IDV solution
#===============================================
kernel_repo+=("CCG-repo" "https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git" off "v5.4.54")
kernel_repo+=("IOTG-repo" "https://github.com/intel/linux-intel-lts.git" off "lts-v5.4.57-yocto-200819T072823Z")


function run_all() {
  portinfo="${1%=*}"
  portinfo="$(echo $portinfo | tr '[:upper:]' '[:lower:]')"
  echo "run_all: $portinfo"

  # install enough package to start config
  run_as_root "apt install uuid"

  # install qemu-system-x86 and copy firmware to /var/vm/fw
  build_vm_directory

  #source scripts/config-kernel.sh
  #================================================
  # VGPU mask setting based on mdev_type user input
  #================================================
  #source scripts/config-select-vgpu.sh
#  source $cdir/scripts/config-mdev-type.sh
  source $cdir/scripts/config-qemu-setup.sh
}
function config_main() {

  # Detect GFX port and update VGPU, GFX_PORT, port_mask
  source $cdir/scripts/config-select-vgpu.sh
  gfx_port=$(grep GFX_PORT $idv_config_file)
  vgpu_port=$(grep VGPU $idv_config_file)

#  source $cdir/scripts/config-mdev-type.sh

  mainlist+=( "Kernel" "Kernel option config (for Kernel build.sh)" )
  mainlist+=( "Mdev" "mdev type option config" )
  for (( i=0; i<${#gfx_port[@]}; i++ )); do
    mainlist+=( "${gfx_port[$i]##*=}" "GFX ${gfx_port[$i]##*=} as ${vgpu_port[$i]}" )
  #  mainlist+=( $((i+2)) "GFX ${gfx_port[$i]##*=} as ${vgpu_port[$i]}" )
  done
  mainlist+=( "Exit" "Exit config menu" )

  while true ; do
    opt=$(dialog --keep-tite --menu "Select configuration options" 20 80 10 \
            "${mainlist[@]}" 3>&1 1>&2 2>&3 )

    [[ $? -eq 1 ]] && break

    echo "option: $opt, cmd: $?"

    case $opt in

      Kernel)  source ./scripts/config-kernel.sh ;;
      Mdev) source $cdir/scripts/config-mdev-type.sh;;
      PORT_B)  echo "source ./scripts/config-qemu-setup.sh"
          run_all "${vgpu_port[0]}"
            echo "Second Option"
            ;;
      Exit)  break ;;
    esac
  done
}
config_main
