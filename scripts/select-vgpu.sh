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
# select_mdev node
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
idv_config_file=./test
function update_idv_config() {
  variable=$1
  string=$2

  (grep -qF "$variable=" $idv_config_file) \
      && sed -i "s/^$variable=.*$/$variable=${string//\//\\/}/" $idv_config_file \
      || echo "$variable=$string" >> $idv_config_file
}

function select_mdev_type() {
  mdev_type=( /sys/bus/pci/devices/0000:00:02.0/mdev_supported_types/i915-GVTg_V5_* )
  # This actually the total number of available node and set to default node
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
            --radiolist "<patches file name>.tar.gz \n\
Select the mdev type from the following list found in ~/mdev_supported_types."  20 80 10 \
            "${list[@]}" \
            3>&1 1>&2 2>&3 )

  update_idv_config "mdev_type" "$mdev_type_option"
}

function set_display_port_mask() {
  card0=( /sys/devices/pci0000\:00/0000\:00\:02.0/drm/card0/gvt_disp_ports_status )
  available_ports=$(grep "Available display ports" $card0)
  ports="${available_ports#*: }"

  detected=0
#  list=""
  port_mask=""
  for (( i=0; i<8; i++)); do
    nibble=$((ports&0xf)); ports=$((ports>>4))

    if [[ $nibble -ne "0" ]]; then
      string="`grep -A $i "Available" $card0`"  # ( PORT_B(2) )
      temp=$(sed 's/.*( \(.*\) )/\1/' <<< "${string##*$'\n'}")
      port_num=$(sed 's/.*(\(.*\))/\1/' <<< "${temp}")
#      list="$test $list, ($port_num)"
      port_mask="0$((1<<(port_num-1)))"$port_mask
      detected=1
    fi
  done
  port_mask=0x$port_mask
  #printf "\x$(printf %08x  $port_mask)"

  update_idv_config "port_mask" "$port_mask"
}

set_display_port_mask
exit 0
select_mdev_type
exit 0

mdev_type=$(select_mdev)
node=($(ls /sys/bus/pci/devices/0000:00:02.0/mdev_supported_types/))
echo "mdev-typs selected: ${green}${node[$((mdev_type-1))]}${NC}"
echo "--mdev_type: $mdev_type"

#get_display_port_mask
exit 0

mask=$(get_display_port_mask)
echo "port_mask: $mask"
exit 0



get_display_port
exit 0

select_mdev
exit 0




