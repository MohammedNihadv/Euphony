# Euphony

A music streaming client for Android — a from-scratch rebuild of the archived
[Harmony Music](https://github.com/anandnet/Harmony-Music), keeping its hard-won
YouTube InnerTube work and replacing everything around it.

Status: **phase 0 of 8** — foundations. Not usable yet.

## Why

Harmony is archived. Its search broke in the wild, playback bugs recur, and forks
patch it piecemeal. Euphony targets feature parity with Harmony 1.12.2 on a
layered architecture with tests around the parts that actually break.

## Stack

| | |
|---|---|
| Flutter | 3.44.1 / Dart 3.12 |
| State | Riverpod 3.3 (codegen) |
| Database | Drift 2.34 / SQLite |
| Settings | shared_preferences behind a typed repository |
| Design | Material 3 with an own token layer in `lib/design/` |

## Layout

```
lib/
├── app/          MaterialApp, shell
├── core/         Result / Failure, logging, retry
├── design/       tokens, theme, components  ← the only place styling lives
├── data/         db/, remote/, repository/
├── domain/       immutable models
├── playback/     audio handler, queue
└── features/     one folder per screen area
```

One rule: `features/` talks to `repository/`, never to Drift or the network
directly.

## Develop

```sh
flutter pub get
dart run build_runner build     # after touching @riverpod or Drift tables
dart run build_runner watch     # or leave this running
flutter run
```

Generated `*.g.dart` files are committed. CI regenerates them and fails if they
drift from their inputs.

Before pushing:

```sh
dart format .
flutter analyze
flutter test
```

## Phases

| # | Phase | State |
|---|---|---|
| 0 | Foundations — Riverpod, Drift, design system, CI | in progress |
| 1 | Data layer — InnerTube client, parsers, golden tests | |
| 2 | Playback — just_audio gapless queue, media session | |
| 3 | Shell + core UI — tabs, mini player, search | |
| 4 | Library — playlists, albums, artists, history | |
| 5 | Offline — cache, downloads, tagging | |
| 6 | Extras — radio, lyrics, sleep timer, equalizer | |
| 7 | Portability — backup, import/export, Piped | |
| 8 | Polish — locales, branding, a11y, signing | |

Each phase ends with an installable APK.

## Credit

The InnerTube endpoint knowledge and response paths are ported from Harmony
Music by anandnet. Euphony would not be possible without that reverse
engineering.
