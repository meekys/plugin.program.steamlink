#!/bin/bash

set -e

TOP=$(cd "$(dirname "$0")" && pwd)

source "$TOP/get-platform.sh"

# Check platform support
if [ ! -d "$TOP/${PLATFORM_ID}" ]
then
  echo "sorry, platform ${PLATFORM_ID} currently not supported!"
  exit 1
fi

# Ensure docker is available in the PATH
if [ "${PLATFORM_ID}" = "libreelec" ]; then
  . /etc/profile
fi

if [ -z "$ADDON_PROFILE_PATH" ]; then
  # If no path is given then we do a well estimated guess
  ADDON_PROFILE_PATH="$(realpath ~/.kodi/userdata/addon_data/plugin.program.steamlink/)"
  echo "ADDON_PROFILE_PATH not set, using $ADDON_PROFILE_PATH"
fi

# Create to the add-on profile path
mkdir -p "$ADDON_PROFILE_PATH"
