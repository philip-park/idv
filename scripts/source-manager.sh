#!/bin/bash

source ./scripts/util.sh
#source ./idv-common

version="0.7"
echo "${green}Current working directory : $cdir${NC}"
kdir="kernel"
krevision="3.0"
kversion="intelgvt"



#================================================
# Output current status
#================================================
function display_settings() {
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
}



##############################################
# qemu source and build 
qemu_source=https://git.qemu.org/git/qemu.git
qemubranch=stable-4.2
qemu_dir=qemu
qemupatch="$patchdir/$qemu_dir"
##############################################

function download_qemu() {

echo "dir: $PWD"
  cd "$builddir"

  run_as_root "apt-get install -y pkg-config libgtk-3-dev libsdl2-dev libgbm-dev libspice-server-dev  libusb-1.0-0-dev libcap-dev libcap-ng-dev libattr1-dev flex bison make libiscsi-dev librbd-dev libaio-dev"
  [[ ! -z "$builddir/$qemu_dir" ]] && find $builddir/$qemu_dir -type d -name "$qemu_dir" -exec sudo rm -rf {} +
#  find $patchdir -type d -name "$qemu_dir" -exec rm -rf {} +

  # pull tree
#  git clone --depth 1 $qemu_source --branch $qemubranch --single-branch $qemu_dir
   git clone $qemu_source
   cd $qemu_dir
   git checkout $qemubranch

  cd $builddir/$qemu_dir
  [[ -d $qemupatch ]] && git apply $qemupatch/*

#  ./configure --prefix=/usr --enable-kvm --disable-xen --enable-libusb --enable-debug-info \
#    --enable-debug --enable-sdl --enable-vhost-net --enable-spice --disable-debug-tcg \
#    --enable-opengl --enable-gtk --enable-virtfs --target-list=x86_64-softmmu \
#    --audio-drv-list=pa
}

#---------------------------------------------
# build qemu
#---------------------------------------------
function build_qemu() {
  echo "make qemu"
#  [[ -z "$(ls -A $builddir/$qemu_dir)" ]] && echo "${red}Can't find qemu source..${NC}"; return
  echo "make 2 qemu cd $builddir/$qemu_dir"

  cd $builddir/$qemu_dir
  ./configure --prefix=/usr --enable-kvm --disable-xen --enable-libusb --enable-debug-info \
    --enable-debug --enable-sdl --enable-vhost-net --enable-spice --disable-debug-tcg \
    --enable-opengl --enable-gtk --enable-virtfs --target-list=x86_64-softmmu \
    --audio-drv-list=pa
  make -j `nproc`
}


kernelpatch="${patches%.tar.gz}"
##############################################
# kernel source and build 
##############################################
function download_kernel() {
  cd $builddir
  # 1) delete existing kernel directory if exist
  [[ ! -z "$builddir/$kdir" ]] && find . -type d -name "$kdir" -exec rm -rf {} +

  # 2) check fresh copy of the kernel from a repo
  git clone --depth 1 $repo --branch $branch --single-branch $kdir

  # 3) apply patches if exists
  if [[ ! -d "$patchdir/$kernelpatch" && -f "$patchdir/$patches" ]]; then
    tar -C $patchdir -xzvf $patchdir/$patches
  fi

  cd $kdir
  echo "kdir: $PWD, git apply $kernelpatch/* #2&>/dev/null"
  git apply $kernelpatch/* #2&>/dev/null
#  git apply --directory=$build/$kdir $patchdir/$kernelpatch/* #2&>/dev/null


# Fetch kernel config to .config and apply it using make oldconfig
  local kernel_config_url="https://kernel.ubuntu.com/~kernel-ppa/config/focal/linux/5.4.0-44.48/amd64-config.flavour.generic"
  echo "fetching kernel config from $kernel_config_url"
  /usr/bin/wget -q -O ./.config $kernel_config_url

  echo "${green}--- Appling kernel config ...${NC}"
  ( yes "" | make oldconfig )
}

#---------------------------------------------
# Build kernel
#---------------------------------------------
function build_kernel() {
  ( cd build/$kdir && CONCURRENCY_LEVEL=`nproc` fakeroot make-kpkg -j`nproc` --initrd --append-to-version=-$kversion --revision $krevision --overlay-dir=$cdir/ubuntu-package kernel_image kernel_headers )
}

##############################################
# build all sources using docker
##############################################
function build_sources() {
echo "in build_srouces builddir: $builddir, $kdir"
#  if [[ -z "$(ls -A $builddir/$kdir)" ]]; then
#    echo "${red}Can't find kernel source..${NC}"
#     return
#  fi
echo "docker calling"
  docker=$( dpkg -l | grep -w " docker " )
  [[ -z "$docker" ]] && source $cdir/scripts/install-docker.sh

echo "cdir: $cdir"
  # run docker as user to build kernel
#  run_as_root "docker run --rm -v $cdir:/build 
  run_as_root "docker run --rm --net=host -v $cdir:$cdir \
        -u $(id -u ${USER}):$(id -g ${USER}) \
       --name bob mydocker/bob_the_builder  bash -c \"cd $cdir/docker; ./build-sources.sh\""
#       --name bob mydocker/bob_the_builder"
}

