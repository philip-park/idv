#!/bin/bash

source ./scripts/util.sh

function update_grub_kernel() {
unset list
old_IFS=$IFS
IFS=$'\n'
default_kernel=($(grep "GRUB_DEFAULT=" /etc/default/grub))
 # grep strings between '_' and '='
#default_kernel=( $( grep "FW_VGPU" $idv_config_file | grep -oP '(?<=>).*(?=")' ) )
echo "default 1: $default_kernel"
temp="${default_kernel%\"*}"
default_kernel="${temp##*>}"
echo "default: $default_kernel"
kernels=$(grep -E 'menuentry ' /boot/grub/grub.cfg | cut -f 2 -d "'")
j=0
#for (( i=0; i<${#kernels[@]}; i++ )); do
#  [[ " ${kernels[@]} " =~ "Ubuntu, " ]] && list+=( $i "${kernels[$i]}" off "test string" ) 
#done

for i in ${kernels[@]}; do
  if [[ $i =~ "Ubuntu, " ]]; then
    [[ $i == $default_kernel ]] && list+=( $j "$i" on ) \
      || list+=( $j "$i" off )

    echo "found" 
    j=$((j+1))
  fi
done
IFS=${old_IFS}

  option=$(dialog --backtitle "Select patches file" \
            --radiolist "Select kernel to boot. /etc/default/grub will be updated"  20 80 10 \
            "${list[@]}" \
            3>&1 1>&2 2>&3 )
echo "options: $option,  ${list[$((option*3+1))]}"
default_grub=GRUB_DEFAULT=""
#   grep -qxF $i /etc/initramfs-tools/modules || echo $i >> /etc/initramfs-tools/modules
}

update_grub_kernel


