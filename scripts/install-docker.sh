#!/bin/bash
echo "install-docker: cdir: $cdir, pwd: $(pwd)"
source ./scripts/util.sh

function install_docker() {
  if ! dpkg -s docker-ce >/dev/null 2>&1; then
    run_as_root "apt-get update"
    install_pkgs "apt-transport-https ca-certificates curl gnupg-agent software-properties-common"
    run_as_root "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -"
    run_as_root "apt-key fingerprint 0EBFCD88"
    run_as_root "add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\""
    run_as_root "apt-get update"
    run_as_root "apt-get install -y docker-ce docker-ce-cli containerd.io"
    run_as_root "setfacl -m user:$USER:rw /var/run/docker.sock"
    run_as_root "groupadd docker"
    run_as_root "usermod -aG docker $USER"
    run_as_root "gpasswd -a $USER docker"
  fi
}

function install_docker_deleteme() {
  if ! docker -v; then
    run_as_root "apt-get update"
    run_as_root "apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common"
    run_as_root "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -"
    run_as_root "apt-key fingerprint 0EBFCD88"
    run_as_root "add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\""
    run_as_root "apt-get update"
    run_as_root "apt-get install -y docker-ce docker-ce-cli containerd.io"
    run_as_root "setfacl -m user:$USER:rw /var/run/docker.sock"
    run_as_root "groupadd docker"
    run_as_root "usermod -aG docker $USER"
    run_as_root "gpasswd -a $USER docker"
  fi
}

function build_docker() {
  if [[ -z $(docker images -q mydocker/bob_the_builder 2> /dev/null) ]]; then
#    echo "in docker build cdir: $cdir, pwd: $(pwd)"
    cd ./docker; run_as_root "docker build . -t mydocker/bob_the_builder"
  fi
}
if ! dpkg -s "docker-ce" >/dev/null 2>&1; then
  install_docker
fi

build_docker
