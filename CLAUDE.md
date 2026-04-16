# app-releases — Project Agent File

## What this repo is

A public distribution repo for compiled Windows executables. Each app has its own subfolder containing:
- `<AppName>.exe` — the compiled binary
- `version.txt` — current version string (e.g. `2.6`)

The running apps check `version.txt` via GitHub API on startup to detect updates, then open the download URL in the browser for the user to install manually.

**GitHub repo:** `bpivk/app-releases` (public — must stay public for unauthenticated downloads)

---

## Repo structure

```
app-releases/
  avery/
    Avery-Labeler.exe     <- compiled exe, downloaded by user via browser
    version.txt           <- current version string (e.g. "2.6")
  norman/
    Nalepke.exe           <- compiled exe for Uvoz podatkov app
    version.txt
  tools/
    build_and_release.bat <- generic build + release script (copy to project folder to use)
    helper.py             <- Python helper called by the bat
  README.md
```

---

## How to add a new app

1. Create a subfolder (e.g. `my-app/`)
2. Run `build_and_release.bat` from the app source folder — it creates `version.txt` automatically on first run
3. In the app's `Updater` class, set `VERSION_API`, `EXE_URL`, and `EXE_NAME` to point to the new subfolder

---

## build_and_release.bat + helper.py

Located at `tools/`. Copy **both files** to the app source folder before running.

**What it does:**
1. Prompts for: script name (without .py), release subfolder in `app-releases`, exe display name
2. Calls `helper.py` (must be in the same folder as the bat), which:
   - Fetches current `version.txt` from this repo via GitHub API, increments minor version
   - Patches `VERSION = "..."` in the source `.py` file
   - Runs `pyinstaller --onefile --noconsole --clean --name {ExeName} {script}.py`
   - Clones `app-releases` to a temp dir, copies exe + `version.txt`, commits and pushes

**Requirements:** `gh` CLI (authenticated as `bpivk`), `pyinstaller` on PATH, `py` Python launcher.

---

## Auto-update flow (consumer side)

Each app:
1. On startup, fetches `api.github.com/repos/bpivk/app-releases/contents/{folder}/version.txt`
   (GitHub API — no CDN caching, always live)
2. Compares with its bundled `VERSION` constant
3. If newer: prompts the user, then opens `webbrowser.open(EXE_URL)` — user downloads and overwrites the exe manually
4. Shows a dialog with the current exe path so the user knows what to replace

---

## Apps currently in this repo

| Subfolder | Exe | Source repo |
|-----------|-----|-------------|
| `avery/` | `Avery-Labeler.exe` | `bpivk/Avery-Labeler` |
| `norman/` | `Nalepke.exe` | `bpivk/Uvoz_podatkov` |
