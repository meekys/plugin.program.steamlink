# Based off steamlink boot-stream
OS_CODENAME=$(grep VERSION_CODENAME /etc/os-release | sed 's,.*=,,')
ARCH=$(dpkg --print-architecture)
UPDATE_URL="https://media.steampowered.com/steamlink/rpi/$OS_CODENAME/$ARCH"
UPDATE_BRANCH="public"
BUILD_URL="$UPDATE_URL/${UPDATE_BRANCH}_build.txt"

# TODO: Update CA, rather than skip certificate check
echo "Checking version using $BUILD_URL"
latest=$(wget -q -O - --no-check-certificate "$BUILD_URL")

echo "Downloading $latest"
wget "$latest" -q -O /tmp/steamlink.tgz --no-check-certificate
