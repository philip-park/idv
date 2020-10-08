#!/bin/bash

grubfile="/etc/default/grub"
tempfile="./temp"

function grub_setup() {
  opts=(i915.enable_gvt=1 kvm.ignore_msrs=1 intel_iommu=on,igfx_off drm.debug=0 consoleblank=0)

  cp -f $grubfile $tempfile

  cmdline="`grep -w "GRUB_CMDLINE_LINUX=" $tempfile`"
  cmdline=${cmdline##*GRUB_CMDLINE_LINUX=} # Capture strings after "GRUB_CMDLINE_LINUX="
  cmdline="${cmdline%\"}"   # Remove the suffix "

  grub_modified=0
  for i in "${opts[@]}"; do
    if !(grep -q $i <<< "$cmdline"); then
      grub_modified=1
      [[ $cmdline == "\"" ]] && cmdline="$cmdline$i" || cmdline="$cmdline $i"
    fi
  done

  if [[ $grub_modified -eq 1 ]]; then
    cmdline="GRUB_CMDLINE_LINUX=$cmdline\""
    sed -i "/.*GRUB_CMDLINE_LINUX=.*/c $cmdline" $tempfile
    run_as_root "cp -f $tempfile $grubfile"
    run_as_root "update-grub2"
  fi
  rm -f $tempfile
}

grub_setup
