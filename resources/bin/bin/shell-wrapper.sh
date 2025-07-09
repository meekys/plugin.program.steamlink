#!/bin/bash
echo "" # Ensure command always starts on a new line
echo "###STATUS(120):Launching SteamLink"
echo "###ACTION(kodi-stop)"

echo "Setting splash screen"
$HOME/bin/png2fb.py /dev/fb0 /data/splash.png > /dev/null &

echo "Waiting for kodi to stop..."
t=0
until [ -e /data/.waitforkodi ] || (( t++ >= 300 )); do # 30 seconds
  sleep 0.1
done
[ -e /data/.waitforkodi ] && echo "Kodi has stopped, continuing" || echo "Timed out waiting for Kodi to stop"

echo "Waiting for splash screen..."
wait # Wait for writing to framebuffer to avoid any conflicts

echo "EXEC $@"
exec "$@"
