# Handoff

`DESIGN.md` holds the decisions and the plan. This file says what is done and what is next.

## State (2026-10-27)

- Research, panel, report: done (`docs/`, `reports/`, `research_notes/`).
- Spike GPUI vs AppKit: done, results in `DESIGN.md`; the user chose T2 (Swift + AppKit).
- App: not started. Milestone 1 (surface) is next; it seeds from `spikes/appkit-line` (clip-at-caret patch pending).

## Build and run

- Spikes: `spikes/run-bench.sh` (two visible windows; under AeroSpace click the AppKit window once).
- App: `app/make-app.sh` (to be written in milestone 1) builds with SwiftPM and assembles `Flow.app`, ad-hoc signed.

## Rules carried over

- No personal or site details in the repo (names, home paths, hosts); placeholders only.
- Commits: no Co-Authored-By trailers, no "Generated with" lines.
