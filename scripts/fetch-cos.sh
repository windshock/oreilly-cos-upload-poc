#!/usr/bin/env bash
# Downloads the public O'Reilly COS jar into webapp/WEB-INF/lib.
# The jar is NOT committed to this repo; this script fetches the public artifact.
set -euo pipefail
cd "$(dirname "$0")/.."
DEST="webapp/WEB-INF/lib/cos.jar"
URL="https://repo1.maven.org/maven2/servlets/com/cos/05Nov2002/cos-05Nov2002.jar"
mkdir -p webapp/WEB-INF/lib
echo "Downloading COS jar from Maven Central..."
if curl -fsSL "$URL" -o "$DEST"; then
  echo "OK -> $DEST"
else
  echo "Download failed. Obtain servlets.com:cos:05Nov2002 (cos.jar) manually and place it at $DEST"
  exit 1
fi
