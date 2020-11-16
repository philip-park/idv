#!/bin/bash

source ./idv-common

default_config=./scripts/idv-config-default
idv_config_file=./.idv-config
[[ -f "./.idv-config" ]] && default_config="./.idv-config" || touch ./.idv-config

source $idv_config_file
retStatus=""

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
#================================================================
function get_patch_file() {
#---------------------------------
  # build the options for dialogget list of patch files in currect directory
#-------------------------------

  files=($( ls $patchdir/*.tar.gz 2> /dev/null ))

  local -a list=()
  # Give option to select no patches
#  list+=(0 "No Patches" on) || list+=(0 "No Patches" off)
  idx=0
  for patch_file in "${files[@]}"; do
    echo "loop: $patch_file"
    list+=($idx "${files[$idx]}" off)

    # case 2, only one patch file found
#    [[ ${#files[@]} -eq 1 ]] && list+=($idx "$patch_file" on) && break 
    # case 3, file name matches existing setting in $patches
#    [[ $patch_file == $patches ]] && list+=($idx "$patch_file" on) || list+=($idx "$patch_file" off)
    idx=$((idx+1))
  done
echo "get_patch_file"
#-------------------------------
  # display the option to user
  option_patch=$(dialog --backtitle "Select patches file" \
            --radiolist "<patches file name>.tar.gz \n\
Will ask for <patch>.tar.gz file upon exit."  20 80 10 \
            "${list[@]}" \
            3>&1 1>&2 2>&3 )

  [[ $? -ne 0 ]] && retStatus="Cancel" && return
  [[ -z $option_patch ]] && patches="" || patches=${list[$((option_patch*3+1))]}

#  echo "results from patch file: $?"
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

  [[ $? -ne 0  ]] && echo "Cancel" && return

  # Replace or add with updated repo and branch information
  for (( i=0; i<${#kernel_repo[@]}; i += 4 )); do
    if [[ $option == ${kernel_repo[$i]} ]]; then
      if grep -qF "repo=" $idv_config_file; then
        sed -i "s/^repo=.*$/repo=${kernel_repo[$((i+1))]//\//\\/}/" $idv_config_file
      else
        echo "repo=${kernel_repo[$((i+1))]}" >> $idv_config_file
      fi

#      echo "kernle source: ${kernel_repo[$i]}"
      if grep -qF "branch=" $idv_config_file; then
        sed -i "s/^branch=.*$/branch=${kernel_repo[$((i+3))]//\//\\/}/" $idv_config_file
      else
        echo "branch=${kernel_repo[$((i+3))]}" >> $idv_config_file
      fi
    fi
  done

  echo "$option"
}

kernel_source="$(kernel_options)"

# IOTG build shouldn't need patch
case $kernel_source in
  Vanilla) unset retStatus; get_patch_file; echo "local retvbal : $retStatus"; 
    [[ $retStatus == "Cancel" ]] && exit 1
    ;;
  IOTG-repo)
    echo "kernel source: $kernel_source"
      (grep -qF "patches=" $idv_config_file) \
        && sed -i "s/^patches=.*$/patches=/" $idv_config_file \
        || echo "patches=" >> $idv_config_file;;
  Cancel)
    exit 1
    ;;
esac


#==============================================
# Source the latest configuration
#==============================================
source $idv_config_file

#echo "results: patches: '$result', $patches, option: $kernel_source"
 

