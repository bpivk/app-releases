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

:: Write a temporary Python helper - handles base64, JSON payloads, and gh API calls
set "PY_HELPER=%TEMP%\release_pub_%RANDOM%.py"

(
echo import base64, json, subprocess, sys, os, tempfile
echo.
echo REPO     = sys.argv[1]
echo FOLDER   = sys.argv[2]
echo EXE_FILE = sys.argv[3]
echo DIST_EXE = sys.argv[4]
echo.
echo VER_PATH = FOLDER + "/version.txt"
echo EXE_PATH = FOLDER + "/" + EXE_FILE
echo.
echo def gh_get^(path^):
echo     r = subprocess.run^(["gh","api","repos/"+REPO+"/contents/"+path],
echo         capture_output=True, text=True^)
echo     if r.returncode != 0: return None, None
echo     d = json.loads^(r.stdout^)
echo     content = base64.b64decode^(d["content"].replace^("\n",""^)^).decode^(^).strip^(^)
echo     return content, d["sha"]
echo.
echo def gh_put^(path, msg, data, sha=None^):
echo     payload = {"message": msg, "content": base64.b64encode^(data^).decode^(^)}
echo     if sha: payload["sha"] = sha
echo     tmp = tempfile.NamedTemporaryFile^(delete=False, suffix=".json", mode="w"^)
echo     json.dump^(payload, tmp^)
echo     tmp.close^(^)
echo     r = subprocess.run^(
echo         ["gh","api","repos/"+REPO+"/contents/"+path,
echo          "--method","PUT","--input",tmp.name,"--jq",".commit.sha"],
echo         capture_output=True, text=True^)
echo     os.unlink^(tmp.name^)
echo     if r.returncode != 0:
echo         sys.stderr.write^("ERROR: " + r.stderr + "\n"^)
echo         sys.exit^(1^)
echo     return r.stdout.strip^(^)
echo.
echo # Get current version, default to 1.0 if not yet created
echo cur, ver_sha = gh_get^(VER_PATH^)
echo if not cur:
echo     cur, ver_sha = "1.0", None
echo     print^("  No version.txt found, starting at 1.0"^)
echo.
echo # Increment last number: 1.0 -> 1.1 / 2.9 -> 2.10
echo parts = cur.split^("."^)
echo parts[-1] = str^(int^(parts[-1]^) + 1^)
echo new_ver = ".".join^(parts^)
echo print^("  Version : " + cur + "  ->  " + new_ver^)
echo.
echo # Push exe (update SHA if it already exists)
echo _, exe_sha = gh_get^(EXE_PATH^)
echo exe_data = open^(DIST_EXE, "rb"^).read^(^)
echo sha1 = gh_put^(EXE_PATH, "Release " + EXE_FILE + " v" + new_ver, exe_data, exe_sha^)
echo print^("  Exe     : " + sha1^)
echo.
echo # Push version.txt
echo sha2 = gh_put^(VER_PATH, "Bump version to " + new_ver + " [" + FOLDER + "]", new_ver.encode^(^), ver_sha^)
echo print^("  version : " + sha2^)
echo print^(^)
echo print^("  Published " + EXE_FILE + " v" + new_ver + " -> " + REPO + "/" + FOLDER + "/"^)
) > "!PY_HELPER!"

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
