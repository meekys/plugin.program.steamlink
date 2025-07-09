#!/bin/bash
set -e

# Ensure apt doesn't prompt to accepts installing packages
echo "APT::Get::Assume-Yes "true";" > /etc/apt/apt.conf.d/90assumeyes

# Steamlink core dependencies
deps='fbset python3-pil python3-numpy sudo curl ca-certificates sndiod steamlink'

missing_deps=()

for dep in $deps; do
   dpkg-query -s "$dep" &>/dev/null || missing_deps="$missing_deps $dep"
done

if [ "$missing_deps" ]; then
  echo "###STATUS(105):Installing SteamLink dependencies"
  apt-get update
  apt-get --no-install-recommends install $missing_deps
fi
