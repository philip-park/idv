#!/bin/bash

source ./scripts/util.sh

CIV_WORK_DIR=$builddir/civ
install_dir=/var/vm/civ
CIV_INSTALL_FOLDER=/var/vm/civ
CIV_SHARE_FOLDER=/var/vm/civ/share_folder

install_pkgs "thermald mtools python3-usb python3-pyudev unzip ovmf pulseaudio jq"

function pull_scripts() {
  cd $builddir/civ

  wget https://github.com/projectceladon/celadon-binary/raw/master/CIV_00.20.02.24_A10/caas-ota-QMm000000.zip
  wget https://github.com/projectceladon/celadon-binary/raw/master/CIV_00.20.02.24_A10/caas-releasefiles-userdebug.tar.gz

  tar -xvf caas-releasefiles-userdebug.tar.gz
}


function save_deleteme() {
# Setup environment variable
s="export CIV_WORK_DIR"
if grep  -q "$s" /etc/environment; then
  sudo sed -i "/^$s.*/c $s=$(pwd)" /etc/environment
else
  grep -q "^$s" /etc/environment || (sudo echo "$s=$(pwd)" >> /etc/environment)
fi
CIV_WORK_DIR=$(pwd)
install_dir=/var/vm/civ
CIV_INSTALL_FOLDER=/var/vm/civ
CIV_SHARE_FOLDER=/var/vm/civ/share_folder

install_pkgs "wget mtools ovmf dmidecode python3-usb python3-pyudev pulseaudio jq"
}

function install_9p_module(){
	echo "installing 9p kernel modules for file-sharing"
	sudo modprobe 9pnet
	sudo modprobe 9pnet_virtio
	sudo modprobe 9p
	run_as_root "mkdir -p $CIV_SHARE_FOLDER"
}


function prepare_required_scripts(){
	run_as_root "mkdir -m a=rwx -p {$CIV_INSTALL_FOLDER/scripts,$CIV_INSTALL_FOLDER/sof_audio}"
	run_as_root "cp $CIV_WORK_DIR/scripts/* $CIV_INSTALL_FOLDER/scripts/"
#	run_as_root "chmod +x $CIV_INSTALL_FOLDER/scripts/*.sh"
	run_as_root "mv -t $CIV_INSTALL_FOLDER/sof_audio $CIV_WORK_DIR/scripts/sof_audio/configure_sof.sh $CIV_WORK_DIR/scripts/sof_audio/blacklist-dsp.conf"
	run_as_root "cp $CIV_WORK_DIR/scripts/guest_pm_control $CIV_INSTALL_FOLDER/scripts"
	run_as_root "cp $CIV_WORK_DIR/scripts/findall.py $CIV_INSTALL_FOLDER/scripts"
	run_as_root "cp $CIV_WORK_DIR/scripts/thermsys $CIV_INSTALL_FOLDER/scripts"
	run_as_root "cp $CIV_WORK_DIR/scripts/batsys $CIV_INSTALL_FOLDER/scripts"
	run_as_root "chmod +x $CIV_INSTALL_FOLDER/scripts/*.sh"
}

function save_env_deleteme(){
	if [ -z "$a" ]; then
		echo "export CIV_WORK_DIR=$(pwd)" | tee -a /etc/environment
	else
		sed -i "s|export CIV_WORK_DIR.*||g" /etc/environment
		echo "export CIV_WORK_DIR=$(pwd)" | tee -a /etc/environment
	fi
}

function ubu_thermal_conf (){

	systemctl stop thermald.service
	run_as_root "cp $CIV_INSTALL_FOLDER/scripts/intel-thermal-conf.xml /etc/thermald"
	run_as_root "cp $CIV_INSTALL_FOLDER/scripts/thermald.service  /lib/systemd/system"
	run_as_root "systemctl daemon-reload"
  run_as_root "systemctl start thermald.service"
}


	
function prep_civ() {
#if [[ $version =~ "Ubuntu" ]]; then
####	check_network
####	ubu_changes_require
####	save_env
####	check_kernel
	#Auto start service for audio will be enabled in future
	#install_auto_start_service
####	ubu_install_qemu
####	ubu_build_ovmf
####	ubu_enable_host
	if [[ $1 == "--gvtd" ]]; then
		systemctl set-default multi-user.target
	fi
	if [[ ! -d $CIV_WORK_DIR/sof_audio ]]; then
		reboot_required=1
	fi
	prepare_required_scripts
	
	
	$CIV_INSTALL_FOLDER/sof_audio/configure_sof.sh "install" $CIV_INSTALL_FOLDER
	$CIV_INSTALL_FOLDER/scripts/setup_audio_host.sh
	#starting Intel Thermal Deamon, currently supporting CML/EHL only.
	ubu_thermal_conf
	install_9p_module
exit
	ask_reboot

}

# Flash qcow2 file
function build_android_qcow() {
  cd $builddir/civ
  sudo ./scripts/start_flash_usb.sh caas-flashfiles-QMm000000.zip --display-off
}

# Start CIV
function start_android() {
  cd $builddir/civ
  sudo -E ./scripts/start_android_qcow2.sh --display-off
}

#pull_scripts
#prep_civ
#build_android_qcow
start_android

