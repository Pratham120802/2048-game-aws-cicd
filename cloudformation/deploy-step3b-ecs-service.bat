@echo off
REM Deploy ECS Service with Application Load Balancer
REM This must be deployed before CodePipeline

setlocal enabledelayedexpansion

set STACK_NAME=game2048-ecs-service
set PROJECT_NAME=game2048
set ENVIRONMENT=production
set TEMPLATE_FILE=03-ecs-service.yaml

echo ================================================
echo Deploying ECS Service and Load Balancer
echo ================================================
echo Stack Name: %STACK_NAME%
echo Project: %PROJECT_NAME%
echo Environment: %ENVIRONMENT%
echo.
echo This will create:
echo - VPC with public subnets
echo - Application Load Balancer
echo - ECS Task Definition
echo - ECS Service (runs your container)
echo.

aws sts get-caller-identity >nul 2>&1
if errorlevel 1 (
    echo Error: AWS credentials are not configured
    exit /b 1
)

echo Creating stack...
aws cloudformation create-stack ^
    --stack-name %STACK_NAME% ^
    --template-body file://%TEMPLATE_FILE% ^
    --capabilities CAPABILITY_IAM ^
    --parameters ^
        ParameterKey=ProjectName,ParameterValue=%PROJECT_NAME% ^
        ParameterKey=Environment,ParameterValue=%ENVIRONMENT%

echo.
echo Waiting for stack creation to complete (this may take 5-10 minutes)...
aws cloudformation wait stack-create-complete --stack-name %STACK_NAME%

if errorlevel 1 (
    echo [ERROR] Stack creation failed
    echo Checking events...
    aws cloudformation describe-stack-events --stack-name %STACK_NAME% --max-items 10
    exit /b 1
)

echo [SUCCESS] Stack created successfully!
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
echo Application URL:
echo ================================================

for /f "tokens=*" %%i in ('aws cloudformation describe-stacks --stack-name %STACK_NAME% --query "Stacks[0].Outputs[?OutputKey==`LoadBalancerURL`].OutputValue" --output text') do set APP_URL=%%i

echo.
echo Your 2048 game is deploying at: %APP_URL%
echo.
echo Note: It may take 2-3 minutes for the service to become healthy.
echo.
echo [SUCCESS] ECS Service deployed!

endlocal
