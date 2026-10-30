# Lemna

A line to write a thought down in one go, without rereading it. ⌃⌥Space summons a one-line box over the app you
are in, with the rest of the screen dimmed; you write forward while the text glides past a fixed caret, and ⌘⏎
puts the text into that app. A mechanical click per key, an optional ambience on the dim, and every key kept in
an encrypted journal on your Mac until the text has gone out. Nothing leaves your Mac.

The page: https://glia-org.github.io/lemna/

## Get it

macOS 14 or later. Download `Lemna-<version>.zip` from the [releases](https://github.com/glia-org/lemna/releases),
unzip, and move Lemna.app to Applications. The build is self-signed, not notarized: the first time, right-click
Lemna.app › Open, and confirm. Or build it yourself with the Xcode Command Line Tools:

```
app/make-cert.sh   # once: a self-signed "Lemna Dev" code-signing certificate in your login keychain
app/make-app.sh    # release build, signs and verifies app/build/Lemna.app
open app/build/Lemna.app
```

Lemna runs in the menu bar. The paste at ⌘⏎ needs the Accessibility permission (System Settings › Privacy &
Security › Accessibility); the first ⌘⏎ asks for it. Build, test and signing details: `app/README.md`.

## Layout

| path | what |
|---|---|
| `app/` | the macOS app (Swift, AppKit, Core Text, Metal for the ambience) and its tests |
| `lib/LemnaJournal/` | the append-only AES-GCM journal, key in the login keychain |
| `lib/LemnaClicks/` | the key clicks: four packs, their sources and licences in `THIRD_PARTY.md` |
| `site/` | the page, published by GitHub Pages |
| `assets/logo/` | the mark and the app icon |
| `DESIGN.md` | the decisions and the plan |
| `HANDOFF.md` | the current state |
| `docs/`, `research_notes/` | the design panels each decision was picked from, and the research behind them |

## Licence

Apache-2.0 (`LICENSE`). The sound packs are CC0 except the Electric pack (CC BY 4.0); credits in
`lib/LemnaClicks/THIRD_PARTY.md`.
