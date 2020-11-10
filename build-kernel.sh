#!/bin/bash

source ./scripts/util.sh

function install_kernel() {
  debs=$( ls -R $cdir/*.deb 2>/dev/null )
  echo "${yellow}$debs${NC}"

  [[ -z "$debs" ]] && echo -e "${red}✖${NC} Can't find *.deb file" && exit 1

  source $cdir/scripts/config-modules.sh
  run_as_root "dpkg -i *.deb"
  source ./grub-setup.sh

  echo "reboot in 5 seconds. Control + C to abort.."
  sleep 5
  run_as_root "reboot" 
}

# check for install option.
[[ $1 == "install" ]] && install_kernel && exit 0

echo "idv config file: $idv_config_file"
source $idv_config_file

function build_kernel() {

  # if repo is not set, then run config-kernel to get option for kernel repo
  if [[ -z "$repo" || -z "$branch" ]]; then
    run_as_root "apt install dialog acl"
    source $cdir/scripts/config-kernel.sh
  fi

  # Install docker to host if not installed
  source $cdir/scripts/install-docker.sh

  # delete linux*.deb file before building new
  run_as_root "rm -rf linux*.deb"
  run_as_root "rm -rf $kdir"
 
  # run docker as user to build kernel
  run_as_root "docker run --rm -v $cdir:/build \
        -u $(id -u ${USER}):$(id -g ${USER}) \
       --name bob mydocker/bob_the_builder"
#       --name bob mydocker/bob_the_builder  bash -c \"cd /build/docker; ./build-docker.sh\""
}

function install_kernel() {
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

pmc=$(cat /sys/devices/cpu/caps/pmu_name)
[[ $pmc == "icelake" ]] && sriov_system || build_kernel

install_kernel


