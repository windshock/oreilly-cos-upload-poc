#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
[ -f webapp/WEB-INF/lib/cos.jar ] || { echo "run scripts/fetch-cos.sh first"; exit 1; }
docker rm -f cos-poc >/dev/null 2>&1 || true
docker run -d --name cos-poc -p 8899:8080 \
  -v "$PWD/webapp:/usr/local/tomcat/webapps/ROOT" \
  tomcat:8.5.93-jdk8-temurin >/dev/null
echo "Tomcat starting on http://localhost:8899/ (ctrl: docker logs -f cos-poc)"
