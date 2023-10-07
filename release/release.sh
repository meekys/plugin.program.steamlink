#/bin/bash

set -e

ABSSRC="$(dirname $0)"
ABSSRC="$(realpath $ABSSRC/..)"
SRC="$(basename $ABSSRC)"

VERSION="$1"
if [ -z "$VERSION" ]; then
  VERSION="local"
fi

cd "$ABSSRC/.."

zip -r "$ABSSRC/release/plugin.program.steamlink-$VERSION.zip" "$SRC" -x "$SRC/.git/*" "$SRC/.git*" "$SRC/.editorconfig" "$SRC/release/*"