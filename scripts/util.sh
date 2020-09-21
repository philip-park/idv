default_config=./scripts/idv-config-default
idv_config_file=./.idv-config
[[ -f "./.idv-config" ]] && default_config="./.idv-config" || touch ./.idv-config

function update_idv_config() {
  opt=("$@")
  string=${opt[@]:1}
  (grep -qF "${opt[0]}=" $idv_config_file) \
      && sed -i "s/^${opt[0]}=.*$/${opt[0]}=${string//\//\\/}/" $idv_config_file \
      || echo "${opt[0]}=${string[@]}" >> $idv_config_file
}

function update_idv_config_concatenate() {
  str=$(grep $1 $idv_config_file)
#  echo "str: $str"
  temp="${str%\"}"
  temp_file="_temp"
  touch $temp_file

  str="$temp $2\""
#  echo "final str: $str"
  grep -v "$1=" ${idv_config_file} >${temp_file}
  cp $temp_file $idv_config_file
  echo "$str" >> $idv_config_file
}


function run_as_root() {
  cmd=$1
  if [[ $EUID -eq 0 ]];then
    ($cmd)
  else
    sudo -s <<RUNASSUDO_PACKAGE
    ($cmd)
RUNASSUDO_PACKAGE
   fi
}


