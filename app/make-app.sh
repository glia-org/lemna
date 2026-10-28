#!/bin/zsh
# Builds Flow in release and assembles build/Flow.app, signed with the "Flow Dev" certificate from make-cert.sh when the
# login keychain holds it (its signature stays the same across builds, so the Accessibility grant and the keychain
# item survive a rebuild), else ad-hoc: there is no Developer ID yet (DESIGN.md E2, X1).
# Idempotent: the bundle is assembled afresh on each run. Run: app/make-app.sh
# LSUIElement: an accessory app from launch on (no Dock icon, no menu bar; DESIGN.md W2), as main.swift sets it too.
set -eu
cd "${0:A:h}"
swift build -c release
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
sign="-"
if security find-identity -v -p codesigning | grep -q '"Flow Dev"'; then sign="Flow Dev"; else echo "ad-hoc (no Flow Dev certificate; app/make-cert.sh makes one)"; fi
codesign --force --sign "$sign" --deep "$app"
codesign --verify --deep --strict "$app"
echo "$PWD/$app"
