#!/usr/bin/env bash
set -euo pipefail

IMAGE_BASE="simulate-cicd"

usage() {
  cat <<EOF
Usage:
  $(basename "$0") <version> [--debug | -d] [--hash-mismatch]

Where:
  <version> ::= v1 | v2 | v3 | 1 | 2 | 3

Options:
  --debug, -d   Keep the container alive on test failure for inspection
               (requires image ENTRYPOINT to honor DEBUG_ON_FAIL=1)
  --hash-mismatch  Simulate a hash mismatch by modifying the artifact after hashing
               (requires image build to include the artifact hash check)

Examples:
  $(basename "$0") v1
  $(basename "$0") v1 --hash-mismatch
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
HASH_MISMATCH=0

if [[ "${2:-}" == "--debug" ]] || [[ "${2:-}" == "-d" ]]; then
  DEBUG_MODE=1
elif [[ "${2:-}" == "--hash-mismatch" ]]; then
  HASH_MISMATCH=1
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

echo "Step 1: Creating artifact: ${IMAGE_TAG}"
ARTIFACT_FILE="app${APP_VERSION}.py"
ARTIFACTS_DIR="artifacts"
ARTIFACT_ZIP="app_v${APP_VERSION}.zip"

# clean any existing artifact for this version before starting
rm -f "${ARTIFACTS_DIR}/app_v${APP_VERSION}.zip"
rm -f "${ARTIFACTS_DIR}/app_v${APP_VERSION}.zip.sha256"

[ -d "$ARTIFACTS_DIR" ] || mkdir -p "$ARTIFACTS_DIR"
cp app/${ARTIFACT_FILE} "$ARTIFACTS_DIR"/app.py
pushd "$ARTIFACTS_DIR" >/dev/null

# Hack: create a zip with a deterministic compression method
# so we can trigger a hash mismatch by changing the compression method later.
zip --compression-method deflate "$ARTIFACT_ZIP" "app.py"
shasum -a 256 "$ARTIFACT_ZIP" > "${ARTIFACT_ZIP}.sha256"

if [[ "${HASH_MISMATCH}" -eq 1 ]]; then
  echo "Simulating hash mismatch by modifying the artifact after hashing."
  echo "This will cause the build to fail immediately before any tests are run."
  # Hack: recompress with different method to change the hash without changing the file contents 
  zip --compression-method store "$ARTIFACT_ZIP" "app.py"
fi
popd >/dev/null

# Do not exit on build failure, as there is a handler for that.
set +e
echo
echo "Step 2: Build Docker image (${IMAGE_TAG})"
docker build \
  --build-arg APP_VERSION="${APP_VERSION}" \
  -t "${IMAGE_TAG}" \
  .

BUILD_EXIT_CODE=$?
if [ "$BUILD_EXIT_CODE" -ne 0 ]; then
  echo "❌ v${APP_VERSION}: build FAILED (exit code: $BUILD_EXIT_CODE)"
  echo "Stopping pipeline: do NOT proceed to testing or deployment."
  rm -f "${ARTIFACTS_DIR}/app_v${APP_VERSION}.zip"
  rm -f "${ARTIFACTS_DIR}/app_v${APP_VERSION}.zip.sha256"
  exit "$BUILD_EXIT_CODE"
else
  echo "✅ v${APP_VERSION}: build PASSED"
  echo "Proceeding to testing step."
fi

echo
echo "Step 3: Run tests inside container"

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
  rm -f "${ARTIFACTS_DIR}/app_v${APP_VERSION}.zip"
  rm -f "${ARTIFACTS_DIR}/app_v${APP_VERSION}.zip.sha256"
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
