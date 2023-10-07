
# Use latest compatible Debian version
FROM navikey/raspbian-buster

RUN sudo apt-get update \
 && sudo DEBIAN_FRONTEND=noninteractive apt-get --no-install-recommends install -y wget apt-transport-https \
 && sudo apt-get update \
 && sudo DEBIAN_FRONTEND=noninteractive apt-get --no-install-recommends install -y steamlink libgl1 libxv1 \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN wget "$(wget -q -O - http://media.steampowered.com/steamlink/rpi/public_build.txt)" -O /tmp/steamlink.tgz

# Script to copy the needed libraries
COPY create_standalone_steamlink.sh /tmp/
RUN chmod a+x /tmp/create_standalone_steamlink.sh

ENTRYPOINT [ "/tmp/create_standalone_steamlink.sh" ]
