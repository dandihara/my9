@echo off
setlocal EnableExtensions

set "PROJECT_DIR=%~dp0"
set "IMAGE_TAG=%~1"
if "%IMAGE_TAG%"=="" set "IMAGE_TAG=latest"

if "%AWS_ACCOUNT_ID%"=="" (
  echo [ERROR] Set AWS_ACCOUNT_ID first.
  echo Example: set AWS_ACCOUNT_ID=123456789012
  exit /b 1
)
if "%AWS_REGION%"=="" (
  echo [ERROR] Set AWS_REGION first.
  echo Example: set AWS_REGION=ap-northeast-2
  exit /b 1
)
if "%API_ECR_REPOSITORY%"=="" set "API_ECR_REPOSITORY=seungyo-api-server"
if "%WORKER_ECR_REPOSITORY%"=="" set "WORKER_ECR_REPOSITORY=seungyo-data-worker"

where aws >nul 2>&1
if errorlevel 1 (
  echo [ERROR] AWS CLI was not found in PATH.
  exit /b 1
)
where docker >nul 2>&1
if errorlevel 1 (
  echo [ERROR] Docker was not found in PATH.
  exit /b 1
)

set "ECR_HOST=%AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com"
set "API_IMAGE=%ECR_HOST%/%API_ECR_REPOSITORY%:%IMAGE_TAG%"
set "WORKER_IMAGE=%ECR_HOST%/%WORKER_ECR_REPOSITORY%:%IMAGE_TAG%"

echo Checking AWS identity...
aws sts get-caller-identity >nul
if errorlevel 1 goto :failed

echo Ensuring ECR repositories exist...
aws ecr describe-repositories --region "%AWS_REGION%" --repository-names "%API_ECR_REPOSITORY%" >nul 2>&1
if errorlevel 1 aws ecr create-repository --region "%AWS_REGION%" --repository-name "%API_ECR_REPOSITORY%" --image-scanning-configuration scanOnPush=true >nul
if errorlevel 1 goto :failed
aws ecr describe-repositories --region "%AWS_REGION%" --repository-names "%WORKER_ECR_REPOSITORY%" >nul 2>&1
if errorlevel 1 aws ecr create-repository --region "%AWS_REGION%" --repository-name "%WORKER_ECR_REPOSITORY%" --image-scanning-configuration scanOnPush=true >nul
if errorlevel 1 goto :failed

echo Logging in to %ECR_HOST%...
aws ecr get-login-password --region "%AWS_REGION%" | docker login --username AWS --password-stdin "%ECR_HOST%"
if errorlevel 1 goto :failed

echo Building API image...
docker build --pull -t "%API_IMAGE%" -f "%PROJECT_DIR%api-server\Dockerfile" "%PROJECT_DIR%api-server"
if errorlevel 1 goto :failed

echo Building data-worker image...
docker build --pull -t "%WORKER_IMAGE%" -f "%PROJECT_DIR%data-worker\Dockerfile" "%PROJECT_DIR%data-worker"
if errorlevel 1 goto :failed

echo Pushing API image...
docker push "%API_IMAGE%"
if errorlevel 1 goto :failed

echo Pushing data-worker image...
docker push "%WORKER_IMAGE%"
if errorlevel 1 goto :failed

echo.
echo Published:
echo   %API_IMAGE%
echo   %WORKER_IMAGE%
exit /b 0

:failed
echo [ERROR] ECR image deployment failed.
exit /b 1
