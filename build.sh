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
# Check whether .idv-config file exists
# The .idv-config file is created by config.sh.
#================================================
echo "idv config file: $idv_config_file"
#[[ -f "$idv_config_file" ]] && echo "exist" || echo "not exists"
if [[ ! -f "$idv_config_file" ]];then
  printf "\n${yellow}Please run config.sh file...\n\n${NC}"
  exit 0
fi

#================================================
# Check validity of the repo and branch
#================================================
repo=($(grep "repo=" $idv_config_file))
branch=($(grep "branch=" $idv_config_file))
printf "\n"
if [[ -z $repo || -z $branch ]]; then
  echo "repo/branch is not set"
fi

if [[ -z "${repo##*repo=}" || -z "${branch##*=}" ]]; then
  printf "${yellow}Empty repo/branch setting. Please run the config.sh.${NC}\n"
  exit 0
fi


#[[ -z "${repo##*repo=}" && -z "${branch##*=}" ]] && source ./scripts/config-kernel.sh

#================================================
# Clean up the IDV
#================================================
[[ "$1" == "clean" ]] && clean && exit 0

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


