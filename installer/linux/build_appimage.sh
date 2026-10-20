#!/usr/bin/env bash
# Packages the Flutter Linux release bundle into a single-file AppImage.
# Run from the repo root after `flutter build linux --release`.
set -euo pipefail

BUNDLE="build/linux/x64/release/bundle"
APPDIR="build/euphony.AppDir"
OUT="Euphony-x86_64.AppImage"
LEGACY_OUT="euphony-linux-x86_64.AppImage"

rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin"
cp -r "$BUNDLE/." "$APPDIR/usr/bin/"

# Bundle libmpv so the AppImage runs self-contained without requiring system mpv/libmpv
mkdir -p "$APPDIR/usr/bin/lib"
for lib in /usr/lib/x86_64-linux-gnu/libmpv.so*; do
  if [ -e "$lib" ]; then
    cp -d "$lib" "$APPDIR/usr/bin/lib/"
  fi
done

# Copy direct dynamic dependencies of libmpv, strictly excluding system/base libraries
# (AppImageKit excludelist: libc, gcc, X11, wayland, systemd, selinux, glib, dbus, etc.)
if ls "$APPDIR/usr/bin/lib/libmpv.so"* >/dev/null 2>&1; then
  MPV_LIB=$(ls "$APPDIR/usr/bin/lib/libmpv.so"* | head -1)
  ldd "$MPV_LIB" | grep "=> /" | awk '{print $3}' | while read -r dep; do
    base=$(basename "$dep")
    case "$base" in
      libc.*|libm.*|libpthread.*|libdl.*|ld-linux*|librt.*|libresolv.*|libselinux*|libsystemd*|libudev*|libglib*|libgobject*|libgio*|libgmodule*|libdbus*|libcap*|libz.*|liblzma*|libzstd*|libcrypt*|libgcc*|libstdc++*|libX*|libxcb*|libwayland*|libdrm*|libgbm*|libasound*|libpulse*|libGL*|libEGL*)
        ;;
      *)
        cp -d "$dep" "$APPDIR/usr/bin/lib/" 2>/dev/null || true
        ;;
    esac
  done
fi

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
cp "$OUT" "$LEGACY_OUT"
echo "built $OUT and $LEGACY_OUT"
