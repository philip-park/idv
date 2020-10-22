#!/bin/bash

source ./scripts/util.sh

[[ $# -eq 0 ]] && echo "Usage: $0 <vgpu1 | vgpu2 | vgpu3>" && exit

#create_vgpu_file=/var/vm/scripts/create-vgpu.sh
#create_vgpu_guid=$( grep "^${1^^}=" $create_vgpu_file )
#vgpu_guid=$( grep "^${1^^}=" $idv_config_file )
#echo "vgpu_guid: ${vgpu_guid##*=}"
#temp=${vgpu_guid##*=}
#echo "temp: $temp"

#temp=$( grep "^${1^^}=" $idv_config_file )
#vgpu_guid=${temp##*=}
#[[ -z $vgpu_guid ]] && echo "empty" || echo "not empty"

#exit

case $1 in
  vgpu1|vgpu2|vgpu3)
    
    temp=$( grep "^${1^^}=" $idv_config_file )
    vgpu_guid=${temp##*=}
    [[ -z $vgpu_guid ]] && echo "Install GVTg kernel/boot to kernel, and run config.sh" && exit 1

    [[ ! -d /sys/bus/pci/devices/0000:00:02.0/$vgpu_guid ]] && run_as_boot "/var/vm/scripts/create-vgpu.sh"
    run_as_root "/var/vm/scripts/start-guest-$1.sh";;
  *)
    echo "The parameter should be either vgpu1, vgpu2, or vgpu3";;
esac

