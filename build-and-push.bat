@echo off
REM Build and Push Docker Image to ECR
REM This script builds the 2048 game Docker image and pushes it to Amazon ECR

setlocal enabledelayedexpansion

REM Configuration
REM Account ID is fetched dynamically so it is never hardcoded
set AWS_REGION=us-east-1
set ECR_REPOSITORY=game2048-production
set IMAGE_TAG=latest
for /f "tokens=*" %%i in ('aws sts get-caller-identity --query Account --output text') do set AWS_ACCOUNT_ID=%%i
set ECR_REGISTRY=%AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com

echo ================================================
echo Building and Pushing 2048 Game to ECR
echo ================================================
echo Registry: %ECR_REGISTRY%
echo Repository: %ECR_REPOSITORY%
echo Region: %AWS_REGION%
echo Tag: %IMAGE_TAG%
echo.

REM Check if Docker is running
docker info >nul 2>&1
if errorlevel 1 (
    echo Error: Docker is not running
    echo Please start Docker Desktop and try again
    exit /b 1
)

REM Authenticate Docker to ECR
echo Step 1: Authenticating Docker with ECR...
for /f "tokens=*" %%i in ('aws ecr get-login-password --region %AWS_REGION%') do set ECR_PASSWORD=%%i
echo !ECR_PASSWORD! | docker login --username AWS --password-stdin %ECR_REGISTRY%

if errorlevel 1 (
    echo Error: Failed to authenticate with ECR
    exit /b 1
)
echo [SUCCESS] Authentication successful
echo.

REM Build the Docker image
echo Step 2: Building Docker image...
cd app
docker build -t game2048:%IMAGE_TAG% .

if errorlevel 1 (
    echo Error: Failed to build Docker image
    cd ..
    exit /b 1
)
echo [SUCCESS] Docker image built successfully
cd ..
echo.

REM Tag the image for ECR
echo Step 3: Tagging image for ECR...
docker tag game2048:%IMAGE_TAG% %ECR_REGISTRY%/%ECR_REPOSITORY%:%IMAGE_TAG%

REM Create timestamped tag
for /f "tokens=2 delims==" %%i in ('wmic os get localdatetime /value') do set datetime=%%i
set BUILD_TAG=build-%datetime:~0,8%-%datetime:~8,6%
docker tag game2048:%IMAGE_TAG% %ECR_REGISTRY%/%ECR_REPOSITORY%:%BUILD_TAG%

echo [SUCCESS] Image tagged
echo Tags: latest, %BUILD_TAG%
echo.

REM Push to ECR
echo Step 4: Pushing image to ECR...
docker push %ECR_REGISTRY%/%ECR_REPOSITORY%:%IMAGE_TAG%

if errorlevel 1 (
    echo Error: Failed to push image to ECR
    exit /b 1
)

docker push %ECR_REGISTRY%/%ECR_REPOSITORY%:%BUILD_TAG%

echo [SUCCESS] Image pushed to ECR successfully
echo.

echo ================================================
echo Success!
echo ================================================
echo Image: %ECR_REGISTRY%/%ECR_REPOSITORY%:%IMAGE_TAG%
echo Build tag: %ECR_REGISTRY%/%ECR_REPOSITORY%:%BUILD_TAG%
echo.
echo To verify, run:
echo aws ecr describe-images --repository-name %ECR_REPOSITORY% --region %AWS_REGION%
echo.
echo [SUCCESS] Step 2 completed successfully!

endlocal
