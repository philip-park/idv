#!/bin/bash

source scripts/util.sh

###################################################################
# version : version of the idv.sh file
# cdir    : pionts to current working directory where idv.sh file runs
# repo    : URL to kernel source repository
# kdir    : Directory where kernel will be pulled and saved from repo
# branch  : tag or branch of the kernel source
# patches : idv patch file name with our ".tar.gz" extention
###################################################################
version="0.7"
cdir=$(pwd)
echo "${green}Current working directory : $cdir${NC}"
kdir="kernel"
krevision="3.0"
kversion="intelgvt"


function set_global_variables_deleteme() {
while IFS=$'\n' read -r line; do
  case $line in
    repo=*) repo=${line##*=} ;;
    branch=*) branch=${line##*=} ;;
    patches=*) patches=${line##*=} ;;
  esac
done < "$default_config"
}

#================================================
# Clean the mess it made
#================================================
function clean_deleteme() {
O_IFS=${IFS}
IFS=$'\n'
  [[ -f $idv_config_file ]] && echo "found" && source $idv_config_file || exit 0
#  set_global_variables
IFS=${O_IFS}
  find . -type d -name "$kdir" -exec rm -rf {} +
  find . -type d -name "${patches%.tar.gz}" -exec rm -rf {} +
  find . -type d -name "ubuntu-package" -exec rm -rf {} +
  find . -type f -name "*.deb" -exec rm -rf {} +
}

[[ "$1" == "clean" ]] && clean && exit 0


#================================================
# repo, branch, patches, kdir, krevision, kversion
#================================================
repo=($(grep "repo=" $idv_config_file))
branch=($(grep "branch=" $idv_config_file))

echo "repo: ${repo##*repo=}, branch: ${branch##*branch=}"
#[[ -z "${repo##*repo=}" && -z "${branch##*=}" ]] && echo -en '\n\n';  printf "\n${red}Please run config.sh file${NC}\n\n"; exit 0
[[ -z "${repo##*repo=}" && -z "${branch##*=}" ]] && source ./scripts/config-kernel.sh

#================================================
# Pull Kernel and Compile
#================================================
source $idv_config_file
source ./scripts/build-helper


#================================================
# Setup Kernel command line option in /etc/default/grub
#================================================
source scripts/grub-setup.sh

run_as_root "apt-get install -y qemu-system-x86"

echo -en '\n'
echo "${green}To Install Kernel: \"sudo dpkg -i *.deb\"${NC}"


