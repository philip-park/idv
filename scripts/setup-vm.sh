#!/bin/bash

source scripts/util.sh
source ./.idv-config

vm_dir="$cdir/vm"

#function create_vm_dir() {
#(mkdir -p {$vm_dir,$vm_dir/fw,$vm_dir/disk,$vm_dir/iso,$vm_dir/scripts})
#}

function build_fw_directory_deleteme() {
  [[ -f /usr/share/qemu/bios.bin ]] && run_as_root "cp /usr/share/qemu/bios.bin $vm_dir/fw" \
      || echo "Error: can't find /usr/share/qemu/bios.bin file"
  [[ -f /usr/share/qemu/OVMF.fd ]] && run_as_root "cp /usr/share/qemu/OVMF.fd $vm_dir/fw" \
      || echo "Error: can't find /usr/share/qemu/OVMF.fd file"
}

function create_vm_dir_deltedme() {
  (mkdir -p {$vm_dir,$vm_dir/fw,$vm_dir/disk,$vm_dir/iso,$vm_dir/scripts})
  build_fw_directory
}

CREATE_VGPU="$vm_dir/create-vgpu.sh"
INSTALL_GUEST="$vm_dir/install-guest"
START_GUEST="$vm_dir/start-guest"

gvt_disp_ports_mask="/sys/class/drm/card0/gvt_disp_ports_mask"
mdev_dir="/sys/bus/pci/devices/0000:00:02.0/mdev_supported_types"

function build_create_vgpu() {
  unset temp
#  vgpuinfo=$1

  temp+=( "#!/bin/bash" )

  temp+=( "# This file is auto generated by IDV setup.sh file." )
  # set VGPU
  vgpu_opt=($(grep "^VGPU" $idv_config_file))
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
  vgpu=$1
  low_vgpu="$( echo $vgpu | tr '[:upper:]' '[:lower:]' )"
  unset str
echo "install qemu: $vgpu"
  str+=( "#!/bin/bash" )
  str+=( "# This file is auto generated by IDV setup.sh file." )
  str+=( "/usr/local/bin/qemu-system-x86_64 \\" )
  str+=( "-m 4096 -smp 1 -M q35 \\" )
  str+=( "-enable-kvm \\" )

  qcow_opt=($(grep "GUEST_QCOW2_$vgpu" $idv_config_file))
  filename=${qcow_opt##*/}
  IFS='.' read fname fext <<< "${filename}"
  str+=( "-name  $fname \\" )
  str+=( "-boot d \\" )

  opt=($(grep "GUEST_ISO_$vgpu=" $idv_config_file))
  str+=( "-cdrom ${opt##*=} \\" )
  temp=${qcow_opt##*=}
  str+=( "-drive file=${temp%.*}.$fext \\" )

  fw_opt=($(grep "FW_$vgpu" $idv_config_file))
  str+=( "-bios ${fw_opt##*=} \\" )

  str+=( "-cpu host -usb -device usb-tablet \\" )
  str+=( "-vga cirrus \\" )
  str+=( "-k en-us \\" )
  str+=( "-vnc :0" )

  printf "%s\n"  "Creating $INSTALL_GUEST-$low_vgpu.sh file.. "
  printf "%s\n"  "${str[@]}" > ./temp_file
  run_as_root "cp ./temp_file $INSTALL_GUEST-$low_vgpu.sh"
  run_as_root "chmod +x $INSTALL_GUEST-$low_vgpu.sh"
  $(rm temp_file)
}

gfx_device="/sys/bus/pci/devices/0000:00:02.0"
function build_start_qemu_batch() {
  vgpu=$1
  low_vgpu="$( echo $vgpu | tr '[:upper:]' '[:lower:]' )"

  unset str

O_IFS=${IFS}
IFS=$'\n'
  str+=( "#!/bin/bash -x" )
  str+=( "# This file is auto generated by IDV setup.sh file." )
  str+=( "/usr/bin/qemu-system-x86_64 \\" )
  str+=( "-m 4096 -smp 1 -M q35 \\" )
  str+=( "-enable-kvm \\" )


  qcow_opt=($(grep "GUEST_QCOW2_$vgpu" $idv_config_file))
  filename=${qcow_opt##*/}
  IFS='.' read fname fext <<< "${filename}"
  str+=( "-name  $fname \\" )

  temp=${qcow_opt##*=}
  str+=( "-hda ${temp%.*}.$fext \\" )

  fw_opt=($(grep "FW_$vgpu" $idv_config_file))
  str+=( "-bios ${fw_opt##*=} \\" )

  str+=( "-cpu host -usb -device usb-tablet \\" )
  str+=( "-vga none \\" )
  str+=( "-k en-us \\" )
  str+=( "-vnc :0 \\" )
  str+=( "-cpu host -usb -device usb-tablet \\" )

  usb_opt=($(grep "^QEMU_USB_$vgpu" $idv_config_file | grep -oP '(?<=").*(?=")')) # remove double quote from option sting
  [[ ! -z $usb_opt ]] && str+=( "$usb_opt \\" )

  vgpu_guid=($(grep "^$vgpu" $idv_config_file))

  if [[ -z $vgpu_guid ]]; then
    unset str          # if there is no GUID set for startup file, then clear the $str
    str+=("GUID is not set. Re-run the config.sh")
  else
    str+=( "-device vfio-pci,sysfsdev=$gfx_device/${vgpu_guid#*=},display=off,x-igd-opregion=on" )
  fi

  printf "%s\n"  "Creating $START_GUEST-$low_vgpu.sh file.. "
  printf "%s\n"  "${str[@]}" > ./temp_file
  run_as_root "cp ./temp_file $START_GUEST-$low_vgpu.sh"
  run_as_root "chmod +x $START_GUEST-$low_vgpu.sh"
IFS=${O_IFS}
  $(rm temp_file)
}


function create_files() {
  local vgpuinfo=$1
  echo "create_file: temp: $vgpuinfo, $cdir"

#  build_fw_directory
#  build_create_vgpu "$vgpuinfo"
  build_install_qemu_batch "$vgpuinfo"
  build_start_qemu_batch "$vgpuinfo"
}

