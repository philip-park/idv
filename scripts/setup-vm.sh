#!/bin/bash

source ./scripts/util.sh
source ./.idv-config

CREATE_VGPU="$vmdir/scripts/create-vgpu.sh"
INSTALL_GUEST="$vmdir/scripts/install-guest"
START_GUEST="$vmdir/scripts/start-guest"

TEMP_FILE="$cdir/temp_file"

gvt_disp_ports_mask="/sys/class/drm/card0/gvt_disp_ports_mask"
mdev_dir="/sys/bus/pci/devices/0000:00:02.0/mdev_supported_types"
gfx_device="/sys/bus/pci/devices/0000:00:02.0"

function build_create_vgpu() {
  unset temp
  [[ -z $mdev_type ]] &&  dialog --msgbox "Can't detect the mdev type. Pleas boot to iGVTg kernel and run config.sh to set the mdev type.\n\n" 20 80 && exit 1
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
    temp+=( "echo \"\$${i%%=*}\" > $mdev_dir/$mdev_type/create" )
  done

  printf "%s\n"  "Creating $CREATE_VGPU file.. " 
  printf "%s\n"  "${temp[@]}" > $TEMP_FILE
  run_as_root "cp $TEMP_FILE $CREATE_VGPU"
  run_as_root "chmod +x $CREATE_VGPU"
  $(rm $TEMP_FILE)
}

