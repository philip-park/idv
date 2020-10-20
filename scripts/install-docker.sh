#!/bin/bash 

function install_docker() {
  if ! docker -v; then
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
  if [[ -z $(docker images -q mydocker/bob_the_builder 2> /dev/null) ]]; then
    cd ./docker; run_as_root "docker build . -t mydocker/bob_the_builder"
  fi
}

install_docker
build_docker

run_as_root "groupadd docker"
run_as_root "usermod -aG docker $USER"
newgrp docker

