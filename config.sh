#!/bin/bash

source scripts/util.sh

[[ "$1" == "clean" ]] && clean && exit 0


function run_all() {
  portinfo=$1

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
tempfile=./temp
function config_main() {
  unset mainlist

  # save as backup
  cp $idv_config_file $tempfile

  # install enough package to start config
  run_as_root "apt -y install uuid"

  # install qemu-system-x86 and copy firmware to /var/vm/fw
  build_vm_directory

  run_as_root "apt -y install dialog"  # make sure dialog is installed
  source $cdir/scripts/config-vgpu.sh  # get vgpu, gfx port, and port mask info

  # gfx_port is ports detected by IDV gvt_port_disp_status
  gfx_port=($(grep "^GFX_PORT=" $idv_config_file | grep -oP '(?<=").*(?=")')) # remove double quote from option sting
  vgpu_port=( $(grep "^VGPU" $idv_config_file) )

  # add GVTg port option
  if [[ ${#gfx_port[@]} -ne 0 ]]; then
    # add MDEV type option
    mainlist+=( "Mdev" "mdev type option config" "Option to select mdev type. Needed for VM config." )

    for (( i=0; i<${#gfx_port[@]}; i++ )); do
      mainlist+=( "${gfx_port[$i]##*=}" "GFX ${gfx_port[$i]##*=} as ${vgpu_port[$i]}"  "Config ${gfx_port[$i]} with guest OS, firmware, and USB devices to pass through" )
			echo "$i) gfx: ${gfx_port[$i]}, vgpu: ${vgpu_port[$i]}"
    done

    # add setup
#    mainlist+=( "Qemu" "Create install & startup qemu scripts" "Will populate /var/vm/scripts directory" )

    # add systemd auto start option
#    mainlist+=( "Systemd" "Add creating VGPU port during boot" "Add systemd to start create-vgpu.sh" )
  else
    dialog --msgbox "Can't detect monitor/s. Neither GVTg kernel is not installed nor monitor/s connected.\n\n" 10 40 && exit 1
  fi

  # add exit option
  mainlist+=( "Exit" "Save and Exit" "Exit the configuration" )

  while true ; do
    opt=$(dialog --item-help --keep-tite --menu "Select configuration options" 20 80 10 \
            "${mainlist[@]}" 3>&1 1>&2 2>&3 )

    [[ "$?" -ne 0 ]] && cp $tempfile $idv_config_file && rm -f $tempfile && break # Cancel selected

    case $opt in
      Mdev) source $cdir/scripts/config-mdev-type.sh;;
      PORT_A|PORT_B|PORT_C|PORT_D)
        for (( i=0; i<${#gfx_port[@]}; i++ )); do
          [[ "$opt" == "${gfx_port[$i]##*=}" ]] && run_all "${vgpu_port[$i]%=*}"
        done ;;
 #     Qemu)
 #       source ./setup.sh;;

#      Systemd)
#        source $cdir/systemd/config-systemd.sh;;
      Exit)  rm -f $tempfile; source ./setup.sh; exit 0 ;;
    esac
  done

  rm -f $tempfile
}
run_as_root "apt install bridge-utils dnsmasq"
config_main
