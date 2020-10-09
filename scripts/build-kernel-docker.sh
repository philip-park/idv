#!/bin/bash -e

###################################################################
# version : version of the idv.sh file
# cdir    : pionts to current working directory where idv.sh file runs
# repo    : URL to kernel source repository
# kdir    : Directory where kernel will be pulled and saved from repo
# branch  : tag or branch of the kernel source
# patches : idv patch file name with our ".tar.gz" extention
###################################################################

#================================================
# Output current status
#================================================
echo -en '\n'
echo "================================================="
echo "idv version:  ${green}$version${NC}"
echo "repo:         ${green}$repo${NC}"
echo "branch:       ${green}$branch${NC}"


if [ -d "${patches%.tar.gz}" ]; then
  # if patches directory exists
  echo "${green} -- patching from a ${patches%.tar.gz} directory ...${NC}"
  echo "patches:      ${green}${patches%.tar.gz} directory${NC}"
elif [ ! -z "$patches" ]; then
  # if .tar.gz file exists
  echo "${green} -- patching from $patches ...${NC}"
  echo "patches:      ${green}$patches${NC}"

else
  echo "patches:      ${yellow}No patches are applied ...${NC}"
fi

echo "kernel dir:   ${green}$kdir${NC}"
echo "Kernel ver:   ${green}$kversion${NC}"
echo "Kernel rev:   ${green}$krevision${NC}"
echo -e "current dir:  ${blink}$cdir${NC}"
echo "=================================================\n"
echo -en '\n'

read -p "Press <Enter> key to continue"

#================================================
#cp -a /usr/share/kernel-package $cdir/ubuntu-package

#================================================
# 4) Pull the kernel source
#================================================
function pull_kernel() {
  [[ ! -d "$cdir/$kdir" ]] && git clone --depth 1 $repo --branch $branch --single-branch $kdir
}

#================================================
# 5) Apply patches if specified
#================================================
function apply_patches() {
if [ -d "${patches%.tar.gz}" ]; then
  # if patches directory exists
  echo "${green} -- patching from a ${patches%.tar.gz} directory ...${NC}"

  ( cd $kdir && git reset --hard )
  git apply --directory=$kdir $cdir/${patches%.tar.gz}/*

elif [ -f "$patches" ]; then
  # if .tar.gz file exists
  echo "${green} -- patching from $patches file ...${NC}"

  tar xzvf $cdir/$patches
  ( cd $kdir && git reset --hard )
  git apply --directory=$kdir $cdir/${patches%.tar.gz}/*
else
  echo "${green} -- No patches is applied ...${NC}"
fi
}

#================================================
# 5) config file for kernel
#================================================
# Fetch kernel config to .config and apply it using make oldconfig
kernel_config_url="https://kernel.ubuntu.com/~kernel-ppa/config/focal/linux/5.4.0-44.48/amd64-config.flavour.generic"
function kernel_config() {
  if [ ! -z "$kernel_config_url" ]; then
    echo "fetching kernel config from $kernel_config_url"
    /usr/bin/wget -q -O $kdir/.config $kernel_config_url
  fi

  echo "${green}--- Appling kernel config ...${NC}"
  ( cd $kdir && yes "" | make oldconfig )
}

function compile_kernel() {
  ( cd $kdir && CONCURRENCY_LEVEL=`nproc` fakeroot make-kpkg -j`nproc` --initrd --append-to-version=-$kversion --revision $krevision --overlay-dir=$cdir/ubuntu-package kernel_image kernel_headers )
}
#cp -a /usr/share/kernel-package $cdir/ubuntu-package
pull_kernel
apply_patches
kernel_config
compile_kernel

