#!/bin/bash

source ./scripts/util.sh

function pull_scripts() {
  cd $builddir/civ

  wget https://github.com/projectceladon/celadon-binary/raw/master/CIV_00.20.02.24_A10/caas-ota-QMm000000.zip
  wget https://github.com/projectceladon/celadon-binary/raw/master/CIV_00.20.02.24_A10/caas-releasefiles-userdebug.tar.gz

}

pull_scripts
