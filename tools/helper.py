import base64, json, re, subprocess, sys, os, tempfile, shutil

REPO        = sys.argv[1]
FOLDER      = sys.argv[2]
EXE_FILE    = sys.argv[3]
DIST_EXE    = sys.argv[4]
SCRIPT      = sys.argv[5]
EXE_DISPLAY = sys.argv[6]

VER_PATH = FOLDER + "/version.txt"

def gh_get_version():
    """Fetch current version.txt via API (it's tiny, API is fine for this)."""
    r = subprocess.run(["gh", "api", "repos/" + REPO + "/contents/" + VER_PATH],
        capture_output=True, text=True)
    if r.returncode != 0:
        return None
    d = json.loads(r.stdout)
    return base64.b64decode(d["content"].replace("\n", "")).decode().strip()

def git_push_release(clone_dir, new_ver):
    """Clone app-releases, copy the built exe + version.txt, commit and push."""
    repo_url = "https://github.com/" + REPO + ".git"

    print("  Cloning " + REPO + "...")
    r = subprocess.run(["gh", "repo", "clone", REPO, clone_dir, "--", "--depth=1"],
        capture_output=True, text=True)
    if r.returncode != 0:
        sys.stderr.write("ERROR cloning: " + r.stderr + "\n")
        sys.exit(1)

    # Copy exe
    dest_folder = os.path.join(clone_dir, FOLDER)
    os.makedirs(dest_folder, exist_ok=True)
    dest_exe = os.path.join(dest_folder, EXE_FILE)
    shutil.copy2(DIST_EXE, dest_exe)
    print("  Copied  : " + dest_exe)

    # Write version.txt
    dest_ver = os.path.join(dest_folder, "version.txt")
    with open(dest_ver, "w") as f:
        f.write(new_ver)

    # Commit and push
    env = os.environ.copy()
    def git(*args):
        r = subprocess.run(["git"] + list(args), cwd=clone_dir,
                           capture_output=True, text=True, env=env)
        if r.returncode != 0:
            sys.stderr.write("ERROR git " + " ".join(args) + ": " + r.stderr + "\n")
            sys.exit(1)
        return r.stdout.strip()

    # Set git identity on the temp clone (uses GitHub login; temp clones have no global config)
    gh_user = subprocess.run(["gh", "api", "user", "--jq", ".login"],
        capture_output=True, text=True).stdout.strip() or "build-script"
    git("config", "user.name", gh_user)
    git("config", "user.email", gh_user + "@users.noreply.github.com")

    git("add", os.path.join(FOLDER, EXE_FILE), os.path.join(FOLDER, "version.txt"))
    git("commit", "-m",
        "Release " + EXE_FILE + " v" + new_ver + " [" + FOLDER + "]")
    sha = git("rev-parse", "HEAD")
    git("push")
    print("  Commit  : " + sha)


# 1. Compute new version
cur = gh_get_version()
if not cur:
    cur = "1.0"
    print("  No version.txt found, starting at 1.0")
parts = cur.split(".")
parts[-1] = str(int(parts[-1]) + 1)
new_ver = ".".join(parts)
print("  Version : " + cur + "  ->  " + new_ver)

# 2. Patch VERSION = "..." in the source file
with open(SCRIPT, "r", encoding="utf-8") as f:
    source = f.read()
patched = re.sub(r'^VERSION\s*=\s*["\'].*?["\']',
                 'VERSION = "' + new_ver + '"',
                 source, flags=re.MULTILINE)
if patched == source:
    print("  WARNING: VERSION not found in " + SCRIPT + " - skipping patch")
else:
    with open(SCRIPT, "w", encoding="utf-8") as f:
        f.write(patched)
    print("  Patched VERSION in " + SCRIPT)

# 3. Build with PyInstaller
print()
print("  Building " + EXE_FILE + "...")
print()
r = subprocess.run(
    ["pyinstaller", "--onefile", "--noconsole", "--clean",
     "--runtime-tmpdir", "%LOCALAPPDATA%\\" + EXE_DISPLAY,
     "--name", EXE_DISPLAY, SCRIPT])
if r.returncode != 0:
    sys.stderr.write("ERROR: PyInstaller build failed.\n")
    sys.exit(1)
if not os.path.exists(DIST_EXE):
    sys.stderr.write("ERROR: " + DIST_EXE + " not found after build.\n")
    sys.exit(1)
print()
print("  Build OK: " + DIST_EXE)

# 4. Clone app-releases, copy files, commit and push
print()
print("  Pushing to app-releases...")
clone_dir = tempfile.mkdtemp(prefix="app-releases-")
try:
    git_push_release(clone_dir, new_ver)
finally:
    shutil.rmtree(clone_dir, ignore_errors=True)

print()
print("  Published " + EXE_FILE + " v" + new_ver + " -> " + REPO + "/" + FOLDER + "/")
