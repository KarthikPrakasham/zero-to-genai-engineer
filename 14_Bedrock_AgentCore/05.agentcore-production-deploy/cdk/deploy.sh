#!/usr/bin/env bash
# Classroom: deploy stages 1→10
#   bash cdk/deploy.sh 1
#   bash cdk/deploy.sh 2
#   ...
#   SUPPORT_RUNTIME_ARN=arn:... bash cdk/deploy.sh 10

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

export AWS_REGION="${AWS_REGION:-us-east-1}"
export AWS_DEFAULT_REGION="$AWS_REGION"
export CDK_DEFAULT_REGION="$AWS_REGION"
export CDK_DEFAULT_ACCOUNT="$(aws sts get-caller-identity --query Account --output text)"

STAGE="${1:-${CDK_STAGE:-10}}"
if [[ ! "$STAGE" =~ ^[0-9]+$ ]]; then
  echo "Usage: bash cdk/deploy.sh <1-10>" >&2
  exit 1
fi
shift || true

if [ "$STAGE" -eq 10 ] && [ -z "${SUPPORT_RUNTIME_ARN:-}" ]; then
  echo "ERROR: stage 10 needs SUPPORT_RUNTIME_ARN" >&2
  exit 1
fi

if [ ! -d .venv ]; then
  python3 -m venv .venv
fi
# shellcheck disable=SC1091
source .venv/bin/activate
pip install -q -r requirements.txt

export JSII_SILENCE_WARNING_UNTESTED_NODE_VERSION=1

echo "==> Account=$CDK_DEFAULT_ACCOUNT Region=$AWS_REGION Stage=$STAGE"
aws sts get-caller-identity

npx --yes cdk@2 bootstrap "aws://${CDK_DEFAULT_ACCOUNT}/${AWS_REGION}"

CTX=(-c "stage=${STAGE}")
if [ -n "${SUPPORT_RUNTIME_ARN:-}" ]; then
  CTX+=(-c "supportRuntimeArn=${SUPPORT_RUNTIME_ARN}")
fi

echo "==> cdk deploy ${CTX[*]} $*"
npx --yes cdk@2 deploy --require-approval never "${CTX[@]}" "$@"
