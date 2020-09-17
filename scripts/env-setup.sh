#!/bin/bash
opts=(i915.enable_gvt=1 kvm.ignore_msrs=1 intel_iommu=on,igfx_off drm.debug=0 consoleblank=0)

cmd_line="`grep -w "GRUB_CMDLINE_LINUX" /etc/default/grub`"
cmd_line=${cmd_line#*'"'}; cmd_line=${cmd_line%'"'*}

replace=false
for i in "${opts[@]}"
  do
    lst="`grep -w "GRUB_CMDLINE_LINUX" ./grub | grep -w $i`"
    if [ -z "$lst" ];then
      cmd_line="$cmd_line $i"
      replace=true
    fi
done

if [ "$replace" = true ];
then
cmd_line="GRUB_CMDLINE_LINUX=\"$cmd_line\""
sed -i "/.*GRUB_CMDLINE_LINUX=.*/c $cmd_line" /etc/default/grub
sudo update-grub2
fi
exit 0


# Install qemu
sudo apt install qemu-system-x86
cp /usr/share/qemu/bios.bin ~/vm/fw
cp /usr/share/qemu/OVMF.fd ~/vm/fw

