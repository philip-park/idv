#!/bin/bash

source ./scripts/util.sh

unset expected
expected+=( "5.4.54-intelgvt+" )

#-----------------------------------------------
# return 0 if kernel install success
# return 1 if kernel installation not found
#-----------------------------------------------
function install_kernel() {
  debs=$( ls -R $cdir/build/*.deb 2>/dev/null )
  echo "${yellow}$debs${NC}"

  [[ -z "$debs" ]] && echo -e "${red}✖${NC} Can't find *.deb file" && return 1

  return 0

#  source $cdir/scripts/config-modules.sh
  run_as_root "dpkg -i build/*.deb"
  source ./grub-setup.sh

  return 0


  echo "reboot in 5 seconds. Control + C to abort.."
  sleep 5
  run_as_root "reboot"
}

#-----------------------------------------------
# return 0 if IDV kernel is already installed
# return 1 if IDV kernel is not installed
#-----------------------------------------------
function check_booted_kernel() {
  booted=$(uname -r)
  echo "booted kernel: $booted"

  found=0
  for i in ${expected[@]}; do
    if [[ $booted == $i ]]; then
      found=1
      break
    fi
  done
  return $found
}

function check_idv_kernel_installed() {
  unset kernel_list
  index=0
  debs=($( ls -R $cdir/build/*.deb 2>/dev/null | grep $kversion ))
  for i in ${debs[@]}; do
    if [[ "$i" == *"$kversion"* && "$i" == *"$krevision"* ]]; then
      echo "debs: ${i##*+_$krevision-}"
      temp=${i##*+_$krevision.}
      temp=${temp%%_*}
      [[ "$index" -le "$temp" ]] && index=$temp
      echo "index: $index"
    fi
    
  done
  ((index=index+1))
  echo "final index: $index"

  return $index
}

function is_kernel_already_installed() {
  
#  kernel_list=($(dpkg --list | egrep -i --color 'linux-image|linux-headers'))
  kernel_list=($(dpkg --list | egrep -i 'linux-image|linux-headers' | awk '/ii/{ print $2}' | grep $kversion))
  for i in ${kernel_list[@]}; do
    echo "kernel_list: $i"
    check_booted_kernel
    [[ $? -ne 0 ]] && echo "${red}Kernel already installed. Please remove the installed IDV kernel and reinstall${NC}"
  done

  return ${#kernel_list[@]}
}

function install_kernel() {
  unset kernel_debs
  kernel_debs=($( ls -R $cdir/build/*.deb 2>/dev/null | grep $kversion | grep image ))

  [[ ${#kernel_debs[@]} -eq "0" ]] && dialog --msgbox "Can't fine the kernel/s in $cdir/build directory. \
            Please run build-kernel.sh.\n\n" 10 40 && exit 1
  j=0
  for i in ${kernel_debs[@]}; do
#      temp=${i##*+_$krevision.}
#      temp=${temp%%_*}
    list+=( $j "$i" off )
    ((j=j+1))
  done

  option=$(dialog --backtitle "Select Kernel to install" \
            --radiolist "Select kernel to install. The matching header file will be installed when available."  20 80 10 \
            "${list[@]}" \
            3>&1 1>&2 2>&3 )
  [[ "$?" -ne 0 ]] && exit 0 

  echo "option: $option, selection $?"
  deb=${kernel_debs[$option]}
  header=${deb/image/headers}
  echo "installing .."
  echo "kernel = $deb"
  echo "header=$header"
  run_as_root "dpkg -i $deb $header"
}

#check_idv_kernel_installed
#echo "count: $?"

install_kernel



