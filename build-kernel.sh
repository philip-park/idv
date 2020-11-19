#!/bin/bash

source ./scripts/util.sh

function install_kernel() {
  debs=$( ls -R $cdir/build/*.deb 2>/dev/null )
  echo "${yellow}$debs${NC}"

  [[ -z "$debs" ]] && echo -e "${red}✖${NC} Can't find *.deb file" && exit 1

  source $cdir/scripts/config-modules.sh
  run_as_root "dpkg -i build/*.deb"
  source ./grub-setup.sh

  echo "reboot in 5 seconds. Control + C to abort.."
  sleep 5
  run_as_root "reboot" 
}

# check for install option.
[[ $1 == "install" ]] && install_kernel && exit 0

echo "idv config file: $idv_config_file"
source $idv_config_file


#-------------------------------------
# Prepare the build environment
#-------------------------------------
function prep_build() {
  install_pkgs "dialog acl make build-essential flex bison bc dmidecode"

  # Install runtime package
  install_pkgs "dnsmasq bridge-utils"

#  dialog=$( dpkg -l | grep -w " dialog " )
#  [[ -z $dialog ]] && run_as_root "apt-get install dialog"
#  acl=$( dpkg -l | grep -w " acl " )
#  [[ -z $acl ]] && run_as_root "apt-get install acl"

#  docker=$( dpkg -l | grep -w " docker " )
#  [[ -z $docker ]] && source $cdir/scripts/install-docker.sh
  [[ -z "$repo" || -z "$branch" ]] && source $cdir/scripts/config-kernel.sh
}

#-------------------------------------
# Build source code using docker
#-------------------------------------
function install_kernel_deleteme() {
  debs=$( ls $cdir/*.deb )
  echo "${yellow}$debs${NC}"

  [[ -z "$debs" ]] && echo -e "${red}✖${NC} Oops.. kernel build error" && exit 1

  read -r -p "\n ${green}✔${NC} Want to install the kernel and reboot? [y/N] " answer
  case "$answer" in
    [yY]) install_kernel;;
    *) echo "you can install kernel using ${yellow}$0 install${NC}";;
  esac
}

function sriov_system() {
  echo "TBD: add sriov support here"

}

prep_build
#pmc=$(cat /sys/devices/cpu/caps/pmu_name)
#[[ $pmc == "icelake" ]] && sriov_system || build_kernel
source $cdir/scripts/source-manager.sh

# display current settings before move on
display_settings

# download kernel and qemu and apply patch
# skip if --nodown specified
[[ $1 != "--nodown" ]] && download_kernel && download_qemu

# get kernel source
#download_kernel

# get qemu source
#download_qemu

# build kernel/qemu
build_sources

