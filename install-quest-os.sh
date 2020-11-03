#!/bin/bash

source ./scripts/util.sh

[[ $# -eq 0 ]] && echo "Usage: $0 <vgpu1 | vgpu2 | vgpu3>" && exit

case $1 in
  vgpu1|vgpu2|vgpu3)
    # kill if qemu-system-x86_64 for $1 is already running
    pID=$(ps -ef | grep 'qemu-system-x86_64' | grep $1 | grep -v 'grep' | awk '{ printf $2 }' )
    run_as_root "kill $pID"
    run_as_root "/var/vm/scripts/install-guest-$1.sh";;
  *)
    echo "The parameter should be either vgpu1, vgpu2, or vgpu3";;
esac

