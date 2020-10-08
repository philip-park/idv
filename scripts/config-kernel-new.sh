#!/bin/bash

default_config=./scripts/idv-config-default
idv_config_file=./.idv-config
[[ -f "./.idv-config" ]] && default_config="./.idv-config" || touch ./.idv-config

source $idv_config_file

#==========================================
# Set default kernel repo 
#==========================================
function set_default_url() {
  for (( i=0; i<${#kernel_repo[@]}; i=i+4 )); do
    [[ ${kernel_repo[$((i+1))]} == $repo ]] && \
          kernel_repo[$((i+2))]="on" 
  done
}

#================================================================
# Vanilla build needs patches, find patches from current directory
# case 1) $patch_file=0 and $patches=0 ====> use No Patches
# case 2) $patch file=1 and $patches=0 ====> use $patch_file
# case 3) $patch_file=1 and $patches=1 ====> use matching pair, no match, then No Patches
#================================================================
function get_patch_file() {
#---------------------------------
  # build the options for dialogget list of patch files in currect directory
#-------------------------------

  files=( *.tar.gz )

  local -a list=()
  # case 1, no patch found
  [[ $patch_file == '*.tar.gz' ]] && list+=(0 "No Patches" on) || list+=(0 "No Patches" off)
  idx=1
  for patch_file in "${files[@]}"; do
    echo "loop: $patch_file"
    # case 2, only one patch file found
    [[ ${#files[@]} -eq 1 ]] && list+=($idx "$patch_file" on) && break 
    # case 3, file name matches existing setting in $patches
    [[ $patch_file == $patches ]] && list+=($idx "$patch_file" on) || list+=($idx "$patch_file" off)
    idx=$((idx+1))
  done
#-------------------------------
  # display the option to user
  option_patch=$(dialog --backtitle "Select patches file" \
            --radiolist "<patches file name>.tar.gz \n\
Will ask for <patch>.tar.gz file upon exit."  20 80 10 \
            "${list[@]}" \
            3>&1 1>&2 2>&3 )
  [[ -z $option_patch || $option_patch -eq "0" ]] && patches="" || patches=${list[$((option_patch*3+1))]}

  (grep -qF "patches=" $idv_config_file) \
    && sed -i "s/^patches=.*$/patches=$patches/" $idv_config_file \
    ||    echo "patches=$patches" >> $idv_config_file
}

#================================================================
# Pickup the user selection of kernel repo
#================================================================
function kernel_options() {

  set_default_url
#  unset option
  option=$( dialog --item-help --backtitle "Kernel URL selection" \
    --radiolist "Kernel can be pulled from two different sources, IOTG and Vanilla repo\n\
*IOTG repo: IOTG kernel development team maintains kernel with IDV patches\n\
  where separate patches is not needed. Warning: the patches update to IDV\n\
  maintained kernel might be delayed due to extensive testing\n\
*Vanilla repo: Vanilla repo doesn't include the IDV patches needed for GVTg\n\
  Without the patches, GVTg will not work. \n\
  Will ask for <patch>.tar.gz file upon exit."  20 80 10 \
"${kernel_repo[@]}" \
    3>&1 1>&2 2>&3 )

  # Replace or add with updated repo and branch information
  for (( i=0; i<${#kernel_repo[@]}; i += 4 )); do
    if [[ $option == ${kernel_repo[$i]} ]]; then
      if grep -qF "repo=" $idv_config_file; then
        sed -i "s/^repo=.*$/repo=${kernel_repo[$((i+1))]//\//\\/}/" $idv_config_file
      else
        echo "repo=${kernel_repo[$((i+1))]}" >> $idv_config_file
      fi
      if grep -qF "branch=" $idv_config_file; then
        sed -i "s/^branch=.*$/branch=${kernel_repo[$((i+3))]//\//\\/}/" $idv_config_file
      else
        echo "branch=${kernel_repo[$((i+3))]}" >> $idv_config_file
      fi
    fi
  done

  echo "$option"
}

#set_default_url

kernel_source="$(kernel_options)"

# IOTG build shouldn't need patch
if [[ $kernel_source == "Vanilla" ]]; then
  get_patch_file
else
  (grep -qF "patches=" $idv_config_file) \
      && sed -i "s/^patches=.*$/patches=/" $idv_config_file \
      || echo "patches=" >> $idv_config_file
fi

#==============================================
# Source the latest configuration
#==============================================
source $idv_config_file

echo "results: patches: '$result', $patches"
 

