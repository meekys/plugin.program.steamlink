#!/bin/bash

cd "$(dirname "$0")"

if [ -z "$ADDON_PROFILE_PATH" ]; then
  # If no path is given then we do a well estimated guess
  export ADDON_PROFILE_PATH="$(realpath ~/.kodi/userdata/addon_data/plugin.program.steamlink/)"
fi

bash bootstrap_steamlink.sh "$@" 2>&1 | tee "$ADDON_PROFILE_PATH/steamlink.log"
