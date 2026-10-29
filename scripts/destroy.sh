#!/usr/bin/env bash
# =============================================================================
# Controlled Teardown Script
# Usage: ./scripts/destroy.sh <dev|staging|prod> [--force-prod]
# =============================================================================
set -euo pipefail

ENV="${1:-dev}"
FORCE_FLAG="${2:-}"

if [[ ! "$ENV" =~ ^(dev|staging|prod)$ ]]; then
  echo "Error: Invalid environment '$ENV'. Must be one of: dev, staging, prod."
  exit 1
fi

if [[ "$ENV" == "prod" && "$FORCE_FLAG" != "--force-prod" ]]; then
  echo "================================================================="
  echo " CRITICAL SAFETY GUARD: PRODUCTION ENVIRONMENT DETECTED"
  echo "================================================================="
  echo "Direct destruction of the production environment is blocked by default."
  echo "To bypass this safety check, you must explicitly pass '--force-prod':"
  echo "  ./scripts/destroy.sh prod --force-prod"
  exit 1
fi

TARGET_DIR="environments/$ENV"

echo "================================================================="
echo " Initiating Teardown for Environment: [$ENV]"
echo "================================================================="

cd "$TARGET_DIR"

read -p "Are you ABSOLUTELY sure you want to destroy all infrastructure in [$ENV]? Type 'destroy-$ENV' to proceed: " CONFIRM

if [[ "$CONFIRM" == "destroy-$ENV" ]]; then
  echo "Proceeding with infrastructure destruction..."
  terraform destroy -auto-approve
  echo "✔ Teardown completed for [$ENV]."
else
  echo "Teardown aborted."
  exit 0
fi
