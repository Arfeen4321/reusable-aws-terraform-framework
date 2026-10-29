#!/usr/bin/env bash
# =============================================================================
# Automated Terraform Validation & Linting Suite
# =============================================================================
set -euo pipefail

echo "================================================================="
echo "  Executing Automated Terraform Validation & Quality Checks"
echo "================================================================="

# 1. Format check
echo "[Step 1/3] Checking Terraform code formatting (terraform fmt)..."
if terraform fmt -check -recursive; then
  echo "✔ Code formatting passed."
else
  echo "✖ Code formatting errors found. Run 'terraform fmt -recursive' to fix."
  exit 1
fi

# 2. Syntax and Configuration Validation across environments
DIRS=("bootstrap" "environments/dev" "environments/staging" "environments/prod")

for dir in "${DIRS[@]}"; do
  echo "[Step 2/3] Validating configuration in $dir..."
  if [ -d "$dir" ]; then
    pushd "$dir" > /dev/null
    terraform init -backend=false > /dev/null
    terraform validate
    popd > /dev/null
    echo "✔ Validation passed for $dir"
  fi
done

# 3. Optional Security Scanners (TFLint, tfsec, trivy)
echo "[Step 3/3] Checking for security scanning tools..."
if command -v tflint &> /dev/null; then
  echo "Running TFLint..."
  tflint --recursive
  echo "✔ TFLint checks passed."
else
  echo "ℹ TFLint not installed in PATH; skipping."
fi

if command -v tfsec &> /dev/null; then
  echo "Running tfsec..."
  tfsec .
  echo "✔ tfsec checks passed."
else
  echo "ℹ tfsec not installed in PATH; skipping."
fi

echo "================================================================="
echo "  All Terraform checks completed successfully!"
echo "================================================================="
