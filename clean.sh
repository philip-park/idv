#!/bin/bash

source scripts/util.sh
source $idv_config_file


function clean() {
  run_as_root "apt purge -y docker-ce docker-ce-cli containerd.io"
  run_as_root "apt purge -y dialog"
  run_as_root "apt purge -y acl"
  run_as_root "apt purge -y uuid"
  run_as_root "apt purge -y qemu-system-x86"

  docker_image_id=$(docker images -q mydocker/bob_the_builder)
  run_as_root "sudo docker rmi $docker_image_id"

  run_as_root "find /var -type d -name \"vm\" -exec sudo rm -rf {} +"
  run_as_root "find . -type d -name $kdir -exec rm -rf {} +"
  find . -type d -name "${patches%.tar.gz}" -exec rm -rf {} +
#  find . -type f -name "*.deb" -exec rm -rf {} +
  echo   "deb: $cdir/*.deb"
  run_as_root "apt autoremove"
}

clean



