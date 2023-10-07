#!/bin/bash

# Make sure all needed files end up in /tmp/steamlink/

set -e

cd "$(dirname "$0")"

echo "Extracting steamlink.tgx"
tar -zxf /tmp/steamlink.tgz -C /tmp

TOP="$(cd "$(dirname "$0")" && pwd)/steamlink"

# Install any additional dependencies, as needed
if [ -z "${STEAMSCRIPT:-}" ]; then
        STEAMSCRIPT=/usr/bin/steamlink
fi
STEAMDEPS="$(dirname $STEAMSCRIPT)/steamlinkdeps"
if [ -f "$STEAMDEPS" ]; then
        VERSION_CODENAME=$(fgrep VERSION_CODENAME /etc/os-release | sed 's/.*=//')
        if [ -f "$TOP/steamlinkdeps-$VERSION_CODENAME.txt" ]; then
                EXTRADEPS="$TOP/steamlinkdeps-$VERSION_CODENAME.txt"
        elif [ -f "$TOP/steamlinkdeps.txt" ]; then
                EXTRADEPS="$TOP/steamlinkdeps.txt"
        fi
fi

if [ -f "$EXTRADEPS" ]; then
    echo "Installing additional steam dependencies"
#    PACKAGES=$(grep -P "^(?!#)([\w.+-]+?)(?:$|:)" "$EXTRADEPS")
    PACKAGES=$(cat /tmp/steamlink/steamlinkdeps.txt | grep -v ^# | awk -F '|' '/[a-z]/{print $1}')
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get --no-install-recommends install -y $PACKAGES
fi

# Include dependencies not present in LibreELEC
DEPENDENCIES="
  libGL.so*
  libGLX.so*
  libGLdispatch.so*
  libX11.so*
  libXau.so*
  libXdmcp.so*
  libXext.so*
  libXv.so*
  libatomic.so*
  libbsd.so*
  libcrypto.so*
  libffi.so*
  libicudata.so*
  libicui18n.so*
  libicuuc.so*
  libjpeg.so*
  libmtdev.so*
  libopus.so*
  libpng16.so*
  libssl.so*
  libwayland-client.so*
  libxcb.so*
"

for DEP in $DEPENDENCIES; do
  cp --verbose --no-dereference --recursive /usr/lib/arm-linux-gnueabihf/$DEP /tmp/steamlink/lib/
done

chown -R --reference=/tmp/steamlink /tmp/steamlink/
