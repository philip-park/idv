#!/bin/bash

source ./scripts/util.sh

echo "${green}Current working directory : $cdir${NC}"
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
#echo "dir: $PWD"
  cd "$builddir"

  install_pkgs "pkg-config libgtk-3-dev libsdl2-dev libgbm-dev libspice-server-dev  libusb-1.0-0-dev libcap-dev libcap-ng-dev libattr1-dev flex bison make libiscsi-dev librbd-dev libaio-dev gettext"

  [[ ! -z "$builddir/$qemu_dir" ]] && find $builddir/$qemu_dir -type d -name "$qemu_dir" -exec rm -rf {} +
  [[ ! -z "$qemupatch" ]] && find $qemupatch -type d -name "$qemu_dir" -exec rm -rf {} +
#  find $patchdir -type d -name "$qemu_dir" -exec rm -rf {} +

  # pull tree
#  git clone --depth 1 $qemu_source --branch $qemubranch --single-branch $qemu_dir
  wget https://download.qemu.org/$QEMU_REL.tar.xz -P $builddir/$qemu_dir
  cd $builddir/$qemu_dir
  tar -xf $QEMU_REL.tar.xz
  cd $QEMU_REL

  wget -q https://raw.githubusercontent.com/projectceladon/vendor-intel-utils/master/host/qemu/0001-Revert-Revert-vfio-pci-quirks.c-Disable-stolen-memor.patch	-P $qemupatch
	wget -q https://raw.githubusercontent.com/projectceladon/vendor-intel-utils/master/host/qemu/Disable-EDID-auto-generation-in-QEMU.patch -P $qemupatch
#	wget -q https://raw.githubusercontent.com/projectceladon/vendor-intel-utils/master/host/ovmf/OvmfPkg-add-IgdAssgingmentDxe-for-qemu-4_2_0.patch -P $qemupatch
  
#   git clone $qemu_source
#   cd $qemu_dir
#   git checkout $qemubranch

#  cd $builddir/$qemu_dir
  patchfiles=$( ls -A $qemupatch 2>/dev/null )
  if [[ $? -eq 0 ]]; then
    for i in ${patchfiles[@]}; do
       patch -p1 < $qemupatch/$i
    done
  fi

  ./configure --prefix=/usr --enable-kvm --disable-xen --enable-libusb --enable-debug-info \
    --enable-debug --enable-sdl --enable-vhost-net --enable-spice --disable-debug-tcg \
    --enable-opengl --enable-gtk --enable-virtfs --target-list=x86_64-softmmu \
    --audio-drv-list=pa

  make -j `nproc`
}

#---------------------------------------------
# build qemu
#---------------------------------------------
function build_qemu_archive() {
  echo "make qemu"
#  [[ -z "$(ls -A $builddir/$qemu_dir)" ]] && echo "${red}Can't find qemu source..${NC}"; return
  echo "make 2 qemu cd $builddir/$qemu_dir"

  cd $builddir/$qemu_dir
#  ./configure --prefix=/usr --enable-kvm --disable-xen --enable-libusb --enable-debug-info \
#    --enable-debug --enable-sdl --enable-vhost-net --enable-spice --disable-debug-tcg \
#    --enable-opengl --enable-gtk --enable-virtfs --target-list=x86_64-softmmu \
#    --audio-drv-list=pa
#  make -j `nproc`
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
#  echo "kdir: $PWD, git apply $kernelpatch/* #2&>/dev/null"
  git apply $kernelpatch/* #2&>/dev/null
#  git apply --directory=$build/$kdir $patchdir/$kernelpatch/* #2&>/dev/null


# Fetch kernel config to .config and apply it using make oldconfig
  local kernel_config_url="https://kernel.ubuntu.com/~kernel-ppa/config/focal/linux/5.4.0-44.48/amd64-config.flavour.generic"
#  echo "fetching kernel config from $kernel_config_url"
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
echo "in build_srouces builddir: $builddir, $kdir, $cdir"
#  if [[ -z "$(ls -A $builddir/$kdir)" ]]; then
#    echo "${red}Can't find kernel source..${NC}"
#     return
#  fi
echo "install docker calling"

  if ! dpkg -s "docker-ce" >/dev/null 2>&1; then
    source $cdir/scripts/install-docker.sh
  fi

echo "return from install docker: $cdir"
  # run docker as user to build kernel
#  run_as_root "docker run --rm -v $cdir:/build 
  run_as_root "docker run --rm --net=host -v $cdir:$cdir \
        -u $(id -u ${USER}):$(id -g ${USER}) \
       --name bob mydocker/bob_the_builder  bash -c \"cd $cdir/docker; ./build-sources.sh\""
#       --name bob mydocker/bob_the_builder"

#  build_qemu
}


##############################################
# build CIV
##############################################
function ubu_build_ovmf(){
#  install_pkgs "uuid-dev nasm acpidump iasl"

  cd $builddir/$qemu_dir/$QEMU_REL/roms/edk2
#  cd $CIV_WORK_DIR/$QEMU_REL/roms/edk2
  patch -p4 < $builddir/civ/patches/ovmf/OvmfPkg-add-IgdAssgingmentDxe-for-qemu-4_2_0.patch
  source ./edksetup.sh
  make -C BaseTools/
  build -b DEBUG -t GCC5 -a X64 -p OvmfPkg/OvmfPkgX64.dsc -D NETWORK_IP4_ENABLE -D NETWORK_ENABLE  -D SECURE_BOOT_ENABLE -DTPM2_ENABLE=TRUE
  cp Build/OvmfX64/DEBUG_GCC5/FV/OVMF.fd ../../../OVMF.fd
  cd -
}

function civ_build() {
  ( mkdir -p $builddir/civ )
  wget https://github.com/projectceladon/celadon-binary/raw/master/CIV_00.20.02.24_A10/caas-ota-QMm000000.zip -P $builddir/civ
  wget https://github.com/projectceladon/celadon-binary/raw/master/CIV_00.20.02.24_A10/caas-releasefiles-userdebug.tar.gz -P $builddir/civ

  cd $builddir/civ
  tar -xvf caas-releasefiles-userdebug.tar.gz

}
