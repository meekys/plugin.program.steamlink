#!/bin/bash
set -e

echo "###STATUS(104):Preparing to start SteamLink"

export DEBIAN_FRONTEND=noninteractive
export HOME=/data
export XDG_DATA_HOME=/data

chmod +x $HOME/bin/*.sh
chmod +x $HOME/bin/*.py

. $HOME/bin/install.sh

cp /usr/bin/steamlink $HOME/bin/steamlink
cp /usr/bin/steamlinkdeps $HOME/bin/steamlinkdeps

# Remove root check
sed -i -e 's|$[(]id -u[)]|1|g' $HOME/bin/steamlink

# Remove all 'key-press' prompts
sed -i -e 's|read input||g' $HOME/bin/steamlink
sed -i -e 's|^read line$||g' $HOME/bin/steamlinkdeps

# Hook into Steamlink start-up script
sed -i -e "s|exec |exec $HOME/bin/steamlink-wrapper.sh |g" $HOME/bin/steamlink

# Ensure steamlink.sh can find correct steamlinkdeps
export STEAMSCRIPT=$HOME/bin/steamlink

# 105 is used for installling dependencies
echo "###STATUS(106):Preparing to start SteamLink"

echo "EXEC: $HOME/bin/steamlink"
exec $HOME/bin/steamlink
