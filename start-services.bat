@echo off
REM Restart all stopped services

setlocal enabledelayedexpansion

echo ================================================
echo Starting AWS Services
echo ================================================
echo.
echo This will restart:
echo - ECS Service (start containers)
echo - CodePipeline (re-enable automatic deployments)
echo.
set /p CONFIRM="Continue? (yes/no): "

if /i not "%CONFIRM%"=="yes" (
    echo Cancelled.
    exit /b 0
)

echo.
echo Starting services...
echo.

REM Start ECS Service
echo [1/2] Starting ECS Service...
aws ecs update-service --cluster game2048-cluster-production --service game2048-service-production --desired-count 1 >nul 2>&1

if errorlevel 1 (
    echo [INFO] ECS service not found or already running
) else (
    echo [SUCCESS] ECS Service started (desired count set to 1)
    echo Waiting for tasks to start (this takes 2-3 minutes)...
    timeout /t 10 >nul
)

REM Enable CodePipeline
echo [2/2] Enabling CodePipeline...
aws codepipeline enable-stage-transition --pipeline-name game2048-pipeline-production --stage-name Source --transition-type Inbound >nul 2>&1

if errorlevel 1 (
    echo [INFO] CodePipeline not found
) else (
    echo [SUCCESS] CodePipeline enabled
)

echo.
echo ================================================
echo Services Started Successfully!
echo ================================================
echo.
echo Your application is starting up...
echo.
echo To check status:
echo   aws ecs describe-services --cluster game2048-cluster-production --services game2048-service-production
echo.
echo To get your application URL:
echo   aws cloudformation describe-stacks --stack-name game2048-ecs-service --query "Stacks[0].Outputs[?OutputKey=='LoadBalancerURL'].OutputValue" --output text
echo.
echo Note: It takes 2-3 minutes for the application to become healthy.

endlocal
