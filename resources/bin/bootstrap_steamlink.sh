#!/bin/bash
#
# Script to launch the Steam Link app on Raspberry Pi

# Only for debugging
# export QT_DEBUG_PLUGINS=1
set -e
# set -x

# To use a specific PulseAudio device:
# export PULSE_SINK="alsa_output.pci-0000_0a_00.1.analog-stereo"

# To disable PulseAudio:
# export PULSE_SERVER="none"

# Force a EGL mode, can also be configured from settings menu addon
# export FORCE_EGL_MODE="1280x720"
# export FORCE_EGL_MODE="1920x1080"
# export FORCE_EGL_MODE="2560x1440"

cd "$(dirname "$0")"

# Get platform and distro
source ./get-platform.sh

# Backup paths
HOME_BACKUP="$HOME"
LD_LIBRARY_PATH_BACKUP="$LD_LIBRARY_PATH"

# Paths
ADDON_BIN_PATH=$(realpath ".")
STEAMLINK_PATH="$ADDON_PROFILE_PATH/steamlink"

# setup udev
if [ ! -f /lib/udev/rules.d/56-steamlink.rules ]; then
  echo 'Adding udev overlay'
  mkdir -p $STEAMLINK_PATH/overlay_work
  mount -t overlay overlay -o lowerdir=/lib/udev/rules.d,upperdir=$STEAMLINK_PATH/udev/rules.d/,workdir=$STEAMLINK_PATH/overlay_work /lib/udev/rules.d
  udevadm trigger
fi

# Alter HOME var to contain all settings in the addon profile path
export HOME="$ADDON_PROFILE_PATH/steamlink-home"
cd $STEAMLINK_PATH

# Restore the display when we're done
cleanup()
{
  # Restore paths
  export HOME="$HOME_BACKUP"
  export LD_LIBRARY_PATH="$LD_LIBRARY_PATH_BACKUP"

  if [ "$CEC_PID" != "" ]; then
    kill $CEC_PID 2>/dev/null
  fi
#  screenblank -k
}
trap cleanup 2 3 15

# Set up the temporary directory
export TMPDIR="$STEAMLINK_PATH/.tmp"
rm -rf "$TMPDIR"
mkdir -p "$TMPDIR"

# Check for distro specific hooks
if [ -d "$ADDON_BIN_PATH/kodi_hooks/$PLATFORM_DISTRO" ]; then
  echo "Using Kodi hooks for $PLATFORM_DISTRO..."
  # Stop kodi using hook
  source "$ADDON_BIN_PATH/kodi_hooks/$PLATFORM_DISTRO/stop.sh"

  # Start kodi when this script exits using trap in hook
  source "$ADDON_BIN_PATH/kodi_hooks/$PLATFORM_DISTRO/start.sh"
fi

# Run the shell application and launch streaming
QT_VERSION=5.14.1
export PATH="$STEAMLINK_PATH/bin:$PATH"
export QTDIR="$STEAMLINK_PATH/Qt-$QT_VERSION"
export QT_PLUGIN_PATH="$QTDIR/plugins"
export LD_LIBRARY_PATH="$STEAMLINK_PATH/lib:$QTDIR/lib:$LD_LIBRARY_PATH"
export SDL_GAMECONTROLLERCONFIG_FILE="${XDG_DATA_HOME:-$HOME/.local/share}/Valve Corporation/SteamLink/controller_map.txt"

if [ "$QT_QPA_PLATFORM" = "" ]; then
  if [ "$DISPLAY" = "" ]; then
    export QT_QPA_PLATFORM="eglfs"
    if [ -c /dev/dri/card0 ]; then
      export QT_QPA_EGLFS_INTEGRATION=eglfs_kms
      export QT_QPA_EGLFS_PRELOAD=""
    elif [ -f /opt/vc/lib/libbrcmGLESv2.so ]; then
      export QT_QPA_EGLFS_INTEGRATION=eglfs_brcm
      export QT_QPA_EGLFS_PRELOAD="/opt/vc/lib/libbrcmGLESv2.so"
    else
      # Let's try the default integration
      export QT_QPA_EGLFS_INTEGRATION=none
      export QT_QPA_EGLFS_PRELOAD=""
    fi
    export QT_QPA_EGLFS_FORCE888=1
    export QT_QPA_EGLFS_ALWAYS_SET_MODE=1
  else
    export QT_QPA_PLATFORM="xcb"
  fi

#  export QT_LOGGING_RULES="qt.qpa.*=true"
fi

if [ -f "$STEAMLINK_PATH/.ignore_cec" ]; then
  CEC_PID=""
else
  cec-client </dev/null | steamlink-cec &
  CEC_PID="$(jobs -p) $!"
fi

echo "Starting SteamLink"
restart=false
while true; do
  LD_PRELOAD=$QT_QPA_EGLFS_PRELOAD shell "$@"

  # See if the shell wanted to launch anything
  cmdline_file="$TMPDIR/launch_cmdline.txt"
  if [ -f "$cmdline_file" ]; then
    cmd=`cat "$cmdline_file"`
    if [ "$cmd" = "\"steamlink\"" ]; then
      restart=true
      rm -f "$cmdline_file"
      break
    else
      eval $cmd
      rm -f "$cmdline_file"

      # We're all done if it was a single session launch
      if echo "$cmd" | fgrep "://" >/dev/null; then
        break
      fi
    fi
  else
    # We're all done...
    break
  fi
done
cleanup

# if [ "$restart" = "true" ]; then
#   exec steamlink "$@"
# fi

exit 0