function build_install_qemu_batch_deleteme() {
  vgpu=$1
  low_vgpu="$( echo $vgpu | tr '[:upper:]' '[:lower:]' )"
  unset str
echo "install qemu: $vgpu"
  str+=( "#!/bin/bash" )
  str+=( "# This file is auto generated by IDV setup.sh file." )
  str+=( "/usr/bin/qemu-system-x86_64 \\" )
  str+=( "-m 4096 -smp 1 -M pc \\" )
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

  # for q35, defaults to q35
#  str+=( "-global ICH9-LPC.disable_s3=1 -global ICH9-LPC.disable_s4=1 \\" )
  str+=( "-global ICH9-LPC.disable_s3=0 -global ICH9-LPC.disable_s4=1 \\" )
  str+=( "-global PIIX4_PM.disable_s3=0 -global PIIX4_PM.disable_s4=1 \\" )
  str+=( "-cpu host -usb -device usb-tablet \\" )
  str+=( "-vga cirrus \\" )
  str+=( "-k en-us \\" )
  str+=( "-vnc :0 \\" )

  MAC=$( ./scripts/network/macgen.sh )
  str+=( "-net nic,macaddr=$MAC -net tap,script=/home/snuc/idv/scripts/network/qemu-ifup.nat,downscript=no \\")

  vgpu_guid=($(grep "^$vgpu" $idv_config_file))
  if [[ -z $vgpu_guid ]]; then
    unset str          # if there is no GUID set for startup file, then clear the $str
    str+=("GUID is not set. Re-run the config.sh")
  else
    str+=( "-device vfio-pci,sysfsdev=$gfx_device/${vgpu_guid#*=},display=off,x-igd-opregion=on" )
  fi

  printf "%s\n"  "Creating $INSTALL_GUEST-$low_vgpu.sh file.. "
  printf "%s\n"  "${str[@]}" > $TEMP_FILE
  run_as_root "cp $TEMP_FILE $INSTALL_GUEST-$low_vgpu.sh"
  run_as_root "chmod +x $INSTALL_GUEST-$low_vgpu.sh"

  $(rm $TEMP_FILE)
}
function build_start_qemu_batch_deleteme() {
  vgpu=$1
  low_vgpu="$( echo $vgpu | tr '[:upper:]' '[:lower:]' )"

  unset str

  str+=( "#!/bin/bash -x" )
  str+=( "# This file is auto generated by IDV setup.sh file." )
  str+=( "/usr/bin/qemu-system-x86_64 \\" )
  str+=( "-m 4096 -smp 1 -M pc \\" )
  str+=( "-enable-kvm \\" )

  qcow_opt=($(grep "GUEST_QCOW2_$vgpu" $idv_config_file))
  filename=${qcow_opt##*/}
  IFS='.' read fname fext <<< "${filename}"
  str+=( "-name  $fname \\" )

  temp=${qcow_opt##*=}
#  str+=( "-hda ${temp%.*}.$fext \\" )
  str+=( "-drive file=${temp%.*}.$fext \\" )

  fw_opt=($(grep "FW_$vgpu" $idv_config_file))
  str+=( "-bios ${fw_opt##*=} \\" )
  str+=( "-vga none \\" )
  str+=( "-display egl-headless \\" )
  str+=( "-k en-us \\" )
  str+=( "-vnc :0 \\" )

  MAC=$( ./scripts/network/macgen.sh )
  str+=( "-net nic,macaddr=$MAC -net tap,script=/home/snuc/idv/scripts/network/qemu-ifup.nat,downscript=no \\")

  str+=( "-global ICH9-LPC.disable_s3=0 -global ICH9-LPC.disable_s4=1 \\" )
  str+=( "-global PIIX4_PM.disable_s3=0 -global PIIX4_PM.disable_s4=1 \\" )
  str+=( "-machine kernel_irqchip=on \\" )
  str+=( "-cpu host -usb -device usb-tablet \\" )

  temp=$(grep "^QEMU_USB_$vgpu" $idv_config_file) # remove double quote from option sting
  temp=${temp##*=\"}
  usb_opt=${temp%\"*}
  [[ ! -z $usb_opt ]] && str+=( "$usb_opt \\" )

  vgpu_guid=($(grep "^$vgpu" $idv_config_file))

  if [[ -z $vgpu_guid ]]; then
    unset str          # if there is no GUID set for startup file, then clear the $str
    str+=("GUID is not set. Re-run the config.sh")
  else
    str+=( "-device vfio-pci,sysfsdev=$gfx_device/${vgpu_guid#*=},display=off,x-igd-opregion=on" )
  fi

  printf "%s\n"  "Creating $START_GUEST-$low_vgpu.sh file.. "
  printf "%s\n"  "${str[@]}" > $TEMP_FILE
  run_as_root "cp $TEMP_FILE $START_GUEST-$low_vgpu.sh"
  run_as_root "chmod +x $START_GUEST-$low_vgpu.sh"

  $(rm $TEMP_FILE)
}

function build_qemu_batch() {
  file_prefix=$1
  vgpu=$2
  low_vgpu="$( echo $vgpu | tr '[:upper:]' '[:lower:]' )"

  unset str

  str+=( "#!/bin/bash -x" )
  str+=( "# This file is auto generated by IDV setup.sh file." )
  str+=( "/usr/bin/qemu-system-x86_64 \\" )
  str+=( "-m 4096 -smp 4 -M pc \\" )
  str+=( "-enable-kvm \\" )

  qcow_opt=($(grep "GUEST_QCOW2_$vgpu" $idv_config_file))
  filename=${qcow_opt##*/}
  IFS='.' read fname fext <<< "${filename}"
  str+=( "-name  $fname \\" )

  if [[ $file_prefix == "install" ]]; then
    opt=($(grep "GUEST_ISO_$vgpu=" $idv_config_file))
    str+=( "-cdrom ${opt##*=} \\" )
  fi

  temp=${qcow_opt##*=}
  str+=( "-drive file=${temp%.*}.$fext \\" )

  fw_opt=($(grep "FW_$vgpu" $idv_config_file))
  str+=( "-bios ${fw_opt##*=} \\" )

  if [[ $file_prefix == "install" ]]; then
    str+=( "-vga cirrus \\" )
  else
    str+=( "-vga none \\" )
  fi
#############################
#  str+=( "-display gtk,gl=on \\" )
  str+=( "-display egl-headless \\" )
  str+=( "-k en-us \\" )
  str+=( "-vnc :0 \\" )

  MAC=$( ./scripts/network/macgen.sh )
  str+=( "-net nic,macaddr=$MAC -net tap,script=$vmdir/scripts/network/qemu-ifup.nat,downscript=no \\" )
  str+=( "-device e1000,netdev=net0 -netdev user,id=net0,hostfwd=tcp::5555-:5555,hostfwd=tcp::5554-:5554 \\" )
  str+=( "-global ICH9-LPC.disable_s3=0 -global ICH9-LPC.disable_s4=1 \\" )
  str+=( "-global PIIX4_PM.disable_s3=0 -global PIIX4_PM.disable_s4=1 \\" )
  str+=( "-machine kernel_irqchip=on \\" )
  str+=( "-cpu host -usb -device usb-tablet \\" )

  temp=$(grep "^QEMU_USB_$vgpu" $idv_config_file) # remove double quote from option sting
  temp=${temp##*=\"}
  usb_opt=${temp%\"*}
  [[ ! -z $usb_opt ]] && str+=( "$usb_opt \\" )

  vgpu_guid=($(grep "^$vgpu" $idv_config_file))

  if [[ -z $vgpu_guid ]]; then
    unset str          # if there is no GUID set for startup file, then clear the $str
    str+=("GUID is not set. Re-run the config.sh")
  else
#################################
#    str+=( "-device vfio-pci,sysfsdev=$gfx_device/${vgpu_guid#*=},display=on,x-igd-opregion=on" )
    if [[ $file_prefix != "install" ]]; then
      str+=( "-device vfio-pci,sysfsdev=$gfx_device/${vgpu_guid#*=},display=off,x-igd-opregion=on" )
    fi
  fi

  printf "%s\n"  "Creating $file_prefix-guest-$low_vgpu.sh file.. "
  run_as_root "rm -rf $vmdir/scripts/$file_prefix-guest-$low_vgpu.sh"

  # passing quoted argument in run_as_root didn't work too good.
  # Until I figure out how to, we do check for current user is root or not.
  if [[ $EUID -eq 0 ]]; then 
    printf "%s\n"  "${str[@]}" | tee -a $vmdir/scripts/$file_prefix-guest-$low_vgpu.sh
  else
    printf "%s\n"  "${str[@]}" | sudo -E tee -a $vmdir/scripts/$file_prefix-guest-$low_vgpu.sh
  fi
  run_as_root "chmod +x $vmdir/scripts/$file_prefix-guest-$low_vgpu.sh"
}


function create_files() {
  local vgpuinfo=$1
  echo "create_file: temp: $vgpuinfo, $cdir"

  qcow_opt=($(grep "GUEST_QCOW2_$vgpuinfo" $idv_config_file))

  if [[ $qcow_opt == *"android"* ]]; then
    echo "${yellow}Setting and Building android qcow2 file. Will take some time.${NC}"
    [[ -f $builddir/civ/android.qcow2 ]] && run_as_root "mv -f $builddir/civ/android.qcow2 ${qcow_opt##*=}"
  else
    echo "building install file"
    build_qemu_batch "install" "$vgpuinfo"

    echo "building start file"
    build_qemu_batch "start" "$vgpuinfo" 
  fi
}

#==========================================================
# Create VM related run time files from user selected FW_VGPU
# Without FW, the guest OS will not boot. So use FW selection
# until find better way.
#==========================================================
function setup_main() {
  # grep strings between '_' and '='
  vgpuinfo=( $( grep "FW_VGPU" $idv_config_file | grep -oP '(?<=_).*(?==)' ) )

  build_create_vgpu

  for vgpu in ${vgpuinfo[@]}; do
    create_files "$vgpu"
  done
}

#if mdev directory not exist then exit
[[ ! -d /sys/bus/pci/devices/0000:00:02.0/mdev_supported_types ]] && dialog --msgbox "/sys/bus/pci/device/0000:00:02.0/mdev_supported_types not exists. Please check kernel boot option.\n\n" 20 80 && exit 1

setup_main
#source $cdir/systemd/config-systemd.sh

