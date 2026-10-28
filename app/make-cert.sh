#!/bin/zsh
# Makes a self-signed code-signing certificate "Flow Dev" in the login keychain, for make-app.sh to sign with instead of
# ad-hoc (DESIGN.md E2: no Developer ID). Why: macOS ties the Accessibility (PostEvent) grant and the keychain item's
# access to the code signature, and an ad-hoc signature changes with every build; a certificate's does not. Run once
# (the keychain may ask for the login password; the first codesign with it asks once, answer Always Allow):
#   app/make-cert.sh
# Idempotent: with "Flow Dev" already in the keychain it only prints the identity. Private key never leaves the keychain.
set -eu
name="Flow Dev"
if security find-identity -v -p codesigning | grep -q "\"$name\""; then
    security find-identity -v -p codesigning | grep "\"$name\""
    exit 0
fi
openssl="$(ls /opt/homebrew/opt/openssl@3/bin/openssl /usr/bin/openssl 2>/dev/null | head -1)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
"$openssl" req -x509 -newkey rsa:2048 -nodes -days 3650 -subj "/CN=$name" \
    -addext "keyUsage=critical,digitalSignature" -addext "extendedKeyUsage=critical,codeSigning" \
    -keyout "$tmp/key.pem" -out "$tmp/cert.pem" 2>/dev/null
# The legacy PBE and MAC: macOS's import does not read OpenSSL 3's default (AES, SHA-256 MAC) and fails with "MAC verification failed".
"$openssl" pkcs12 -export -name "$name" -inkey "$tmp/key.pem" -in "$tmp/cert.pem" -out "$tmp/id.p12" -passout pass:flow \
    -keypbe PBE-SHA1-3DES -certpbe PBE-SHA1-3DES -macalg sha1
keychain="$HOME/Library/Keychains/login.keychain-db"
security import "$tmp/id.p12" -k "$keychain" -P flow -T /usr/bin/codesign -T /usr/bin/security
# Trusted for code signing by this user, so codesign accepts it as a valid identity.
security add-trusted-cert -p codeSign -k "$keychain" "$tmp/cert.pem"
security find-identity -v -p codesigning | grep "\"$name\""
