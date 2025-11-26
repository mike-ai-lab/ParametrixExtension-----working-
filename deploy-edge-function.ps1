# PARAMETRIX Edge Function Deployment Script

Write-Host "PARAMETRIX License System - Edge Function Deployment" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan

# Check if Supabase CLI is installed
if (!(Get-Command "supabase" -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Supabase CLI..." -ForegroundColor Yellow
    npm install -g supabase
}

# Login to Supabase (if not already logged in)
Write-Host "Checking Supabase login status..." -ForegroundColor Yellow
$loginStatus = supabase projects list 2>&1
if ($loginStatus -like "*not logged in*" -or $loginStatus -like "*error*") {
    Write-Host "Please login to Supabase:" -ForegroundColor Yellow
    supabase login
}

# Get project reference
Write-Host ""
Write-Host "Available projects:" -ForegroundColor Green
supabase projects list

Write-Host ""
$projectRef = Read-Host "Enter your Supabase project reference ID"

# Deploy the edge function
Write-Host ""
Write-Host "Deploying validate-license edge function..." -ForegroundColor Yellow
supabase functions deploy validate-license --project-ref $projectRef

Write-Host ""
Write-Host "Edge function deployed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Go to your Supabase dashboard > Edge Functions > Settings" -ForegroundColor White
Write-Host "2. Add environment variable: RSA_PRIVATE_KEY (your private key)" -ForegroundColor White
Write-Host "3. Test the function with a license key" -ForegroundColor White
Write-Host ""
Write-Host "Function URL: https://<your-project-ref>.supabase.co/functions/v1/validate-license" -ForegroundColor Yellow