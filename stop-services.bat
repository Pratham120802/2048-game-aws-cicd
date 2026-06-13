@echo off
REM Temporarily stop all running services to save costs
REM You can restart them later with start-services.bat

setlocal enabledelayedexpansion

echo ================================================
echo Stopping AWS Services Temporarily
echo ================================================
echo.
echo This will stop:
echo - ECS Service (stops running containers)
echo - CodePipeline (disables automatic deployments)
echo.
echo You can restart everything later with start-services.bat
echo.
set /p CONFIRM="Continue? (yes/no): "

if /i not "%CONFIRM%"=="yes" (
    echo Cancelled.
    exit /b 0
)

echo.
echo Stopping services...
echo.

REM Check if services exist
aws ecs describe-services --cluster game2048-cluster-production --services game2048-service-production >nul 2>&1
if errorlevel 1 (
    echo [INFO] ECS service not found. Nothing to stop.
    echo.
    echo It looks like you haven't deployed the services yet.
    echo You only have ECR repository and ECS cluster from Step 1.
    echo.
    echo No charges are being incurred for:
    echo - Empty ECR repository: FREE
    echo - Empty ECS cluster: FREE
    echo - S3 buckets with minimal data: ~$0.01/month
    echo.
    echo You're safe! No action needed.
    exit /b 0
)

REM Stop ECS Service
echo [1/2] Stopping ECS Service (containers)...
aws ecs update-service --cluster game2048-cluster-production --service game2048-service-production --desired-count 0 >nul 2>&1

if errorlevel 1 (
    echo [INFO] ECS service not running or doesn't exist
) else (
    echo [SUCCESS] ECS Service stopped (desired count set to 0)
)

REM Disable CodePipeline
echo [2/2] Disabling CodePipeline...
aws codepipeline list-pipelines --query "pipelines[?name=='game2048-pipeline-production'].name" --output text >nul 2>&1
if not errorlevel 1 (
    echo [INFO] To disable CodePipeline, delete the GitHub webhook or stop transitions:
    echo Run: aws codepipeline disable-stage-transition --pipeline-name game2048-pipeline-production --stage-name Source --transition-type Inbound --reason "Temporarily stopped"
    aws codepipeline disable-stage-transition --pipeline-name game2048-pipeline-production --stage-name Source --transition-type Inbound --reason "Temporarily stopped" >nul 2>&1
    echo [SUCCESS] CodePipeline disabled
) else (
    echo [INFO] CodePipeline not found
)

echo.
echo ================================================
echo Services Stopped Successfully!
echo ================================================
echo.
echo What's stopped:
echo [x] ECS containers (no longer running)
echo [x] CodePipeline (won't trigger on git push)
echo.
echo What's still active (minimal cost):
echo - ECR repository: ~$0.10/month for stored images
echo - S3 buckets: ~$0.05/month for artifacts
echo - Load Balancer (if deployed): ~$16/month
echo - ECS Cluster: FREE (no charges when no tasks running)
echo.
echo Monthly cost while stopped: ~$0.15 - $16 depending on what was deployed
echo.
echo To restart everything:
echo   start-services.bat
echo.
echo To delete everything completely:
echo   cleanup-all.bat

endlocal
