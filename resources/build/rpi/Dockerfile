
# Use latest compatible Debian version
FROM dtcooper/raspberrypi-os:latest

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get --no-install-recommends install -y wget apt-transport-https \
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get --no-install-recommends install -y steamlink libgl1 libxv1 \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

COPY download.sh /tmp/
RUN bash /tmp/download.sh

# Script to copy the needed libraries
COPY create_standalone_steamlink.sh /tmp/
RUN chmod a+x /tmp/create_standalone_steamlink.sh

ENTRYPOINT [ "/tmp/create_standalone_steamlink.sh" ]
