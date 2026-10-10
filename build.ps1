# build.ps1 - Build the Lambda deployment package
Write-Host "Cleaning previous build..." -ForegroundColor Cyan
Remove-Item -Recurse -Force terraform/build -ErrorAction SilentlyContinue
Remove-Item -Force terraform/lambda.zip -ErrorAction SilentlyContinue

Write-Host "Creating build directory..." -ForegroundColor Cyan
New-Item -ItemType Directory -Path terraform/build | Out-Null

Write-Host "Installing Python dependencies..." -ForegroundColor Cyan
python -m pip install -r src/requirements.txt -t terraform/build --quiet

Write-Host "Copying Lambda source code..." -ForegroundColor Cyan
Copy-Item src/lambda_function.py terraform/build/

Write-Host "Build complete! You can now run 'terraform apply'." -ForegroundColor Green