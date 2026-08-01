<div align="center">

<img src="docs/screenshots/banner.png" alt="Euphony Open Source Neo-Brutalist Music Player" width="100%"/>

<br>

[![Flutter](https://img.shields.io/badge/Flutter-3.44+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Release](https://img.shields.io/badge/Release-v0.2.0-6A4BE8?style=for-the-badge&logo=github&logoColor=white)](https://github.com/MohammedNihadv/Euphony/releases)
[![License](https://img.shields.io/badge/License-GPL--3.0-24292E?style=for-the-badge&logo=open-source-initiative&logoColor=white)](LICENSE)
[![Stars](https://img.shields.io/github/stars/MohammedNihadv/Euphony?style=for-the-badge&color=F5C518)](https://github.com/MohammedNihadv/Euphony)

<br>

<p align="center">
  <a href="https://euphonymusic.vercel.app/">
    <img src="https://img.shields.io/badge/🌐_Visit_Official_Website-6A4BE8?style=for-the-badge&logo=vercel&logoColor=white" alt="Official Website"/>
  </a>
  <a href="https://github.com/MohammedNihadv/Euphony/releases">
    <img src="https://img.shields.io/badge/📥_Download_Latest_APK-181824?style=for-the-badge&logo=android&logoColor=white" alt="Download APK"/>
  </a>
</p>

</div>

---

## 💎 Why Euphony?

Somewhere along the way, music players became subscription services, shuffle became a premium feature, and ads started interrupting your playlists.

**Euphony is a music player that simply gets out of your way:**

- 🚫 **Zero Ads & Zero Tracking** — Music without interruptions or telemetry.
- 🎨 **Neo-Brutalist & Material 3 Design** — High-contrast slab borders, hard shadows, and expressive typography in both **Light** and **Dark** modes.
- ⚡ **Lightweight & Blazing Fast** — Engineered with Flutter & Riverpod for fluid 120Hz performance.
- ❤️ **100% Open Source** — Built by the community, for the community under the **GPL-3.0 License**.

---

## ⚡ Core Features

| 🎧 Playback & Discovery | 📚 Library & Offline Storage |
| :--- | :--- |
| **• Universal Music Search** across tracks, albums, artists & playlists<br>**• Queue Management** with seamless shuffle, repeat-all, and repeat-one<br>**• Precision Speed Controls** (0.75x to 2.0x playback speed)<br>**• Smart Sleep Timer** with automatic fade-out<br>**• Native Media Controls** on lock screen, notification panel & wearables | **• Offline Downloads** for 100% offline local playback<br>**• Persistent Playlists** with instant SQLite storage<br>**• Adaptive Audio Quality** (High 256kbps AAC & Standard modes)<br>**• One-Tap Backup & Restore** of playlists and downloads<br>**• AMOLED Black Theme** for true OLED power saving |

---

## 📦 Which APK Should I Download?

| APK Filename | Target Device | Recommendation |
| :--- | :--- | :--- |
| `app-arm64-v8a-release.apk` | **Modern Android Phones & Tablets** | ⭐ **Recommended for 99% of users** (devices from 2017+). Smallest download size (~42 MB) and optimized 64-bit performance. |
| `app-armeabi-v7a-release.apk` | **Older / Budget Android Devices** | For legacy 32-bit smartphones or older tablets. |
| `app-x86_64-release.apk` | **Emulators, PCs & Chromebooks** | For Android Studio / BlueStacks emulators and Intel/AMD Chromebooks. |

---

## 🛠️ Architecture & Tech Stack

| Technology | Role | Description |
| :--- | :--- | :--- |
| **[Flutter](https://flutter.dev)** | Core Framework | High-performance cross-platform UI engine |
| **[Riverpod](https://riverpod.dev)** | State Management | Type-safe, testable state & dependency injection |
| **[Drift](https://drift.simonbinder.eu)** + **SQLite** | Persistence Layer | Reactive local database for library and playlists |
| **just_audio** + **audio_service** | Audio Playback | Background audio playback with native OS media integration |
| **go_router** | Navigation | Declarative URL-based app routing |

---

## 🤝 Contributing

We welcome contributions from developers, designers, and music lovers!

1. **Fork** the repository on GitHub.
2. **Clone** your fork locally and create a feature branch (`git checkout -b feature/amazing-feature`).
3. **Commit** your changes (`git commit -m 'feat: add amazing feature'`).
4. **Push** to your branch (`git push origin feature/amazing-feature`).
5. Open a **Pull Request** and describe your improvements!

---

## 📄 License

Euphony is free software released under the **[GNU General Public License v3.0 (GPL-3.0)](LICENSE)**.