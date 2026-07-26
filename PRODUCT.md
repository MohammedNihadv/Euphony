# Product

## Register

product

## Users

Android listeners who want a lightweight YouTube Music client, especially users
coming from Harmony Music who value familiar streaming, library, and playback
workflows without fragile behavior. Secondary users are maintainers who need the
InnerTube integration to be understandable, typed, and testable when YouTube
changes response shapes.

## Product Purpose

Euphony rebuilds Harmony Music from scratch with a layered Flutter architecture.
Its purpose is to reach Harmony feature parity while making the brittle parts,
especially InnerTube parsing and playback, explicit, tested, and replaceable.
Success means a user can search, play, collect, cache, and manage music on
Android with predictable behavior and installable APKs at each phase.

## Brand Personality

Neo-Brutalist and confident: flat colour, hard black borders, zero-blur offset
shadows, heavy type. The interface should feel constructed rather than
atmospheric — built, not rendered. Album art still carries the emotion; the
chrome around it is deliberate structure, not decoration.

Boldness is not licence to be loose. The look holds together because a small
vocabulary repeats exactly: three accents, one border weight per role, one
shadow scale. See `lib/design/tokens/brutal.dart`.

## Anti-references

Avoid the soft-gradient, glassmorphic streaming look, and generic card-heavy
dashboards. Equally, avoid brutalism as an excuse for noise: a new colour per
surface, arbitrary border widths, or shadows that vary from screen to screen.

Avoid Harmony's fragile patterns: untyped dynamic maps, silent parser failures,
recursive retries, misspelled load-bearing setting keys, and storage models that
make ordering or migration brittle.

## Design Principles

- Ship vertical slices that prove the fragile integration points.
- Let music content lead; chrome should be bold but strictly systematic.
- Three accents, each with exactly one job. A fourth colour is a bug.
- Prefer typed contracts over display-string or map-shape guesses.
- Make failure visible and recoverable instead of silently empty.
- Keep UI paths close to the user's task: search, inspect, play, save.

## Accessibility & Inclusion

Use Material 3 semantics and target at least WCAG AA contrast for text and
controls. Respect system theme, support AMOLED dark mode without sacrificing
legibility, avoid color-only state communication, and keep motion short,
purposeful, and compatible with reduced-motion preferences.
