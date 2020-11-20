#!/bin/bash

source ./scripts/util.sh

function clean() {
  run_as_root "systemctl stop vgpu.service"
  run_as_root "systemctl disable vgpu.service"

  qemu_service=$( ls  /etc/systemd/system/multi-user.target.wants/qemu@* )
  for i in $qemu_service; do
    run_as_root "systemctl stop ${i##*/}"
    run_as_root "systemctl disable ${i##*/}"
  done
}

[[ "$1" == "clean" ]] && clean && exit 0

source $cdir/scripts/setup-vm.sh
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

#if mdev directory not exist then exit
[[ ! -d /sys/bus/pci/devices/0000:00:02.0/mdev_supported_types ]] && echo "i${red}/sys/bus/pci/device/0000:00:02.0/mdev_supported_types not exists${NC}" && exit 1

setup_main
source $cdir/systemd/config-systemd.sh
