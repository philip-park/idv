#!/bin/bash

source ./scripts/util.sh


grubfile="/etc/default/grub"
tempfile="./temp"
grub_modified=0

function grub_setup() {
  opts=(i915.enable_gvt=1 kvm.ignore_msrs=1 intel_iommu=on,igfx_off drm.debug=0 consoleblank=0 i915.force=probe=*)

  cp -f $grubfile $tempfile

  cmdline="`grep -w "GRUB_CMDLINE_LINUX=" $tempfile`"
  cmdline=${cmdline##*GRUB_CMDLINE_LINUX=} # Capture strings after "GRUB_CMDLINE_LINUX="
  cmdline="${cmdline%\"}"   # Remove the suffix "

  for i in "${opts[@]}"; do
    if !(grep -q $i <<< "$cmdline"); then
      grub_modified=1
      [[ $cmdline == "\"" ]] && cmdline="$cmdline$i" || cmdline="$cmdline $i"
    fi
  done

  if [[ $grub_modified -eq 1 ]]; then
    cmdline="GRUB_CMDLINE_LINUX=$cmdline\""
    sed -i "/.*GRUB_CMDLINE_LINUX=.*/c $cmdline" $tempfile
    run_as_root "cp -f $tempfile $grubfile"
#    run_as_root "update-grub2"
  fi
  rm -f $tempfile
}


function update_grub_kernel() {
  unset list

  old_IFS=$IFS
  IFS=$'\n'

  # detect default kernel by looking at the GRUB_DEFAULT
  default_kernel=($(grep "GRUB_DEFAULT=" /etc/default/grub))
  temp="${default_kernel%\"*}"
  default_kernel="${temp##*>}"

  kernels=$(grep -E 'menuentry ' /boot/grub/grub.cfg | cut -f 2 -d "'")
  j=0

  for i in ${kernels[@]}; do
    if [[ $i =~ "Ubuntu, " ]]; then
      [[ $i == $default_kernel ]] && list+=( $j "$i" on ) \
        || list+=( $j "$i" off )

      echo "found" 
      j=$((j+1))
    fi
  done

  option=$(dialog --backtitle "Select patches file" \
            --radiolist "Select kernel to boot. /etc/default/grub will be updated"  20 80 10 \
            "${list[@]}" \
            3>&1 1>&2 2>&3 )
  [[ "$?" -ne 0 ]] && exit 0 || grub_modified=1
 
  # for now, we assume we have one submenu
  submenu=($(grep -E 'submenu ' /boot/grub/grub.cfg | cut -f 2 -d "'"))
  grub_default="GRUB_DEFAULT=\"$submenu>${list[$((option*3+1))]}\""

  echo "grub_default: $grub_default"
  IFS=${old_IFS}

  cp -f $grubfile $tempfile
  sed -i "/^GRUB_DEFAULT=.*/c $grub_default" $tempfile
  run_as_root "cp -f $tempfile $grubfile"
#  run_as_root "update-grub2"
  rm -f $tempfile
}

grub_setup
update_grub_kernel
 
[[ "$grub_modified" -eq 1 ]] && run_as_root "update-grub2"
