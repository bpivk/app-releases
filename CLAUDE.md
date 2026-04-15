# app-releases — Project Agent File

## What this repo is

A public distribution repo for compiled Windows executables. Each app has its own subfolder containing:
- `<AppName>.exe` — the compiled binary
- `version.txt` — current version string (e.g. `2.6`)

The running apps check `version.txt` via GitHub API on startup to detect updates, then download the new `.exe` from this repo.

**GitHub repo:** `bpivk/app-releases` (public — must stay public for unauthenticated downloads)

---

## Repo structure

```
app-releases/
  avery/
    Avery-Labeler.exe     <- compiled exe, downloaded by auto-updater
    version.txt           <- current version string (e.g. "2.6")
  tools/
    build_and_release.bat <- generic build + release script
    helper_src.py         <- readable source of the Python helper embedded in the bat
  README.md
```

---

## How to add a new app

1. Create a subfolder (e.g. `my-app/`)
2. Add `version.txt` with content `1.0`
3. Run `build_and_release.bat` from the app source folder:
   - Script name (without .py): `my_script`
   - Release subfolder: `my-app`
   - Exe name: `My-App`

---

## build_and_release.bat

Located at `tools/build_and_release.bat`. Copy it to the app source folder (or run from there).

**What it does:**
1. Prompts for: script name, release subfolder in `app-releases`, exe display name
2. Decodes an embedded Python helper (base64 inside the bat) to `%TEMP%\release_pub.py`
3. Runs the helper, which:
   - Fetches current `version.txt` from this repo via GitHub API
   - Increments the minor version (e.g. `2.5 -> 2.6`)
   - Patches `VERSION = "..."` in the source `.py` file
   - Runs `pyinstaller --onefile --noconsole --clean --name {ExeName} {script}.py`
   - Pushes new exe + updated `version.txt` to this repo

**Requirements:** `gh` CLI (authenticated as `bpivk`), `pyinstaller` on PATH, `py` Python launcher.

---

## helper_src.py

Human-readable source of the Python helper that is base64-embedded in `build_and_release.bat`.
It is NOT used at runtime — the bat decodes and runs its own embedded copy.
Edit `helper_src.py` when you need to change the helper logic, then re-encode and update the bat.

### Re-encoding helper_src.py into the bat

```bash
python -c "import base64; print(base64.b64encode(open('helper_src.py','rb').read()).decode())"
```

Paste the output as the value of `PY_B64` in `build_and_release.bat`.

---

## Auto-update flow (consumer side)

Each app:
1. On startup, fetches `api.github.com/repos/bpivk/app-releases/contents/{folder}/version.txt`
   (GitHub API — no CDN caching, always live)
2. Compares with its bundled `VERSION` constant
3. If newer: downloads `raw.githubusercontent.com/bpivk/app-releases/main/{folder}/{App}.exe`
4. Calls PowerShell `Unblock-File` on the downloaded exe (removes Zone.Identifier ADS — prevents `Failed to load Python DLL` error on first launch of updated exe)
5. Writes a bat swap script: waits 3 s, copies new exe over itself, relaunches, self-deletes

---

## Apps currently in this repo

| Subfolder | App | Source repo |
|-----------|-----|-------------|
| `avery/` | Avery-Labeler | `bpivk/Avery-Labeler` |
