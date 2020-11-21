#!/bin/bash

source ./scripts/util.sh

function build_fw_directory() {
#  run_as_root "apt-get install -y qemu-system-x86"
  install_pkgs "qemu-system-x86"
  if [[ -f /usr/share/qemu/bios.bin ]]; then
    run_as_root "cp /usr/share/qemu/bios.bin $vmdir/fw"
  elif [[ -f /usr/share/seabios/bios.bin ]]; then
    run_as_root "cp /usr/share/seabios/bios.bin $vmdir/fw"
  fi

  [[ -f /usr/share/qemu/OVMF.fd ]] && run_as_root "cp /usr/share/qemu/OVMF.fd $vmdir/fw" \
      || echo "Error: can't find /usr/share/qemu/OVMF.fd file"
}

function build_vm_directory() {
  run_as_root "mkdir -m a=rwx -p {$vmdir,$vmdir/fw,$vmdir/disk,$vmdir/iso,$vmdir/scripts}"
  build_fw_directory
  run_as_root "cp -r ./scripts/network $vmdir/scripts"
  if [[ -f "$builddir/civ/OVMF.fd" ]]; then
    run_as_root "cp -f $builddir/civ/OVMF.fd $vmdir/fw"
  else
    [[ -f "/usr/share/qemu/OVMF.fd" ]] && run_as_root "cp -f /usr/share/qemu/OVMF.fd $vmdir/fw"
  fi
}

build_vm_directory
