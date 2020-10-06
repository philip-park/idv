#!/bin/bash

source ./scripts/util.sh

function enable_vgpu_create() {
run_as_root "cp $cdir/systemd/vgpu.service $vmdir/scripts"
run_as_root "systemctl enable $vmdir/scripts/vgpu.service"
}

TEMP_FILE=$cdir/temp_file
QEMU_SERVICE=$vmdir/scripts/qemu@.service

function qemu_start_deleteme() {
  unset str
  qemu_start_files=( $vmdir/scripts/start-guest-* )

  [[ ${#qemu_start_files[@]} -eq 0 ]] && echo "no startup file found" && exit 1

  str+=( "[Unit]" )
  str+=( "Description=Auto start QEMU virtual machine" )
  str+=( "After=vgpu.service" )
  str+=( "[Service]" )
  str+=( "Type=forking" )
#  str+=( "User=vmadmin" )
#  str+=( "Group=kvm" )
  str+=( "LimitMEMLOCK=infinity:infinity" )
  str+=( "PIDFile=/tmp/qemu_%i.pid" )
  str+=( "ExecStart=/bin/sh -c \"/var/vm/scripts/start-qemu.sh %i\"" )
  str+=( "ExecStop=/bin/sh -c \"/var/vm/scripts/start-qemu.sh %i\"" )
#  str+=( "TimeoutStopSec=30" )
#  str+=( "Restart=on-failure" )
#  str+=( "RestartSec=60s" )
  str+=( "[Install]" )
  str+=( "WantedBy=multi-user.target" )

  printf "%s\n"  "${str[@]}" > $TEMP_FILE
  run_as_root "cp $TEMP_FILE $QEMU_SERVICE"
  run_as_root "cp $QEMU_SERVICE /lib/systemd/system"

  for i in ${qemu_start_files[@]}; do
    temp="${i##*-}"
    vgpu="${temp%.*}"
    run_as_root "systemctl enable qemu@$vgpu.service"
  done

  $(rm $TEMP_FILE)
}

function qemu_starti_delete() {
  unset str
  qemu_start_files=( $vmdir/scripts/start-guest-* )

  str+=( "[Unit]" )
  str+=( "Description=QEMU virtual machine" )
  str+=( "After=vgpu.service network.target" )
  str+=( "" )
  str+=( "[Service]" )
  str+=( "Type=simple" )
  str+=( "Environment=\"type=system-x86_64\" \"haltcmd=kill -INT $MAINPID\"" )
#  str+=( "EnvironmentFile=/var/vm/%i" )
  str+=( "ExecStart=/var/vm/scripts/start-qemu.sh %i" )
  str+=( "ExecStop=/bin/sh -c ${haltcmd}" )
  str+=( "TimeoutStopSec=30" )
  str+=( "KillMode=none" )
  str+=( "" )
  str+=( "[Install]" )
  str+=( "WantedBy=multi-user.target" )
  printf "%s\n"  "${str[@]}" > $TEMP_FILE
  run_as_root "cp $TEMP_FILE $QEMU_SERVICE"
  run_as_root "cp $QEMU_SERVICE /lib/systemd/system"

  for i in ${qemu_start_files[@]}; do
    temp="${i##*-}"
    vgpu="${temp%.*}"
    run_as_root "systemctl enable qemu@$vgpu.service"
  done

  $(rm $TEMP_FILE)
}

function qemu_start() {
  unset str
  qemu_start_files=( $vmdir/scripts/start-guest-* )

  run_as_root "cp $cdir/systemd/start-qemu.sh $vmdir/scripts/"
  run_as_root "cp $cdir/systemd/qemu@.service /lib/systemd/system"

  for i in ${qemu_start_files[@]}; do
    temp="${i##*-}"
    vgpu="${temp%.*}"
    run_as_root "systemctl enable qemu@$vgpu.service"
  done
#  $(rm $TEMP_FILE)

}

enable_vgpu_create
qemu_start
