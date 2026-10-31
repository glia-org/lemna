#!/bin/zsh
# Builds Lemna in release and assembles build/Lemna.app, signed with the "Lemna Dev" certificate from make-cert.sh when
# the login keychain holds it (its signature stays the same across builds, so the Accessibility grant and the keychain
# item survive a rebuild), else ad-hoc: there is no Developer ID yet (DESIGN.md E2, X1).
# Idempotent: the bundle is assembled afresh on each run. Run: app/make-app.sh
# LSUIElement: an accessory app from launch on (no Dock icon, no menu bar; DESIGN.md W2), as main.swift sets it too.
# The app icon (DESIGN.md L1): make-icon.swift draws the variant below into build/AppIcon.icns.
set -eu
cd "${0:A:h}"
icon=../assets/logo/icon-K1.svg  # K1 of docs/design-panel-icon-round-3.html (DESIGN.md L1)
swift build -c release
bin="$(swift build -c release --show-bin-path)"
app=build/Lemna.app
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$bin/Lemna" "$app/Contents/MacOS/Lemna"
# The symbol table's debug entries (STABS SO/OSO) name this machine's build folders by absolute path; strip them, and
# refuse a binary that still names any home folder (`strings` misses these entries, `nm -pa` sees them).
strip -S "$app/Contents/MacOS/Lemna"
if nm -pa "$app/Contents/MacOS/Lemna" | grep -q '/Users/'; then echo "the executable names a home folder; not built" >&2; exit 1; fi
swift make-icon.swift "$icon" build
cp build/AppIcon.icns "$app/Contents/Resources/AppIcon.icns"
# The click packs (lib/LemnaClicks, each a pack.json and its WAVs): SoundPack.bundled(<folder>) loads them from
# Contents/Resources; Session › Sound chooses among them. The beds (Beds/<name>, a bed.json and its loop) go in as one
# folder, where Bed.bundled(<name>) loads the one chosen.
cp -R ../lib/LemnaClicks/Sources/LemnaClicks/Beds "$app/Contents/Resources/Beds"
for pack in DefaultPack TypewriterPack SoftPack ElectricPack StonePack; do
  cp -R "../lib/LemnaClicks/Sources/LemnaClicks/$pack" "$app/Contents/Resources/$pack"
done
# The bundled fonts (Fonts, one folder per family with its licence, THIRD_PARTY.md): the app registers every font file
# in Contents/Resources/Fonts at launch (Theme.Typeface.register).
cp -R Fonts "$app/Contents/Resources/Fonts"
# The version: LEMNA_VERSION, else 0.0.0; the build number is the commit count.
version="${LEMNA_VERSION:-0.0.0}"
build="$(git rev-list --count HEAD 2>/dev/null || echo 0)"
cat > "$app/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleIdentifier</key>
	<string>dev.lemna.app</string>
	<key>CFBundleShortVersionString</key>
	<string>$version</string>
	<key>CFBundleVersion</key>
	<string>$build</string>
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
