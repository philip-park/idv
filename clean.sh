#!/bin/bash

source scripts/util.sh
source $idv_config_file


function clean() {
  sudo apt purge -y dialog
  sudo apt purge -y acl
  sudo apt purge -y docker-ce docker-ce-cli containerd.io

  docker_image_id=$(docker images -q mydocker/bob_the_builder)
  sudo docker rmi $docker_image_id

  run_as_root "find /var -type d -name \"vm\" -exec sudo rm -rf {} +"
  run_as_root "find . -type d -name $kdir -exec rm -rf {} +"
  find . -type d -name "${patches%.tar.gz}" -exec rm -rf {} +
#  find . -type f -name "*.deb" -exec rm -rf {} +
  echo   "deb: $cdir/*.deb"
}

clean



