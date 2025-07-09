#!/bin/bash

set -e

TOP=$(cd "$(dirname "$0")" && pwd)

source $TOP/common.sh

function die()
{
  echo "$@"
  exit 1
}

if [ -f "$TOP/$PLATFORM_ID/docker.sh" ]; then
  source "$TOP/$PLATFORM_ID/docker.sh"
else
  die "No docker environment available/support for $PLATFORM_ID"
fi

if [ -z "$DOCKER_BASE" ]; then
  die "No docker base image found for $PLATFORM_ID"
fi

function cleanup() {
  retval=$?
  echo "TODO: Cleanup any temporary images? (ie. steamlink_base)"

  if [ ! -z "$(docker ps -aq -f name=^steamlink_base$)" ]; then
    echo "Cleaning up transient docker container..."
    docker rm steamlink_base
  fi
}

echo "###STATUS(100):Preparing to launch SteamLink"
mkdir -v -p "$ADDON_PROFILE_PATH/data/bin"
cp -v $TOP/bin/*.sh $ADDON_PROFILE_PATH/data/bin/
cp -v $TOP/bin/*.py $ADDON_PROFILE_PATH/data/bin/
cp -v $TOP/../splash.png $ADDON_PROFILE_PATH/data/

echo "###STATUS(990):Migrating data"
if [ -d "$ADDON_PROFILE_PATH/steamlink-home/.local/share/Valve Corporation" ]; then
  if [ ! -d "$ADDON_PROFILE_PATH/data/Valve Corporation" ]; then
    echo "Migrating SteamLink settings"
    mv "$ADDON_PROFILE_PATH/steamlink-home/.local/share/Valve Corporation" "$ADDON_PROFILE_PATH/data/Valve Corporation"
  fi
fi

if [ -d "$ADDON_PROFILE_PATH/steamlink-home/.config/Valve Corporation" ]; then
  if [ ! -d "$ADDON_PROFILE_PATH/data/.config/Valve Corporation" ]; then
    echo "Migrating SteamLink settings (.config)"
    mkdir -v -p "$ADDON_PROFILE_PATH/data/.config"
    mv "$ADDON_PROFILE_PATH/steamlink-home/.config/Valve Corporation" "$ADDON_PROFILE_PATH/data/.config/Valve Corporation"
  fi
fi

if [ -d "$ADDON_PROFILE_PATH/steamlink" ]; then
  echo "Removing old steamlink installation"
  rm -rf "$ADDON_PROFILE_PATH/steamlink"
fi

if [ -z "$(docker ps -a -q -f name=steamlink 2> /dev/null)" ]; then
  echo "###STATUS(102):Creating SteamLink container"
  docker create \
    --privileged \
    --tty \
    --volume /run:/run \
    --volume /dev/input:/dev/input \
    --volume /dev/usb:/dev/usb \
    --network="host" \
    --volume "$ADDON_PROFILE_PATH/data:/data" \
    --name steamlink \
    --entrypoint /bin/bash \
    $DOCKER_BASE \
    /data/bin/launch.sh
fi

if [ -f "$TOP/$PLATFORM_ID/kodi-start.sh" ]; then
  . "$TOP/$PLATFORM_ID/kodi-start.sh"
fi

stop_container()
{
  echo "Stopping container"
  docker stop steamlink
}

on_error()
{
  LASTERROR = $?
  echo "###ERROR($LASTERROR)"
}

stop_kodi()
{
  if [ -f "$TOP/$PLATFORM_ID/kodi-stop.sh" ]; then
    . "$TOP/$PLATFORM_ID/kodi-stop.sh"
  fi

  echo "Signalling Kodi has stopped"
  touch "$ADDON_PROFILE_PATH/data/.waitforkodi"
}

rm -f "$ADDON_PROFILE_PATH/data/.waitforkodi"

parse_result() {
  while read line; do
    echo "$line"

    if [[ "$line" = '###ACTION(kodi-stop)'* ]]; then
      stop_kodi &
    fi
  done
}

trap on_error ERR
trap stop_container SIGINT

echo "###STATUS(103):Starting SteamLink container"
parse_result < <(docker start --attach --interactive steamlink)

echo "###ACTION(kodi-start)"
