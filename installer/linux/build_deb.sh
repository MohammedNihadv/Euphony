#!/usr/bin/env bash
# Packages the Flutter Linux release bundle into a native Debian (.deb) package.
# Run from the repo root after `flutter build linux --release`.
set -euo pipefail

BUNDLE="build/linux/x64/release/bundle"
if [ ! -d "$BUNDLE" ]; then
  echo "Error: Flutter bundle not found at $BUNDLE. Run 'flutter build linux --release' first." >&2
  exit 1
fi

VERSION=$(grep -m1 '^version:' pubspec.yaml | awk '{print $2}' | cut -d'+' -f1)
ARCH="amd64"
PKG_NAME="euphony_${VERSION}_${ARCH}"
BUILD_ROOT="build/deb/${PKG_NAME}"

echo "Creating Debian package structure for ${PKG_NAME}..."
rm -rf "$BUILD_ROOT"
mkdir -p "$BUILD_ROOT/DEBIAN"
mkdir -p "$BUILD_ROOT/usr/bin"
mkdir -p "$BUILD_ROOT/usr/lib/euphony"
mkdir -p "$BUILD_ROOT/usr/share/applications"
mkdir -p "$BUILD_ROOT/usr/share/icons/hicolor/256x256/apps"
mkdir -p "$BUILD_ROOT/usr/share/metainfo"

# 1. Copy application bundle into /usr/lib/euphony
cp -r "$BUNDLE/." "$BUILD_ROOT/usr/lib/euphony/"

# 2. Binary launcher in /usr/bin
cat > "$BUILD_ROOT/usr/bin/euphony" <<'EOF'
#!/bin/sh
exec /usr/lib/euphony/euphony "$@"
EOF
chmod 755 "$BUILD_ROOT/usr/bin/euphony"

# 3. Desktop Entry
cat > "$BUILD_ROOT/usr/share/applications/in.fedaration.euphony.desktop" <<'EOF'
[Desktop Entry]
Name=Euphony Music
Comment=Modern, 100% ad-free, open-source Neo-Brutalist music player
Exec=euphony %U
Icon=in.fedaration.euphony
Terminal=false
Type=Application
Categories=AudioVideo;Audio;Player;Music;
StartupWMClass=euphony
MimeType=audio/mpeg;audio/x-mpeg;audio/flac;audio/x-flac;audio/mp4;audio/aac;audio/ogg;audio/wav;audio/x-wav;
EOF
chmod 644 "$BUILD_ROOT/usr/share/applications/in.fedaration.euphony.desktop"

# 4. App Icon
cp assets/images/app.icon.png "$BUILD_ROOT/usr/share/icons/hicolor/256x256/apps/in.fedaration.euphony.png"
chmod 644 "$BUILD_ROOT/usr/share/icons/hicolor/256x256/apps/in.fedaration.euphony.png"

# 5. AppStream Metainfo
cat > "$BUILD_ROOT/usr/share/metainfo/in.fedaration.euphony.metainfo.xml" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<component type="desktop-application">
  <id>in.fedaration.euphony</id>
  <metadata_license>CC0-1.0</metadata_license>
  <project_license>GPL-3.0-or-later</project_license>
  <name>Euphony Music</name>
  <summary>Modern, 100% ad-free, open-source Neo-Brutalist music player</summary>
  <developer_name>Mohammed Nihad V</developer_name>
  <description>
    <p>
      Euphony Music is a modern, high-performance, open-source music player built with Flutter, Riverpod, and Drift SQLite for Android, Windows, macOS, and Linux.
    </p>
  </description>
  <launchable type="desktop-id">in.fedaration.euphony.desktop</launchable>
  <url type="homepage">https://euphony.fedaration.in/</url>
  <url type="vcs-browser">https://github.com/MohammedNihadv/Euphony</url>
  <categories>
    <category>AudioVideo</category>
    <category>Audio</category>
    <category>Music</category>
    <category>Player</category>
  </categories>
</component>
EOF
chmod 644 "$BUILD_ROOT/usr/share/metainfo/in.fedaration.euphony.metainfo.xml"

# Calculate installed size in KB
INSTALLED_SIZE=$(du -sk "$BUILD_ROOT/usr" | cut -f1)

# 6. Control File
cat > "$BUILD_ROOT/DEBIAN/control" <<EOF
Package: euphony
Version: ${VERSION}
Section: sound
Priority: optional
Architecture: ${ARCH}
Installed-Size: ${INSTALLED_SIZE}
Maintainer: Mohammed Nihad V <166234155+MohammedNihadv@users.noreply.github.com>
Depends: libc6 (>= 2.34), libgtk-3-0 (>= 3.24.0), libmpv2 | libmpv1, libpulse0
Homepage: https://euphony.fedaration.in/
Description: Modern, 100% ad-free, open-source Neo-Brutalist music player
 Euphony Music is a high-performance offline and local music player built with Flutter,
 Riverpod, and Drift SQLite for Linux, Android, and Windows. Complete privacy with
 zero telemetry, no ads, and native media controls.
EOF

# 7. Build the .deb archive
mkdir -p dist
dpkg-deb --build --root-owner-group "$BUILD_ROOT" "dist/${PKG_NAME}.deb"
cp "dist/${PKG_NAME}.deb" "dist/euphony-linux-amd64.deb"
echo "Successfully built dist/${PKG_NAME}.deb and dist/euphony-linux-amd64.deb"
