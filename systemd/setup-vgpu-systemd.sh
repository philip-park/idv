#!/bin/bash

source ./scripts/util.sh

function systemd_vgpu_enable() {
  run_as_root "cp $cdir/systemd/vgpu.service $vmdir/scripts"
  run_as_root "systemctl enable $vmdir/scripts/vgpu.service"
}

systemd_vgpu_enable

