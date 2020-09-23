#!/bin/bash

source scripts/util.sh
###################################################################
# 
###################################################################



[[ "$1" == "clean" ]] && clean && exit 0
install_packages
build_vm_directory

source scripts/config-kernel.sh
#================================================
# VGPU mask setting based on mdev_type user input
#================================================
source scripts/config-select-vgpu.sh
source scripts/config-qemu-setup.sh

function config_main() {


cmd=(dialog --keep-tite --menu "Select options:" 22 76 16)
options=(1 "Kernel Configure"
         2 "Guest OS 1 configure"
         3 "Guest OS 2 configure"
         4 "Guest OS 3 configure")

choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)

for choice in $choices
do
    case $choice in
        1) source ./scripts/config-kernel.sh ;;
        2) 
            echo "Second Option"
            ;;
        3)
            echo "Third Option"
            ;;
        4)
            echo "Fourth Option"
            ;;
    esac
done
}
