
#================================================
# text attributes ####
#================================================
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
blue=`tput setaf 4`
magenta=`tput setaf 5`
cyan=`tput setaf 6`
white=`tput setaf 7`
blink=`tput blink`
NC=`tput sgr0`

#=================================
# global variable shared among scripts
#=================================
cdir=$(pwd)
vmroot=/var
#vmroot=$cdir
vmdir="$vmroot/vm"

default_config=./scripts/idv-config-default
idv_config_file="$cdir/.idv-config"
[[ -f "$idv_config_file" ]] && default_config=$idv_config_file || touch $idv_config_file

function update_idv_config() {
  opt=("$@")
  string=${opt[@]:1}
  (grep -qF "${opt[0]}=" $idv_config_file) \
      && sed -i "s/^${opt[0]}=.*$/${opt[0]}=${string//\//\\/}/" $idv_config_file \
      || echo "${opt[0]}=${string[@]}" >> $idv_config_file
}

function run_as_root() {
  cmd=$1
  if [[ $EUID -eq 0 ]];then
    ($cmd)
  else
    sudo -s <<EOF
    ($cmd)
EOF
   fi
}

function install_packages() {
  echo "${green}Installing packages needed.. may take some time.${NC}"
  if [[ $EUID -eq 0 ]];then
    apt-get -y autoremove #&>/dev/null"
    apt-get -y install rsync qemu-system-x86 liblz4-tool kernel-package libelf-dev build-essential git libfdt-dev libpixman-1-dev libssl-dev vim bc socat libsdl1.2-dev libspice-server-dev autoconf libtool xtightvncviewer tightvncserver x11vnc uuid-runtime uuid uml-utilities bridge-utils python-dev liblzma-dev libc6-dev libegl1-mesa-dev libepoxy-dev libdrm-dev libgbm-dev spice-client-gtk libgtk2.0-dev libusb-1.0-0-dev bison flex openssh-server net-tools kernel-package uuid
# &>/dev/null"
  else
    sudo apt-get -y autoremove #&>/dev/null"
    sudo apt-get -y install rsync qemu-system-x86 liblz4-tool kernel-package libelf-dev build-essential git libfdt-dev libpixman-1-dev libssl-dev vim bc socat libsdl1.2-dev libspice-server-dev autoconf libtool xtightvncviewer tightvncserver x11vnc uuid-runtime uuid uml-utilities bridge-utils python-dev liblzma-dev libc6-dev libegl1-mesa-dev libepoxy-dev libdrm-dev libgbm-dev spice-client-gtk libgtk2.0-dev libusb-1.0-0-dev bison flex openssh-server net-tools kernel-package uuid
  fi
}

function build_fw_directory() {
  run_as_root "apt-get install -y qemu-system-x86"

  [[ -f /usr/share/qemu/bios.bin ]] && run_as_root "cp /usr/share/qemu/bios.bin $vmdir/fw" \
      || echo "Error: can't find /usr/share/qemu/bios.bin file"
  [[ -f /usr/share/qemu/OVMF.fd ]] && run_as_root "cp /usr/share/qemu/OVMF.fd $vmdir/fw" \
      || echo "Error: can't find /usr/share/qemu/OVMF.fd file"
}

function build_vm_directory() {
  if [[ $EUID -eq 0 ]];then
    mkdir -p {$vmdir,$vmdir/fw,$vmdir/disk,$vmdir/iso,$vmdir/scripts}
  else
    run_as_root "mkdir -p {$vmdir,$vmdir/fw,$vmdir/disk,$vmdir/iso,$vmdir/scripts}"
  fi
  build_fw_directory
}


#================================================
# Clean the mess it made
#================================================
function clean() {
  [[ -f $idv_config_file ]] && source $idv_config_file || exit 0
echo "clean idv"
  run_as_root "find /var -type d -name "vm" -exec rm -rf {} +"
  [[ ! -z "$kdir" ]] && find . -type d -name "$kdir" -exec rm -rf {} +
  [[ ! -z "$patches" ]] && find . -type d -name "${patches%.tar.gz}" -exec rm -rf {} +
  find . -type d -name "ubuntu-package" -exec rm -rf {} +
  find . -type f -name "*.deb" -exec rm -rf {} +
}

