// flow_harper: Harper's English grammar and spelling suggestions (harper-core, Rust) behind a C ABI, for Flow's
// review (DESIGN.md R2). Built by rust/ as libflow_harper.a. Every function is safe to call from any thread; lints
// run one at a time on one cached linter.
#ifndef FLOW_HARPER_H
#define FLOW_HARPER_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

// Lints `len` bytes of UTF-8 at `utf8` (null with any length, or invalid UTF-8, gives an empty array) with Harper's
// standard rule set, its curated default config and the American dialect, and returns a JSON array:
//
//   [{"start": 12, "end": 15, "kind": "Typo", "message": "Did you mean ...?", "replacements": ["the"]}, ...]
//
// - start, end: UTF-8 byte offsets into the input, end exclusive, on Unicode scalar boundaries (not necessarily
//   on grapheme cluster boundaries).
// - kind: Harper's LintKind name (Spelling, Typo, Grammar, Repetition, Capitalization, ...).
// - message: Harper's text; may hold Markdown (`code`, **bold**).
// - replacements: zero or more texts, each replacing start..end in full ("" deletes it).
//
// Sorted by start; ranges do not overlap (Harper's remove_overlaps keeps the more important one). `[]` when there
// is nothing to suggest, and also when the linter fails: a panic never crosses this boundary. The first call in a
// process also builds the linter, which takes several times longer than a lint (README, Latency).
//
// Never null. Free with fh_free, once.
char *_Nonnull fh_lint(const char *_Nullable utf8, size_t len);

// Frees a string from fh_lint. Null is ignored.
void fh_free(char *_Nullable json);

// "harper-core x.y.z", the linked version. Static: do not free.
const char *_Nonnull fh_version(void);

#ifdef __cplusplus
}
#endif

#endif
