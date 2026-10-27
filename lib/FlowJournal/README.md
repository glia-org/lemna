# FlowJournal

The never-lose, private journal of Flow (`DESIGN.md` E2). One encrypted, append-only file per writing session; the
session's key sits in the keychain and is destroyed on Done or Discard, which leaves the file unreadable noise.
No dependencies; macOS 14+.

```swift
let journal = try Journal.open(directory: sessions, keyStore: KeychainKeyStore())
model.apply(journal.replay)        // what was recovered; empty for a new session
journal.append(.insert("w"))       // returns at once; written within 50 ms
journal.flush(.full)               // on ~1 s idle, on deactivate, on quit
try journal.finish()               // Done: key destroyed, then the file deleted
```

## What survives

| Event | Text kept | Why |
|---|---|---|
| App crash, force quit, `kill -9` | all but the last ≤ 50 ms | each 50 ms batch is `write()`n at once; the kernel keeps written bytes past the process (tested) |
| ⌘Q | all | the app calls `flush(.full)` on quit; quitting never discards |
| Logout, restart, OS update | all | as ⌘Q; the key stays in the keychain |
| Power loss, kernel panic | up to the last `.full` flush (≈ 1 s idle), often more | a barrier after every batch keeps the file a valid prefix of the session |
| Done, Discard | nothing, by design | key destroyed first, then the file deleted |

**Residual:** local APFS snapshots (about hourly, kept up to 24 h, plus one before each macOS update) hold the journal
and the keychain file as they were. Until macOS thins them, someone in control of the logged-in account on this Mac
might recover a finished session. Nothing can exclude a file from a snapshot.

## Privacy on disk

- The directory is created 0700, each file 0600. Every `open` marks the directory excluded from Time Machine (the
  sticky `com_apple_backup_excludeItem` attribute; `tmutil isexcluded` reports it). Backups carry the keychain but
  not the journal, so the key opens nothing there.
- Spotlight: give the directory a `.noindex` suffix. Recommended: `~/Library/Application Support/Flow/sessions.noindex/`.
  The library takes any directory.
- The file holds no timestamps. Edits within 50 ms share one record, so records follow bursts, not single keys; the
  record sizes still show roughly how much each burst typed.
- Each journal holds an exclusive `flock` on its file while it lives; `open` skips a locked file (in use by
  another process or instance) and starts a new session instead.

## The key

- **Now:** the login keychain (the file-based one), a generic password with service `org.flow.app.session` and the
  session's UUID as account. Apple's documentation allows `kSecAttrAccessible` on macOS only in the data protection
  keychain, so this item has no `WhenUnlockedThisDeviceOnly` class: it is readable while the login keychain is
  unlocked and moves with the keychain file (backups, Migration Assistant). Its access list names the build that
  created it; an ad-hoc signed rebuild may make macOS ask before a session is restored.
- **Later**, with a Developer ID and a provisioning profile carrying `keychain-access-groups`:
  `KeychainKeyStore(useDataProtectionKeychain: true)`, which uses the data protection keychain with
  `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` and does not prompt. Without the profile it fails with -34018.
  Sessions open in one keychain at the switch are not seen by the other; finish them first.

## Format

`<uuid>.journal`: `FLOWJ1`, the session UUID (16 bytes), then records. A record is a 4-byte little-endian length and an
AES-256-GCM `SealedBox.combined` (random 12-byte nonce, ciphertext, tag) of `{"seq": n, "edits": [...]}`. The sequence
number is also the authenticated data, so a reordered, dropped or foreign record stops the replay there. A torn
tail is ignored and cut off before new records are written. `open` reports journals it cannot read (no key, or
the first record does not open) in `unreadable`; the app may delete them.

## Test

The Command Line Tools need the Testing framework passed by hand:

```sh
F=/Library/Developer/CommandLineTools/Library/Developer/Frameworks
swift test -Xswiftc -F -Xswiftc $F -Xlinker -F -Xlinker $F -Xlinker -rpath -Xlinker $F
```

The login-keychain test is skipped unless `FLOW_KEYCHAIN_TEST=1` is set (it writes, reads and deletes one item; the
keychain may prompt). The timing test prints the cost of a record with each flush level and of restoring a long
session. `Package.swift` turns off cross-import overlays for the test target: the Command Line Tools 26.1 ship
`_Testing_Foundation.framework` without its module, so `import Testing` with `import Foundation` fails otherwise.
