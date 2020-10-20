#!/bin/bash

source ./scripts/util.sh

[[ "$1" == "clean" ]] && clean && exit 0


#source $cdir/systemd/setup-vgpu-systemd.sh
source $cdir/systemd/config-systemd.sh
