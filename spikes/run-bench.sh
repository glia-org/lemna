#!/bin/bash
# The sliding-line spike (SPEC.md): builds both halves in release, runs each with --bench, then prints the two
# summaries side by side as one table. Idempotent: a rerun rebuilds only what changed and overwrites results/.
# Each bench opens a window, takes the focus and types for ~30 s; leave the keyboard and mouse alone meanwhile.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
results="$here/results"
mkdir -p "$results"
export PATH="$HOME/.rustup/toolchains/stable-aarch64-apple-darwin/bin:$PATH"
clock() { perl -MTime::HiRes=time -e 'printf "%.1f", time'; }

# --- GPUI half ---------------------------------------------------------------------------------------------------
gpui="$here/gpui-line"
bin="$gpui/target/release/gpui-line"
cold=0
[ -x "$bin" ] || cold=1
t0=$(clock)
(cd "$gpui" && CARGO_INCREMENTAL=0 cargo build --release)
t1=$(clock)
# A cold build (no target/release yet) records its wall time; a rebuild keeps the recorded one.
if [ "$cold" = 1 ]; then
  perl -e "printf '%.1f', $t1 - $t0" > "$gpui/cold-build-seconds.txt"
fi
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
strip -o "$tmp/gpui-line" "$bin"
export GPUI_LINE_STRIPPED_BYTES="$(stat -f%z "$tmp/gpui-line")"
# Crates compiled on this Mac (normal and build dependencies, without the crate itself).
export GPUI_LINE_DEPS="$(cd "$gpui" && cargo tree -e normal,build --prefix none \
  | sed -E 's/ \((\*|proc-macro)\)//g' | sort -u | grep -vc '^gpui-line ')"
export GPUI_LINE_COLD_BUILD_S="$(cat "$gpui/cold-build-seconds.txt" 2>/dev/null || echo n/a)"
echo "== gpui-line --bench"
"$bin" --bench

# --- AppKit half -------------------------------------------------------------------------------------------------
appkit="$here/appkit-line"
# Its own script: a cold release build, timed, and the stripped size, into results/appkit-build.txt (its summary reads it).
"$appkit/build.sh"
echo "== appkit-line --bench"
"$appkit/.build/release/appkit-line" --bench

# --- One table: a row per "key: value" line found in either summary ----------------------------------------------
echo
awk -F': ' '
  FNR == 1 { f++ }
  /: / { k = $1; v = substr($0, length($1) + 3)
         if (!(k in seen)) { seen[k] = 1; order[++n] = k }
         val[f, k] = v }
  END { printf "%-30s | %-48s | %s\n", "", "GPUI", "AppKit"
        for (i = 1; i <= n; i++) { k = order[i]; printf "%-30s | %-48s | %s\n", k, val[1, k], val[2, k] } }
' "$results/gpui-summary.txt" "$results/appkit-summary.txt"
