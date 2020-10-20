#!/bin/bash

source ./scripts/util.sh

function install_kernel() {
  debs=$( ls $cdir/*.deb )
  echo "${yellow}$debs${NC}"

  [[ -z "$debs" ]] && echo -e "${red}✖${NC} Can't find *.deb file" && exit 1

  run_as_root "dpkg -i *.deb"

  echo "reboot in 5 seconds. Control + C to abort.."
  sleep 5
  run_as_root "reboot" 
}

# check for install option.
[[ $1 == "install" ]] && install_kernel && exit 0

run_as_root "apt install dialog"
run_as_root "apt install acl"

echo "idv config file: $idv_config_file"
source $idv_config_file

source $cdir/scripts/config-grub.sh
source $cdir/scripts/config-modules.sh

# if repo is not set, then run config-kernel to get option for kernel repo
[[ -z $repo || -z $branch ]] && source $cdir/scripts/config-kernel-new.sh

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

debs=$( ls $cdir/*.deb )
echo "${yellow}$debs${NC}"

[[ -z "$debs" ]] && echo -e "${red}✖${NC} Oops.. kernel build error" && exit 1

read -r -p "\n ${green}✔${NC} Want to install the kernel and reboot? [y/N] " answer
case "$answer" in
  [yY]) install_kernel;;
  *) echo "you can install kernel using ${yellow}$0 install${NC}";;
esac

