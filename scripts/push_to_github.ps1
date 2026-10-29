# =============================================================================
# Automated Git Push Script for reusable-aws-terraform-framework
# =============================================================================
$ErrorActionPreference = "Stop"

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " Pushing AWS Terraform Framework to GitHub" -ForegroundColor Cyan
Write-Host " Target: https://github.com/Arfeen4321/reusable-aws-terraform-framework.git" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# 1. Initialize Git if not initialized
if (!(Test-Path ".git")) {
    Write-Host "[1/5] Initializing Git repository..." -ForegroundColor Yellow
    git init
} else {
    Write-Host "[1/5] Git already initialized." -ForegroundColor Green
}

# 2. Add all tracked files
Write-Host "[2/5] Staging files for commit..." -ForegroundColor Yellow
git add .

# 3. Commit
Write-Host "[3/5] Committing changes..." -ForegroundColor Yellow
git commit -m "feat: complete production-ready reusable AWS Terraform framework with Jenkins pipeline"

# 4. Set branch to main
Write-Host "[4/5] Setting default branch to main..." -ForegroundColor Yellow
git branch -M main

# 5. Configure remote origin
Write-Host "[5/5] Configuring remote origin..." -ForegroundColor Yellow
$remoteUrl = "https://github.com/Arfeen4321/reusable-aws-terraform-framework.git"
git remote remove origin 2>$null
git remote add origin $remoteUrl

# 6. Push to GitHub
Write-Host "Pushing to GitHub..." -ForegroundColor Cyan
git push -u origin main

Write-Host "=================================================================" -ForegroundColor Green
Write-Host "✔ Successfully pushed to GitHub!" -ForegroundColor Green
Write-Host "View your code at: https://github.com/Arfeen4321/reusable-aws-terraform-framework" -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Green
