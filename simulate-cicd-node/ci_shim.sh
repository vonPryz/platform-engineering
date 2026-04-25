#!/usr/bin/env bash
set -euo pipefail

IMAGE_BASE="simulate-cicd-node"

usage() {
  cat <<EOF
Usage:
  $(basename "$0") <version> [--debug|-d]

Where:
  <version> ::= v1 | v2 | v3 | 1 | 2 | 3

Options:
  --debug, -d   Keep the container alive on test failure for inspection
               (requires image ENTRYPOINT to honor DEBUG_ON_FAIL=1)

Examples:
  $(basename "$0") v1
  $(basename "$0") 2
  $(basename "$0") v2 --debug
EOF
}

# No args, or help flags:  show usage
if [[ $# -lt 1 ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
  usage
  exit 1
fi

RAW_VERSION="$1"
DEBUG_MODE=0

if [[ "${2:-}" == "--debug" ]] || [[ "${2:-}" == "-d" ]]; then
  DEBUG_MODE=1
elif [[ $# -ge 2 ]]; then
  echo "Error: unknown option '$2'"
  echo
  usage
  exit 1
fi

# Normalize version: allow "1" or "v1" etc.
case "$RAW_VERSION" in
  1|v1) APP_VERSION=1 ;;
  2|v2) APP_VERSION=2 ;;
  3|v3) APP_VERSION=3 ;;
  *)
    echo "Error: unknown version '$RAW_VERSION'"
    echo
    usage
    exit 1
    ;;
esac

IMAGE_TAG="${IMAGE_BASE}:v${APP_VERSION}"
DEBUG_CONTAINER_NAME="${IMAGE_BASE}-debug-v${APP_VERSION}"

echo "============================"
echo " Running pipeline for version v${APP_VERSION}"
echo "============================"

echo
echo "Step 1: Build Docker image (${IMAGE_TAG})"

set +e
docker build \
  --target "v${APP_VERSION}" \
  -t "${IMAGE_TAG}" \
  .
BUILD_EXIT_CODE=$?
set -e

if [ "${BUILD_EXIT_CODE}" -ne 0 ]; then
  echo
  echo "❌ v${APP_VERSION}: build FAILED (exit code: ${BUILD_EXIT_CODE})"
  echo "Stopping pipeline: do NOT deploy this version."
  exit "${BUILD_EXIT_CODE}"
fi

echo
echo "Step 2: Run tests inside container"
set +e

if [[ "${DEBUG_MODE}" -eq 1 ]]; then
  echo "Debug mode enabled: container will stay alive on failure."
  echo "Container name: ${DEBUG_CONTAINER_NAME}"
  docker rm -f "${DEBUG_CONTAINER_NAME}" >/dev/null 2>&1 || true
  docker run --name "${DEBUG_CONTAINER_NAME}" -e DEBUG_ON_FAIL=1 "${IMAGE_TAG}"
else
  docker run --rm "${IMAGE_TAG}"
fi

TEST_EXIT_CODE=$?
set -e

echo

if [ "$TEST_EXIT_CODE" -ne 0 ]; then
  echo "❌ v${APP_VERSION}: tests FAILED (exit code: $TEST_EXIT_CODE)"
  echo "Stopping pipeline: do NOT deploy this version."
  if [[ "${DEBUG_MODE}" -eq 1 ]]; then
    echo
    echo "Debugging:"
    echo "  docker exec -it ${DEBUG_CONTAINER_NAME} sh"
    echo "  docker logs ${DEBUG_CONTAINER_NAME}"
    echo "Cleanup:"
    echo "  docker stop ${DEBUG_CONTAINER_NAME}"
    echo "  docker rm ${DEBUG_CONTAINER_NAME}"
  fi
  exit "$TEST_EXIT_CODE"
else
  echo "✅ v${APP_VERSION}: tests PASSED"
  echo "OK to proceed with deployment steps."
  if [[ "${DEBUG_MODE}" -eq 1 ]]; then
    # No need to keep a passing container around
    docker rm -f "${DEBUG_CONTAINER_NAME}" >/dev/null 2>&1 || true
  fi
fi
