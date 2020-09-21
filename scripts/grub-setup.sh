#!/bin/bash
grub_file="./grub"
function grub_setup() {
opts=(i915.enable_gvt=1 kvm.ignore_msrs=1 intel_iommu=on,igfx_off drm.debug=0 consoleblank=0)

cmd_line="`grep -w "GRUB_CMDLINE_LINUX" $grub_file`"
cmd_line=${cmd_line#*'"'}; cmd_line=${cmd_line%'"'*}

replace=false
for i in "${opts[@]}"
  do
    lst="`grep -w "GRUB_CMDLINE_LINUX" $grub_file | grep -w $i`"
    if [ -z "$lst" ];then
      cmd_line="$cmd_line $i"
      replace=true
    fi
done

if [ "$replace" = true ];
then
  cmd_line="GRUB_CMDLINE_LINUX=\"$cmd_line\""
  sed -i "/.*GRUB_CMDLINE_LINUX=.*/c $cmd_line" $grub_file
#  sudo update-grub2
fi
}
