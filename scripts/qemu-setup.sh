#!/bin/bash


vm_dir=/var/vm

(mkdir -p {$vm_dir,$vm_dir/fw,$vm_dir/disk,$vm_dir/iso,$vm_dir/scripts})
declare -a usb_devs
source scripts/util.sh

function get_qemu_firmware_option() {
  fw=( $vm_dir/fw/* )

  for i in ${fw[@]}; do
    temp=${i##*/}
    echo "temp: $temp"
    temp=${temp%.*}
    echo "$i, temp: $temp"
    [[ $temp == "OVMF" ]] && options+=("$temp" "$i" on) || options+=("$temp" "$i" off)
  done
  [[ ${options[0]} == '*' ]] && dialog --msgbox \
"Cant find firmware in $vm_dir/fw\n\n" 10 40 && exit 1

  cmd=(dialog --radiolist "Please choose firmware to be used for guest OS." 30 60 5)
  options=(${options[@]})
  choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)

  for (( i=0; i<${#options[@]}; $((i+=3)) )); do
    [[ $choices == ${options[$i]} ]] && update_idv_config "FW" "${options[$((i+1))]}"
  done
}


function find_attached_port() {
local vid="$1"
local pid="$2"
local usb_port=""

for sysdevpath in $(find /sys/bus/usb/devices/usb*/ -name idVendor); do
  if [[ `cat $sysdevpath` == "$vid" ]]; then
    usb_port=${sysdevpath%/idVendor*}
    if [[ `cat $usb_port/idProduct` == "$pid" ]]; then
      usb_port=${usb_port##*/}
      break
    fi
  fi
done

echo "$usb_port"
}

function get_qemu_usb_option() {
  local array options
  local n=0
  O_IFS=$IFS
  IFS=$'\n'

  while read f; do options+=($n "$f" "off"); n=$((n+1)); done < <(lsusb)

  cmd=(dialog --checklist "Hi, this is the checklist box. this is test check list" 40 100 13)
  options=(${options[@]})
  choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)

  IFS=${O_IFS}
  new_option=0
  i=0
  for choice in $choices
  do
    idx=$((choice*3+1))
    IFS=' ' read -ra usbinfo <<< "${options[$idx]}"
    IFS=':' read vid pid <<< "${usbinfo[5]}"
    usb_port=$(find_attached_port $vid $pid)
    IFS=$'-' read bus port <<< "$usb_port"
    if [[ "$port" ]]; then
      qemu_option+=("-device usb-host,hostbus=$bus,hostport=$port")
    fi
  done
  IFS=${O_IFS}
  echo "qemu_option: ${qemu_option[@]}"
  update_idv_config "QEMU_USB" "${qemu_option[@]}"
}
get_qemu_firmware_option
get_qemu_usb_option

exit 0


cat <<EOF > /var/vm/install-guest.sh
#!/bin/bash 
/usr/local/bin/qemu-system-x86_64 \
-m 4096 -smp 1 -M q35 \
-enable-kvm \
-name ubuntu-guest \
-boot d \
-cdrom /home/snuc/vm/iso/ubuntu18.iso \
-drive file=/home/snuc/vm/disk/ubuntu18-ovmf.qcow2 \
-bios /home/snuc/vm/fw/OVMF-pure-efi.fd \
-cpu host -usb -device usb-tablet \
-vga cirrus \
-k en-us \
-vnc :0
EOF

cat <<EOF > /var/vm/start-guest.sh
#!/bin/bash -x
/usr/bin/qemu-system-x86_64 \
-m 4096 -smp 1 -M q35 \
-enable-kvm \
-name ubuntu-guest \
-hda /home/snuc/vm/disk/ubuntu18-ovmf.qcow2 \
-bios /home/snuc/vm/fw/OVMF-pure-efi.fd \
-cpu host -usb -device usb-tablet \
-vga none \
-k en-us \
-vnc :0 \
-cpu host -usb -device usb-tablet \
-device vfio-pci,sysfsdev=/sys/bus/pci/devices/0000:00:02.0/37414358-bd2b-11e8-8fa3-7bde838751b0,display=off,x-igd-opregion=on \
-device usb-host,hostbus=1,hostport=3 \
-device usb-host,hostbus=2,hostport=4.4
EOF

