#!/bin/zsh
# Builds the Rust static library (rust/, release), then the Swift package against it; extra arguments go to
# `swift build` (e.g. -c release). Run: lib/FlowHarper/build.sh
set -eu
cd "${0:A:h}"
# rustup's default toolchain when cargo is not on PATH.
command -v cargo >/dev/null || PATH="$HOME/.rustup/toolchains/stable-aarch64-apple-darwin/bin:$PATH"
# No incremental caches: they are the bulk of a target/ folder and a release build gains nothing from them.
CARGO_INCREMENTAL=0 cargo build --release --manifest-path rust/Cargo.toml
# The module map links libflow_harper.a by name; this is where the linker finds it.
swift build -Xlinker -L"$PWD/rust/target/release" "$@"
