#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage:
  $(basename "$0") <version> [--create-artifacts]

Where:
  <version> ::= v1 | v2 | v3 | 1 | 2 | 3

Examples:
  $(basename "$0") v1
  $(basename "$0") 2
  $(basename "$0") 2 --create-artifacts
EOF
}

# No args, or help flags:  show usage
if [[ $# -lt 1 ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
  usage
  exit 1
fi

APP_VERSION="1"
RAW_VERSION="$1"
CREATE_ARTIFACTS=0

if [[ "${2:-}" == "--create-artifacts" ]]; then
  CREATE_ARTIFACTS=1
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

ARTIFACTS_DIR="../simulate-cicd/artifacts"
ARTIFACTS_FILE="app_v${APP_VERSION}"
ARTIFACT_ZIP="${ARTIFACTS_DIR}/${ARTIFACTS_FILE}.zip"
ARTIFACT_SHA="${ARTIFACTS_DIR}/${ARTIFACTS_FILE}.zip.sha256"

# Hack to streamline demo. In a real CI/CD pipeline, the artifact would
# necessarily exist before promotion steps are triggered.
# If the artifact does not exist, --create-artifacts allows calling
# simulate-cicd pipeline to create it.

if [[ -f "$ARTIFACT_ZIP" && -f "$ARTIFACT_SHA" ]]; then
  echo "Artifact already exists: $ARTIFACT_ZIP"
else
  echo "❌ Missing artifact zip: $ARTIFACT_ZIP."
  if [[ "${CREATE_ARTIFACTS}" -eq 1 ]]; then
    echo "Creating artifact for version v${APP_VERSION}..."
    pushd ../simulate-cicd > /dev/null
    ./ci_shim.sh "$APP_VERSION"
    popd > /dev/null
  else
    echo "Cannot proceed without artifact. Please create the artifact and try again, or run with --create-artifacts to generate it automatically."
    exit 1
  fi
fi

echo "============================"
echo " Running promotion pipeline for version v${APP_VERSION}"
echo "============================"

echo "Step 1: Verifying artifact integrity"
pushd "$ARTIFACTS_DIR" >/dev/null
if [[ ! -f "${ARTIFACTS_FILE}.zip" ]]; then
  pwd
  echo "❌ Missing artifact zip: ${ARTIFACTS_FILE}.zip"
  exit 1
fi

if [[ ! -f "${ARTIFACTS_FILE}.zip.sha256" ]]; then
  echo "❌ Artifact SHA file not found: ${ARTIFACTS_FILE}.zip.sha256"
  exit 1
fi

if ! sha256sum -c "${ARTIFACTS_FILE}.zip.sha256"; then
  echo "❌ Artifact integrity check failed: ${ARTIFACTS_FILE}.zip"
  exit 1
fi
echo "✅ Artifact integrity verified: ${ARTIFACTS_FILE}.zip"
echo "Proceeding with promotion steps."
popd >/dev/null

ENDPOINT_URL_PARAMETER="--endpoint-url=http://localhost:4566"

echo "Step 2: Verifying AWS/LocalStack connectivity"
if ! aws ${ENDPOINT_URL_PARAMETER} sts get-caller-identity >/dev/null 2>&1; then
  echo "❌ Failed to connect to AWS/LocalStack."
  echo "Please ensure LocalStack is running and accessible at http://localhost:4566"
  exit 1
fi
echo "✅ Successfully connected to AWS/LocalStack S3 endpoint."

echo "Step 3: Creating S3 bucket if it doesn't exist"
BUCKET_NAME="cicd-artifacts-bucket"
if ! aws ${ENDPOINT_URL_PARAMETER} s3 ls "s3://${BUCKET_NAME}" >/dev/null 2>&1; then
  echo "Bucket '${BUCKET_NAME}' does not exist. Creating bucket..."
  if ! aws ${ENDPOINT_URL_PARAMETER} s3 mb "s3://${BUCKET_NAME}"; then
    echo "❌ Failed to create bucket '${BUCKET_NAME}'."
    exit 1
  fi
  echo "✅ Bucket '${BUCKET_NAME}' created successfully."
else
  echo "✅ Bucket '${BUCKET_NAME}' already exists."
fi

echo "Step 4: Promoting artifact to S3 bucket '${BUCKET_NAME}'"
if ! (aws ${ENDPOINT_URL_PARAMETER} s3 cp "$ARTIFACT_ZIP" "s3://${BUCKET_NAME}/${ARTIFACTS_FILE}.zip" && \
       aws ${ENDPOINT_URL_PARAMETER} s3 cp "$ARTIFACT_SHA" "s3://${BUCKET_NAME}/${ARTIFACTS_FILE}.zip.sha256"); then
  echo "❌ Failed to upload artifact to S3 bucket '${BUCKET_NAME}'."
  exit 1
fi
echo "✅ Artifact uploaded successfully to s3://${BUCKET_NAME}/${ARTIFACTS_FILE}.zip" 

echo "Step 5: Verifying artifact upload with 'aws s3 ls'"
if ! aws ${ENDPOINT_URL_PARAMETER} s3 ls "s3://${BUCKET_NAME}/${ARTIFACTS_FILE}.zip" >/dev/null 2>&1; then
  echo "❌ Failed to verify artifact upload with 'aws s3 ls'."
  exit 1
fi
echo "✅ Artifact upload verified with 'aws s3 ls'. Promotion pipeline completed successfully." 
