#!/bin/bash

source ./scripts/util.sh
run_as_root "apt install dialog"

echo "idv config file: $idv_config_file"
source $idv_config_file

# if repo is not set, then run config-kernel to get option for kernel repo
[[ -z $repo || -z $branch ]] && source $cdir/scripts/config-kernel-new.sh

# Install docker to host if not installed
source $cdir/scripts/install-docker.sh

# run docker as user to build kernel
run_as_root "docker run --rm -v /home/snuc/idv:/build \
        -u $(id -u ${USER}):$(id -g ${USER}) \
       --name bob mydocker/bob_the_builder  bash -c \"cd /build/docker; ./build-docker.sh\""

# update grub and modules file
source $cdir/scripts/config-grub.sh
source $cdir/scripts/config-modules.sh

ls *.deb

read -r -p "\n ${green}✔${NC} Want to install the kernel and reboot? [y/N] " answer
case "$answer" in
  [yY]) run_as_root "dpkg -i *.deb"
        echo "reboot in 5 seconds"
        sleep 5
        run_as_root "reboot" ;;
  *) echo "you can install kernel using ${yellow}sudo dpkg -i *.deb${NC}";;
esac

