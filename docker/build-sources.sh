#!/bin/bash

export env TERM=xterm-256color
cd .. 
source ./scripts/util.sh

###################################################################
# version : version of the idv.sh file
# cdir    : pionts to current working directory where idv.sh file runs
# repo    : URL to kernel source repository
# kdir    : Directory where kernel will be pulled and saved from repo
# branch  : tag or branch of the kernel source
# patches : idv patch file name with our ".tar.gz" extention
###################################################################
echo "${green}Current working directory : $cdir${NC}"

echo "build_source ************************************"
source ./scripts/source-manager.sh
build_kernel

ubu_build_ovmf
#build_qemu

exit 0



