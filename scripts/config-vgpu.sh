#!/bin/bash

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
#idv_config_file=./test
function update_idv_config_deleteme() {
  variable=$1
  string=$2

  (grep -qF "$variable=" $idv_config_file) \
      && sed -i "s/^$variable=.*$/$variable=${string//\//\\/}/" $idv_config_file \
      || echo "$variable=$string" >> $idv_config_file
}

function select_mdev_type_deleteme() {
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

default_guid=( f50aab10-7cc8-11e9-a94b-6b9d8245bfc1  f50aab10-7cc8-11e9-a94b-6b9d8245bfc2 f50aab10-7cc8-11e9-a94b-6b9d8245bfc3 f50aab10-7cc8-11e9-a94b-6b9d8245bfc4 )

function set_display_port_mask() {
  card0=( /sys/devices/pci0000\:00/0000\:00\:02.0/drm/card0/gvt_disp_ports_status )
  available_ports=$(grep "Available display ports" $card0)
  ports="${available_ports#*: }"

#  detected=0
  port_mask=""
  j=1
  for (( i=0; i<${#default_guid[@]}; i++)); do
    nibble=$((ports&0xf)); ports=$((ports>>4))

#    guid=$( grep "^VGPU$i=" $idv_config_file )
#    [[ ! -z ${guid##*=} ]] && continue && echo "same guil"

    if [[ $nibble -ne "0" ]]; then
      string="`grep -A $j "Available" $card0`"  # ( PORT_B(2) )
      temp=$(sed 's/.*( \(.*\) )/\1/' <<< "${string##*$'\n'}")

      gfx_port+=( "${temp%(*}" )
      port_num=$(sed 's/.*(\(.*\))/\1/' <<< "${temp}")
      port_mask="0$((1<<(port_num-1)))"$port_mask

      # if UUID already *not" exists then update
      guid=$( grep "^VGPU$i=" $idv_config_file )
#      [[ -z ${guid##*=} ]] && update_idv_config "VGPU$i" "$(uuid)"
      [[ -z ${guid##*=} ]] && update_idv_config "VGPU$i" "${default_guid[$i]}"
#      update_idv_config "VGPU$i" "$(uuid)"
#      detected=1
      j=$((j+1))
    fi
  done
  echo "gfx_port: ${gfx_port[@]}"
  update_idv_config "GFX_PORT" "\"${gfx_port[@]}\""
  update_idv_config "port_mask" "0x$port_mask"
}

set_display_port_mask
#select_mdev_type

