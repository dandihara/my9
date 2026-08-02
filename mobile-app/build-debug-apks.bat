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

echo [1/3] Building local API arm64 debug APK...
call flutter build apk --debug --split-per-abi --dart-define=API_BASE_URL=%LOCAL_API_URL% --dart-define=DOOSAN_SECTION_THEME=cheolwoong
if errorlevel 1 goto :failed
copy /Y "build\app\outputs\flutter-apk\app-arm64-v8a-debug.apk" "build\app\outputs\flutter-apk\MY9-local-arm64-debug.apk" >nul
if errorlevel 1 goto :failed

echo [2/3] Building external API arm64 debug APK with Cheolwoong Doosan sections...
call flutter build apk --debug --split-per-abi --dart-define=API_BASE_URL=%EXTERNAL_API_URL% --dart-define=DOOSAN_SECTION_THEME=cheolwoong
if errorlevel 1 goto :failed
copy /Y "build\app\outputs\flutter-apk\app-arm64-v8a-debug.apk" "build\app\outputs\flutter-apk\MY9-external-cheolwoong-arm64-debug.apk" >nul
if errorlevel 1 goto :failed

echo [3/3] Building external API arm64 debug APK with Mangom Doosan sections...
call flutter build apk --debug --split-per-abi --dart-define=API_BASE_URL=%EXTERNAL_API_URL% --dart-define=DOOSAN_SECTION_THEME=mangom
if errorlevel 1 goto :failed
copy /Y "build\app\outputs\flutter-apk\app-arm64-v8a-debug.apk" "build\app\outputs\flutter-apk\MY9-external-mangom-arm64-debug.apk" >nul
if errorlevel 1 goto :failed

echo.
echo Build complete:
echo   %APP_DIR%build\app\outputs\flutter-apk\MY9-local-arm64-debug.apk
echo   %APP_DIR%build\app\outputs\flutter-apk\MY9-external-cheolwoong-arm64-debug.apk
echo   %APP_DIR%build\app\outputs\flutter-apk\MY9-external-mangom-arm64-debug.apk
popd
exit /b 0

:failed
echo [ERROR] APK build failed.
popd
exit /b 1
