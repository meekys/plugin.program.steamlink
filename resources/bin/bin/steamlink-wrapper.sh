#!/bin/bash
set -e

if [ -f /data/.env ]; then
  source /data/.env
fi

cmd="$1"
newcmd="$1-modified"
cp -v "$cmd" "$newcmd"

# Insert wrapper into steamlink.sh for call to bin/shell
sed -i -e "s|exec shell|exec $HOME/bin/shell-wrapper.sh shell|g" "$newcmd"

# Prevent inline udev script running
UDEV_RULES_FILE=$(grep "UDEV_RULES_FILE=" "$newcmd")
UDEV_RULES_FILE=${UDEV_RULES_FILE##*=}
if ! [ -z "$UDEV_RULES_FILE" ]; then
    echo "Flagging $UDEV_RULES_FILE"
    touch /lib/udev/rules.d/$UDEV_RULES_FILE
fi

echo "" # Ensure command always starts on a new line
echo "###STATUS(110):Checking SteamLink dependencies"

shift
echo "EXEC $newcmd $@"
exec "$newcmd" "$@"
