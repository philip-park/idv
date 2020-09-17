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

function select_mdev() {
  node=($(ls /sys/bus/pci/devices/0000:00:02.0/mdev_supported_types/))
  # This actually the total number of available node and set to default node
  current_option=${#res[@]}

  # set to default option
  [ "$current_option" > 2 ] && current_option=2

  for i in ${!node[@]}; do
    res="`grep resolution /sys/bus/pci/devices/0000:00:02.0/mdev_supported_types/${node[$i]}/description`"
    if [ "$current_option" -eq "$i" ]; then
      opts[$i]="${green}${node[$i]} (${res#* })${NC}"
    else
      opts[$i]="${node[$i]} (${res#* })"
    fi
  done

  source scripts/custom-function
  choice=$(selectWithDefault "${opts[@]}")
  [ -z "${choice}" ] && choice=$((current_option+1))

  echo "$choice"
}


card0="/sys/devices/pci0000:00/0000:00:02.0/drm/card0"
function get_display_port_mask() {
  port_mask=0
  status="`grep "Available display ports" $card0/gvt_disp_ports_status`"

  opts="${status#*: }"

  # Detect ports
  detected=0
  for (( i=0; i<8; i++)); do
    test=$((opts&0xf))
    opts=$((opts>>4))
    if [ "$test" -ne "0" ]; then
      string="`grep -A $i "Available" /sys/devices/pci0000:00/0000:00:02.0/drm/card0/gvt_disp_ports_status`"
      string="`grep -oP '(?<= )\w+' <<< "${string##*$'\n'}"`"
      detected=1
    fi
  done

  # creat port mask for gvt_disp_ports_mask
  if [ "$detected" ]; then
    val=()
    read -p "Enter mask (e.g. 42, 34, 432): " mask && [[ -z "$mask" ]] && mask=00000002
    if [ "$mask" -ne "0" ]; then
      for (( i=0; i<${#mask}; i++)); do
        port=$((16#${mask:(${#mask}-1-$i):1}))
        case $port in
          0) break;;
          1) val[$i]=01;;
          2) val[$i]=02;;
          3) val[$i]=04;;
          4) val[$i]=08;;
          *) break;;
        esac

      done
    fi
    port_mask="${val[2]}${val[1]}${val[0]}"
  fi
  echo "$port_mask"
}

mask=$(get_display_port_mask)
echo "port_mask: $mask"
exit 0


mdev_type=$(select_mdev)
node=($(ls /sys/bus/pci/devices/0000:00:02.0/mdev_supported_types/))
echo "mdev-typs selected: ${green}${node[$((mdev_type-1))]}${NC}"
echo "--mdev_type: $mdev_type"

#get_display_port_mask
exit 0




get_display_port
exit 0

select_mdev
exit 0




