#!/bin/bash

source scripts/util.sh
source ./.idv-config

vm_dir=/var/vm

function create_vm_dir() {
(mkdir -p {$vm_dir,$vm_dir/fw,$vm_dir/disk,$vm_dir/iso,$vm_dir/scripts})
}

function build_fw_directory() {
  [[ -f /usr/share/qemu/bios.bin ]] && run_as_root "cp /usr/share/qemu/bios.bin $vm_dir/fw" \
      || echo "Error: can't find /usr/share/qemu/bios.bin file"
  [[ -f /usr/share/qemu/OVMF.fd ]] && run_as_root "cp /usr/share/qemu/OVMF.fd $vm_dir/fw" \
      || echo "Error: can't find /usr/share/qemu/OVMF.fd file"
}

CREATE_VGPU="/var/vm/create-vgpu.sh"
INSTALL_GUEST="/var/vm/install-guest.sh"
START_GUEST="/var/vm/start-guest.sh"

gvt_disp_ports_mask="/sys/class/drm/card0/gvt_disp_ports_mask"
mdev_dir="/sys/bus/pci/devices/0000:00:02.0/mdev_supported_types"

function build_create_vgpu() {
  unset temp

  temp+=( "#!/bin/bash" )

  temp+=( "# This file is auto generated by IDV setup.sh file." )
  # set VGPU
  vgpu_opt=($(grep "VGPU" $idv_config_file))
  temp+=( "${vgpu_opt[@]}" )

  # set port mask
  opt=($(grep "port_mask=" $idv_config_file))
  temp+=( "echo \"${opt#*=}\" > $gvt_disp_ports_mask" )

  for i in ${vgpu_opt[@]}; do
    temp+=( "echo \"${i%%=*}\" > $mdev_dir/$mdev_type/create" )
  done

  printf "%s\n"  "Creating $CREATE_VGPU file.. " 
  printf "%s\n"  "${temp[@]}" > ./temp_file
  run_as_root "cp ./temp_file $CREATE_VGPU"
  run_as_root "chmod +x $CREATE_VGPU"
  $(rm temp_file)
}

function build_install_qemu_batch() {
  unset temp
  temp+=( "#!/bin/bash" )
  temp+=( "# This file is auto generated by IDV setup.sh file." )
  temp+=( "/usr/local/bin/qemu-system-x86_64 \\" )
  temp+=( "-m 4096 -smp 1 -M q35 \\" )
  temp+=( "-enable-kvm \\" )
  temp+=( "-name install-qemu \\" )
  temp+=( "-boot d \\" )

  opt=($(grep "GUEST_ISO=" $idv_config_file))
  temp+=( "-cdrom ${opt##*=} \\" )

  opt=($(grep "GUEST_QCOW2=" $idv_config_file))
  temp+=( "-drive file=${opt##*=} \\" )

  fw_opt=($(grep "FW=" $idv_config_file))
  temp+=( "-bios ${fw_opt#*=} \\" )

  temp+=( "-cpu host -usb -device usb-tablet \\" )
  temp+=( "-vga cirrus \\" )
  temp+=( "-k en-us \\" )
  temp+=( "-vnc :0" )

  printf "%s\n"  "Creating $INSTALL_GUEST file.. " 
  printf "%s\n"  "${temp[@]}" > ./temp_file
  run_as_root "cp ./temp_file $INSTALL_GUEST"
  run_as_root "chmod +x $INSTALL_GUEST"
  $(rm temp_file)
}

gfx_device="/sys/bus/pci/devices/0000:00:02.0"
function build_start_qemu_batch() {
  unset temp

O_IFS=${IFS}
IFS=$'\n'
  temp+=( "#!/bin/bash -x" )
  temp+=( "# This file is auto generated by IDV setup.sh file." )
  temp+=( "/usr/bin/qemu-system-x86_64 \\" )
  temp+=( "-m 4096 -smp 1 -M q35 \\" )
  temp+=( "-enable-kvm \\" )
  temp+=( "-name ubuntu-guest \\" )

  opt=($(grep "GUEST_QCOW2=" $idv_config_file))
#  temp+=( "-drive file=${opt##*=} \\" )
  temp+=( "-hda ${opt##*=} \\" )

  fw_opt=($(grep "FW=" $idv_config_file))
  temp+=( "-bios ${fw_opt#*=} \\" )

#  temp+=( "-bios /home/snuc/vm/fw/OVMF-pure-efi.fd \\" )
  temp+=( "-cpu host -usb -device usb-tablet \\" )
  temp+=( "-vga none \\" )
  temp+=( "-k en-us \\" )
  temp+=( "-vnc :0 \\" )
  temp+=( "-cpu host -usb -device usb-tablet \\" )

  vgpu_opt=($(grep "VGPU" $idv_config_file))
  if [[ -z $vgpu_opt ]]; then
    temp+=( "-device vfio-pci,sysfsdev=$gfx_device/$VGPU1,display=off,x-igd-opregion=on" )
  else
    temp+=( "-device vfio-pci,sysfsdev=$gfx_device/$VGPU1,display=off,x-igd-opregion=on \\" )
    opt=($(grep "QEMU_USB" $idv_config_file))
    temp+=( ${opt#*=} )
#    temp+=( $opt )  
  fi

#  printf "%s\n"  "${temp[@]}" 
  printf "%s\n"  "Creating $START_GUEST file.. " 
  printf "%s\n"  "${temp[@]}" > ./temp_file
  run_as_root "cp ./temp_file $START_GUEST"
  run_as_root "chmod +x $START_GUEST"
IFS=${O_IFS}
  $(rm temp_file)
}

_iso_="$cdir/iso/*.iso"
QEMU_IMG="/usr/bin/qemu-img"
#====================================================
# Create *.qcow2 file if user select the ISO file
#====================================================
function get_user_option() {
  isofiles=( $_iso_ )

  echo "iso: ${isofiles[@]}"

  [[ ${isofiles[0]} == "$_iso_" ]] && update_idv_config "GUEST_ISO" "" \
    && dialog --msgbox "Cant find ISO files in $cdir/iso\n\n" 10 40 && exit 1

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
      update_idv_config "GUEST_ISO" "${list[$((i+3))]}"
      ($QEMU_IMG create -f qcow2 temp.qcow2 60G)
      run_as_root "mv temp.qcow2 $vm_dir/disk/${list[$((i+1))]%%.*}.qcow2"
      update_idv_config "GUEST_QCOW2" "$vm_dir/disk/${list[$((i+1))]%%.*}.qcow2"
    fi
  done
}

create_vm_dir
get_user_option

build_fw_directory
build_create_vgpu
build_install_qemu_batch
build_start_qemu_batch


