#!/bin/bash

TOP=$(cd "$(dirname "$0")" && pwd)

source $TOP/common.sh

bash $TOP/run.sh 2>&1 | tee "$ADDON_PROFILE_PATH/steamlink.log"
