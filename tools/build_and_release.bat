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
    pause ^& exit /b 1
)

echo Press any key to start, or Ctrl+C to cancel...
pause >nul

:: ---------- Decode Python helper from base64, run it ----------
set "PY_HELPER=%TEMP%/release_pub.py"
set "PY_B64=aW1wb3J0IGJhc2U2NCwganNvbiwgcmUsIHN1YnByb2Nlc3MsIHN5cywgb3MsIHRlbXBmaWxlCgpSRVBPICAgICAgICA9IHN5cy5hcmd2WzFdCkZPTERFUiAgICAgID0gc3lzLmFyZ3ZbMl0KRVhFX0ZJTEUgICAgPSBzeXMuYXJndlszXQpESVNUX0VYRSAgICA9IHN5cy5hcmd2WzRdClNDUklQVCAgICAgID0gc3lzLmFyZ3ZbNV0KRVhFX0RJU1BMQVkgPSBzeXMuYXJndls2XQoKVkVSX1BBVEggPSBGT0xERVIgKyAiL3ZlcnNpb24udHh0IgpFWEVfUEFUSCA9IEZPTERFUiArICIvIiArIEVYRV9GSUxFCgpkZWYgZ2hfZ2V0KHBhdGgpOgogICAgciA9IHN1YnByb2Nlc3MucnVuKFsiZ2giLCJhcGkiLCJyZXBvcy8iK1JFUE8rIi9jb250ZW50cy8iK3BhdGhdLAogICAgICAgIGNhcHR1cmVfb3V0cHV0PVRydWUsIHRleHQ9VHJ1ZSkKICAgIGlmIHIucmV0dXJuY29kZSAhPSAwOiByZXR1cm4gTm9uZSwgTm9uZQogICAgZCA9IGpzb24ubG9hZHMoci5zdGRvdXQpCiAgICBjb250ZW50ID0gYmFzZTY0LmI2NGRlY29kZShkWyJjb250ZW50Il0ucmVwbGFjZSgiXG4iLCIiKSkuZGVjb2RlKCkuc3RyaXAoKQogICAgcmV0dXJuIGNvbnRlbnQsIGRbInNoYSJdCgpkZWYgZ2hfcHV0KHBhdGgsIG1zZywgZGF0YSwgc2hhPU5vbmUpOgogICAgcGF5bG9hZCA9IHsibWVzc2FnZSI6IG1zZywgImNvbnRlbnQiOiBiYXNlNjQuYjY0ZW5jb2RlKGRhdGEpLmRlY29kZSgpfQogICAgaWYgc2hhOiBwYXlsb2FkWyJzaGEiXSA9IHNoYQogICAgdG1wID0gdGVtcGZpbGUuTmFtZWRUZW1wb3JhcnlGaWxlKGRlbGV0ZT1GYWxzZSwgc3VmZml4PSIuanNvbiIsIG1vZGU9InciKQogICAganNvbi5kdW1wKHBheWxvYWQsIHRtcCkKICAgIHRtcC5jbG9zZSgpCiAgICByID0gc3VicHJvY2Vzcy5ydW4oCiAgICAgICAgWyJnaCIsImFwaSIsInJlcG9zLyIrUkVQTysiL2NvbnRlbnRzLyIrcGF0aCwKICAgICAgICAgIi0tbWV0aG9kIiwiUFVUIiwiLS1pbnB1dCIsdG1wLm5hbWUsIi0tanEiLCIuY29tbWl0LnNoYSJdLAogICAgICAgIGNhcHR1cmVfb3V0cHV0PVRydWUsIHRleHQ9VHJ1ZSkKICAgIG9zLnVubGluayh0bXAubmFtZSkKICAgIGlmIHIucmV0dXJuY29kZSAhPSAwOgogICAgICAgIHN5cy5zdGRlcnIud3JpdGUoIkVSUk9SOiAiICsgci5zdGRlcnIgKyAiXG4iKQogICAgICAgIHN5cy5leGl0KDEpCiAgICByZXR1cm4gci5zdGRvdXQuc3RyaXAoKQoKIyAxLiBDb21wdXRlIG5ldyB2ZXJzaW9uCmN1ciwgdmVyX3NoYSA9IGdoX2dldChWRVJfUEFUSCkKaWYgbm90IGN1cjoKICAgIGN1ciwgdmVyX3NoYSA9ICIxLjAiLCBOb25lCiAgICBwcmludCgiICBObyB2ZXJzaW9uLnR4dCBmb3VuZCwgc3RhcnRpbmcgYXQgMS4wIikKcGFydHMgPSBjdXIuc3BsaXQoIi4iKQpwYXJ0c1stMV0gPSBzdHIoaW50KHBhcnRzWy0xXSkgKyAxKQpuZXdfdmVyID0gIi4iLmpvaW4ocGFydHMpCnByaW50KCIgIFZlcnNpb24gOiAiICsgY3VyICsgIiAgLT4gICIgKyBuZXdfdmVyKQoKIyAyLiBQYXRjaCBWRVJTSU9OID0gIi4uLiIgaW4gdGhlIHNvdXJjZSBmaWxlCndpdGggb3BlbihTQ1JJUFQsICJyIiwgZW5jb2Rpbmc9InV0Zi04IikgYXMgZjoKICAgIHNvdXJjZSA9IGYucmVhZCgpCnBhdGNoZWQgPSByZS5zdWIocideVkVSU0lPTlxzKj1ccypbIlwnXS4qP1siXCddJywKICAgICAgICAgICAgICAgICAnVkVSU0lPTiA9ICInICsgbmV3X3ZlciArICciJywKICAgICAgICAgICAgICAgICBzb3VyY2UsIGZsYWdzPXJlLk1VTFRJTElORSkKaWYgcGF0Y2hlZCA9PSBzb3VyY2U6CiAgICBwcmludCgiICBXQVJOSU5HOiBWRVJTSU9OIG5vdCBmb3VuZCBpbiAiICsgU0NSSVBUICsgIiAtIHNraXBwaW5nIHBhdGNoIikKZWxzZToKICAgIHdpdGggb3BlbihTQ1JJUFQsICJ3IiwgZW5jb2Rpbmc9InV0Zi04IikgYXMgZjoKICAgICAgICBmLndyaXRlKHBhdGNoZWQpCiAgICBwcmludCgiICBQYXRjaGVkIFZFUlNJT04gaW4gIiArIFNDUklQVCkKCiMgMy4gQnVpbGQgd2l0aCBQeUluc3RhbGxlcgpwcmludCgpCnByaW50KCIgIEJ1aWxkaW5nICIgKyBFWEVfRklMRSArICIuLi4iKQpwcmludCgpCnIgPSBzdWJwcm9jZXNzLnJ1bigKICAgIFsicHlpbnN0YWxsZXIiLCAiLS1vbmVmaWxlIiwgIi0tbm9jb25zb2xlIiwgIi0tY2xlYW4iLAogICAgICItLW5hbWUiLCBFWEVfRElTUExBWSwgU0NSSVBUXSkKaWYgci5yZXR1cm5jb2RlICE9IDA6CiAgICBzeXMuc3RkZXJyLndyaXRlKCJFUlJPUjogUHlJbnN0YWxsZXIgYnVpbGQgZmFpbGVkLlxuIikKICAgIHN5cy5leGl0KDEpCmlmIG5vdCBvcy5wYXRoLmV4aXN0cyhESVNUX0VYRSk6CiAgICBzeXMuc3RkZXJyLndyaXRlKCJFUlJPUjogIiArIERJU1RfRVhFICsgIiBub3QgZm91bmQgYWZ0ZXIgYnVpbGQuXG4iKQogICAgc3lzLmV4aXQoMSkKcHJpbnQoKQpwcmludCgiICBCdWlsZCBPSzogIiArIERJU1RfRVhFKQoKIyA0LiBQdXNoIGV4ZQpwcmludCgpCnByaW50KCIgIFB1c2hpbmcgdG8gYXBwLXJlbGVhc2VzLi4uIikKXywgZXhlX3NoYSA9IGdoX2dldChFWEVfUEFUSCkKZXhlX2RhdGEgPSBvcGVuKERJU1RfRVhFLCAicmIiKS5yZWFkKCkKc2hhMSA9IGdoX3B1dChFWEVfUEFUSCwgIlJlbGVhc2UgIiArIEVYRV9GSUxFICsgIiB2IiArIG5ld192ZXIsIGV4ZV9kYXRhLCBleGVfc2hhKQpwcmludCgiICBFeGUgICAgIDogIiArIHNoYTEpCgojIDUuIFB1c2ggdmVyc2lvbi50eHQKc2hhMiA9IGdoX3B1dChWRVJfUEFUSCwgIkJ1bXAgdmVyc2lvbiB0byAiICsgbmV3X3ZlciArICIgWyIgKyBGT0xERVIgKyAiXSIsCiAgICAgICAgICAgICAgbmV3X3Zlci5lbmNvZGUoKSwgdmVyX3NoYSkKcHJpbnQoIiAgVmVyc2lvbiA6ICIgKyBzaGEyKQpwcmludCgpCnByaW50KCIgIFB1Ymxpc2hlZCAiICsgRVhFX0ZJTEUgKyAiIHYiICsgbmV3X3ZlciArICIgLT4gIiArIFJFUE8gKyAiLyIgKyBGT0xERVIgKyAiLyIpCg=="
powershell -NoProfile -Command "[System.IO.File]::WriteAllBytes('!PY_HELPER!', [System.Convert]::FromBase64String('%PY_B64%'))"

if not exist "!PY_HELPER!" (
    echo ERROR: Failed to write Python helper to temp folder.
    pause ^& exit /b 1
)

echo.
echo [1/3] Fetching version ^& patching source...
echo [2/3] Building with PyInstaller...
echo [3/3] Publishing to app-releases...
echo.

py "!PY_HELPER!" "!RELEASES_REPO!" "!REPO_FOLDER!" "!EXE_FILE!" "!DIST_EXE!" "!SCRIPT!" "!EXE_DISPLAY!"
set "PY_EXIT=!errorlevel!"
del "!PY_HELPER!" 2>nul

if !PY_EXIT! neq 0 (
    echo.
    echo ERROR: Build or publishing failed. See above for details.
    pause ^& exit /b 1
)

echo.
echo ==================================================
echo   All done!
echo ==================================================
echo.
pause
