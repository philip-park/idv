#!/bin/bash

source scripts/util.sh

[[ "$1" == "clean" ]] && clean && exit 0


#===============================================
# Fixed Kernel repo supported by IDV solution
#===============================================
kernel_repo+=("CCG-repo" "https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git" off "v5.4.54")
kernel_repo+=("IOTG-repo" "https://github.com/intel/linux-intel-lts.git" off "lts-v5.4.57-yocto-200819T072823Z")


function run_all() {
  portinfo=$1

  # install enough package to start config
#  run_as_root "apt install uuid"

  # install qemu-system-x86 and copy firmware to /var/vm/fw
#  build_vm_directory

  #source scripts/config-kernel.sh
  #================================================
  # VGPU mask setting based on mdev_type user input
  #================================================
  #source scripts/config-select-vgpu.sh
#  source $cdir/scripts/config-mdev-type.sh
	source $cdir/scripts/config-iso-option.sh
	get_iso_file "$portinfo"

  source $cdir/scripts/config-qemu-setup.sh
  get_qemu_firmware_option "$portinfo"
  get_qemu_usb_option "$portinfo"
}

#=========================================================
# gfx_port is ports detected by IDV gvt_port_disp_status
# vgpu_port is guid. (TBD: need to change it to vgpu_guid)
#=========================================================
function config_main() {
  unset mainlist

  # install enough package to start config
  run_as_root "apt install uuid"

  # install qemu-system-x86 and copy firmware to /var/vm/fw
  build_vm_directory

  run_as_root "apt install dialog"  # make sure dialog is installed
  source $cdir/scripts/config-select-vgpu.sh  # get vgpu, gfx port, and port mask info

  # gfx_port is ports detected by IDV gvt_port_disp_status
  gfx_port=($(grep "^GFX_PORT=" $idv_config_file | grep -oP '(?<=").*(?=")')) # remove double quote from option sting
  vgpu_port=( $(grep "^VGPU" $idv_config_file) )

  # add kernel option to the menu
  mainlist+=( "Kernel" "Kernel option config (for Kernel build.sh)" "This option is only for kernel build." )

  # add GVTg port option
  if [[ ${#gfx_port[@]} -ne 0 ]]; then
    # add MDEV type option
    mainlist+=( "Mdev" "mdev type option config" "Option to select mdev type. Needed for VM config." )

    for (( i=0; i<${#gfx_port[@]}; i++ )); do
      mainlist+=( "${gfx_port[$i]##*=}" "GFX ${gfx_port[$i]##*=} as ${vgpu_port[$i]}"  "Config ${gfx_port[$i]} with guest OS, firmware, and USB devices to pass through" )
			echo "$i) gfx: ${gfx_port[$i]}, vgpu: ${vgpu_port[$i]}"
    done

    # add setup
    mainlist+=( "Setup" "Minimum setup VM without systemd" "Sets up initial qemu scripts and populate vm directory" )

    # add systemd auto start option
    mainlist+=( "Systemd" "Add creating VGPU port during boot" "Add systemd to start create-vgpu.sh" )
  fi

  # add exit option
  mainlist+=( "Exit" "Exit config menu" "Exit the configuration" )

  while true ; do
    opt=$(dialog --item-help --keep-tite --menu "Select configuration options" 20 80 10 \
            "${mainlist[@]}" 3>&1 1>&2 2>&3 )

    [[ $? -eq 1 ]] && break # Cancel selected

    case $opt in
      Kernel)  source $cdir/scripts/config-kernel.sh ;;
      Mdev) source $cdir/scripts/config-mdev-type.sh;;
      PORT_A|PORT_B|PORT_C|PORT_D)
        for (( i=0; i<${#gfx_port[@]}; i++ )); do
          [[ "$opt" == "${gfx_port[$i]##*=}" ]] && run_all "${vgpu_port[$i]%=*}"
        done ;;
      Setup)
        source ./setup.sh;;

      Systemd)
        source $cdir/systemd/config-systemd.sh;;
      Exit)  exit 0 ;;
    esac
  done
}

config_main
