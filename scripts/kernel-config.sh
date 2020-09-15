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
# Set "on" once default found in kernel_repo
#==========================================
function set_default_url() {
  #default_repo=$(grep repo $default_config)

  for (( i=0; i<${#kernel_repo[@]}; i=i+4 )); do
    [[ ${kernel_repo[$((i+1))]} == $repo ]] && \
          kernel_repo[$((i+2))]="on" 
  done
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

  #================================================================
  # CCG build needs patches, find patches from current directory
  if [[ $option == "CCG-repo" ]]; then
    # get list of patch files
    idx=0
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
    [[ -z $option_patch ]] && patches="" || patches=${list[$((option_patch*3+1))]}

    if grep -qF "patches=" $idv_config_file; then
      sed -i "s/^patches=.*$/patches=$patches/" $idv_config_file
    else
      echo "patches=" >> $idv_config_file
    fi
  fi
exit 0
  case $option in
    IOTG-repo)

  test=${test//\//\\/}

#      `sed -i "s/^.*repo=.*$/repo/" ./.idv-config` 
#      `sed -i "s/^.*repo=.*$/repo=https://github.com/intel/linux-intel-lts.git/" ./.idv-config` 
#      sed -i 's/^.*repo=.*$/repo=\"https://github.com/intel/linux-intel-lts.git\"/' ./.idv-config 
unset repo
      echo 'export repo="https://github.com/intel/linux-intel-lts.git"' >> ./temp
      echo 'export branch="lts-v5.4.57-yocto-200819T072823Z"' >> ./temp
      echo 'export patches=""' >> ./temp

      ;;
    CCG-repo)
      echo 'export repo="https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git"' >> ./temp
      echo 'export branch="v5.4.54"' >> ./temp
#    patches="idv3.0_er3_patchset_rbhe"

      # Handle patch file
      idx=0
      while IFS=$'\n' read -r line; do
        [[ $line == $patches ]] && list+=($idx "$line" on) || list+=($idx "$line" off)
        idx=$((idx+1))
      done < <(ls *.tar.gz | grep patch)

      option_patch=$(dialog --backtitle "Select patches file" \
            --radiolist "<patches file name>.tar.gz \n\
Will ask for <patch>.tar.gz file upon exit."  20 80 10 \
            "${list[@]}" \
            3>&1 1>&2 2>&3 )
        [[ -z $option_patch ]] && patches="" || patches=${list[$((option_patch*3+1))]}
      ;;
  esac

  echo "export patches=$patches" >> ./temp
  echo "$patches"
#  return 3 
}

rm ./temp; touch ./temp
set_default_url
patches=$(kernel_options)
source ./temp
echo "results: patches: '$result', $patches"
#exit 0
#kernel_config=(repo branch patches kdir krevision kversion)
#source $default_config
 

