## Euphony v0.2.6 — Playback fixed for real 🎧

Songs now load and play. Earlier versions could resolve a track but then fail to actually play it ("Source error"), because YouTube's media servers reject the kind of large, open-ended download request the Android player makes by default.

### 🔧 Fixed
- **Music plays reliably again.** Euphony now streams audio in small chunks that YouTube's servers accept, instead of one big request they refuse. This fixes tracks that spun forever or failed to load — including on mobile data, IPv6, and networks with ad-blockers or proxies.
- **Switching songs no longer gets stuck.**

### ✨ Also in recent updates
- Update notifications when you open the app.
- A cleaner look and a fixed logo.

If a track still won't play, please [tell us](https://github.com/MohammedNihadv/Euphony/issues).

### 📥 Which APK should I download?

| APK File | Target Device | Recommendation |
| :--- | :--- | :--- |
| `app-arm64-v8a-release.apk` | Modern Android phones & tablets | **Best for 99% of devices** (2017 and newer). |
| `app-armeabi-v7a-release.apk` | Older 32-bit Android devices | For older or budget phones. |
| `app-x86_64-release.apk` | Emulators & Chromebooks | For emulators and Intel Chromebooks. |

---

Euphony is free, open source, and built by the community. ❤️
