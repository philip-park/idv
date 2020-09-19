#!/bin/bash


vm_dir=/var/vm

(mkdir -p {$vm_dir,$vm_dir/fw,$vm_dir/disk,$vm_dir/iso,$vm_dir/scripts})
#[[ ! -d $vm_dir ]] && sudo mkdir $vm_dir


# Install qemu
sudo apt install qemu-system-x86
sudo cp /usr/share/qemu/bios.bin $vm_dir/fw
sudo cp /usr/share/qemu/OVMF.fd $vm_dir/fw


cat <<EOF > /var/vm/install-guest.sh
#!/bin/bash

EOF


