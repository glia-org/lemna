# Never lose typed text, without storing it in the clear (macOS 14 – 26)

Notes for the report writer. Three kinds of evidence are marked:
- **[web]**: a cited web source.
- **[measured]**: measured for this research on one Mac (Apple M2 Pro, Mac14,9; macOS 26.5.2; internal APFS SSD, FileVault on). Methods:
  - **Method A (fsync)**: a C program appended 64-byte records 500 times per mode to a file opened with `O_APPEND`, timing `write()` plus the sync call. It also timed an atomic replace of a 16 KiB file: write a temp file, sync it, `rename()`, then sync the directory. Two runs.
  - **Method B (SQLite)**: the system Python linked to Apple's system SQLite 3.51.0. It made 400 single-row commits of 64 bytes each in WAL mode.
  - **Method C (crypto)**: a Swift program built with `swiftc -O`, timing CryptoKit `AES.GCM.seal`, `ChaChaPoly.seal` and Secure Enclave calls. The binary was unsigned (ad-hoc signed by the linker) and carried no entitlements. It also tried `SecItemAdd` into the data protection keychain.
  - **Method D (defaults)**: `vim` and `emacs --batch` printed their own default settings.
  - These are single-machine numbers taken with light background load. They show orders of magnitude, not a benchmark.
- **Inference / Recommendation**: my reasoning, kept apart from the facts.

Design labels used throughout (the full evaluation is in Q1 → Inferences):
- **D0**: plaintext journal or swap file, as Vim, Emacs and VS Code do.
- **D1**: NSDocument autosave-in-place plus Versions.
- **D2**: an encrypted journal whose per-session key sits in the data protection keychain. This is the "ephemeral by default" design.
- **D3**: D2, but the session key is wrapped by a Secure Enclave key.
- **D4**: an encrypted journal whose key lives only in RAM, in a separate helper or agent process.
- **D5**: an encrypted journal whose key is derived from a passphrase.
- **D6**: RAM only, nothing on disk.

---

## Q1. Threat and failure matrix: which designs cover which failures?

### Takeaway
No design both survives power loss and leaves nothing recoverable on disk. To survive a kernel panic or power loss, the key or the plaintext must be on persistent storage, or be re-derivable from something the user types. The practical sweet spot is D2: an encrypted append-only journal, with a per-session key in the data protection keychain that is destroyed on Done or Discard. D4, with the key in RAM in a helper process, is the stronger-privacy variant. It survives only an app crash or force-quit.

### Cited Findings

