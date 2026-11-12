# Lemna

A line to write a thought down in one go, without rereading it. ⌃⌥Space shows a one-line box over the app you
are in, with the rest of the screen dimmed; you write on while the text glides past a fixed caret, and ⌘⏎ pastes
the text into that app. Key sounds, a background sound and an animation on the dimmed screen are each optional.
Until you paste, copy or save the text, it is saved as you type, encrypted, on your Mac, so a crash loses nothing.
Nothing leaves your Mac.

The page: https://glia-org.github.io/lemna/

## Get it

macOS 14 or later. Download `Lemna-<version>.zip` from the [releases](https://github.com/glia-org/lemna/releases),
unzip, and move Lemna.app to Applications. The build is self-signed, not notarized by Apple, so macOS blocks it
the first time you open it; then click Open Anyway in System Settings › Privacy & Security. Or build it yourself
with the Xcode Command Line Tools:

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
| `lib/LemnaClicks/` | the key sounds and the background sounds: five packs and five beds, their sources and licences in `THIRD_PARTY.md` |
| `site/` | the page, published by GitHub Pages |
| `assets/logo/` | the mark and the app icon |
| `DESIGN.md` | the decisions and the plan |
| `HANDOFF.md` | the current state |
| `docs/`, `research_notes/` | the design panels each decision was picked from, and the research behind them |

## Licence

Apache-2.0 (`LICENSE`). The key-sound packs and the background sounds are CC0 except the Electric pack and the Lab
background sound (CC BY 4.0); credits in `lib/LemnaClicks/THIRD_PARTY.md`.

The Literata typeface in `app/Fonts/` (Still's line face) and its Latin subset the page serves (`site/assets/fonts/`) are
under the SIL Open Font License 1.1, its licence beside each; its source and version in `app/THIRD_PARTY.md`.
