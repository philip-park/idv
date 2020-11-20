#!/bin/bash
source scripts/util.sh

QEMU_IMG="/usr/bin/qemu-img"
#====================================================
# Create *.qcow2 file if user select the ISO file
#====================================================
function get_iso_file() {
  isofiles=($( ls $cdir/iso/* 2>/dev/null ))
  vgpuinfo=$1
  low_vgpu="$( echo $vgpuinfo | tr '[:upper:]' '[:lower:]' )"
	unset list

  [[ -z "$isofiles" ]] && update_idv_config "GUEST_ISO_$vgpuinfo" "" \
    && dialog --msgbox "Can't find ISO files in $cdir/iso. Please download guest OS ISO file to $cdir/iso\n\n" 10 40 && exit 1

  for (( i=0; i<${#isofiles[@]}; i++ )); do
    list+=($i "${isofiles[$i]##*\/}" off "${isofiles[$i]}")
    echo "($i)list: ${list[@]}"
  done

  # We support one package
  android_mark=$i 
  list+=($i "android-civ_00_20_02_24_a10" off "https://github.com/projectceladon/celadon-binary/raw/master/" )

  cmd=(dialog --item-help --radiolist "Please choose Windows and Ubuntu in ISO files, or *.tar.gz for Android located in ./iso directory for your guest OS." 30 80 5)
  list=(${list[@]})
  choices=$("${cmd[@]}" "${list[@]}" 2>&1 >/dev/tty)

  [[ $? -eq 1 ]] && exit 0    # cancel pressed
#  echo "choices: $choices, cmd: $? (OK/Cancel)"
  update_idv_config "GUEST_ISO_$vgpuinfo" "${list[$((choices*4+3))]}"
  update_idv_config "GUEST_QCOW2_$vgpuinfo" "$vmdir/disk/${list[$((choices*4+1))]%%.*}-$low_vgpu.qcow2"

  # For Android, it will be done by civ.sh
  if [[ "$choices" -lt "$android_mark" ]]; then
    run_as_root "$QEMU_IMG create -f qcow2 $vmdir/disk/${list[$((choices*4+1))]%%.*}-$low_vgpu.qcow2 60G"
  fi

return
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
