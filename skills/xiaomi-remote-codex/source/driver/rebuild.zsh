#!/bin/zsh
set -euo pipefail
cd "${0:A:h}"
bundle="$PWD/build/MiRemoteVoice.driver"
mkdir -p "$bundle/Contents/MacOS" "$bundle/Contents/Resources"
cp Info.plist "$bundle/Contents/Info.plist"
cp BlackHole.icns "$bundle/Contents/Resources/BlackHole.icns"
cp ../../licenses/BlackHole-GPL-3.0.txt "$bundle/Contents/Resources/LICENSE"
xcrun clang -arch arm64 -mmacosx-version-min=12.0 -O2 -DNDEBUG -DDEBUG=0 \
 '-DkDriver_Name="MiRemoteV"' '-DkPlugIn_BundleID="audio.local.MiRemoteVoice2chXX"' \
 -bundle MiRemoteVoice.c -framework CoreAudio -framework CoreFoundation -framework Accelerate \
 -o "$bundle/Contents/MacOS/BlackHole"
codesign --force --deep --sign - --timestamp=none "$bundle"
codesign --verify --deep --strict "$bundle"
root="$PWD/build/pkg-root"
mkdir -p "$root/Library/Audio/Plug-Ins/HAL" build/pkg-scripts
ditto --noextattr --norsrc --noacl "$bundle" "$root/Library/Audio/Plug-Ins/HAL/MiRemoteVoice.driver"
cp postinstall build/pkg-scripts/postinstall
chmod +x build/pkg-scripts/postinstall
pkgbuild --root "$root" --scripts build/pkg-scripts --identifier audio.local.MiRemoteVoice2chXX --version 0.4.1 --install-location / build/MiRemoteVoice-Driver.pkg
