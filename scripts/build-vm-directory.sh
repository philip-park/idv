#!/bin/bash

source ./scripts/util.sh

function build_fw_directory() {
#  run_as_root "apt-get install -y qemu-system-x86"
#  install_pkgs "qemu-system-x86"
echo "build_fw_directory"

  # pickup the BIOS
  if [[ -f $builddir/qemu/$QEMU_REL/pc-bios/bios.bin ]]; then
    run_as_root "cp $builddir/qemu/$QEMU_REL/pc-bios/bios.bin /var/vm/fw"
  elif [[ -f /usr/share/qemu/bios.bin ]]; then
    run_as_root "cp /usr/share/qemu/bios.bin $vmdir/fw"
  elif [[ -f /usr/share/seabios/bios.bin ]]; then
    run_as_root "cp /usr/share/seabios/bios.bin $vmdir/fw"
  fi

  # pickup the OVMF.fd
  if [[ -f "$builddir/OVMF.fd" ]]; then
    run_as_root "cp -f $builddir/OVMF.fd $vmdir/fw"
  elif [[ -f "/usr/share/qemu/OVMF.fd" ]]; then
    run_as_root "cp -f /usr/share/qemu/OVMF.fd $vmdir/fw"
  fi
}

function build_vm_directory() {
  run_as_root "mkdir -m a=rwx -p {$vmdir,$vmdir/fw,$vmdir/disk,$vmdir/iso,$vmdir/scripts}"
  build_fw_directory
  run_as_root "cp -r ./scripts/network $vmdir/scripts"
#  if [[ -f "$builddir/civ/OVMF.fd" ]]; then
#    run_as_root "cp -f $builddir/civ/OVMF.fd $vmdir/fw"
#  else
#    [[ -f "/usr/share/qemu/OVMF.fd" ]] && run_as_root "cp -f /usr/share/qemu/OVMF.fd $vmdir/fw"
#  fi
}
echo "build vm direcotry"
build_vm_directory
