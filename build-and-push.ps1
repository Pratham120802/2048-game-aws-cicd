# Build and Push Docker Image to ECR
# PowerShell script for Windows

# Configuration
$ECR_REGISTRY = "825184644172.dkr.ecr.us-east-1.amazonaws.com"
$ECR_REPOSITORY = "game2048-production"
$AWS_REGION = "us-east-1"
$IMAGE_TAG = "latest"

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Building and Pushing 2048 Game to ECR" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Registry: $ECR_REGISTRY"
Write-Host "Repository: $ECR_REPOSITORY"
Write-Host "Region: $AWS_REGION"
Write-Host "Tag: $IMAGE_TAG"
Write-Host ""

# Check if Docker is running
try {
    docker info | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Docker is not running"
    }
} catch {
    Write-Host "Error: Docker is not running" -ForegroundColor Red
    Write-Host "Please start Docker Desktop and try again"
    exit 1
}

# Step 1: Authenticate Docker to ECR
Write-Host "Step 1: Authenticating Docker with ECR..." -ForegroundColor Yellow
try {
    $loginCommand = aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY
    if ($LASTEXITCODE -ne 0) {
        throw "Authentication failed"
    }
    Write-Host "[SUCCESS] Authentication successful" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "Error: Failed to authenticate with ECR" -ForegroundColor Red
    Write-Host "Details: $_" -ForegroundColor Red
    exit 1
}

# Step 2: Build the Docker image
Write-Host "Step 2: Building Docker image..." -ForegroundColor Yellow
Push-Location app
try {
    docker build -t game2048:$IMAGE_TAG .
    if ($LASTEXITCODE -ne 0) {
        throw "Build failed"
    }
    Write-Host "[SUCCESS] Docker image built successfully" -ForegroundColor Green
} catch {
    Write-Host "Error: Failed to build Docker image" -ForegroundColor Red
    Pop-Location
    exit 1
}
Pop-Location
Write-Host ""

# Step 3: Tag the image for ECR
Write-Host "Step 3: Tagging image for ECR..." -ForegroundColor Yellow
docker tag game2048:$IMAGE_TAG "$ECR_REGISTRY/${ECR_REPOSITORY}:$IMAGE_TAG"

# Create timestamped tag
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$BUILD_TAG = "build-$timestamp"
docker tag game2048:$IMAGE_TAG "$ECR_REGISTRY/${ECR_REPOSITORY}:$BUILD_TAG"

Write-Host "[SUCCESS] Image tagged" -ForegroundColor Green
Write-Host "Tags: latest, $BUILD_TAG"
Write-Host ""

# Step 4: Push to ECR
Write-Host "Step 4: Pushing image to ECR..." -ForegroundColor Yellow
try {
    Write-Host "Pushing latest tag..."
    docker push "$ECR_REGISTRY/${ECR_REPOSITORY}:$IMAGE_TAG"
    if ($LASTEXITCODE -ne 0) {
        throw "Push failed"
    }
    
    Write-Host "Pushing build tag..."
    docker push "$ECR_REGISTRY/${ECR_REPOSITORY}:$BUILD_TAG"
    
    Write-Host "[SUCCESS] Image pushed to ECR successfully" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "Error: Failed to push image to ECR" -ForegroundColor Red
    exit 1
}

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Success!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Image: $ECR_REGISTRY/${ECR_REPOSITORY}:$IMAGE_TAG"
Write-Host "Build tag: $ECR_REGISTRY/${ECR_REPOSITORY}:$BUILD_TAG"
Write-Host ""
Write-Host "To verify, run:"
Write-Host "aws ecr describe-images --repository-name $ECR_REPOSITORY --region $AWS_REGION"
Write-Host ""
Write-Host "[SUCCESS] Step 2 completed successfully!" -ForegroundColor Green
