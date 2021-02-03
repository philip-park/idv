#!/bin/bash

red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
blue=`tput setaf 4`
magenta=`tput setaf 5`
cyan=`tput setaf 6`
white=`tput setaf 7`
blink=`tput blink`
NC=`tput sgr0`

#===========================================
# select_mdev type
# locate and list the node for user to select.
# The default will be display in Green color
# i915-GVTg_V5_1 (1920x1200)
# i915-GVTg_V5_2 (1920x1200)
# i915-GVTg_V5_4 (1920x1200)  <-- default
# i915-GVTg_V5_8 (1024x768)
#
# Require:
# scripts/custom-function for selectWithDefault
#===========================================
function select_mdev_type() {
  unset list
#  local declare -a list=()
#echo "mdev entgered"
  mdev_type=($( ls /sys/bus/pci/devices/0000:00:02.0/mdev_supported_types/ 2>/dev/null ))
  # This actually the total number of available node and set to default node

  [[ -z $mdev_type ]] && \
    dialog --msgbox "Can't find mdev supported type /sys/bus/pci/devices/0000:00:02.0/mdev_supported_types. Please check installation of kernel and grub setting. \n\n" 10 40 && exit 1

  current_option=${#mdev_type[@]}

  # set to default option
  [[ "$current_option" > 2 ]] && current_option=2

  for (( i=0; i<${#mdev_type[@]}; i++ )); do
    resolution="`grep resolution ${mdev_type[$i]}/description`"
    [[ $current_option -eq "$i" ]] \
        && list+=(${mdev_type[$i]##*/} "(${resolution##* })" on "${mdev_type[$i]}") \
        || list+=(${mdev_type[$i]##*/} "(${resolution##* })" off "${mdev_type[$i]}")
  done

  mdev_type_option=$(dialog --item-help --backtitle "Select patches file" \
            --radiolist "Select mdev type to use. Once set it will be used for all guestg OS \n\
Select the mdev type from the following list found in ~/mdev_supported_types."  20 80 10 \
            "${list[@]}" \
            3>&1 1>&2 2>&3 )
  echo "return: $?, mdev_type_option: $mdev_type_option"
  update_idv_config "mdev_type" "$mdev_type_option"
}

#set_display_port_mask
select_mdev_type

