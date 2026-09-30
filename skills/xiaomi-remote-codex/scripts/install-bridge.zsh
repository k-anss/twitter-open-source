#!/bin/zsh
set -euo pipefail
ROOT=${0:A:h:h}
dry=0
destination="$HOME/Applications/MiRemoteBridge.app"
while (( $# )); do
  case "$1" in
    --dry-run) dry=1; shift ;;
    --destination) (( $# >= 2 )) || { print -u2 -- "--destination requires a path"; exit 2; }; destination="$2"; shift 2 ;;
    *) print -u2 'Usage: install-bridge.zsh [--dry-run] [--destination /path/MiRemoteBridge.app]'; exit 2 ;;
  esac
done
(( EUID != 0 )) || { print -u2 "Run as the logged-in user, not root."; exit 2; }
[[ $(uname -s) == Darwin && $(uname -m) == arm64 ]] || { print -u2 'This prebuilt package requires Apple Silicon macOS.'; exit 2; }
[[ "$destination" == /*/MiRemoteBridge.app && ! -L "$destination" ]] || { print -u2 'Destination must be an absolute MiRemoteBridge.app path, not a symlink.'; exit 2; }
if [[ -e "$destination" ]]; then
 [[ -d "$destination" ]] || { print -u2 'Destination exists but is not an app directory.'; exit 2; }
 existing_id=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$destination/Contents/Info.plist")
 [[ "$existing_id" == 'local.simaqingfeng.MiRemoteBridge' ]] || { print -u2 'Refusing to overwrite a different application.'; exit 2; }
fi
(cd "$ROOT" && shasum -a 256 -c assets/SHA256SUMS)
stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT
/usr/bin/ditto -x -k "$ROOT/assets/MiRemoteBridge-arm64.zip" "$stage"
/usr/bin/codesign --verify --deep --strict "$stage/MiRemoteBridge.app"
if (( dry )); then
 print "Verified. Would install: $destination"
 exit 0
fi
# Refuse replacement while any installed bridge is running.
set +e
/usr/bin/pgrep -x MiRemoteBridge >/dev/null
status=$?
set -e
if (( status == 0 )); then print -u2 'Quit MiRemoteBridge from its menu before installing.'; exit 3; fi
if (( status != 1 )); then print -u2 'Cannot check running processes. Stop here; verify permissions before retrying.'; exit 3; fi
if [[ -e "$destination" ]]; then
 backup="$HOME/Library/Application Support/MiRemoteBridge/InstallBackups"
 mkdir -p "$backup"
 /usr/bin/ditto -c -k --keepParent "$destination" "$backup/MiRemoteBridge-$(date +%Y%m%d-%H%M%S)-$$.zip"
fi
mkdir -p "${destination:h}"
# Update contents without deleting the app container, which can need broader parent permission.
/usr/bin/ditto "$stage/MiRemoteBridge.app" "$destination"
/usr/bin/codesign --verify --deep --strict "$destination"
print "Installed and verified: $destination"
print 'Next: install the audio driver if missing, launch the app, grant system permissions, and test physical keys.'
