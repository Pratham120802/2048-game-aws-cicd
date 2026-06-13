@echo off
REM Step 1: Deploy ECS Cluster and ECR Repository
REM This script creates the foundational infrastructure for the 2048 Game CI/CD Pipeline

setlocal enabledelayedexpansion

REM Configuration
set STACK_NAME=game2048-ecr-ecs-setup
set PROJECT_NAME=game2048
set ENVIRONMENT=production
set TEMPLATE_FILE=01-ecr-ecs-setup.yaml

echo ================================================
echo Deploying Step 1: ECS Cluster and ECR Repository
echo ================================================
echo Stack Name: %STACK_NAME%
echo Project: %PROJECT_NAME%
echo Environment: %ENVIRONMENT%
echo.

REM Check if AWS CLI is installed
aws --version >nul 2>&1
if errorlevel 1 (
    echo Error: AWS CLI is not installed
    echo Please install it from: https://aws.amazon.com/cli/
    exit /b 1
)

REM Check if AWS credentials are configured
aws sts get-caller-identity >nul 2>&1
if errorlevel 1 (
    echo Error: AWS credentials are not configured
    echo Please run: aws configure
    exit /b 1
)

for /f "tokens=*" %%i in ('aws sts get-caller-identity --query Account --output text') do set AWS_ACCOUNT=%%i
for /f "tokens=*" %%i in ('aws configure get region') do set AWS_REGION=%%i

echo AWS Account: %AWS_ACCOUNT%
echo AWS Region: %AWS_REGION%
echo.

REM Check if stack already exists
aws cloudformation describe-stacks --stack-name %STACK_NAME% >nul 2>&1
if not errorlevel 1 (
    echo Stack %STACK_NAME% already exists!
    set /p UPDATE_CHOICE="Do you want to update it? (yes/no): "
    
    if /i "!UPDATE_CHOICE!"=="yes" (
        echo Updating stack...
        aws cloudformation update-stack ^
            --stack-name %STACK_NAME% ^
            --template-body file://%TEMPLATE_FILE% ^
            --capabilities CAPABILITY_NAMED_IAM ^
            --parameters ^
                ParameterKey=ProjectName,ParameterValue=%PROJECT_NAME% ^
                ParameterKey=Environment,ParameterValue=%ENVIRONMENT%
        
        echo Waiting for stack update to complete...
        aws cloudformation wait stack-update-complete --stack-name %STACK_NAME%
        echo [SUCCESS] Stack updated successfully!
    ) else (
        echo Skipping update.
        exit /b 0
    )
) else (
    echo Creating new stack...
    aws cloudformation create-stack ^
        --stack-name %STACK_NAME% ^
        --template-body file://%TEMPLATE_FILE% ^
        --capabilities CAPABILITY_NAMED_IAM ^
        --parameters ^
            ParameterKey=ProjectName,ParameterValue=%PROJECT_NAME% ^
            ParameterKey=Environment,ParameterValue=%ENVIRONMENT%
    
    echo Waiting for stack creation to complete...
    aws cloudformation wait stack-create-complete --stack-name %STACK_NAME%
    echo [SUCCESS] Stack created successfully!
)

echo.
echo ================================================
echo Stack Outputs:
echo ================================================

REM Get and display stack outputs
aws cloudformation describe-stacks ^
    --stack-name %STACK_NAME% ^
    --query "Stacks[0].Outputs[*].[OutputKey,OutputValue]" ^
    --output table

echo.
echo ================================================
echo Important Information:
echo ================================================

REM Get ECR Repository URI
for /f "tokens=*" %%i in ('aws cloudformation describe-stacks --stack-name %STACK_NAME% --query "Stacks[0].Outputs[?OutputKey==`ECRRepositoryUri`].OutputValue" --output text') do set ECR_URI=%%i

for /f "tokens=*" %%i in ('aws cloudformation describe-stacks --stack-name %STACK_NAME% --query "Stacks[0].Outputs[?OutputKey==`ECSClusterName`].OutputValue" --output text') do set ECS_CLUSTER=%%i

echo ECR Repository URI: %ECR_URI%
echo ECS Cluster Name: %ECS_CLUSTER%
echo.
echo Save these values for the next steps!
echo.
echo To authenticate Docker with ECR, run:
echo aws ecr get-login-password --region %AWS_REGION% ^| docker login --username AWS --password-stdin %ECR_URI%
echo.
echo [SUCCESS] Step 1 completed successfully!

endlocal
