#!/bin/bash

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
echo "cdir : $0"
#================================================
# repo, branch, patches, kdir, krevision, kversion
#================================================
# iotg repo: "https://github.com/intel/linux-intel-lts.git"
# iotg idv branch/tag: "lts-v5.4.57-yocto-200819T072823Z"
#repo="https://github.com/intel/linux-intel-lts.git"
#branch="lts-v5.4.57-yocto-200819T072823Z"
#patches=""

# ccp repo: "https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git"
# ccp idv branch/tag: "v5.4.54"
#repo="https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git"
#branch="v5.4.54"
#patches="idv3.0_er3_patchset_rbhe"
kdir="kernel"
krevision="3.0"
kversion="intelgvt"
source ./scripts/kernel-config.sh
echo "build: patches: $patches"

#================================================
# Pull Kernel and Compile
#================================================
#source ./.idv-config
source ./scripts/build-helper

#source . `dirname $0`/simple_curses.sh
exit 0


install_packages
add_modules
cp -a /usr/share/kernel-package $cdir/ubuntu-package
pull_kernel
apply_patches
kernel_config
compile_kernel

#================================================
# Setup Kernel command line option in /etc/default/grub
#================================================
source scripts/grub-setup.sh
grub_setup

echo -en '\n'
echo "${green}To Install Kernel: \"sudo dpkg -i *.deb\"${NC}"

