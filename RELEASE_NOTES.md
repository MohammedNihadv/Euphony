## Euphony v0.2.11 — iOS (sideload) + hardening 🍏

Euphony now has an iOS build you can sideload, plus a security tidy-up of the build pipeline.

### ✨ New
- **iOS app (`euphony-ios.ipa`)** — an unsigned build you can install with **AltStore**, **Sideloadly** or **TrollStore** — no App Store or developer account required. (A signed App Store release is still planned.)

### 🔒 Hardening
- Locked every CI workflow to least-privilege permissions (resolves the CodeQL "workflow does not contain permissions" warnings).

### 📥 Downloads
| Platform | File | Install |
| :-- | :-- | :-- |
| Android | `app-arm64-v8a-release.apk` | Tap to install |
| Windows | `euphony-windows-setup.exe` | Run the installer |
| macOS | `euphony-macos.dmg` | Open, drag to Applications |
| Linux | `euphony-linux-x86_64.AppImage` | `chmod +x` then run |
| iOS | `euphony-ios.ipa` | Sideload (AltStore / Sideloadly / TrollStore) |

---

Euphony is free, open source, and built by the community. ❤️
