<div align="center">

# Euphony

---

Life already has enough interruptions. Your music doesn't need 30-second unskippable ads for products you'll never buy. **Free, ad-free, and crafted with open-source love — now on every device.**

<br>

<img src="docs/screenshots/banner.png" alt="Euphony Open Source Neo-Brutalist Music Player for Android, iOS, Windows, macOS and Linux" width="100%"/>

<br>

**Get Euphony for your platform**

<p align="center">
  <a href="https://github.com/MohammedNihadv/Euphony/releases/latest/download/app-arm64-v8a-release.apk">
    <img src="https://img.shields.io/badge/Android-Download%20APK-3DDC84?style=for-the-badge&labelColor=000000&logo=android&logoColor=3DDC84" alt="Download for Android"/>
  </a>
  &nbsp;
  <a href="https://github.com/MohammedNihadv/Euphony/releases/latest/download/euphony-windows-setup.exe">
    <img src="https://img.shields.io/badge/Windows-Installer-0078D6?style=for-the-badge&labelColor=000000&logo=windows&logoColor=white" alt="Download for Windows"/>
  </a>
  &nbsp;
  <a href="https://github.com/MohammedNihadv/Euphony/releases/latest/download/euphony-macos.dmg">
    <img src="https://img.shields.io/badge/macOS-.dmg-000000?style=for-the-badge&labelColor=000000&logo=apple&logoColor=white" alt="Download for macOS"/>
  </a>
  &nbsp;
  <a href="https://github.com/MohammedNihadv/Euphony/releases/latest/download/euphony-linux-x86_64.AppImage">
    <img src="https://img.shields.io/badge/Linux-AppImage-FCC624?style=for-the-badge&labelColor=000000&logo=linux&logoColor=white" alt="Download for Linux"/>
  </a>
</p>

<p align="center">
  <a href="https://euphonymusic.vercel.app/">
    <img src="https://img.shields.io/badge/WEB-VISIT%20OFFICIAL%20SITE-6A4BE8?style=for-the-badge&labelColor=000000&logo=vercel&logoColor=white" alt="Official Website"/>
  </a>
  &nbsp;
  <a href="https://github.com/MohammedNihadv/Euphony/releases/latest">
    <img src="https://img.shields.io/badge/All%20Downloads-LATEST%20RELEASE-F5C518?style=for-the-badge&labelColor=000000&logo=github&logoColor=white" alt="All downloads"/>
  </a>
</p>

<sub>📱 Android · 🍎 iOS · 🪟 Windows · 🍏 macOS · 🐧 Linux &nbsp;•&nbsp; iOS builds from source (App Store coming)</sub>

</div>

---

## Why Euphony?

- 🚫 **Zero Ads & Zero Tracking** — Music without interruptions or telemetry.
- 🎨 **Neo-Brutalist & Material 3 Design** — High-contrast slab borders, hard shadows, and expressive typography in both **Light** and **Dark** modes.
- ⚡ **Lightweight & Blazing Fast** — Engineered with Flutter & Riverpod for fluid 120Hz performance.
- ❤️ **100% Open Source** — Built by the community, for the community under the **GPL-3.0 License**.

---

## Core Features

| 🎧 Playback & Discovery | 📚 Library & Offline Storage |
| :--- | :--- |
| **• Universal Music Search** across tracks, albums, artists & playlists<br>**• Queue Management** with seamless shuffle, repeat-all, and repeat-one<br>**• Precision Speed Controls** (0.75x to 2.0x playback speed)<br>**• Smart Sleep Timer** with automatic fade-out<br>**• Native Media Controls** on lock screen, notification panel & wearables | **• Offline Downloads** for 100% offline local playback<br>**• Persistent Playlists** with instant SQLite storage<br>**• Adaptive Audio Quality** (High 256kbps AAC & Standard modes)<br>**• One-Tap Backup & Restore** of playlists and downloads<br>**• AMOLED Black Theme** for true OLED power saving |

---

## Download & Install

Grab the [**latest release**](https://github.com/MohammedNihadv/Euphony/releases/latest) and pick your platform:

| Platform | File | How to install |
| :--- | :--- | :--- |
| 🪟 **Windows** 10/11 | `euphony-windows-setup.exe` | Run the installer — no admin needed, adds Start-menu & desktop shortcuts. |
| 🍏 **macOS** | `euphony-macos.dmg` | Open the disk image and drag **Euphony** to Applications. |
| 🐧 **Linux** | `euphony-linux-x86_64.AppImage` | `chmod +x` the file and run it (requires `libmpv`). |
| 📱 **Android** | `app-arm64-v8a-release.apk` | ⭐ Best for 99% of phones (2017+). Tap to install. |
| 📱 Android (legacy) | `app-armeabi-v7a-release.apk` | Older 32-bit devices. |
| 📱 Android (x86) | `app-x86_64-release.apk` | Emulators & Intel Chromebooks. |
| 🍎 **iOS** | build from source | Requires Xcode + an Apple Developer account (App Store release planned). |

---

## Architecture & Tech Stack

| Technology | Role | Description |
| :--- | :--- | :--- |
| **[Flutter](https://flutter.dev)** | Core Framework | High-performance cross-platform UI engine |
| **[Riverpod](https://riverpod.dev)** | State Management | Type-safe, testable state & dependency injection |
| **[Drift](https://drift.simonbinder.eu)** + **SQLite** | Persistence Layer | Reactive local database for library and playlists |
| **just_audio** + **audio_service** | Audio Playback | Background audio playback with native OS media integration |
| **go_router** | Navigation | Declarative URL-based app routing |

---

## Contributing

We welcome contributions from developers, designers, and music lovers!

1. **Fork** the repository on GitHub.
2. **Clone** your fork locally and create a feature branch (`git checkout -b feature/amazing-feature`).
3. **Commit** your changes (`git commit -m 'feat: add amazing feature'`).
4. **Push** to your branch (`git push origin feature/amazing-feature`).
5. Open a **Pull Request** and describe your improvements!

---

## License

Euphony is free software released under the **[GNU General Public License v3.0 (GPL-3.0)](LICENSE)**.