**Storage and caching facts that drive the matrix**
- Time Machine makes a local APFS snapshot of the startup disk about every hour. It keeps each for up to 24 hours, or until the space is needed. It keeps an extra snapshot of the last successful backup. Since macOS 10.13 it also takes a snapshot before every macOS update — [Apple: About Time Machine local snapshots](https://support.apple.com/en-ca/102154); [Apple Mac User Guide](https://support.apple.com/guide/mac-help/about-time-machine-local-snapshots-mh35933/15.0/mac/15.0) [web]
- Nothing can be excluded from an APFS snapshot: "no folders or files can be excluded from APFS snapshots" because "snapshots always capture the entire volume". Time Machine exclusions apply only to what is copied to the backup disk — [Eclectic Light 2026-01-06](https://eclecticlight.co/2026/01/06/exclude-or-include-items-in-backup-search-icloud-drive-and-quicklook-preview/); [Eclectic Light, What isn't backed up (2025)](https://eclecticlight.co/2025/05/02/what-isnt-backed-up/) [web]
- Spotlight: a folder named `*.noindex` is not indexed. However, "Spotlight may still index files in most Library folders, but withholds the results", and hiding items from results "won't normally prevent indexing" — [Eclectic Light 2026](https://eclecticlight.co/2026/01/06/exclude-or-include-items-in-backup-search-icloud-drive-and-quicklook-preview/) [web]
- iCloud Drive does not sync items ending in `.nosync` or `.tmp`. If "Desktop & Documents Folders" is turned on, those folders move into iCloud Drive — [Eclectic Light 2026](https://eclecticlight.co/2026/01/06/exclude-or-include-items-in-backup-search-icloud-drive-and-quicklook-preview/); [Apple Mac User Guide](https://support.apple.com/guide/mac-help/mchle5a61431) [web]
- QuickLook: "There's currently no proven way to exclude any file or folder from QuickLook's reach" — [Eclectic Light 2026](https://eclecticlight.co/2026/01/06/exclude-or-include-items-in-backup-search-icloud-drive-and-quicklook-preview/) [web]
- FileVault on Apple silicon and T2 Macs:
  - The internal Data volume is always encrypted. Without FileVault, "the volume encryption key is protected only by the hardware UID in the Secure Enclave".
  - With FileVault on, the user password is combined with the UID, and credentials are required at boot. Removed storage stays protected — [Apple Platform Security: Volume encryption with FileVault](https://support.apple.com/guide/security/sec4c6dc1b6e); [Eclectic Light: Why you should enable FileVault](https://eclecticlight.co/2023/03/31/why-you-should-enable-filevault/) [web]
- macOS swap is always encrypted ("secure virtual memory"). On Mac OS X 10.6 it was optional. A Mac OS X 10.6 STIG told admins to enable it — [Apple support page](https://support.apple.com/te-in/guide/mac-help/mh11852/11.0/mac/11.0) (as summarised by search; not fetched in full); [DISA STIG 10.6](https://stigviewer.com/stig/mac_osx_10.6_workstation/2012-01-30/finding/V-25332) [web]
- Since macOS 14, an app that tries to read the container of a sandboxed app from another developer triggers a consent prompt. If the user denies it, the reading app loses access. One analysis says this "requires user consent before any application can access data in a data container from a different developer" and protects sandboxed apps only — [SentinelOne: macOS 14 Sonoma](https://www.sentinelone.com/blog/macos-14-sonoma-toughening-up-macos-for-the-enterprise/) [web]
- Clipboard and cloud copies: the general pasteboard takes part in Universal Clipboard, which reaches the user's other devices — [Apple NSPasteboard docs](https://developer.apple.com/documentation/appkit/nspasteboard) [web]. Details are in Q6.

**Process death versus power loss**
- On macOS, `fsync()` "always has and always will flush all file data from host memory to the drive". But "`fsync()` is not sufficient to guarantee that your data is on stable storage". `F_FULLFSYNC` asks the drive to flush its cache — [Dominic Giampaolo, darwin-dev 2005, via mjtsai](https://mjtsai.com/blog/2022/02/17/apple-ssd-benchmarks-and-f_fullsync); [fsync(2)](https://leancrew.com/all-this/man/man2/fsync.html) [web]
- In a 2022 test of four NVMe SSDs from four vendors, "half lose FLUSH'd data on power loss". This concerns non-Apple drives, such as external ones — [Russ Bishop, via mjtsai](https://mjtsai.com/blog/2022/02/17/apple-ssd-benchmarks-and-f_fullsync) [web]

### Inferences

**Matrix.** ✓ = text survives; ✗ = text lost; "exposed" = readable plaintext.

| Event | D0 plaintext journal (editors) | D1 NSDocument + Versions | D2 encrypted journal + DP-keychain key | D3 D2 + SE-wrapped key | D4 key only in RAM of helper agent | D5 passphrase key | D6 RAM only |
|---|---|---|---|---|---|---|---|
| App crash, `abort`, SIGKILL | ✓ (everything already `write()`n) | ✓ up to last autosave | ✓ | ✓ | ✓ (agent alive) | ✓ (user re-enters passphrase) | ✗ |
| Force Quit of the app | ✓ | ✓ up to last autosave | ✓ | ✓ | ✓ unless the agent is killed too | ✓ | ✗ |
| Accidental ⌘Q / ⌘W | ✓ (if quit ≠ discard) | ✓ | ✓ | ✓ | ✓ | ✓ | needs confirm |
| Kernel panic / power loss | ✓ up to the last full flush | ✓ up to last autosave flush | ✓ up to last full flush (key persisted when the session started) | ✓ | ✗ (key gone; journal is unreadable, fail-closed) | ✓ | ✗ |
| Logout, restart, OS update | ✓ | ✓ | ✓ | ✓ | ✗ (agent ends with the user session) | ✓ | ✗ |
| Disk full | write fails; keep RAM buffer | autosave fails | same as D0, plus key write can fail at session start | same | RAM unaffected; journal stops | same as D0 | n/a |
| Time Machine backup disk | exposed unless excluded | Versions store is backed up (exposed) | ciphertext; `ThisDeviceOnly` key does not migrate | ciphertext, only decryptable by this Mac's SE | ciphertext, key never on disk | ciphertext, passphrase strength | nothing |
| Local APFS snapshot (≤24 h, plus pre-update snapshot) | exposed, even after delete | exposed | ciphertext plus keychain DB both captured (see Q5 caveat) | ciphertext plus SE blob captured (same Mac only) | useless ciphertext | ciphertext | nothing |
| Spotlight index | exposed unless `.noindex` (Library folders may still be indexed) | exposed | binary noise | same | same | same | nothing |
| iCloud Drive | only if stored in iCloud Drive or Desktop & Documents | same | same, but ciphertext | same | same | same | nothing |
| Other app, same user, not sandboxed | can read the file | can read | reads ciphertext; DP-keychain item needs the access group | SE use needs the blob and this Mac; blob is readable | ciphertext; must defeat the agent's IPC check | ciphertext | nothing on disk |
| Another local user (non-admin) | blocked by home permissions (unverified, see Gaps) | same | same | same | same | same | n/a |
| Another local user (admin / root) | exposed | exposed | ciphertext; key in the victim's keychain | same | ciphertext | ciphertext | n/a |
| Theft, powered off, FileVault on | protected by FileVault | protected | protected (two layers) | protected | protected | protected | n/a |
| Theft while logged in and unlocked | exposed | exposed | decryptable by anyone at the keyboard | same, unless a biometry ACL gates recovery | same | same until auto-lock | exposed in UI |

**Recommendation (to evaluate, not a fact):**
- D2 covers every failure row and keeps plaintext off every copy that leaves the live session: backups, Spotlight, iCloud, other users, Versions. Its residual weakness is the ≤24 h local-snapshot window for anyone who controls the user's logged-in account.
- D4 removes that weakness. It loses text on power loss, logout or reboot.
- A per-session choice is possible: "survive restarts" means D2, and "never touch disk" means D4. It is the only way to offer both properties.
- FileVault alone (D0 or D1 on an encrypted volume) meets "encrypted at rest against an offline thief". It does not meet "not casually stored in the clear". The plaintext stays readable to every process running as the user, to Spotlight, to snapshots, to backup disks and to forensic tools.

### Gaps
- No source found for the default permissions of `~/Library` (believed to be 0700) or for what other standard users can traverse. Verify with `ls -led ~ ~/Library` on a fresh account.
- Whether an XPC service bundled inside the app is killed with its client on Force Quit. A launchd agent registered with `SMAppService` should survive, but this was not verified. Not found.
- How Force Quit terminates an app (SIGKILL or a staged signal sequence) was not verified. It does not change the matrix, because data already `write()`n survives either way.

---

## Q2. Crash-only persistence: journal design, fsync cost on APFS, what editors do

### Takeaway
On a current Apple SSD, per-keystroke `F_FULLFSYNC` is affordable if it runs off the main thread: about 2 ms median and about 4–5 ms p99, measured on an M2 Pro. Typing at 10 characters per second leaves about 100 ms between keys. Plain `fsync` (about 25 µs) and `F_BARRIERFSYNC` (about 190 µs) are much cheaper.

A plain `write()` alone already protects against app crash and force-quit, because the data sits in the kernel's cache. Only power loss and kernel panic need the flush. Editors settle for far weaker guarantees: Vim after 200 characters or 4 s, Emacs after 300 keystrokes or 30 s, VS Code backups on change.

### Cited Findings

**Method A: Apple M2 Pro, macOS 26.5.2, APFS, FileVault on [measured]**

| Operation (64 B append) | mean | p50 | p90 | p99 | max |
|---|---|---|---|---|---|
| `write()` only | 4–6 µs | 3 µs | 5 µs | 14–75 µs | 48–396 µs |
| `write()` + `fsync()` | 28–30 µs | 23–24 µs | 45–48 µs | 79–82 µs | ≈ 0.1 ms |
| `write()` + `fcntl(F_BARRIERFSYNC)` | 193–207 µs | 184–189 µs | 211–225 µs | 307–358 µs | 0.7–4.1 ms |
| `write()` + `fcntl(F_FULLFSYNC)` | 1.8–2.1 ms | 2.0 ms | 3.0 ms | 4.0–5.0 ms | 6.0–6.6 ms |
| Atomic replace of a 16 KiB file (tmp + sync + rename + dir sync), `fsync` | 0.21–0.35 ms | 0.18–0.31 ms | 0.42–0.52 ms | 0.7–1.0 ms | 1–2.2 ms |
| Same, `F_FULLFSYNC` | 4.9–6.4 ms | 4.2–6.0 ms | 6.0–8.0 ms | 6.3–11 ms | 7–14 ms |

**SQLite WAL (method B), measured with Apple's system SQLite 3.51.0, one 64 B row per commit [measured]**
- `synchronous=NORMAL`: p50 10 µs, p99 26 µs.
- `synchronous=FULL`: p50 46 µs, p99 100 µs.
- `synchronous=FULL` plus `fullfsync=1`: p50 246 µs, p99 681 µs.

**Older and third-party numbers [web]**
- Hector Martin (2022, M1 MacBook Air, single-threaded Python file rewrite): **46 IOPS with flushing**, against about 40,000 without. An x86 iMac with a WD SN550 managed 2,000 flushing IOPS, and a Samsung 860 EVO SATA SSD managed 143. He said Apple SSDs were "1000x slower when flushing" — [eevblog quoting the thread](https://www.eevblog.com/forum/general-computing/apples-ssd-milking-machine/25/); [mjtsai](https://mjtsai.com/blog/2022/02/17/apple-ssd-benchmarks-and-f_fullsync)
  - **This conflicts with Method A above:** about 500 flushes per second on an M2 Pro under macOS 26.5. Possible reasons are firmware or OS changes since 2022, a different test (whole-file rewrites rather than 64 B appends), or a different machine. The report should present both numbers and note the conflict.
- Tom Lane (Jan 2021, Intel MacBook Pro), `pg_test_fsync`: `fsync_writethrough` (that is, `F_FULLFSYNC`) ran at **41.5 ops/s (24 ms/op)**, plain `fsync` at about 24,677 ops/s. An old Mac mini with spinning disks ran at about 12 ops/s — [PostgreSQL list](https://www.postgresql.org/message-id/1673109.1610733352@sss.pgh.pa.us)
- An Apple engineer said `F_FULLFSYNC` is inherently heavy because it flushes the volume and ends in a device command. Apple's patched SQLite has used `F_BARRIERFSYNC` since 2022 — [Apple dev forums reply](https://origin-devforums.apple.com/forums/profile/davidbarsky/replies). Scott Perry also noted that SQLite on Darwin uses `F_BARRIERFSYNC` — [mjtsai](https://mjtsai.com/blog/2022/02/17/apple-ssd-benchmarks-and-f_fullsync)
- A SQLite developer found that `F_FULLFSYNC` slowed things a lot on every drive tested, though on older hardware — [SQLite forum](https://sqlite.org/forum/info/b94afa45dda82aae8cbf49f9d511a00b332870fc926cba18954acd889bbfb7cd)
- Michael Tsai: "often, what you really want is `F_BARRIERFSYNC`, not `F_FULLSYNC`". Barriers enforce ordering without forcing a flush — [mjtsai](https://mjtsai.com/blog/2022/02/17/apple-ssd-benchmarks-and-f_fullsync)

**SQLite WAL semantics**
- Under `synchronous=NORMAL`, WAL writers skip the sync on commit, and checkpoints are the only syncs. "transactions are no longer durable and might rollback following a power failure or hard reset". Under FULL, the WAL is synced on every commit — [SQLite WAL](https://www.sqlite.org/wal.html)
- Under both settings, checkpoints sync, which prevents corruption — [SQLite WAL](https://www.sqlite.org/wal.html)

**Language runtimes**
- Rust's `File::sync_all` (and `sync_data`) on macOS calls `fcntl(F_FULLFSYNC)`. The change came in rust-lang PR #60121 (2019) — [rust-lang/rust#60121](https://github.com/rust-lang/rust/pull/60121); [miri#1418](https://github.com/rust-lang/miri/issues/1418)
- Python's `os.fsync` did not use `F_FULLFSYNC` at the time of a 2025 discussion — [discuss.python.org](https://discuss.python.org/t/call-f-fullfsync-in-os-fsync-for-macos/79332)

**What editors do**
- **Vim**:
  - "The swap file is updated after typing 200 characters or when you have not typed anything for four seconds", and "After writing to the swap file Vim syncs the file to disk" (`'swapsync'`) — [vimhelp recover.txt](https://vimhelp.org/recover.txt.html)
  - Local defaults [measured, method D]: `updatecount=200`, `updatetime=4000`, `swapsync=fsync`, `fsync` on, `directory=.,~/tmp,/var/tmp,/tmp`. With these defaults the swap file lands next to the edited file, which may be an iCloud or synced folder.
  - "When the text file is encrypted the swap file is encrypted as well" — [vimhelp](https://vimhelp.org/recover.txt.html)
- **Emacs**: local defaults [measured, method D] are `auto-save-interval=300` (keystrokes) and `auto-save-timeout=30` (seconds idle). The manual page is [Auto-Save Control](https://www.gnu.org/software/emacs/manual/html_node/emacs/Auto-Save-Control.html), which could not be fetched (HTTP 429).
- **VS Code**:
  - Hot exit is on by default. Backups go to `~/Library/Application Support/Code/Backups` in plaintext. `files.hotExit` takes `off`, `onExit` or `onExitAndWindowClose`. Unsaved files are backed up "so they can be restored if the application closes unexpectedly" — [VS Code docs](https://code.visualstudio.com/docs/editing/codebasics)
  - "As soon as the working copy reports a content change, the workbench will call the `backup` method". Backups are deleted once the file is saved — [VS Code wiki: Working Copies](https://github.com/microsoft/vscode/wiki/Working-Copies/fb27eb3492225ac6378c6f21fd226db779adc716)
  - `files.autoSave=afterDelay` defaults to 1000 ms — [VS Code docs](https://code.visualstudio.com/docs/editing/codebasics)
- **Crypto cost per record is negligible next to the flush**: CryptoKit `AES.GCM.seal` of 64 B took 1.5 µs and `open` 0.9 µs (details in Q3) [measured, method C].

### Inferences

**Data written with `write()` survives the process.** Once `write()` returns, the bytes are in the kernel's unified buffer cache. They survive `abort()`, SIGKILL and Force Quit, and the OS writes them out on a clean logout or shutdown. Only a kernel panic, a power loss or a forced power-button shutdown loses unflushed data. So "write every keystroke" alone already covers the most common failures.
- This follows from POSIX semantics and the Giampaolo quote. I found no single Apple page that states it for process death.

**Recommended journal discipline (Recommendation):**
1. A dedicated writer thread or queue, never the main thread. It does `write()` immediately for each edit batch. Batches are coalesced keystrokes, for example everything typed while the previous sync was in flight ("group commit").
2. `F_BARRIERFSYNC` after each batch. This orders the journal, so after power loss it is a valid prefix.
3. `F_FULLFSYNC` on idle (about 1 s after the last key), on `applicationWillResignActive`, on window close, on terminate, and at most every N seconds while typing goes on.
   - Per-keystroke `F_FULLFSYNC` is feasible by latency (about 2 ms at p50 and about 5 ms at p99, against about 100 ms between keystrokes).
   - Unknown costs remain: SSD write amplification and energy, at roughly 10 flushes per second for hours. A 1 s idle flush bounds the power-loss window to about 1 s at much lower cost.
4. Put an AEAD tag on every record: AES-GCM, or CRC32 if unencrypted. Recovery then drops a torn tail cleanly.
5. Compaction: periodically write a full-text snapshot record into a new file with an atomic replace, measured at 0.2–6 ms, then drop the old journal.

**SQLite as the journal.** WAL with `synchronous=FULL` behaves like `fsync` per commit (about 46 µs).
- With Apple's system SQLite, `fullfsync=1` measured about 246 µs. That is close to `F_BARRIERFSYNC` (about 190 µs) and far below `F_FULLFSYNC` (about 2 ms). This is consistent with the forum claim that Apple's SQLite uses `F_BARRIERFSYNC`.
- A bundled SQLite (for example rusqlite's `bundled` feature) would presumably issue a real `F_FULLFSYNC` and cost about 2 ms per commit. This was not measured.
- SQLite adds little over an append-only file for a single-writer, single-document journal. It does add a second file pair (`-wal`, `-shm`).

**Memory-mapped journal.** Stores into a `MAP_SHARED` mapping also survive process death, since they live in the page cache. But they give no ordering, no torn-write detection, and an unclear durability call on macOS. They are not recommended.

**Atomic rename resets the backup exclusion.** Apple warns that "some common file operations cause [the exclusion] property to reset to false". So set the exclusion on the containing folder, not on each file — [Apple: isExcludedFromBackupKey](https://developer.apple.com/documentation/foundation/urlresourcekey/isexcludedfrombackupkey)

### Gaps
- No published `F_FULLFSYNC` latency for M3, M4 or M5 Macs was found. Method A above covers one M2 Pro. Run it on the target machines.
- SSD wear and energy cost of sustained per-keystroke `F_FULLFSYNC`: no data found.
- `msync()` durability semantics on macOS (whether it implies a device flush): not found.
- Whether Apple's internal SSDs honour flushes under real power cuts: only second-hand forum commentary was found ([techboards](https://techboards.net/threads/what-is-going-on-with-random-writes-on-apple-silicon.4706)).
- No source found for how often the kernel writes back dirty pages without a sync, and therefore how much un-synced data a panic loses.

---

## Q3. Encryption at rest with a key that is not on disk

### Takeaway
- The data protection keychain gives the cleanest "key not in a plain file" store. It raises no ACL prompts, its `ThisDeviceOnly` items do not migrate through backups, and Developer ID apps may use it. It needs an app bundle with a provisioning profile.
- The Secure Enclave adds device binding: a stolen backup or clone is useless on another Mac. It does not make the key forgettable while snapshots exist.
- A key held only in memory makes the journal crash-safe only if the key lives in another process.
- Per-record AES-GCM costs about 1.5 µs, which is free compared with the flush.
- FileVault is necessary but does not meet "not stored in the clear".

### Cited Findings

**Keychain**
- macOS has two keychain implementations: the file-based keychain and the data protection keychain. `SecItem` targets the file-based one by default. Setting `kSecUseDataProtectionKeychain` (or `kSecAttrSynchronizable`) targets the data protection keychain. "The file-based keychain is on the road to deprecation" — [TN3137](https://developer.apple.com/documentation/technotes/tn3137-on-mac-keychains) [web]
- Access control differs: "The file-based keychain uses access control lists (`SecAccess`). The data protection keychain uses keychain access groups, supplemented by an optional access control object (`SecAccessControl`)". The groups come from code-signing entitlements, which "must be authorized by a provisioning profile". The program "needs an app-like bundle structure in which to embed that profile" — [TN3137](https://developer.apple.com/documentation/technotes/tn3137-on-mac-keychains) [web]
- The data protection keychain "is only available in a user login context". A launchd daemon cannot use it. Secure Enclave protection and biometric protection require it — [TN3137](https://developer.apple.com/documentation/technotes/tn3137-on-mac-keychains) [web]
- **macOS 26.4 change**: a file-based keychain file "might reference a protected entropy file" in `/var/db/SystemKeys`. A copied keychain file is useless without it, and the directory is not readable even by root without disabling SIP. (TN3137 revision 2026-09-24) — [TN3137](https://developer.apple.com/documentation/technotes/tn3137-on-mac-keychains) [web]
- A DTS engineer says the data protection keychain is open to directly distributed apps signed with Developer ID, which need a Developer ID provisioning profile — [Apple forums thread 826107](https://developer.apple.com/forums/thread/826107) (search summary, not fetched in full) [web]
- An unsigned or ad-hoc-signed CLI with no entitlements got **`-34018 "A required entitlement isn't present."`** from `SecItemAdd` with `kSecUseDataProtectionKeychain` [measured, method C].
- `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`: the item can be read "only while the device is unlocked by the user". "Items with this attribute do not migrate to a new device. Thus, after restoring from a backup of a different device, these items will not be present" — [Apple docs](https://developer.apple.com/documentation/security/ksecattraccessiblewhenunlockedthisdeviceonly) [web]
- File-based keychain prompts:
  - An item "is tagged with the DR [designated requirement] of the creating app and any future versions of that app must be able to satisfy that requirement". This happens automatically with Developer ID or Mac App Store signing — [Apple forums 98484](https://developer.apple.com/forums/thread/98484) [web]
  - A user who saw prompts after an upgrade found that the item's `partition_id` had gained the new build's cdhash. That is typical of ad-hoc or unstable signing — [Apple forums 732869](https://developer.apple.com/forums/thread/732869); [Apple forums 100557](https://developer.apple.com/forums/thread/100557) [web]
  - Evidence that ad-hoc builds prompt on every rebuild is indirect (a TCC analogy); no authoritative source.

**Secure Enclave (SE)**
- Hardware: "a Mac with the Touch Bar and Touch ID or with an M1 or later processor" — [Apple: Protecting keys with the Secure Enclave](https://developer.apple.com/documentation/security/protecting-keys-with-the-secure-enclave) [web]. Apple Platform Security says Macs with Apple silicon or a T2 chip — [Apple Platform Security: FileVault](https://support.apple.com/guide/security/sec4c6dc1b6e) [web]. **The two lists differ slightly.** Some T2 Macs have no Touch Bar.
- Only NIST P-256 keys. Usable for signatures and ECDH, "and by extension, symmetric encryption", for example `eciesEncryptionCofactorX963SHA256AESGCM`. Existing keys cannot be imported. "only the Secure Enclave that created the key can make use of the key" — [Apple](https://developer.apple.com/documentation/security/protecting-keys-with-the-secure-enclave) [web]
- Access control: Apple's example uses `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` plus `.privateKeyUsage`. Adding `biometryAny` gates use behind Touch ID or a fallback passcode — [Apple](https://developer.apple.com/documentation/security/protecting-keys-with-the-secure-enclave) [web]
- DTS: "There is no Secure Enclave entitlement… Access to the SE is the same as access to the data protection keychain". It needs "an App ID that's authorised by a profile" and a user context. Daemons cannot use it, but agents and CLI tools can with a wrapped profile — [Apple forums 786171](https://developer.apple.com/forums/thread/786171) [web]
- **Conflicting data point [measured, method C]:**
  - The unsigned CLI with no entitlements and no profile *succeeded* in creating a CryptoKit `SecureEnclave.P256.KeyAgreement.PrivateKey()` in 19.5 ms, giving a 284-byte `dataRepresentation` blob. It restored the key from that blob, and ran ECDH plus HKDF in **4.5 ms per operation**.
  - So the profile requirement appears to apply to SE keys *stored in the keychain*, not to CryptoKit's blob-returning path. The open-source CLI `age-plugin-se` (Swift, CryptoKit, standalone binary, needs macOS 13 or 14 and an SE) is consistent with this — [age-plugin-se](https://github.com/remko/age-plugin-se) [web].
  - Apple does not document this. Treat it as behaviour that may change.
- 1Password: when unlocking with the Mac, "1Password creates an unlock secret and encrypts it using an encryption key stored in the Secure Enclave… The Secure Enclave will only decrypt the secret if your Mac is successfully unlocked". 1Password identifies itself to macOS by code signature — [1Password support](https://support.1password.com/device-unlock-mac-security) [web]
  - 1Password 6 kept the encrypted secret in the keychain with its key on disk. Version 7 moved it to the SE — [AgileBits forum](https://discussions.agilebits.com/discussion/comment/451893) [web]
  - CVE-2024-42218: 1Password 8 for Mac before 8.10.38 let local attackers exfiltrate vault items by bypassing macOS-specific (IPC) protections — [Tenable CVE-2024-42218](https://tenable.com/cve/CVE-2024-42218) [web]

**Throughput of authenticated encryption**

| CryptoKit op (M2 Pro) [measured, method C] | 64 B | 4 KiB | 1 MiB |
|---|---|---|---|
| `AES.GCM.seal` | 1.50 µs (43 MB/s) | 1.93 µs (2.1 GB/s) | 159 µs (6.6 GB/s) |
| `ChaChaPoly.seal` | 1.56 µs | 7.37 µs (0.56 GB/s) | 1.52 ms (0.69 GB/s) |
| `AES.GCM.open` | 0.88 µs | – | – |

- wolfSSL on M1 (wolfCrypt, not CryptoKit), tuned build: AES-256-GCM encryption about 1.7 GB/s, ChaCha20-Poly1305 about 1.2 GB/s — [wolfSSL M1 benchmarks](https://www.wolfssl.com/cryptographic-benchmarks-new-apple-m1/) [web]

**How privacy-conscious apps store keys and explain it**
- **Standard Notes**, four configurations:
  - Without account or passcode, the device database is "Not encrypted".
  - With an account and no passcode, account keys are "Stored plainly in secure device keychain".
  - With a passcode, passcode keys are "Ephemeral, never stored to disk". They are regenerated at each launch and held in memory until lock or quit.
  - Biometrics on mobile are "non-cryptographically backed".
  - "Stay signed in" unchecked means nothing is saved to disk or keychain — [Standard Notes help 79](https://standardnotes.com/help/79) [web]
- **Signal Desktop**: until a 2018 report, its SQLCipher database key sat in plaintext in `config.json` — [Security Affairs 2018](https://securityaffairs.com/77340/hacking/signal-desktop-application-bug.html). Since 2024 the key is protected with Electron `safeStorage` (`encryptedKey` plus a `safeStorageBackend` in `config.json`) — [yingtongli blog, 2025](https://www.yingtongli.me/blog/2025/08/13/signal-secrets.html) [web]. Secondary source; a plaintext fallback was reportedly still possible.
- **Electron `safeStorage`** on macOS keeps keys "in Keychain Access in a way that prevents other applications from loading them without user override". Content is "protected from other users and other apps running in the same userspace". Calls "can block the current thread to collect user input", meaning a keychain prompt — [Electron docs](https://www.electronjs.org/docs/latest/api/safe-storage) [web]
- **Apple Notes locked notes**: a key derived from the passphrase with PBKDF2-SHA256 encrypts the note with AES-GCM. The user can use the device passcode or a separate password — [Apple Platform Security: Secure notes](https://support.apple.com/guide/security/sec1782bcab1/web) [web]
- **Bear**:
  - Notes live in a plain SQLite database that any tool can read — [Bear community: database readability](https://community.bear.app/t/bear-database-readability/14822) (user report).
  - Bear Pro encrypts individual notes. Titles stay visible. Encrypted notes are not searchable — [Bear FAQ](https://bear.app/faq/how-to-encrypt-lock-notes-with-bear/); [Bear roadmap 2025](https://community.bear.app/t/bear-s-encryption-roadmap-for-2025/15401)
  - Bear warns that Apple's Advanced Data Protection "does not encrypt notes stored on your device" — [Bear roadmap 2025](https://community.bear.app/t/bear-s-encryption-roadmap-for-2025/15401); [Bear blog 2023](https://blog.bear.app/2023/10/encryption-bear-and-your-private-data/) [web]
- **Obsidian**: no native at-rest encryption, only community plugins. A forum user reports that plaintext note content remains in the app's index or cache even when the vault sits in an encrypted container — [Obsidian forum](https://forum.obsidian.md/t/password-protect-lock-folder-encryption-at-rest/1754?page=6) [web]
- **Raycast** clipboard history: content "stays on the machine and is encrypted on the local drive". Passwords from password managers and other transient data are ignored by default — [Raycast](https://raycast.com/core-features/clipboard-history); [Raycast extension page](https://www.raycast.com/extensions/clipboard-history) [web]

### Inferences

**FileVault versus "not in the clear".** FileVault protects only against an offline attacker. Every process running as the user reads the plaintext through the file system. Spotlight indexes it. Snapshots and Time Machine (to an unencrypted backup disk) copy it, and Versions keeps old copies. So "FileVault is on" should be presented as a baseline, not the answer. App-level encryption is what turns "delete" into a real promise, through crypto-shredding.

**Ephemeral in-app key.** A key kept only in the app's own memory buys nothing for crash recovery: the journal becomes unreadable at exactly the moment you need it. It only makes sense together with "never restore" (D6), or with the key also held in a second process (D4).

**D4: key held by a launchd agent or helper.** It survives app crash and force-quit. It loses the session on logout, reboot, panic and power loss, in a fail-closed way.
- Risks:
  - Another process running as the user can connect to the agent unless the agent checks the client's audit token and code signature. 1Password's CVE-2024-42218 shows this IPC check is where such designs break.
  - The agent's memory may be swapped, though swap is encrypted.
- UX cost: registering an agent likely produces a "Background Items Added" notice. No source fetched.

**SE wrapping (D3) versus the plain DP keychain (D2).**
- Both survive power loss.
- Both are captured by local snapshots (the keychain DB, or the SE blob plus the wrapped key) for up to 24 h.
- The SE adds three things:
  - A backup or clone of the journal plus blob is useless on any other Mac.
  - A per-session SE key with a `biometryAny` access control can require Touch ID before a crashed session is restored.
  - The key is never in process memory, but the session key K derived from it is.
- Cost: a 4.5 ms ECDH at session start or restore, which is irrelevant.
- From Rust, the SE route needs either a Swift shim (CryptoKit) or keychain entitlements (`SecKey` with `kSecAttrIsPermanent`). See Q7.

**Recommendation.**
- Use D2 as the default. Add the SE wrap only if the "backup disk stolen" or "Touch ID to restore" cases matter to users.
- Use D4 for a "nothing ever on disk" mode.
- Use AES-256-GCM, not ChaChaPoly. It is about 4–10× faster here on 4 KiB and larger, and equal at 64 B.

### Gaps
- What `WhenUnlocked` means on macOS: whether the class key is evicted on screen lock or only on logout. DTS said in passing that "right now, this stuff is unlocked as part of the user authentication process" ([forums 786171](https://developer.apple.com/forums/thread/786171)), which suggests login. No authoritative statement found.
- No Apple statement found that ad-hoc-signed builds trigger a file-based keychain prompt on every rebuild. The evidence is indirect.
- Whether CryptoKit SE keys created without a profile keep working on future macOS versions is undocumented; only method C shows they work now.
- Whether the macOS 26.4 protected-entropy change also affects the data protection keychain is not stated in TN3137.

---

## Q4. macOS mechanics: NSDocument and Versions, sudden termination, App Nap, exclusions, secure deletion

### Takeaway
- Do not use NSDocument autosave-in-place with Versions for private drafts. It copies every version into a per-volume store, owned by root, that the app cannot purge and Time Machine backs up.
- Opt the journal folder out of backups, Spotlight and iCloud by name and attribute, but treat that only as hygiene.
- Secure deletion of individual files is impossible on APFS and SSD, so crypto-shredding is the only real delete.
- With a journal that is always current, the app can safely allow sudden termination.

### Cited Findings

**Versions**
- Each APFS or HFS+ volume has a hidden, root-only `.DocumentRevisions-V100` folder. It holds a `db-V1` SQLite database and stored versions for apps with Revert To. Saving in a versioning-enabled app adds the prior version, and users cannot disable this per app — [Eclectic Light 2025-09-08](https://eclecticlight.co/2025/09/08/managing-macos-versioning-and-the-documentrevisions-v100-folder/) [web]
- Forensic tools collect `.DocumentRevisions-V100` as evidence of earlier document content — [Binalyze AIR docs](https://kb.binalyze.com/air/features/acquisition/supported-evidence/macos-collections-detail/document-revisions) [web]

**Sudden and automatic termination**
- The `NSProcessInfo` sudden-termination counter: at 0 "the system [may] terminate the process without first sending a notification or event". `NSSupportsSuddenTermination=YES` in Info.plist equals calling `enableSuddenTermination` at launch.
  - Apple's guidance: call `disableSuddenTermination` when writing is first deferred, and `enableSuddenTermination` once it is done. Calls nest.
  - `beginActivity(options: .automaticTerminationDisabled…)` is the paired form for automatic termination — [Apple ProcessInfo docs](https://developer.apple.com/documentation/foundation/processinfo) (as summarised in search); [Apple forums 825681](https://developer.apple.com/forums/thread/825681) [web]

**App Nap**
- App Nap throttles a background app's timers and deprioritises its I/O, unless the app holds an activity assertion (`beginActivity(options:reason:)`, for example `.userInitiated` or `.latencyCritical`) — [Lazarus wiki: macOS App Nap](https://wiki.lazarus.freepascal.org/macOS_App_Nap); [Chromium app_nap_activity.mm](https://chromium.googlesource.com/chromium/src.git/+/61.0.3140.1/content/common/mac/app_nap_activity.mm) [web]

**Exclusions**
- Time Machine:
  - `tmutil addexclusion` (or the Options list); `tmutil isexcluded path` to test.
  - A sticky exclusion through the `com.apple.metadata:com_apple_backup_excludeItem` extended attribute.
  - A `.nobackup` name suffix (tested on Sequoia and Tahoe).
  - `.exclusions.plist` "has gone missing in backups made since upgrading to Tahoe" — [Eclectic Light 2026](https://eclecticlight.co/2026/01/06/exclude-or-include-items-in-backup-search-icloud-drive-and-quicklook-preview/) [web]
- `NSURLIsExcludedFromBackupKey` / `URLResourceKey.isExcludedFromBackupKey`: "excludes the resource from all backups of app data". Set it "each time you save a file because some common file operations cause this property to reset to false" — [Apple docs](https://developer.apple.com/documentation/foundation/urlresourcekey/isexcludedfrombackupkey) [web]
- Spotlight `.noindex`, iCloud `.nosync`, and the limits of QuickLook: see Q1.

**Secure deletion**
- Apple removed "Secure Empty Trash" in OS X 10.11 (CVE-2015-5901). It could not guarantee secure overwriting on flash storage — [Loop Insight 2015](https://www.loopinsight.com/2015/11/30/why-secure-empty-trash-is-gone-in-el-capitan-and-what-to-do-instead) [web]
- `srm` was removed in 10.11 according to [Wikipedia](https://en.wikipedia.org/wiki/Srm_(Unix)), which contradicts [Intego](https://www.intego.com/mac-security-blog/how-to-securely-empty-trash-in-os-x-el-capitan/), which says it still exists. Either way, overwriting is meaningless on APFS and SSD.
- Apple's own fast wipe is crypto-shredding. The file system key sits in Effaceable Storage "to facilitate fast wipe, rather than confidentiality". Effaceable Storage is "a dedicated area of NAND storage, used to store cryptographic keys, that can be addressed directly and wiped securely" — [Apple Platform Security glossary](https://support.apple.com/guide/security/sec93292bfa6/web) [web]

**Quit protection**
- Chrome on macOS has "Warn Before Quitting": the user must hold ⌘Q for a moment, because ⌘W sits next to ⌘Q — [TekRevue](https://www.tekrevue.com/tip/hold-command-q-to-quit-chrome-mac/) [web]

### Inferences
- **Storage location:**
  - Keep sessions in `~/Library/Application Support/<app>/Sessions.noindex/` (or the sandbox container, which also earns macOS 14+ container protection).
  - Set the sticky backup-exclusion attribute on the folder, not on each file, because atomic renames reset per-file flags.
  - Never under `~/Documents` or `~/Desktop`, which may be in iCloud.
  - Never use the Vim-style "swap file next to the document".
- **Do not use NSDocument autosave-in-place or Versions for drafts**, and do not use `NSUserDefaults`. The latter is a plaintext plist written by `cfprefsd` (unsourced, from platform knowledge).
  - `NSFileCoordinator` is irrelevant for a private journal. It matters only if the app later writes into shared or iCloud locations.
- **Sudden termination:**
  - If every edit is `write()`n immediately, the app loses nothing to SIGKILL, and can declare `NSSupportsSuddenTermination`. That makes logout and OS-update restarts faster.
  - Disable it (`disableSuddenTermination`) only while the writer queue holds unwritten bytes, which is microseconds.
  - Run the final `F_FULLFSYNC` in `applicationShouldTerminate`, and reply `.terminateLater` only if it is still pending.
- **App Nap**: write-on-edit does not depend on timers, so App Nap is harmless. But an idle-flush timer (Q2 step 3) may be throttled while the app is in the background. Flush in `applicationDidResignActive` instead of relying on the timer.
- **Secure deletion**: deleting a key is the only real delete (crypto-shredding). Unlinking a plaintext file leaves copies in snapshots, Time Machine and SSD blocks.

### Gaps
- No Apple primary source fetched for NSDocument autosave timing, or for whether autosave in place always writes to `.DocumentRevisions-V100`.
- Exact sudden-termination behaviour during logout and OS update on macOS 14–26, such as the timeouts before macOS kills an app that replied `.terminateLater`, was not found.
- No current Apple page fetched on the encryption of `sleepimage` (hibernation) on Apple silicon.

---

## Q5. Session semantics: "ephemeral by default" (D2) in detail

### Takeaway
D2 is sound and prompt-free if the app ships as a proper bundle with a Developer ID provisioning profile carrying a keychain access group. It covers every failure in the matrix. An explicit Done or Discard crypto-shreds the session. Two caveats:
- Local snapshots keep both the ciphertext and the keychain database for up to 24 hours. Shredding is therefore proven against everyone except a party who controls the logged-in account in that window.
- Development builds without the profile fail with `-34018`, or, if they fall back to the file-based keychain, show prompts.

### Cited Findings
- Developer ID apps may use the data protection keychain. It needs `keychain-access-groups` / application-identifier entitlements authorised by a provisioning profile embedded in an app bundle — [TN3137](https://developer.apple.com/documentation/technotes/tn3137-on-mac-keychains); [Apple forums 826107](https://developer.apple.com/forums/thread/826107) [web]
- The data protection keychain's access control is access groups plus an optional `SecAccessControl`. The ACL prompts belong to the file-based keychain — [TN3137](https://developer.apple.com/documentation/technotes/tn3137-on-mac-keychains) [web]
- Without the entitlement: `-34018` [measured, method C].
- File-based keychain items survive updates without prompts when the designated requirement stays the same (Developer ID) — [Apple forums 98484](https://developer.apple.com/forums/thread/98484) [web]
- `ThisDeviceOnly` items do not come back when restoring a backup onto another device — [Apple docs](https://developer.apple.com/documentation/security/ksecattraccessiblewhenunlockedthisdeviceonly) [web]
- Local snapshots capture the whole volume, keychain files included, for up to 24 h. An extra snapshot is taken before macOS updates — [Apple 102154](https://support.apple.com/en-ca/102154); [Eclectic Light](https://eclecticlight.co/2026/01/06/exclude-or-include-items-in-backup-search-icloud-drive-and-quicklook-preview/) [web]
- Standard Notes uses the same pattern: an account key in the keychain encrypts the local database, and an optional passcode makes the keys ephemeral — [Standard Notes help 79](https://standardnotes.com/help/79) [web]
- VS Code treats quit as "keep": hot exit restores unsaved work on next launch by default — [VS Code docs](https://code.visualstudio.com/docs/editing/codebasics) [web]

### Inferences

**Flow (Recommendation):**
1. **Session start.**
   - Generate a 256-bit key K and a session UUID.
   - `SecItemAdd` a generic password with `kSecUseDataProtectionKeychain=true`, `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`, `kSecAttrSynchronizable=false`, and the app's access group. Service and account are the app and the session UUID.
   - Create `Sessions.noindex/<uuid>.journal`. Its header holds the version and the UUID, never the key.
2. **Every edit.**
   - Seal the record with AES-GCM under K. The nonce is a 96-bit counter, unique per key.
   - `write()` on the writer queue. Flush policy as in Q2.
   - Optional: batch or pad records to about 50 ms windows or fixed sizes. Per-keystroke records otherwise leak typing rhythm and text length through record count, sizes and timestamps (inference).
3. **Crash, force-quit, ⌘Q, ⌘W, logout, OS update, power loss.**
   - The key and journal stay. On next launch the app reopens the session as it was. A VS Code-style silent restore is better than a "Restore?" dialog, which invites a wrong click.
   - **Quit ≠ discard.** Then accidental ⌘Q costs nothing, and hold-to-quit or a confirm dialog become optional, not necessary.
4. **Done** (text handed off, see Q6), or **Discard**:
   - `SecItemDelete` the key, zero K in memory, unlink the journal.
   - For an "Undo discard" grace period, keep K in RAM only for N seconds after deleting the keychain item. A crash in that window completes the discard (fail-closed, the safer direction).
5. **Orphans.** A journal with no key, or a key with no journal, is deleted at launch.

**Residual exposure after Discard:**
- Ciphertext blocks on the SSD: unreadable.
- Up to 24 h of local snapshots, plus the pre-update snapshot and the last-backup snapshot "until space is needed". These hold the journal *and* `~/Library/Keychains/…` as they were.
- Recovering the key from a snapshotted keychain DB would need the user's keybag (the same Mac, the user logged in) and tooling to make `securityd` read an old DB. Whether this is practical is unknown. Describe it to users as "unreadable once discarded; system snapshots are cleared within about a day".
- D4 (key in a helper's RAM) avoids even this.

**Keychain prompts:**
- In the data protection keychain: none, unless the app adds a `SecAccessControl` user-presence or biometry flag, which is a deliberate prompt.
- The file-based fallback (for example a dev build without a profile): ACL prompts whenever the signature's designated requirement changes. Ad-hoc dev builds probably prompt on every rebuild.
- Recommendation: have dev builds use a Development provisioning profile, or a plain-file key store behind a `debug` flag that is never shipped.

**macOS lock state:** if `WhenUnlocked` items on macOS are readable whenever the user is logged in (see the Q3 gap), screen lock does not protect a running session. Only FileVault plus logout or power-off does.

### Gaps
- Whether a deleted data protection keychain item can be recovered from an APFS local snapshot of the keychain database by the same user on the same Mac. No source.
- Whether `SMAppService` agent registration shows a user-visible notice on macOS 14–26, which affects D4's UX. Not fetched.

---

## Q6. Handing off the finished text, and when to wipe the app's copy

### Takeaway
Every hand-off path moves the text into someone else's storage policy. The clipboard is the leakiest: clipboard managers, Universal Clipboard, and macOS 26's own Spotlight clipboard history. Mark it with the nspasteboard.org markers and `currentHostOnly`. Optionally clear it after a timeout. Wipe the app's own copy (key delete) once the hand-off has demonstrably happened.

### Cited Findings
- nspasteboard.org markers:
  - `org.nspasteboard.ConcealedType`: confidential; avoid writing it to disk unencrypted.
  - `org.nspasteboard.TransientType`: on the pasteboard only briefly; do not record it in history.
  - `org.nspasteboard.AutoGeneratedType`: not produced by a user Copy.
  - `org.nspasteboard.source`: the bundle ID of the app that produced the content.
  - Maccy ignores Transient, Concealed and AutoGenerated by default. Alfred, Paste, CopyPaste Pro, iClip, ClipBook and others support some or all of them. TextExpander-style tools mark temporary writes as transient — [nspasteboard.org](https://nspasteboard.org/) [web]
  - This is a community convention, not an Apple API.
- Raycast's clipboard history ignores password-manager and transient items by default, and stores its history encrypted on the device — [Raycast](https://www.raycast.com/extensions/clipboard-history) [web]
- Universal Clipboard: the general pasteboard takes part in it, and there is no macOS API for interacting with the feature. `NSPasteboard.ContentsOptions.currentHostOnly` makes contents "available only on the current device, and not on any other devices" — [NSPasteboard](https://developer.apple.com/documentation/appkit/nspasteboard); [ContentsOptions](https://developer.apple.com/documentation/appkit/nspasteboard/contentsoptions) [web]. Content arriving from another device is marked `com.apple.is-remote-clipboard` — [nspasteboard.org](https://nspasteboard.org/) [web]
- macOS 26 Tahoe adds clipboard history in Spotlight:
  - It is opt-in: the user is asked to "Enable" on first use — [Apple Mac User Guide](https://support.apple.com/guide/mac-help/mchl40d5b86b/mac)
  - 26.1 adds retention settings (30 min, 8 h, 7 days), a clear button and an off switch — [Macworld](https://www.macworld.com/article/2962021/this-macos-tahoe-26-1-setting-will-eliminate-embarrassing-clipboard-mishaps.html); [iPhoneSoft](https://iphonesoft.fr/2025/11/04/macos-tahoe-26-1-apporte-controle-accru-presse-papiers-spotlight) [web]
- Pasteboard privacy:
  - In May 2025, Apple's AppKit docs previewed alerts when apps read the pasteboard without user interaction, plus new `detect` methods.
  - Testing goes through `defaults write <bundle id> EnablePasteboardPrivacyDeveloperPreview -bool yes` — [9to5Mac](https://9to5mac.com/2025/05/12/macos-16-clipboard-privacy-protection/) [web]
  - A March 2026 comment says it is still only a developer preview — [mjtsai 2025-05-12 comments](https://mjtsai.com/blog/2025/05/12/) [web]
- Apple Notes, Bear and Obsidian keep finished text in their own stores, readable at rest except for locked or encrypted notes (Q3). Hand-off into them inherits that policy.

### Inferences
- **Copy to clipboard**, the default hand-off:
  - Write the text with the `ConcealedType` marker (and probably `TransientType`, if the clipboard is restored afterwards) and `.currentHostOnly`.
  - Optionally clear the pasteboard after N seconds if `changeCount` is still the app's own. This mirrors password-manager practice (unsourced here).
  - Tell the user that macOS 26's Spotlight clipboard history may still record it. Whether it honours the nspasteboard markers is unknown.
  - Some users *want* their text in clipboard history, so a toggle is reasonable.
- **Paste into the previously focused app**:
  - The pattern: put the text on the pasteboard marked transient, re-activate the target app, post ⌘V, then restore the previous pasteboard.
  - Posting synthetic key events needs Accessibility (TCC) permission (unsourced here). It is fragile across apps, and the text still lands in that app's undo and autosave.
  - It avoids leaving the text on the pasteboard.
- **Save as file**: the user chooses the location. It then becomes ordinary, indexed, backed-up and possibly iCloud-synced data, which is expected for a deliberate save.
  - Use plain `write` plus atomic replace, not NSDocument Versions, so no hidden version copies are made.
- **Share sheet / Services / URL scheme**: the text goes into the receiver's storage, and the app cannot know or control it.
- **When to wipe the app's copy**:
  - On an explicit action that confirms the hand-off happened (copied, saved, pasted), plus a short undo grace period (Q5).
  - Never on ⌘Q or window close.
  - Crypto-shred: delete the keychain item, then unlink the journal.

### Gaps
- Whether macOS 26 Spotlight clipboard history skips `org.nspasteboard.ConcealedType` or `TransientType` items: not found.
- Whether the pasteboard privacy alerts shipped (enabled by default) in any macOS 26.x release: still a developer preview per a March 2026 comment. Not confirmed.
- No source fetched on the Accessibility permission required for synthetic ⌘V (`CGEventPost`) on macOS 14–26.

---

## Q7. Rust-side availability (vs Swift)

### Takeaway
- Everything except CryptoKit is reachable from Rust:
  - The data protection keychain through `security-framework` 3.x.
  - Secure Enclave keys through `SecKey` with `Token::SecureEnclave`.
  - AES-GCM through `ring`, RustCrypto or the system libraries.
  - `F_FULLFSYNC` through `File::sync_all` or `fcntl`.
- CryptoKit's SE path, the one that works without a profile, would need a small Swift shim.
- The real Rust cost is packaging: an app bundle with an embedded provisioning profile and entitlements, signed outside cargo.

### Cited Findings
- `security-framework` 3.7.0, `PasswordOptions`:
  - `new_generic_password`, `set_access_control`, `set_access_control_options`, `set_access_group`, `set_access_synchronized`, `set_label`, `set_comment`, `set_description`.
  - **`use_protected_keychain()`**: "Uses the data protection keychain"; always true except on macOS — [docs.rs PasswordOptions](https://docs.rs/security-framework/latest/security_framework/passwords/struct.PasswordOptions.html) [web]
  - No dedicated `kSecAttrAccessible` setter appeared on that page. The protection class can go through a `SecAccessControl` (Apple's `SecAccessControlCreateWithFlags` takes it) — [Apple SE article](https://developer.apple.com/documentation/security/protecting-keys-with-the-secure-enclave) [web]
- `security-framework` keys:
  - `key::Token::SecureEnclave`: "The key is generated in the Secure Enclave, so the private key cannot be extracted", and is EC only — [docs.rs Token](https://docs.rs/security-framework/latest/security_framework/key/enum.Token.html)
  - `GenerateKeyOptions` has `set_token`, `set_location` ("Which keychain to store the key in, if any"), `set_access_control`, and is passed to `SecKey::new` (`SecKeyCreateRandomKey`) — [docs.rs GenerateKeyOptions](https://docs.rs/security-framework/latest/security_framework/key/struct.GenerateKeyOptions.html)
  - `SecKey` exposes encrypt, decrypt, sign and verify — [docs.rs SecKey](https://docs.rs/security-framework/3.7.0/security_framework/key/struct.SecKey.html) [web]
- Other crates:
  - `keychain-services`: experimental; it warns of "bugs and memory safety issues".
  - GoDaddy `enclave`: SE, TPM and keyring, maturity unknown — [docs.rs keychain-services](https://docs.rs/keychain-services/^0.1.1); [hardware-enclave](https://awesome.ecosyste.ms/projects/github.com%2Fgodaddy%2Fhardware-enclave) [web]
- Entitlements authorised by a profile need "an app-like bundle structure in which to embed that profile". For a library, access "is determined by the entitlements of the host process's main executable" — [TN3137](https://developer.apple.com/documentation/technotes/tn3137-on-mac-keychains) [web]
- Rust `File::sync_all` uses `F_FULLFSYNC` on macOS — [rust-lang/rust#60121](https://github.com/rust-lang/rust/pull/60121) [web]
- CryptoKit SE from Swift works without a profile, from a plain binary (19.5 ms key creation, 4.5 ms ECDH) [measured, method C]. `age-plugin-se` ships exactly this as a standalone Swift CLI — [age-plugin-se](https://github.com/remko/age-plugin-se) [web]

### Inferences
**Rust mapping (Recommendation):**
- Keychain: `security-framework` with `PasswordOptions::new_generic_password(...).use_protected_keychain()`, plus `set_access_group`. Protection class through `SecAccessControl` if no direct setter exists.
- Journal crypto: RustCrypto `aes-gcm` or `ring`. Benchmark both against CryptoKit's 1.5 µs per 64 B; both use the ARMv8 AES instructions on Apple silicon (unverified here).
- Durability:
  - `File::sync_all()` gives `F_FULLFSYNC`.
  - `libc::fcntl(fd, F_BARRIERFSYNC)` gives the barrier. The constant is 85 on Darwin; check whether the `libc` crate exports it.
  - Plain `libc::fsync` gives drive-cache-only syncing.
- AppKit bits: `NSProcessInfo` sudden termination and activities, `NSPasteboard` types and `currentHostOnly`, `NSApplicationDelegate` `applicationShouldTerminate`. These come through the `objc2` / `objc2-app-kit` / `objc2-foundation` crates. That they are available was not verified in this research.
- SE via CryptoKit: a tiny Swift static library with a C ABI, or a Swift helper binary. Alternatively, `security-framework`'s `Token::SecureEnclave`, which, for a persistent key, needs the same profile as the data protection keychain.
- Packaging: cargo builds the binary. A separate step assembles `.app`, embeds `embedded.provisionprofile`, and runs `codesign --entitlements` with the hardened runtime, then notarises. Without that, the data protection keychain fails with `-34018`.

### Gaps
- No `objc2-security` crate was confirmed (search found none). Whether `objc2-app-kit` exposes `NSPasteboard.ContentsOptions.currentHostOnly` and the `detect` methods was not verified.
- No `aes-gcm` or `ring` throughput measured on Apple silicon.
- Whether `security-framework`'s `Location` enum offers a data-protection-keychain variant for `SecKey::new` (needed to persist an SE key) was not visible on the fetched page.
