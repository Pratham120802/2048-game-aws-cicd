@echo off
REM Deploy CodePipeline - Final Step!
REM This creates the complete CI/CD pipeline

setlocal enabledelayedexpansion

set STACK_NAME=game2048-codepipeline
set PROJECT_NAME=game2048
set ENVIRONMENT=production
set TEMPLATE_FILE=04-codepipeline.yaml

echo ================================================
echo Deploying Step 4: AWS CodePipeline
echo ================================================
echo Stack Name: %STACK_NAME%
echo Project: %PROJECT_NAME%
echo Environment: %ENVIRONMENT%
echo.

REM Prompt for GitHub information
set /p GITHUB_REPO="Enter GitHub repository (format: username/repo-name): "
if "%GITHUB_REPO%"=="" (
    echo Error: GitHub repository is required
    exit /b 1
)

set /p GITHUB_BRANCH="Enter GitHub branch [main]: "
if "%GITHUB_BRANCH%"=="" set GITHUB_BRANCH=main

echo.
echo ================================================
echo GitHub Personal Access Token Required
echo ================================================
echo.
echo CodePipeline needs a GitHub Personal Access Token to:
echo - Detect code changes in your repository
echo - Trigger builds automatically
echo.
echo To create a token:
echo 1. Go to: https://github.com/settings/tokens
echo 2. Click "Generate new token" ^> "Generate new token (classic)"
echo 3. Name: AWS CodePipeline
echo 4. Scopes: Check "repo" (full control)
echo 5. Click "Generate token"
echo 6. Copy the token
echo.
set /p GITHUB_TOKEN="Paste your GitHub token: "
if "%GITHUB_TOKEN%"=="" (
    echo Error: GitHub token is required
    exit /b 1
)

echo.
echo GitHub Repo: %GITHUB_REPO%
echo GitHub Branch: %GITHUB_BRANCH%
echo.

aws sts get-caller-identity >nul 2>&1
if errorlevel 1 (
    echo Error: AWS credentials are not configured
    exit /b 1
)

echo Creating CodePipeline stack...
aws cloudformation create-stack ^
    --stack-name %STACK_NAME% ^
    --template-body file://%TEMPLATE_FILE% ^
    --capabilities CAPABILITY_IAM ^
    --parameters ^
        ParameterKey=ProjectName,ParameterValue=%PROJECT_NAME% ^
        ParameterKey=Environment,ParameterValue=%ENVIRONMENT% ^
        ParameterKey=GitHubRepo,ParameterValue=%GITHUB_REPO% ^
        ParameterKey=GitHubBranch,ParameterValue=%GITHUB_BRANCH% ^
        ParameterKey=GitHubToken,ParameterValue=%GITHUB_TOKEN%

echo.
echo Waiting for stack creation to complete...
aws cloudformation wait stack-create-complete --stack-name %STACK_NAME%

if errorlevel 1 (
    echo [ERROR] Stack creation failed
    exit /b 1
)

echo [SUCCESS] CodePipeline created successfully!
echo.
echo ================================================
echo Stack Outputs:
echo ================================================

aws cloudformation describe-stacks ^
    --stack-name %STACK_NAME% ^
    --query "Stacks[0].Outputs[*].[OutputKey,OutputValue]" ^
    --output table

echo.
echo ================================================
echo Pipeline Information:
echo ================================================

for /f "tokens=*" %%i in ('aws cloudformation describe-stacks --stack-name %STACK_NAME% --query "Stacks[0].Outputs[?OutputKey==`PipelineUrl`].OutputValue" --output text') do set PIPELINE_URL=%%i

echo.
echo Pipeline Console: %PIPELINE_URL%
echo.
echo ================================================
echo Success! CI/CD Pipeline is Complete!
echo ================================================
echo.
echo The pipeline will now:
echo 1. Monitor your GitHub repository for changes
echo 2. Automatically build Docker images when you push code
echo 3. Deploy new images to ECS
echo.
echo To test the pipeline:
echo 1. Make a change to your code
echo 2. Push to GitHub: git push
echo 3. Watch the pipeline execute automatically!
echo.
echo [SUCCESS] Step 4 completed!

endlocal
