#!/bin/zsh
# Builds Lemna in release and assembles build/Lemna.app, signed with the "Lemna Dev" certificate from make-cert.sh when
# the login keychain holds it (its signature stays the same across builds, so the Accessibility grant and the keychain
# item survive a rebuild), else ad-hoc: there is no Developer ID yet (DESIGN.md E2, X1).
# Idempotent: the bundle is assembled afresh on each run. Run: app/make-app.sh
# LSUIElement: an accessory app from launch on (no Dock icon, no menu bar; DESIGN.md W2), as main.swift sets it too.
# The app icon (DESIGN.md L1): make-icon.swift draws the variant below into build/AppIcon.icns.
set -eu
cd "${0:A:h}"
icon=../assets/logo/icon-I1-M3-b.svg  # J2 of docs/design-panel-icon-round-2.html, until the user's pick
swift build -c release
bin="$(swift build -c release --show-bin-path)"
app=build/Lemna.app
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$bin/Lemna" "$app/Contents/MacOS/Lemna"
swift make-icon.swift "$icon" build
cp build/AppIcon.icns "$app/Contents/Resources/AppIcon.icns"
# The click packs (lib/LemnaClicks, each a pack.json and its WAVs): SoundPack.bundled(<folder>) loads them from
# Contents/Resources; Session › Sound chooses among them.
for pack in DefaultPack TypewriterPack SoftPack ElectricPack; do
  cp -R "../lib/LemnaClicks/Sources/LemnaClicks/$pack" "$app/Contents/Resources/$pack"
done
cat > "$app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleIdentifier</key>
	<string>dev.lemna.app</string>
	<key>CFBundleName</key>
	<string>Lemna</string>
	<key>CFBundleExecutable</key>
	<string>Lemna</string>
	<key>CFBundleIconFile</key>
	<string>AppIcon</string>
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
# The identity, in this order: "Lemna Dev" (make-cert.sh); else "Flow Dev", the certificate make-cert.sh made before the
# rename (2026-10-28), so builds keep their signature until make-cert.sh runs again; else ad-hoc, with a notice.
sign="-"
if security find-identity -v -p codesigning | grep -q '"Lemna Dev"'; then sign="Lemna Dev"
elif security find-identity -v -p codesigning | grep -q '"Flow Dev"'; then sign="Flow Dev"
else echo "ad-hoc (no Lemna Dev certificate; app/make-cert.sh makes one)"; fi
codesign --force --sign "$sign" --deep "$app"
codesign --verify --deep --strict "$app"
echo "$PWD/$app"
