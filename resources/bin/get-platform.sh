#!/bin/bash

# This script resolves a string to describe the platform where this script is
# executed. Information is pulled from /etc/os-release. For more info see:
#   https://www.linux.org/docs/man5/os-release.html

set -e

TOP=$(cd "$(dirname "$0")" && pwd)

for file in /etc/os-release /usr/lib/os-release; do
  if [ -f $file ]; then
    source $file
    break
  fi
done

ARCH=$(uname -m)

if [ "$ARCH" = "aarch64" ]; then
  ARCH="arm64"
fi

# Figure out distro (libreelec, ubuntu)
DISTRO="$ID"

if [ -d "$TOP/$DISTRO/$ARCH" ]; then
  PLATFORM_ID="$DISTRO/$ARCH"
elif [ -d "$TOP/$DISTRO" ]; then
  PLATFORM_ID="$DISTRO"
elif [ -d "$$TOP/ARCH" ]; then
  PLATFORM_ID="$ARCH"
else
  PLATFORM_ID="generic"
fi

echo "'$DISTRO' ($ARCH) detected, using platform '$PLATFORM_ID'"

