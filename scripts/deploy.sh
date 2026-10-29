#!/usr/bin/env bash
# =============================================================================
# Standardized Deployment Script
# Usage: ./scripts/deploy.sh <dev|staging|prod>
# =============================================================================
set -euo pipefail

ENV="${1:-dev}"

if [[ ! "$ENV" =~ ^(dev|staging|prod)$ ]]; then
  echo "Error: Invalid environment '$ENV'. Must be one of: dev, staging, prod."
  exit 1
fi

TARGET_DIR="environments/$ENV"

echo "================================================================="
echo " Deploying AWS Infrastructure: Environment [$ENV]"
echo "================================================================="

# 1. AWS Credentials Verification
echo "[1/5] Verifying active AWS credentials..."
CALLER_IDENTITY=$(aws sts get-caller-identity --output json 2>/dev/null || true)
if [ -z "$CALLER_IDENTITY" ]; then
  echo "Error: Unable to verify AWS credentials. Run 'aws configure' or export AWS_PROFILE / AWS_ACCESS_KEY_ID."
  exit 1
fi
echo "Active AWS Account: $(echo "$CALLER_IDENTITY" | grep -o '"Account": "[^"]*' | cut -d'"' -f4)"

# 2. Navigate to target environment
cd "$TARGET_DIR"

# 3. Initialize Terraform
echo "[2/5] Initializing Terraform..."
terraform init

# 4. Generate Execution Plan
echo "[3/5] Generating plan..."
terraform plan -out=tfplan

# 5. Confirmation and Apply
echo "[4/5] Review the plan above carefully."
read -p "Do you want to apply these changes to [$ENV]? (yes/no): " CONFIRM

if [[ "$CONFIRM" == "yes" ]]; then
  echo "[5/5] Applying approved execution plan..."
  terraform apply tfplan
  rm -f tfplan
  echo "✔ Deployment completed successfully for [$ENV]!"
else
  echo "Deployment aborted by user."
  rm -f tfplan
  exit 0
fi
