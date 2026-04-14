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
set "DIST_EXE=dist\!EXE_FILE!"
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

echo Press any key to build, or Ctrl+C to cancel...
pause >nul

:: ---------- Step 1: PyInstaller ----------
echo.
echo [1/3] Building !EXE_FILE! with PyInstaller...
echo.
pyinstaller --onefile --noconsole --clean --name "!EXE_DISPLAY!" "!SCRIPT!"
if errorlevel 1 (
    echo.
    echo ERROR: PyInstaller build failed.
    pause & exit /b 1
)
if not exist "!DIST_EXE!" (
    echo.
    echo ERROR: Expected output not found at !DIST_EXE!
    pause & exit /b 1
)
echo.
echo Build OK: !DIST_EXE!

:: ---------- Step 2+3: Version bump + GitHub publish ----------
echo.
echo [2/3] Fetching current version from app-releases...
echo [3/3] Publishing exe and version.txt...
echo.

:: Decode the embedded Python helper from base64 and write it to a temp file
set "PY_HELPER=%TEMP%\release_pub.py"
set "PY_B64=aW1wb3J0IGJhc2U2NCwganNvbiwgc3VicHJvY2Vzcywgc3lzLCBvcywgdGVtcGZpbGUKClJFUE8gICAgID0gc3lzLmFyZ3ZbMV0KRk9MREVSICAgPSBzeXMuYXJndlsyXQpFWEVfRklMRSA9IHN5cy5hcmd2WzNdCkRJU1RfRVhFID0gc3lzLmFyZ3ZbNF0KClZFUl9QQVRIID0gRk9MREVSICsgIi92ZXJzaW9uLnR4dCIKRVhFX1BBVEggPSBGT0xERVIgKyAiLyIgKyBFWEVfRklMRQoKZGVmIGdoX2dldChwYXRoKToKICAgIHIgPSBzdWJwcm9jZXNzLnJ1bihbImdoIiwiYXBpIiwicmVwb3MvIitSRVBPKyIvY29udGVudHMvIitwYXRoXSwKICAgICAgICBjYXB0dXJlX291dHB1dD1UcnVlLCB0ZXh0PVRydWUpCiAgICBpZiByLnJldHVybmNvZGUgIT0gMDogcmV0dXJuIE5vbmUsIE5vbmUKICAgIGQgPSBqc29uLmxvYWRzKHIuc3Rkb3V0KQogICAgY29udGVudCA9IGJhc2U2NC5iNjRkZWNvZGUoZFsiY29udGVudCJdLnJlcGxhY2UoIlxuIiwiIikpLmRlY29kZSgpLnN0cmlwKCkKICAgIHJldHVybiBjb250ZW50LCBkWyJzaGEiXQoKZGVmIGdoX3B1dChwYXRoLCBtc2csIGRhdGEsIHNoYT1Ob25lKToKICAgIHBheWxvYWQgPSB7Im1lc3NhZ2UiOiBtc2csICJjb250ZW50IjogYmFzZTY0LmI2NGVuY29kZShkYXRhKS5kZWNvZGUoKX0KICAgIGlmIHNoYTogcGF5bG9hZFsic2hhIl0gPSBzaGEKICAgIHRtcCA9IHRlbXBmaWxlLk5hbWVkVGVtcG9yYXJ5RmlsZShkZWxldGU9RmFsc2UsIHN1ZmZpeD0iLmpzb24iLCBtb2RlPSJ3IikKICAgIGpzb24uZHVtcChwYXlsb2FkLCB0bXApCiAgICB0bXAuY2xvc2UoKQogICAgciA9IHN1YnByb2Nlc3MucnVuKAogICAgICAgIFsiZ2giLCJhcGkiLCJyZXBvcy8iK1JFUE8rIi9jb250ZW50cy8iK3BhdGgsCiAgICAgICAgICItLW1ldGhvZCIsIlBVVCIsIi0taW5wdXQiLHRtcC5uYW1lLCItLWpxIiwiLmNvbW1pdC5zaGEiXSwKICAgICAgICBjYXB0dXJlX291dHB1dD1UcnVlLCB0ZXh0PVRydWUpCiAgICBvcy51bmxpbmsodG1wLm5hbWUpCiAgICBpZiByLnJldHVybmNvZGUgIT0gMDoKICAgICAgICBzeXMuc3RkZXJyLndyaXRlKCJFUlJPUjogIiArIHIuc3RkZXJyICsgIlxuIikKICAgICAgICBzeXMuZXhpdCgxKQogICAgcmV0dXJuIHIuc3Rkb3V0LnN0cmlwKCkKCiMgR2V0IGN1cnJlbnQgdmVyc2lvbiwgZGVmYXVsdCB0byAxLjAgaWYgc3ViZm9sZGVyIGlzIGJyYW5kIG5ldwpjdXIsIHZlcl9zaGEgPSBnaF9nZXQoVkVSX1BBVEgpCmlmIG5vdCBjdXI6CiAgICBjdXIsIHZlcl9zaGEgPSAiMS4wIiwgTm9uZQogICAgcHJpbnQoIiAgTm8gdmVyc2lvbi50eHQgZm91bmQsIHN0YXJ0aW5nIGF0IDEuMCIpCgojIEluY3JlbWVudCBsYXN0IHNlZ21lbnQ6IDEuMCAtPiAxLjEsIDIuOSAtPiAyLjEwCnBhcnRzID0gY3VyLnNwbGl0KCIuIikKcGFydHNbLTFdID0gc3RyKGludChwYXJ0c1stMV0pICsgMSkKbmV3X3ZlciA9ICIuIi5qb2luKHBhcnRzKQpwcmludCgiICBWZXJzaW9uIDogIiArIGN1ciArICIgIC0+ICAiICsgbmV3X3ZlcikKCiMgUHVzaCBleGUgKHBhc3MgZXhpc3RpbmcgU0hBIGlmIHRoZSBmaWxlIGFscmVhZHkgZXhpc3RzKQpfLCBleGVfc2hhID0gZ2hfZ2V0KEVYRV9QQVRIKQpleGVfZGF0YSA9IG9wZW4oRElTVF9FWEUsICJyYiIpLnJlYWQoKQpzaGExID0gZ2hfcHV0KEVYRV9QQVRILCAiUmVsZWFzZSAiICsgRVhFX0ZJTEUgKyAiIHYiICsgbmV3X3ZlciwgZXhlX2RhdGEsIGV4ZV9zaGEpCnByaW50KCIgIEV4ZSAgICAgOiAiICsgc2hhMSkKCiMgUHVzaCB2ZXJzaW9uLnR4dApzaGEyID0gZ2hfcHV0KFZFUl9QQVRILCAiQnVtcCB2ZXJzaW9uIHRvICIgKyBuZXdfdmVyICsgIiBbIiArIEZPTERFUiArICJdIiwgbmV3X3Zlci5lbmNvZGUoKSwgdmVyX3NoYSkKcHJpbnQoIiAgVmVyc2lvbiA6ICIgKyBzaGEyKQpwcmludCgpCnByaW50KCIgIFB1Ymxpc2hlZCAiICsgRVhFX0ZJTEUgKyAiIHYiICsgbmV3X3ZlciArICIgLT4gIiArIFJFUE8gKyAiLyIgKyBGT0xERVIgKyAiLyIpCg=="
powershell -NoProfile -Command "[System.IO.File]::WriteAllBytes($env:TEMP + '\release_pub.py', [System.Convert]::FromBase64String('%PY_B64%'))"

if not exist "!PY_HELPER!" (
    echo ERROR: Failed to write Python helper to temp folder.
    pause & exit /b 1
)

py "!PY_HELPER!" "!RELEASES_REPO!" "!REPO_FOLDER!" "!EXE_FILE!" "!DIST_EXE!"
set "PY_EXIT=!errorlevel!"
del "!PY_HELPER!" 2>nul

if !PY_EXIT! neq 0 (
    echo.
    echo ERROR: Publishing to GitHub failed. See above for details.
    pause & exit /b 1
)

echo.
echo ==================================================
echo   All done!
echo ==================================================
echo.
pause
