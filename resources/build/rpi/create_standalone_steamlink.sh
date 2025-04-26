#!/bin/bash

# Make sure all needed files end up in /tmp/steamlink/

set -e

cd "$(dirname "$0")"

USRLIBARCH=`cat /etc/ld.so.conf.d/* | grep "/usr/lib" | head --lines 1`

[[ -z "${USRLIBARCH}" ]] && { echo "Unable to determine /usr/lib directory from ld.so.conf.d/*"; exit 1; }

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
  libavcodec.so*
  libepoxy.so*
  libwayland-egl.so*
  libvpx.so*
  libwebpmux.so*
  libwebp.so*
  liblzma.so*
  libdav1d.so*
  librsvg-2.so*
  libzvbi.so*
  libsnappy.so*
  libaom.so*
  libavutil.so*
  libcodec2.so*
  libgsm.so*
  libjxl.so*
  libjxl_threads.so.0.7*
  libmp3lame.so*
  libopenjp2.so*
  librav1e.so*
  libshine.so*
  libSvtAv1Enc.so*
  libtheoraenc.so*
  libtheoradec.so*
  libtwolame.so*
  libvorbis.*
  libvorbisenc.so*
  libx264.so*
  libx265.so*
  libxvidcore.so*
  libva.so*
  libva-drm.so*
  libva-x11.so*
  libvdpau.so*
  libOpenCL.so*
  libmd4c.so*
  libgssapi_krb5.so*
  libdouble-conversion.so*
  libzstd.so*
  libgdk_pixbuf-2.0.so*
  libpangocairo-1.0.so*
  libpango-1.0.so*
  libbrotlidec.so*
  libhwy.so*
  libbrotlienc.so*
  liblcms2.so*
  libogg.so*
  libnuma.so*
  libXfixes.so*
  libX11-xcb.so*
  libxcb-dri3.so*
  libkrb5.so*
  libk5crypto.so*
  libcom_err.so*
  libkrb5support.so*
  libpangoft2-1.0.so*
  libfribidi.so*
  libthai.so*
  libbrotlicommon.so*
  libkeyutils.so*
  libdatrie.so*
  libmd.so*
"

for DEP in $DEPENDENCIES; do
  cp --verbose --no-dereference --recursive $USRLIBARCH/$DEP /tmp/steamlink/lib/
done

chown -R --reference=/tmp/steamlink /tmp/steamlink/
