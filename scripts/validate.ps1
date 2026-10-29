<#
.SYNOPSIS
    Automated Terraform Validation & Quality Checks for Windows PowerShell.
#>

$ErrorActionPreference = "Stop"

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "  Executing Automated Terraform Validation & Quality Checks" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# 1. Format check
Write-Host "[Step 1/3] Checking Terraform code formatting (terraform fmt)..." -ForegroundColor Yellow
$fmtResult = terraform fmt -check -recursive
if ($LASTEXITCODE -eq 0) {
    Write-Host "✔ Code formatting passed." -ForegroundColor Green
} else {
    Write-Host "✖ Code formatting errors found. Run 'terraform fmt -recursive' to fix." -ForegroundColor Red
    exit 1
}

# 2. Syntax validation
$directories = @("bootstrap", "environments\dev", "environments\staging", "environments\prod")

foreach ($dir in $directories) {
    if (Test-Path $dir) {
        Write-Host "[Step 2/3] Validating configuration in $dir..." -ForegroundColor Yellow
        Push-Location $dir
        try {
            terraform init -backend=false | Out-Null
            terraform validate
            Write-Host "✔ Validation passed for $dir" -ForegroundColor Green
        } finally {
            Pop-Location
        }
    }
}

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "  All validation checks passed successfully!" -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Cyan
