#!/bin/sh
set -eu

echo "==> Running tests: $*"
if "$@"; then
  echo "==> Tests passed."
  exit 0
fi

echo "==> Tests failed."
if [ "${DEBUG_ON_FAIL:-0}" = "1" ]; then
  echo "==> DEBUG_ON_FAIL=1: keeping container alive for inspection."
  echo "    (use: docker exec -it <container> sh)"
  echo "    (stop: docker stop <container>)"
  sleep infinity
fi

exit 1
