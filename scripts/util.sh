
#================================================
# text attributes ####
#================================================
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
blue=`tput setaf 4`
magenta=`tput setaf 5`
cyan=`tput setaf 6`
white=`tput setaf 7`
blink=`tput blink`
NC=`tput sgr0`

#=================================
# global variable shared among scripts
#=================================
cdir=$(pwd)
version="0.8"

krevision="3.0"
kversion="intelgvt"

vmroot=/var
#vmroot=$cdir
vmdir="$vmroot/vm"
kdir="kernel"
builddir="$cdir/build"
patchdir="$cdir/build/patches"

QEMU_REL=qemu-4.2.0

#===============================================
# Fixed Kernel repo supported by IDV solution
#===============================================
kernel_repo+=("Vanilla" "https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git" off "v5.4.54")
kernel_repo+=("IOTG-repo-old" "https://github.com/intel/linux-intel-lts.git" off "lts-v5.4.57-yocto-200819T072823Z")
kernel_repo+=("IOTG-repo" "https://github.com/intel/linux-intel-lts.git" on "lts-v5.4.81-yocto-201210T224912Z")


default_config=./scripts/idv-config-default
idv_config_file="$cdir/.idv-config"
echo "idv_config_file: $idv_config_file"
[[ -f "$idv_config_file" ]] && default_config=$idv_config_file || touch $idv_config_file

function update_idv_config() {
  opt=("$@")
  string=${opt[@]:1}
  (grep -qF "${opt[0]}=" $idv_config_file) \
      && sed -i "s/^${opt[0]}=.*$/${opt[0]}=${string//\//\\/}/" $idv_config_file \
      || echo "${opt[0]}=${string[@]}" >> $idv_config_file
}

function run_as_root() {
  cmd=$1
echo "cmd: ($EUID) $cmd"
  if [[ $EUID -eq 0 ]];then
    ($cmd)
  else
    sudo -s -E <<EOF
    ($cmd)
EOF
   fi
}

function install_pkgs() {
  pkgs=$1

  for i in ${pkgs[@]}; do
    if ! dpkg -s $i >/dev/null 2>&1; then
      echo "installing_packages $i"
      run_as_root "apt-get install -y $i >/dev/null 2>&1"
#    else
#      echo "already installed: $i"
    fi
  done
}

function progressshow ()
{
  local flag=false c count cr=$'\r' nl=$'\n'
  while IFS='' read -d '' -rn 1 c
  do
    [[ $flag == "true" ]] && printf '%s' "$c" || \
        [[ $c != $cr && $c != $nl ]] && count=0 || ((count++)); [[ "$count" -gt 1 ]] && flag=true
  done
}
