#!/bin/sh
set -eu

echo "==> Running tests: $*"
if "$@"; then
  echo "==> Tests passed."
  exit 0
else
  echo "==> Tests failed."
  exit 1
fi
exit 1
