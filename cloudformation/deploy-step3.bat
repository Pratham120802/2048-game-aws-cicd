@echo off
REM Step 3: Deploy CodeBuild Project
REM This script creates the CodeBuild project for building Docker images

setlocal enabledelayedexpansion

REM Configuration
set STACK_NAME=game2048-codebuild-project
set PROJECT_NAME=game2048
set ENVIRONMENT=production
set TEMPLATE_FILE=02-codebuild-project.yaml

echo ================================================
echo Deploying Step 3: CodeBuild Project
echo ================================================
echo Stack Name: %STACK_NAME%
echo Project: %PROJECT_NAME%
echo Environment: %ENVIRONMENT%
echo.

REM Prompt for GitHub repository URL
set /p GITHUB_REPO="Enter your GitHub repository URL (e.g., https://github.com/username/2048-game): "
if "%GITHUB_REPO%"=="" (
    echo Error: GitHub repository URL is required
    exit /b 1
)

REM Prompt for GitHub branch
set /p GITHUB_BRANCH="Enter GitHub branch [main]: "
if "%GITHUB_BRANCH%"=="" set GITHUB_BRANCH=main

echo.
echo GitHub Repository: %GITHUB_REPO%
echo GitHub Branch: %GITHUB_BRANCH%
echo.

REM Check if AWS CLI is installed
aws --version >nul 2>&1
if errorlevel 1 (
    echo Error: AWS CLI is not installed
    exit /b 1
)

REM Check if AWS credentials are configured
aws sts get-caller-identity >nul 2>&1
if errorlevel 1 (
    echo Error: AWS credentials are not configured
    exit /b 1
)

echo AWS Account: 
for /f "tokens=*" %%i in ('aws sts get-caller-identity --query Account --output text') do echo %%i

echo AWS Region: 
for /f "tokens=*" %%i in ('aws configure get region') do echo %%i
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
            --capabilities CAPABILITY_IAM ^
            --parameters ^
                ParameterKey=ProjectName,ParameterValue=%PROJECT_NAME% ^
                ParameterKey=Environment,ParameterValue=%ENVIRONMENT% ^
                ParameterKey=GitHubRepo,ParameterValue=%GITHUB_REPO% ^
                ParameterKey=GitHubBranch,ParameterValue=%GITHUB_BRANCH%
        
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
        --capabilities CAPABILITY_IAM ^
        --parameters ^
            ParameterKey=ProjectName,ParameterValue=%PROJECT_NAME% ^
            ParameterKey=Environment,ParameterValue=%ENVIRONMENT% ^
            ParameterKey=GitHubRepo,ParameterValue=%GITHUB_REPO% ^
            ParameterKey=GitHubBranch,ParameterValue=%GITHUB_BRANCH%
    
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

for /f "tokens=*" %%i in ('aws cloudformation describe-stacks --stack-name %STACK_NAME% --query "Stacks[0].Outputs[?OutputKey==`CodeBuildProjectName`].OutputValue" --output text') do set BUILD_PROJECT=%%i

echo CodeBuild Project: %BUILD_PROJECT%
echo.
echo To start a build manually, run:
echo aws codebuild start-build --project-name %BUILD_PROJECT%
echo.
echo [SUCCESS] Step 3 completed successfully!
echo.
echo Next Steps:
echo 1. Push your code to GitHub repository: %GITHUB_REPO%
echo 2. Make sure buildspec.yml is in the root of your repository
echo 3. CodeBuild will automatically build when you push code

endlocal
