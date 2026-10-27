# FlowHarper

Offline English grammar and spelling suggestions for Flow's review (`DESIGN.md` R2), from
[Harper](https://github.com/Automattic/harper): its `harper-core` crate, built in `rust/` as a static library with a
C ABI (`include/flow_harper.h`), wrapped by this Swift package. macOS 14+, no package dependencies, nothing leaves
the Mac.

```swift
import FlowHarper

for s in Harper.lint(text) {          // in text order, ranges disjoint
    text[s.range]                     // the flagged text
    s.kind                            // Harper's lint kind: "Spelling", "Typo", "Repetition", …
    s.message                         // Harper's text, may hold Markdown (`code`)
    s.replacements                    // each replaces s.range in full; "" deletes
}
Harper.version                        // "harper-core 3.0.0"
```

- Harper's standard rule set (`LintGroup::new_curated`) with its curated default config, the American dialect, plain
  text (not Markdown). One linter per process, built on the first call.
- Overlapping lints are reduced to the more important one (`harper_core::remove_overlaps`), so each suggestion can
  be accepted on its own.
- Harper's ranges count Unicode scalars, the C ABI UTF-8 bytes; `lint` converts them to `String.Index` and drops a
  suggestion whose range starts or ends inside a Character (Harper ends `teh` before a combining accent on its
  `h`, for one).
- `lint` is safe from any thread; calls run one at a time. A panic inside Harper gives `[]`, never a crash.
- The dialect flags British spellings: in the test text, `labelled` and `Afterwards` come back as Spelling.

## Build

Rust (rustup's stable toolchain) and the Command Line Tools:

```sh
lib/FlowHarper/build.sh            # cargo build --release in rust/, then swift build with the -L below
```

By hand, from `lib/FlowHarper`:

```sh
CARGO_INCREMENTAL=0 cargo build --release --manifest-path rust/Cargo.toml
swift build -Xlinker -L"$PWD/rust/target/release"
```

## Test

```sh
F=/Library/Developer/CommandLineTools/Library/Developer/Frameworks
swift test -Xswiftc -F -Xswiftc $F -Xlinker -F -Xlinker $F -Xlinker -rpath -Xlinker $F \
    -Xlinker -L"$PWD/rust/target/release"
(cd rust && CARGO_INCREMENTAL=0 cargo test --release -- --nocapture)    # prints the latencies
```

The Swift tests: the planted errors (`teh` → `the`, `a idea` → `an idea`, `the the` → `the`), a clean sentence, offsets
past `é`, `ö`, 🙂 and 👩‍💻, a suggestion inside a Character dropped, the version, and the 1,000-word text
(`Tests/prose-1000.txt`, shared with the Rust test) under 100 ms on the second call and after an edit. No file
imports Foundation next to Testing (`FlowJournal/README.md`); the test reads the text with Darwin's stdio.

## Linking

The module map (`include/module.modulemap`) carries `link "flow_harper"`, so every target that imports FlowHarper
asks the linker for `libflow_harper.a`; the build command says where it is:

```sh
-Xlinker -L<absolute path to lib/FlowHarper/rust/target/release>
```

Without it the link fails with `Could not find or use auto-linked library 'flow_harper'` and
`symbol(s) not found`. The path goes on the command line rather than into `Package.swift` because a linker
search path there has to be `unsafeFlags`, which SwiftPM refuses in a package fetched by URL; a path dependency (as
the app uses) accepts them. Run cargo before `swift build`: SwiftPM does not know about `rust/`.

System libraries: `cargo rustc --release -- --print native-static-libs` names `-liconv -lSystem -lc -lm`.
`libSystem` (with libc and libm) is linked into every Swift binary; the library uses nothing from `libiconv` (a
dead-stripped C program and the Swift tests link without it). No framework is needed.

## Sizes and latency

Measured 2026-10-27 on an Apple M2 Pro, release Rust with LTO (`rust/Cargo.toml`):

| | |
|---|---|
| `libflow_harper.a` | 17.0 MB (56 MB without LTO) |
| a release executable that links it (dead-stripped) | 9.5 MB, about what the app grows by |
| Swift test binary (debug) | 9.7 MB |
| `rust/target` after build and test (git-ignored) | 589 MB; `.build` 124 MB |
| cold build: cargo / swift | 90 s / 23 s |

996 words of prose with four planted errors (8 suggestions), Rust test through the C ABI:

| Call | Time |
|---|---|
| first in the process (builds the linter, about 300 ms, then lints) | 356–399 ms |
| the same text again | 16–17 ms |
| after a one-word edit | 17–18 ms |
| a different 1,000-word text (most sentences new) | 67–70 ms |

The Swift test (debug Swift, the linter already built by the tests before it) prints about 100 ms for its first lint
of the text, 16–17 ms for the second and 17–18 ms after an edit.

Harper caches per sentence (its pattern rules in the shared linter, its neural noun-phrase chunker per thread), hence
the spread. A first call on a thread that has not linted before costs 43–64 ms for the same text. So the app should
make one call early, off the main thread, and lint from one long-lived thread.
