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


#source $cdir/systemd/setup-vgpu-systemd.sh
source $cdir/systemd/config-systemd.sh
