#!/bin/bash

source scripts/util.sh

_iso_="$cdir/iso/*.iso"
QEMU_IMG="/usr/bin/qemu-img"
#====================================================
# Create *.qcow2 file if user select the ISO file
#====================================================
function get_iso_file() {
  isofiles=( $_iso_ )
  vgpuinfo=$1
  low_vgpu="$( echo $vgpuinfo | tr '[:upper:]' '[:lower:]' )"
	unset list

  [[ ${isofiles[0]} == "$_iso_" ]] && update_idv_config "GUEST_ISO_$vgpuinfo" "" \
    && dialog --msgbox "Can't find ISO files in $cdir/iso. Please download guest OS ISO file to $cdir/iso\n\n" 10 40 && exit 1

  for (( i=0; i<${#isofiles[@]}; i++ )); do
    list+=($i "${isofiles[$i]##*\/}" off "${isofiles[$i]}")
    echo "($i)list: ${list[@]}"
  done

  cmd=(dialog --item-help --radiolist "Please choose ISO files from ./iso for your guest OS." 30 80 5)
  list=(${list[@]})
  choices=$("${cmd[@]}" "${list[@]}" 2>&1 >/dev/tty)

  [[ $? -eq 1 ]] && exit 0    # cancel pressed

#  echo "choices: $choices, cmd: $? (OK/Cancel)"

  for (( i=0; i<${#list[@]}; $((i+=4)) )); do
    echo "($i): ${list[$i]}"
    if [[ $choices == ${list[$i]} ]]; then
      update_idv_config "GUEST_ISO_$vgpuinfo" "${list[$((i+3))]}"
      ($QEMU_IMG create -f qcow2 temp.qcow2 60G)
      run_as_root "mv temp.qcow2 $vmdir/disk/${list[$((i+1))]%%.*}-$low_vgpu.qcow2"
      update_idv_config "GUEST_QCOW2_$vgpuinfo" "$vmdir/disk/${list[$((i+1))]%%.*}-$low_vgpu.qcow2"
      run_as_root "rm -f temp.qcow2"
    fi
  done
}
