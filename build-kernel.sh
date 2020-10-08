#!/bin/bash

source ./scripts/util.sh

echo "idv config file: $idv_config_file"
source $idv_config_file

# if repo is not set, then run config-kernel to get option for kernel repo
[[ -z $repo ]] && source $cdir/scripts/config-kernel-new.sh

# Install docker to host if not installed
source $cdir/scripts/install-docker.sh

# build kernel on docker
run_as_root "docker run --rm -v /home/snuc/idv:/build --name bob mydocker/bob_the_builder  bash -c \"cd build; ./build-docker.sh\""


