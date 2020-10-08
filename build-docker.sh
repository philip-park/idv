#!/bin/bash

export env TERM=xtern-256color
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
echo "${green}Current working directory : $cdir${NC}"
kdir="kernel"
krevision="3.0"
kversion="intelgvt"

source $idv_config_file
source ./scripts/build-kernel-docker.sh
exit 0
#================================================
# Check whether .idv-config file exists
# The .idv-config file is created by config.sh.
#================================================
echo "idv config file: $idv_config_file"
if [[ ! -f "$idv_config_file" ]];then
  printf "\n${yellow}Please run config.sh file...\n\n${NC}"
  exit 0
fi

#================================================
# Check validity of the repo and branch
# Can't build if repo and branch is empty
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

source $idv_config_file
source ./scripts/build-kernel-docker.sh



