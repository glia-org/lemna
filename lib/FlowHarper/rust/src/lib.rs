//! Harper's English grammar and spelling lints behind a C ABI, for Flow's review (DESIGN.md R2).
//! `include/flow_harper.h` documents the ABI; the Swift package `FlowHarper` wraps it.

use std::ffi::{CStr, CString, c_char};
use std::panic::catch_unwind;
use std::sync::{LazyLock, Mutex};

use harper_core::linting::{LintGroup, Linter, Suggestion};
use harper_core::spell::FstDictionary;
use harper_core::{Dialect, Document, remove_overlaps};

/// Kept in step with the `=` pin in Cargo.toml; a test compares it with the crate's own version.
const VERSION: &CStr = c"harper-core 3.0.0";

/// One linter per process: building the rule set costs several lints, and the group caches its pattern rules'
/// results per chunk, which a re-lint after a small edit reuses.
static LINTER: LazyLock<Mutex<LintGroup>> = LazyLock::new(|| Mutex::new(new_linter()));

/// Harper's standard rule set with its curated default config (what Harper's own integrations use).
fn new_linter() -> LintGroup {
    LintGroup::new_curated(FstDictionary::curated(), Dialect::American)
}

fn lint_json(text: &str) -> String {
    let document = Document::new_plain_english_curated(text);
    let mut lints = {
        let mut linter = LINTER.lock().unwrap_or_else(|poisoned| {
            // A panic inside an earlier lint may have left the caches half written: start from a fresh group.
            let mut linter = poisoned.into_inner();
            *linter = new_linter();
            LINTER.clear_poison();
            linter
        });
        linter.lint(&document)
    };
    // Rules overlap (a misspelling inside a flagged phrase); the review accepts changes one at a time, which needs
    // disjoint ranges. Harper's own helper keeps the more important lint, as harper.js does with `dedup`.
    remove_overlaps(&mut lints);
    lints.sort_by_key(|lint| (lint.span.start, lint.span.end));

    // Harper's spans count chars (Unicode scalars); the ABI speaks UTF-8 bytes. Entry n is char n's byte offset,
    // with the text's length appended for spans that end at the end.
    let mut byte_at: Vec<usize> = text.char_indices().map(|(offset, _)| offset).collect();
    byte_at.push(text.len());

    let suggestions: Vec<serde_json::Value> = lints
        .iter()
        .filter_map(|lint| {
            let (&start, &end) = (byte_at.get(lint.span.start)?, byte_at.get(lint.span.end)?);
            if start > end {
                return None;
            }
            // Every suggestion becomes the text that replaces start..end, so a caller needs one operation.
            let replacements: Vec<String> = lint
                .suggestions
                .iter()
                .map(|suggestion| match suggestion {
                    Suggestion::ReplaceWith(chars) => chars.iter().collect(),
                    Suggestion::InsertAfter(chars) => text[start..end].chars().chain(chars.iter().copied()).collect(),
                    Suggestion::Remove => String::new(),
                })
                .collect();
            Some(serde_json::json!({
                "start": start,
                "end": end,
                "kind": lint.lint_kind.to_string_key(),
                "message": lint.message,
                "replacements": replacements,
            }))
        })
        .collect();
    serde_json::to_string(&suggestions).unwrap_or_else(|_| "[]".to_owned())
}

/// See `include/flow_harper.h`.
///
/// # Safety
/// `utf8` points at `len` readable bytes, or is null.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn fh_lint(utf8: *const c_char, len: usize) -> *mut c_char {
    let json = catch_unwind(|| {
        if utf8.is_null() || len == 0 {
            return "[]".to_owned();
        }
        // SAFETY: the caller promises `len` readable bytes at `utf8`.
        let bytes = unsafe { std::slice::from_raw_parts(utf8.cast::<u8>(), len) };
        std::str::from_utf8(bytes).map_or_else(|_| "[]".to_owned(), lint_json)
    })
    .unwrap_or_else(|_| "[]".to_owned());
    // serde_json escapes U+0000, so the JSON has no interior NUL; the fallback only keeps this path panic-free.
    CString::new(json).unwrap_or_else(|_| c"[]".to_owned()).into_raw()
}

/// See `include/flow_harper.h`.
///
/// # Safety
/// `json` came from `fh_lint` and is freed once, or is null.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn fh_free(json: *mut c_char) {
    if !json.is_null() {
        // SAFETY: `json` came from `CString::into_raw` in `fh_lint` and has not been freed.
        drop(unsafe { CString::from_raw(json) });
    }
}

/// See `include/flow_harper.h`.
#[unsafe(no_mangle)]
pub extern "C" fn fh_version() -> *const c_char {
    VERSION.as_ptr()
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::time::{Duration, Instant};

    fn lint(text: &str) -> Vec<serde_json::Value> {
        // Through the C ABI, as the Swift package calls it.
        let json = unsafe { fh_lint(text.as_ptr().cast(), text.len()) };
        let parsed = serde_json::from_slice(unsafe { CStr::from_ptr(json) }.to_bytes()).unwrap();
        unsafe { fh_free(json) };
        parsed
    }

    #[test]
    fn version_matches_the_crate() {
        assert_eq!(VERSION.to_str().unwrap(), format!("harper-core {}", harper_core::core_version()));
    }

    #[test]
    fn null_empty_and_invalid_utf8_give_an_empty_array() {
        // None of these reaches the linter, so this test does not warm it for the latency test.
        for (ptr, len) in [(std::ptr::null(), 5), (c"".as_ptr(), 0), (c"\xff\xfe".as_ptr(), 2)] {
            let json = unsafe { fh_lint(ptr, len) };
            assert_eq!(unsafe { CStr::from_ptr(json) }, c"[]");
            unsafe { fh_free(json) };
        }
    }

    /// The only test that lints, so its first call is the process's first and includes building the linter.
    #[test]
    fn latency_of_1000_words() {
        let text = include_str!("../../Tests/prose-1000.txt");
        // The review re-lints after each accepted change: one chunk differs, the rest hit the group's cache.
        let edited = text.replacen("one bakery", "one bakry", 1);
        // Most sentences differ, so few chunks hit the cache: what a new session's text costs on a warm linter.
        let other = text.replace(" the ", " this ").replace(" and ", " or ");
        assert!(edited != text && other != text);

        let timed = |text: &str| {
            let started = Instant::now();
            let suggestions = lint(text);
            (started.elapsed(), suggestions)
        };
        let (first, suggestions) = timed(text);
        let (second, _) = timed(text);
        let (after_edit, _) = timed(&edited);
        let (other_text, _) = timed(&other);
        let ms = |d: Duration| d.as_secs_f64() * 1000.0;
        println!(
            "{} words, {} suggestions: first call {:.1} ms (builds the linter), second {:.1} ms, \
             after a one-word edit {:.1} ms, another text {:.1} ms",
            text.split_whitespace().count(),
            suggestions.len(),
            ms(first),
            ms(second),
            ms(after_edit),
            ms(other_text)
        );

        let starts: Vec<u64> = suggestions.iter().map(|s| s["start"].as_u64().unwrap()).collect();
        assert!(starts.is_sorted());
        for (wrong, right) in [("Teh", "The"), ("recieve", "receive")] {
            let found = suggestions.iter().any(|s| {
                let range = s["start"].as_u64().unwrap() as usize..s["end"].as_u64().unwrap() as usize;
                &text[range] == wrong && s["replacements"].as_array().unwrap().iter().any(|r| r == right)
            });
            assert!(found, "{wrong} → {right} not suggested");
        }
        assert!(second < Duration::from_millis(100) && after_edit < Duration::from_millis(100));
    }
}
