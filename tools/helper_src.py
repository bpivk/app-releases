import base64, json, re, subprocess, sys, os, tempfile

REPO        = sys.argv[1]
FOLDER      = sys.argv[2]
EXE_FILE    = sys.argv[3]
DIST_EXE    = sys.argv[4]
SCRIPT      = sys.argv[5]
EXE_DISPLAY = sys.argv[6]

VER_PATH = FOLDER + "/version.txt"
EXE_PATH = FOLDER + "/" + EXE_FILE

def gh_get(path):
    r = subprocess.run(["gh","api","repos/"+REPO+"/contents/"+path],
        capture_output=True, text=True)
    if r.returncode != 0: return None, None
    d = json.loads(r.stdout)
    content = base64.b64decode(d["content"].replace("\n","")).decode().strip()
    return content, d["sha"]

def gh_put(path, msg, data, sha=None):
    payload = {"message": msg, "content": base64.b64encode(data).decode()}
    if sha: payload["sha"] = sha
    tmp = tempfile.NamedTemporaryFile(delete=False, suffix=".json", mode="w")
    json.dump(payload, tmp)
    tmp.close()
    r = subprocess.run(
        ["gh","api","repos/"+REPO+"/contents/"+path,
         "--method","PUT","--input",tmp.name,"--jq",".commit.sha"],
        capture_output=True, text=True)
    os.unlink(tmp.name)
    if r.returncode != 0:
        sys.stderr.write("ERROR: " + r.stderr + "\n")
        sys.exit(1)
    return r.stdout.strip()

# 1. Compute new version
cur, ver_sha = gh_get(VER_PATH)
if not cur:
    cur, ver_sha = "1.0", None
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
     "--name", EXE_DISPLAY, SCRIPT])
if r.returncode != 0:
    sys.stderr.write("ERROR: PyInstaller build failed.\n")
    sys.exit(1)
if not os.path.exists(DIST_EXE):
    sys.stderr.write("ERROR: " + DIST_EXE + " not found after build.\n")
    sys.exit(1)
print()
print("  Build OK: " + DIST_EXE)

# 4. Push exe
print()
print("  Pushing to app-releases...")
_, exe_sha = gh_get(EXE_PATH)
exe_data = open(DIST_EXE, "rb").read()
sha1 = gh_put(EXE_PATH, "Release " + EXE_FILE + " v" + new_ver, exe_data, exe_sha)
print("  Exe     : " + sha1)

# 5. Push version.txt
sha2 = gh_put(VER_PATH, "Bump version to " + new_ver + " [" + FOLDER + "]",
              new_ver.encode(), ver_sha)
print("  Version : " + sha2)
print()
print("  Published " + EXE_FILE + " v" + new_ver + " -> " + REPO + "/" + FOLDER + "/")
