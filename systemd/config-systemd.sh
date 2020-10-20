#!/bin/bash

source ./scripts/util.sh

function enable_vgpu_create() {
run_as_root "cp $cdir/systemd/vgpu.service $vmdir/scripts"
run_as_root "systemctl enable $vmdir/scripts/vgpu.service"
}

TEMP_FILE=$cdir/temp_file
QEMU_SERVICE=$vmdir/scripts/qemu@.service

function qemu_start() {
  unset str
  qemu_start_files=$( ls $vmdir/scripts/start-guest-* )

  [[ -z $qemu_start_files ]] && exit 1

  run_as_root "cp $cdir/systemd/start-qemu.sh $vmdir/scripts/"
  run_as_root "cp $cdir/systemd/qemu@.service /lib/systemd/system"

  for i in ${qemu_start_files[@]}; do
    temp="${i##*-}"
    vgpu="${temp%.*}"
    run_as_root "systemctl enable qemu@$vgpu.service"
  done
}

enable_vgpu_create
qemu_start
