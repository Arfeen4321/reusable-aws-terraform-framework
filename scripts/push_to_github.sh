#!/usr/bin/env bash
# =============================================================================
# Automated Git Push Script for reusable-aws-terraform-framework
# =============================================================================
set -euo pipefail

echo "================================================================="
echo " Pushing AWS Terraform Framework to GitHub"
echo " Target: https://github.com/Arfeen4321/reusable-aws-terraform-framework.git"
echo "================================================================="

# 1. Initialize Git if not initialized
if [ ! -d ".git" ]; then
    echo "[1/5] Initializing Git repository..."
    git init
else
    echo "[1/5] Git already initialized."
fi

# 2. Add all files
echo "[2/5] Staging files for commit..."
git add .

# 3. Commit
echo "[3/5] Committing changes..."
git commit -m "feat: complete production-ready reusable AWS Terraform framework with Jenkins pipeline"

# 4. Set branch to main
echo "[4/5] Setting default branch to main..."
git branch -M main

# 5. Configure remote origin
echo "[5/5] Configuring remote origin..."
git remote remove origin 2>/dev/null || true
git remote add origin https://github.com/Arfeen4321/reusable-aws-terraform-framework.git

# 6. Push to GitHub
echo "Pushing to GitHub..."
git push -u origin main

echo "================================================================="
echo "✔ Successfully pushed to GitHub!"
echo "View your code at: https://github.com/Arfeen4321/reusable-aws-terraform-framework"
echo "================================================================="
