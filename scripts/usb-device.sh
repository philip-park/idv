#!/bin/bash

declare -a usb_devs

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

function build_qemu_usb_option() {
  local array options
  local n=0
  O_IFS=$IFS
  IFS=$'\n'

  while read f; do options+=($n "$f" "off"); n=$((n+1)); done < <(lsusb)

  cmd=(dialog --checklist "Hi, this is the checklist box. this is test check list" 40 100 13)
  options=(${options[@]})
  choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)

  IFS=${O_IFS}
  for choice in $choices
  do
    idx=$((choice*3+1))
    IFS=' ' read -ra usbinfo <<< "${options[$idx]}"
    IFS=':' read vid pid <<< "${usbinfo[5]}"
    usb_port=$(find_attached_port $vid $pid)
    #if [[ "$usb_port" ]]; then
    IFS=$'-' read bus port <<< "$usb_port"
    if [[ "$port" ]]; then
      qemu_option+=("-device usb-host,hostbus=$bus,hostport=$port")
#      echo "qemu_option: ${qemu_option[@]}"
#      echo "bus: $bus, port: $port, $usb_port"
    fi
    #fi
  done
  IFS=${O_IFS}
  echo "qemu_option: ${qemu_option[@]}"
}

INSTALL_QEMU_SCRIPT="install.sh"
function write_install_script() {
cat << EOF | sudo tee $INSTALL_QEMU_SCRIPT
#!/bin/bash -x
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


#!/bin/bash -x
/usr/bin/qemu-system-x86_64 \
-m 4096 -smp 1 -M q35 \
-enable-kvm \
-name ubuntu-guest \
-hda /home/snuc/vm/disk/ubuntu18.qcow2 \
-bios /home/snuc/vm/fw/ubuntu-bios.bin \
-cpu host -usb -device usb-tablet \
-vga none \
-k en-us \
-vnc :0 \
-cpu host -usb -device usb-tablet \
-device vfio-pci,sysfsdev=/sys/bus/pci/devices/0000:00:02.0/37414358-bd2b-11e8-8fa3-7bde838751b0,display=off,x-igd-opregion=on \
-device usb-host,hostbus=1,hostport=3 \
-device usb-host,hostbus=2,hostport=4.4




#!/bin/bash -x
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

}

cmd=(dialog --keep-tite --menu "Select options:" 22 76 16)

options=(1 "Pass USB devices"
         2 "Option 2"
         3 "Option 3"
         4 "Option 4")

choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)

for choice in $choices
do
    case $choice in
        1)

build_qemu_usb_option
           ;;
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

