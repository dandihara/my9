@echo off
setlocal EnableExtensions

set "APP_DIR=%~dp0"
set "ROOT_ENV=%APP_DIR%..\.env"
set "LOCAL_API_URL=%MY9_LOCAL_API_URL%"
set "EXTERNAL_API_URL=%MY9_EXTERNAL_API_URL%"

if exist "%ROOT_ENV%" (
  for /f "usebackq tokens=1,* delims==" %%A in ("%ROOT_ENV%") do (
    if /I "%%A"=="MY9_LOCAL_API_URL" if not defined LOCAL_API_URL set "LOCAL_API_URL=%%B"
    if /I "%%A"=="MY9_EXTERNAL_API_URL" if not defined EXTERNAL_API_URL set "EXTERNAL_API_URL=%%B"
  )
)

if not "%~1"=="" set "LOCAL_API_URL=%~1"
if not "%~2"=="" set "EXTERNAL_API_URL=%~2"

if "%LOCAL_API_URL%"=="" (
  echo [ERROR] Set MY9_LOCAL_API_URL or pass the local API URL as argument 1.
  exit /b 1
)
if "%EXTERNAL_API_URL%"=="" (
  echo [ERROR] Set MY9_EXTERNAL_API_URL or pass the external API URL as argument 2.
  exit /b 1
)

where flutter >nul 2>&1
if errorlevel 1 (
  echo [ERROR] flutter command was not found in PATH.
  exit /b 1
)

pushd "%APP_DIR%"
if errorlevel 1 exit /b 1

echo [1/2] Building local API debug APK...
call flutter build apk --debug --dart-define=API_BASE_URL=%LOCAL_API_URL%
if errorlevel 1 goto :failed
copy /Y "build\app\outputs\flutter-apk\app-debug.apk" "build\app\outputs\flutter-apk\MY9-local-debug.apk" >nul
if errorlevel 1 goto :failed

echo [2/2] Building external API debug APK...
call flutter build apk --debug --dart-define=API_BASE_URL=%EXTERNAL_API_URL%
if errorlevel 1 goto :failed
copy /Y "build\app\outputs\flutter-apk\app-debug.apk" "build\app\outputs\flutter-apk\MY9-external-debug.apk" >nul
if errorlevel 1 goto :failed

echo.
echo Build complete:
echo   %APP_DIR%build\app\outputs\flutter-apk\MY9-local-debug.apk
echo   %APP_DIR%build\app\outputs\flutter-apk\MY9-external-debug.apk
popd
exit /b 0

:failed
echo [ERROR] APK build failed.
popd
exit /b 1
