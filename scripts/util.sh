
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
blue=`tput setaf 4`
magenta=`tput setaf 5`
cyan=`tput setaf 6`
white=`tput setaf 7`
blink=`tput blink`
NC=`tput sgr0`

default_config=./scripts/idv-config-default
idv_config_file=./.idv-config
[[ -f "./.idv-config" ]] && default_config="./.idv-config" || touch ./.idv-config

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
    sudo -s <<RUNASSUDO_PACKAGE
    ($cmd)
RUNASSUDO_PACKAGE
   fi
}

function install_packages() {
  echo "${green}Installing packages needed.. may take some time.${NC}"
  run_as_root "apt-get autoremove -y &>/dev/null"
  run_as_root "apt-get install -y rsync qemu-system-x86 liblz4-tool kernel-package libelf-dev build-essential git libfdt-dev libpixman-1-dev libssl-dev vim bc socat libsdl1.2-dev libspice-server-dev autoconf libtool xtightvncviewer tightvncserver x11vnc uuid-runtime uuid uml-utilities bridge-utils python-dev liblzma-dev libc6-dev libegl1-mesa-dev libepoxy-dev libdrm-dev libgbm-dev spice-client-gtk libgtk2.0-dev libusb-1.0-0-dev bison flex openssh-server net-tools kernel-package uuid"
# &>/dev/null
}

function make_var_vm() {
vm_dir=/var/vm
echo "make var vm"
run_as_root "mkdir -p {$vm_dir,$vm_dir/fw,$vm_dir/disk,$vm_dir/iso,$vm_dir/scripts}"
}

#================================================
# Clean the mess it made
#================================================
function clean() {

  [[ -f $idv_config_file ]] && source $idv_config_file || exit 0
  run_as_root "find /var -type d -name "vm" -exec rm -rf {} +"
  [[ ! -z "$kdir" ]] && run_as_root "find . -type d -name "$kdir" -exec rm -rf {} +"
  [[ ! -z "$patches" ]] && run_as_root "find . -type d -name "${patches%.tar.gz}" -exec rm -rf {} +"
  run_as_root "find . -type d -name "ubuntu-package" -exec rm -rf {} +"
  run_as_root "find . -type f -name "*.deb" -exec rm -rf {} +"
}

