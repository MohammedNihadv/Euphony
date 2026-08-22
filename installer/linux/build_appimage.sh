#!/usr/bin/env bash
# Packages the Flutter Linux release bundle into a single-file AppImage.
# Run from the repo root after `flutter build linux --release`.
set -euo pipefail

BUNDLE="build/linux/x64/release/bundle"
APPDIR="build/euphony.AppDir"
OUT="euphony-linux-x86_64.AppImage"

rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin"
cp -r "$BUNDLE/." "$APPDIR/usr/bin/"

# App icon (PNG) at the AppDir root, named after the desktop entry.
cp assets/images/app.icon.png "$APPDIR/euphony.png"

# Desktop entry.
cat > "$APPDIR/euphony.desktop" <<DESKTOP
[Desktop Entry]
Name=Euphony
Exec=euphony
Icon=euphony
Type=Application
Categories=AudioVideo;Audio;Player;
DESKTOP

# AppRun launcher.
cat > "$APPDIR/AppRun" <<'APPRUN'
#!/bin/sh
HERE="$(dirname "$(readlink -f "$0")")"
export LD_LIBRARY_PATH="$HERE/usr/bin/lib:$LD_LIBRARY_PATH"
exec "$HERE/usr/bin/euphony" "$@"
APPRUN
chmod +x "$APPDIR/AppRun"

# Fetch appimagetool and build.
TOOL="appimagetool-x86_64.AppImage"
if [ ! -f "$TOOL" ]; then
  wget -q "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage" -O "$TOOL"
  chmod +x "$TOOL"
fi
ARCH=x86_64 ./"$TOOL" --appimage-extract-and-run "$APPDIR" "$OUT"
echo "built $OUT"
