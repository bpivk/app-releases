@echo off
setlocal enabledelayedexpansion

echo.
echo ==================================================
echo   Build ^& Release Publisher
echo ==================================================
echo.

:: ---------- Inputs ----------
set /p "APP_NAME=Script name (without .py): "
set /p "REPO_FOLDER=Release subfolder in app-releases (e.g. avery): "
set /p "EXE_DISPLAY=Exe name (without .exe, Enter = same as script name): "
if "!EXE_DISPLAY!"=="" set "EXE_DISPLAY=!APP_NAME!"

set "SCRIPT=!APP_NAME!.py"
set "EXE_FILE=!EXE_DISPLAY!.exe"
set "DIST_EXE=dist/!EXE_FILE!"
set "RELEASES_REPO=bpivk/app-releases"

echo.
echo   Script  : !SCRIPT!
echo   Output  : !EXE_FILE!
echo   Publish : github.com/!RELEASES_REPO!/!REPO_FOLDER!/
echo.

if not exist "!SCRIPT!" (
    echo ERROR: !SCRIPT! not found in the current directory.
    echo        Run this script from the folder that contains !SCRIPT!
    pause & exit /b 1
)

set "HELPER=%~dp0helper.py"
echo   Helper  : !HELPER!
echo.

if not exist "!HELPER!" (
    echo ERROR: helper.py not found.
    echo        helper.py must be in the same folder as build_and_release.bat
    pause & exit /b 1
)

echo Press any key to start, or Ctrl+C to cancel...
pause >nul

echo.
echo [1/3] Fetching version ^& patching source...
echo [2/3] Building with PyInstaller...
echo [3/3] Publishing to app-releases...
echo.

py "!HELPER!" "!RELEASES_REPO!" "!REPO_FOLDER!" "!EXE_FILE!" "!DIST_EXE!" "!SCRIPT!" "!EXE_DISPLAY!"
set "PY_EXIT=!errorlevel!"

echo.
echo Helper exited with code: !PY_EXIT!
echo.

if !PY_EXIT! neq 0 (
    echo ERROR: Build or publishing failed. See above for details.
    pause & exit /b 1
)

echo ==================================================
echo   All done!
echo ==================================================
echo.
pause
