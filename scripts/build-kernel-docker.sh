#!/bin/bash -e

###################################################################
# version : version of the idv.sh file
# cdir    : pionts to current working directory where idv.sh file runs
# repo    : URL to kernel source repository
# kdir    : Directory where kernel will be pulled and saved from repo
# branch  : tag or branch of the kernel source
# patches : idv patch file name with our ".tar.gz" extention
###################################################################
#version="0.7"
#cdir=$(pwd)

#================================================
# 1) IOTG kernel source repo, patches and kernel directory
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
# 3) Add modules for KVM/GVTg
#================================================
function add_modules() {
modules=(kvmgt vfio-iommu-type1 vfio-mdev vfio-pci)

  echo "${green}Adding kernel modules.${NC}"
for i in "${modules[@]}"
  do
    echo $i
  run_as_root "grep -qxF $i /etc/initramfs-tools/modules || echo $i >> /etc/initramfs-tools/modules"
done
}

function install_docker() {
  $(docker -v)
  if [[ $? -ne 0 ]]; then
    run_as_root "apt-get update"
    run_as_root "apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common"
    run_as_root "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -"
    run_as_root "apt-key fingerprint 0EBFCD88"
    run_as_root "add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\""
    run_as_root "apt-get update"
    run_as_root "apt-get install -y docker-ce docker-ce-cli containerd.io"
  fi
}

function build_docker() {
  if [[ "$(docker images -q mydocker/bob_the_builder 2> /dev/null)" == "" ]]; then
    cd ./docker; run_as_root "docker build . -t mydocker/bob_the_builder"
  fi
}

#================================================
#cp -a /usr/share/kernel-package $cdir/ubuntu-package

#================================================
# 4) Pull the kernel source
#================================================
function pull_kernel() {
#echo "repo: $repo"
#source $idv_config_file
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
function kernel_config() {
if [ ! -z "$configurl" ]; then
    echo "fetching kernel config from $configurl"
    /usr/bin/wget -q -O $kdir/.config $configurl
fi

echo "${green}--- Appling kernel config ...${NC}"
( cd $kdir && yes "" | make oldconfig )
}

function compile_kernel() {
( cd $kdir && CONCURRENCY_LEVEL=`nproc` fakeroot make-kpkg -j`nproc` --initrd --append-to-version=-$kversion --revision $krevision --overlay-dir=$cdir/ubuntu-package kernel_image kernel_headers )
}
install_docker
build_docker
exit 0
install_packages
#exit 0
add_modules
cp -a /usr/share/kernel-package $cdir/ubuntu-package
pull_kernel
apply_patches
kernel_config
compile_kernel

