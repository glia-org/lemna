#!/bin/zsh
# Builds Flow in release and assembles build/Flow.app, ad-hoc signed: there is no Developer ID yet (DESIGN.md E2, X1).
# Idempotent: the bundle is assembled afresh on each run. Run: app/make-app.sh
# LSUIElement: an accessory app from launch on (no Dock icon, no menu bar; DESIGN.md W2), as main.swift sets it too.
set -eu
cd "${0:A:h}"
# Harper (DESIGN.md R2) is a Rust static library that SwiftPM does not build: cargo first (rustup's default toolchain
# when cargo is not on PATH; no incremental caches, a release build gains nothing from them), then the Swift build
# with the linker told where the library is (../lib/FlowHarper/README.md, Linking).
command -v cargo >/dev/null || PATH="$HOME/.rustup/toolchains/stable-aarch64-apple-darwin/bin:$PATH"
harper="${PWD:h}/lib/FlowHarper/rust"
CARGO_INCREMENTAL=0 cargo build --release --manifest-path "$harper/Cargo.toml"
swift build -c release -Xlinker -L"$harper/target/release"
bin="$(swift build -c release --show-bin-path)"
app=build/Flow.app
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$bin/Flow" "$app/Contents/MacOS/Flow"
# The click pack (lib/FlowClicks, pack.json and its WAVs): SoundPack.bundled() loads it from Contents/Resources.
cp -R ../lib/FlowClicks/Sources/FlowClicks/DefaultPack "$app/Contents/Resources/DefaultPack"
cat > "$app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleIdentifier</key>
	<string>org.flow.app</string>
	<key>CFBundleName</key>
	<string>Flow</string>
	<key>CFBundleExecutable</key>
	<string>Flow</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>LSMinimumSystemVersion</key>
	<string>14.0</string>
	<key>LSUIElement</key>
	<true/>
	<key>NSHighResolutionCapable</key>
	<true/>
	<key>NSPrincipalClass</key>
	<string>NSApplication</string>
</dict>
</plist>
PLIST
plutil -lint -s "$app/Contents/Info.plist"
codesign --force --sign - --deep "$app"
codesign --verify --deep --strict "$app"
echo "$PWD/$app"
