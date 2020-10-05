#!/bin/bash

source ./scripts/util.sh
run_as_root "systemctl enable $cdir/systemd/vgpu.service"

