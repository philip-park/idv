#!/bin/bash

kernel_repo+=("CCG-repo" "https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git" off \
              "v5.4.54")
kernel_repo+=("IOTG-repo" "https://github.com/intel/linux-intel-lts.git" off \
              "lts-v5.4.57-yocto-200819T072823Z")

default_config=./scripts/idv-config-default
idv_config_file=./.idv-config
[[ -f "./.idv-config" ]] && default_config="./.idv-config" 
source $default_config

#==========================================
# Set default kernel repo 
#==========================================
function set_default_url() {
  #default_repo=$(grep repo $default_config)

  for (( i=0; i<${#kernel_repo[@]}; i=i+4 )); do
    [[ ${kernel_repo[$((i+1))]} == $repo ]] && \
          kernel_repo[$((i+2))]="on" 
  done
}

#================================================================
# CCG build needs patches, find patches from current directory
#================================================================
function get_patch_file() {
  echo "parameter: ($#), [patches: $patches]"
#  [[ $# -eq 1 ]] && option=$1 || exit 1

  # build the options for dialogget list of patch files in currect directory
  list+=(0 "No Patches" on)
  idx=1
  while IFS=$'\n' read -r line; do
    [[ $line == $patches ]] && list+=($idx "$line" on) || list+=($idx "$line" off)
    idx=$((idx+1))
  done < <(ls *.tar.gz | grep patch)

  # display the option to user
  option_patch=$(dialog --backtitle "Select patches file" \
            --radiolist "<patches file name>.tar.gz \n\
Will ask for <patch>.tar.gz file upon exit."  20 80 10 \
            "${list[@]}" \
            3>&1 1>&2 2>&3 )
  [[ -z $option_patch || $option_patch -eq "0" ]] && patches="" || patches=${list[$((option_patch*3+1))]}

  if grep -qF "patches=" $idv_config_file; then
    sed -i "s/^patches=.*$/patches=$patches/" $idv_config_file
  else
    echo "patches=" >> $idv_config_file
  fi
}

function kernel_options() {

  option=$( dialog --item-help --backtitle "Kernel URL selection" \
    --radiolist "Kernel can be pulled from two different sources, IOTG and CCG repo\n\
*IOTG repo: IOTG kernel development team maintains kernel with IDV patches\n\
  where separate patches is not needed. Warning: the patches update to IDV\n\
  maintained kernel might be delayed due to extensive testing\n\
*CCG repo: CCG repo doesn't include the IDV patches needed for GVTg\n\
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
}

rm ./temp; touch ./temp
set_default_url
kernel_options
get_patch_file
source ./temp
echo "results: patches: '$result', $patches"
#exit 0
#kernel_config=(repo branch patches kdir krevision kversion)
#source $default_config
 

