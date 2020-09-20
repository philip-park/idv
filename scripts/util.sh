default_config=./scripts/idv-config-default
idv_config_file=./.idv-config
[[ -f "./.idv-config" ]] && default_config="./.idv-config" || touch ./.idv-config

#idv_config_file=./test
function update_idv_config() {
  variable=$1
  string=$2

  (grep -qF "$variable=" $idv_config_file) \
      && sed -i "s/^$variable=.*$/$variable=${string//\//\\/}/" $idv_config_file \
      || echo "$variable=$string" >> $idv_config_file
}

function run_as_root() {
  cmd=$1
  if [[ $EUID -eq 0 ]];then
    ($cmd)
  else
    sudo -s <<RUNASSUDO_PACKAGE
    ($cmd)
   fi
}


