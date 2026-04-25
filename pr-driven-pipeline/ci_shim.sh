#!/usr/bin/env bash
set -euo pipefail

IMAGE_BASE="pr-driven-pipeline"

echo "============================"
echo " Running CI pipeline"
echo "============================"

echo "Step 1: Build Docker image"
docker build -t "${IMAGE_BASE}" .

# A failing test would cause the script to exit immediately. Disable -e, run
# the tests, and capture the exit code to report the test result properly.
set +e
echo "Step 2: Run tests"
docker run --rm "${IMAGE_BASE}"

TEST_EXIT_CODE=$?

if [ "$TEST_EXIT_CODE" -ne 0 ]; then
  echo "❌ Tests FAILED"
  exit "$TEST_EXIT_CODE"
else
  echo "✅ Tests PASSED"
fi
