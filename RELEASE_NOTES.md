## Euphony v0.2.3 — Media Notifications & Export Bug Fixes 🚀

Euphony v0.2.3 resolves critical bugs regarding media notifications and data export on modern Android devices.

### ✨ What's New & Fixed

- **Media Notification Fix**: Fixed an issue where the app would completely crash on track changes due to R8 shrinking notification icons (`ic_stat_*`) out of the release build. Notification actions (play/pause/skip) are fully visible again.
- **Export Data Fix**: Implemented native Android Secure Access Framework (SAF) `MethodChannel` bridging. Exporting error logs and backing up the database to secure Android directories (like Downloads or Documents) now works perfectly and no longer results in empty 0-byte files or `MissingPluginException` errors.

---

## Euphony v0.2.2 — Dynamic App Versioning & SEO Polish 🎶

Euphony v0.2.2 introduces dynamic app version resolution, ensuring update notifications always match your installed build perfectly.

### ✨ What's New & Fixed

- **Dynamic Version Resolution (`package_info_plus`)**: Refactored `UpdateChecker` to read the app version dynamically from `PackageInfo` instead of a hardcoded string constant. The app will never show a false update prompt after installing a new version again!
- **Dynamic Settings UI**: Updated Settings screen to dynamically display the active version via `appVersionProvider`.
- **Website Live GitHub API Integration**: Embedded dynamic release fetching on [Euphony Website](https://euphonymusic.vercel.app/) — version badges, download buttons, and APK modal links now automatically sync with official GitHub releases on every page load.
- **Enhanced Search Engine Optimization**: Added canonical links, OpenGraph cards, Twitter preview metadata, `sitemap.xml`, `robots.txt`, and Google `SoftwareApplication` JSON-LD schema for rich search result indexing.

### 📥 Which APK should I download?

| APK File | Target Device | Recommendation |
| :--- | :--- | :--- |
| `app-arm64-v8a-release.apk` | Modern Android phones & tablets | ⭐ **Best for 99% of devices** (2017 and newer). Smallest size, best performance. |
| `app-armeabi-v7a-release.apk` | Older 32-bit Android devices | For older or budget phones. |
| `app-x86_64-release.apk` | Emulators & Chromebooks | For Android emulators, PCs, and Intel Chromebooks. |

---

Euphony is free, open source, and built by the community. Found a bug or have an idea? [Open an issue](https://github.com/MohammedNihadv/Euphony/issues) — we'd love your help. ❤️
