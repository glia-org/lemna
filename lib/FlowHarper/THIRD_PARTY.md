# Third-party material in FlowHarper

## harper-core 3.0.0

- Crate: https://crates.io/crates/harper-core/3.0.0 (published 2026-10-26), pinned `=3.0.0` in `rust/Cargo.toml`.
- Source: https://github.com/Automattic/harper (Automattic), tag `v3.0.0`.
- Licence: **Apache-2.0** (the crate's `license` field and the repository's `LICENSE`).
- Built with `default-features = false, features = ["concurrent"]`: the default `thesaurus` feature (crate
  `harper-thesaurus`, Apache-2.0) is left out; only the BoringWords rule reads it, and the curated config turns that
  rule off.
- Compiled in from the same repository, all Apache-2.0: `harper-brill` 3.0.0 (Brill part-of-speech tagger and a small
  neural noun-phrase chunker, model and vocabulary embedded) and `harper-pos-utils` 3.0.0.

### The dictionary

`harper-core` embeds its curated English dictionary (`dictionary.dict`, 54,900 entries in 3.0.0, with
`annotations.json` for affixes and word metadata). Provenance, from the repository's history:

- It entered the repository on 2024-01-20 (commit `ecb2534e80`, "Fully functional with new dictionary") as a Hunspell
  word list of 49,568 entries plus an affix file. That word list is byte-identical to the **en_US Hunspell
  dictionary built from SCOWL** (Spell Checker Oriented Word Lists, http://wordlist.aspell.net/), version
  2020.12.07, as packaged in https://github.com/wooorm/dictionaries (`dictionaries/en/index.dic`; checked
  2026-10-27 with `diff`), and the affix file starts with the same header.
- Harper's contributors have since extended and re-annotated it (dialect spellings, their own annotation format).
- SCOWL's licence is permissive (an MIT/BSD-style notice, with parts under the Ispell BSD licence and WordNet's
  licence); it asks that its copyright and permission notice appear in supporting documentation. The full notice
  is in `dictionaries/en/license` of the wooorm repository above and in SCOWL's own `Copyright` file. Harper's
  repository (v3.0.0: an Apache-2.0 `LICENSE`, no SCOWL notice) does not carry it; a distributed build of
  Flow should include it with the other notices.

## Other crates compiled into the library

About 200 crates in the build graph (proc-macros included), most of them through `harper-brill` (the `burn`
neural-network crates, `ndarray`, `rayon`) and `ammonia` (`html5ever`). Licences: MIT and/or Apache-2.0 for almost
all; also Zlib, Unicode-3.0 (the `icu_*` crates), BSD-2-Clause, CC0-1.0, Unlicense, and **MPL-2.0** (`colored`,
`cssparser`, `dtoa-short`: file-level copyleft; used unmodified). The exact list with versions:
`cd rust && cargo tree -e normal --target aarch64-apple-darwin --prefix none --format '{p} | {l}'`. Before Flow is
distributed (DESIGN X1), the app's notices file needs the MIT and BSD texts these require.
