import CryptoKit
import Darwin
import Foundation

/// One change to the text, as the app's text model replays it: offsets and counts in Characters (Swift's grapheme
/// clusters) of the text as it stands before the edit. The journal holds edits, never the text, and never the caret:
/// moving it changes nothing to keep.
public enum Edit: Codable, Equatable {
    case insert(at: Int, String)
    case delete(at: Int, count: Int)
}

public enum FlushLevel {
    /// `F_BARRIERFSYNC`: orders the journal on the drive, so after a power loss the file is a valid prefix.
    case barrier
    /// `F_FULLFSYNC`: drains the drive's cache; everything written so far survives a power loss.
    case full
}

/// A session's encrypted, append-only journal (DESIGN.md E2). One file per session, `<uuid>.journal`:
/// `FLOWJ2`, the session's UUID (16 bytes), then records. A record is a 4-byte little-endian length and an AES-GCM
/// `SealedBox.combined` (nonce, ciphertext, tag) of one batch of edits; its sequence number is in the payload and is
/// the authenticated data, so records cannot be reordered, dropped or spliced in without the replay stopping there.
public final class Journal {
    public let sessionID: UUID
    public let fileURL: URL
    /// What was recovered when `open` restored the session, in order; empty for a new session.
    public let replay: [Edit]
    /// Journals in the directory that `open` could not read: no key for them (finished, discarded) or their first
    /// record does not open with the key. Noise; the app may delete them.
    public let unreadable: [URL]

    private let keyStore: KeyStore
    private let queue = DispatchQueue(label: "dev.lemna.journal")
    // Everything below is touched only on `queue`.
    private var key: SymmetricKey?  // nil once finished
    private var fd: Int32
    private var end: off_t  // the end of the last whole record: where a failed write is cut back to
    private var seq: UInt64  // the next record's sequence number
    private var pending: [Edit] = []
    private var windowOpen = false

    /// Restores the most recent unfinished session in `directory` (a journal whose key `keyStore` still has), or
    /// starts a new one. Creates the directory (0700) and marks it excluded from backups. Each journal holds an
    /// exclusive `flock` on its file for its lifetime; `open` skips files whose lock is held. A session restored from
    /// a format 1 file moves into a new file of format 2 (`migrate`): this journal is then the new one.
    public static func open(directory: URL, keyStore: KeyStore) throws -> Journal {
        let fm = FileManager.default
        try fm.createDirectory(at: directory, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        // Set on every open, because Apple notes some file operations reset it; on the folder, so it covers every
        // file in it. Hygiene only (the files are ciphertext either way), so a failure does not stop the journal.
        var dir = directory
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? dir.setResourceValues(values)

        let keyed = Set(try keyStore.sessions())
        let modified: (URL) -> Date = {
            (try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
        }
        // Named under `directory` as given: the listing resolves symlinks (/var → /private/var).
        let journals = try fm.contentsOfDirectory(atPath: directory.path)
            .filter { $0.hasSuffix(".journal") }
            .map { directory.appendingPathComponent($0) }
            .sorted { modified($0) > modified($1) }
        var unreadable: [URL] = []
        var restored: (url: URL, id: UUID, key: SymmetricKey, version: Int, edits: [Edit], end: Int, records: Int,
                       size: Int, fd: Int32)?
        for url in journals {
            let fd = Darwin.open(url.path, O_WRONLY | O_APPEND | O_CLOEXEC)
            // Locked by the journal writing it (in another process, or another instance in this one): in use, so
            // neither restored nor noise.
            if fd >= 0 && flock(fd, LOCK_EX | LOCK_NB) != 0 && errno == EWOULDBLOCK {
                Darwin.close(fd)
                continue
            }
            guard fd >= 0, let data = try? Data(contentsOf: url), let id = Format.sessionID(in: data), keyed.contains(id)
            else {
                if fd >= 0 { Darwin.close(fd) }
                unreadable.append(url)
                continue
            }
            if restored != nil { Darwin.close(fd); continue }  // another unfinished session; v1 runs one at a time
            // A store that will not answer throws out of `open`: that session may still be readable later.
            let key: SymmetricKey?
            do { key = try keyStore.key(for: id) } catch { Darwin.close(fd); throw error }
            guard let key, let read = Format.read(data, key: key) else {
                Darwin.close(fd)
                unreadable.append(url)
                continue
            }
            restored = (url, id, key, read.version, read.edits, read.end, read.records, data.count, fd)
        }

        if let r = restored {
            let fd = r.fd
            if r.version == 1 {
                return try migrate(r.edits, from: (r.id, r.url, fd), directory: directory, keyStore: keyStore,
                                   unreadable: unreadable)
            }
            if r.end < r.size {
                // Cut the torn or unreadable tail, so what is typed next follows the last whole record.
                guard ftruncate(fd, off_t(r.end)) == 0 else { let e = posixError(); Darwin.close(fd); throw e }
                _ = fcntl(fd, F_BARRIERFSYNC)
            }
            return Journal(id: r.id, url: r.url, key: r.key, fd: fd, end: off_t(r.end), seq: UInt64(r.records),
                           replay: r.edits, unreadable: unreadable, keyStore: keyStore)
        }

        let new = try create(in: directory, keyStore: keyStore)
        return Journal(id: new.id, url: new.url, key: new.key, fd: new.fd, end: off_t(Format.headerSize), seq: 0,
                       replay: [], unreadable: unreadable, keyStore: keyStore)
    }

    /// Sessions kept under an older name (the app was Flow until 2026-10-28): each journal in `old` with a record in it
    /// and no lock on it moves into `directory`, its key from `oldKeyStore` into `keyStore`, so `open` restores it there
    /// as if it had been written there. Keys stored first, then the files moved, then the old keys destroyed: a crash
    /// at any point leaves what the next call takes up, and nothing is lost. A journal with no record holds no text and
    /// stays, with its key, unasked for; one whose lock is held (the old app still runs) stays until it is let go.
    /// Throws when a store will not answer (a keychain question denied); no file has moved then.
    public static func adopt(from old: URL, keyStore oldKeyStore: KeyStore, into directory: URL, keyStore: KeyStore)
        throws {
        let fm = FileManager.default
        let typed = ((try? fm.contentsOfDirectory(atPath: old.path)) ?? []).filter { $0.hasSuffix(".journal") }
            .compactMap { name -> (name: String, id: UUID)? in
                let url = old.appendingPathComponent(name)
                guard !inUse(url), let data = try? Data(contentsOf: url), data.count > Format.headerSize,
                      let id = Format.sessionID(in: data) else { return nil }
                return (name, id)
            }
        guard !typed.isEmpty else { return }
        for t in typed {
            guard try keyStore.key(for: t.id) == nil, let key = try oldKeyStore.key(for: t.id) else { continue }
            try keyStore.store(key: key, for: t.id)
        }
        try fm.createDirectory(at: directory, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        for t in typed {
            try fm.moveItem(at: old.appendingPathComponent(t.name), to: directory.appendingPathComponent(t.name))
        }
        for t in typed { try? oldKeyStore.destroy(for: t.id) }  // a key left behind opens a file that is gone
    }

    /// Another journal holds the file's lock: an app writes it.
    private static func inUse(_ url: URL) -> Bool {
        let fd = Darwin.open(url.path, O_RDONLY | O_CLOEXEC)
        guard fd >= 0 else { return false }
        defer { Darwin.close(fd) }
        return flock(fd, LOCK_EX | LOCK_NB) != 0 && errno == EWOULDBLOCK
    }

    /// A new session's file, locked, with its header. The key reaches the store before the file has a byte, so no
    /// record is ever without it.
    private static func create(in directory: URL, keyStore: KeyStore) throws
        -> (id: UUID, url: URL, key: SymmetricKey, fd: Int32) {
        let id = UUID()
        let key = SymmetricKey(size: .bits256)
        try keyStore.store(key: key, for: id)
        let url = directory.appendingPathComponent("\(id.uuidString).journal")
        // O_EXLOCK takes the same lock as flock, atomically, so no other `open` sees the new file unlocked.
        let fd = Darwin.open(url.path, O_WRONLY | O_CREAT | O_EXCL | O_APPEND | O_CLOEXEC | O_EXLOCK, 0o600)
        guard fd >= 0 else {
            let e = posixError()
            try? keyStore.destroy(for: id)
            throw e
        }
        let header = Format.header(id)
        guard writeAll(fd, header) else {
            let e = posixError()
            Darwin.close(fd)
            unlink(url.path)
            try? keyStore.destroy(for: id)
            throw e
        }
        // The new name has to survive a power loss too: push the directory to the drive; the next F_FULLFSYNC
        // drains the drive's cache, this included.
        let dfd = Darwin.open(directory.path, O_RDONLY | O_CLOEXEC)
        if dfd >= 0 { fsync(dfd); Darwin.close(dfd) }
        return (id, url, key, fd)
    }

    /// A session of format 1 (typing only at the end) restored: its edits, read as format 2's, go into a new file of
    /// format 2, which is on the drive (F_FULLFSYNC) before the old file is finished, key destroyed first, then the
    /// file deleted. A crash in between leaves both keyed; `open` then takes the newer, the new one. If the old key
    /// will not go, the new file goes instead and `open` throws, so the session stays as it was, in format 1, for
    /// the next open. Silent: the text is the same, and the journal is the new one from here on.
    private static func migrate(_ edits: [Edit], from old: (id: UUID, url: URL, fd: Int32), directory: URL,
                                keyStore: KeyStore, unreadable: [URL]) throws -> Journal {
        let new: (id: UUID, url: URL, key: SymmetricKey, fd: Int32)
        do { new = try create(in: directory, keyStore: keyStore) } catch { Darwin.close(old.fd); throw error }
        var end = off_t(Format.headerSize), seq: UInt64 = 0
        do {
            if !edits.isEmpty {
                let record = try Format.record(edits, seq: 0, key: new.key)
                guard writeAll(new.fd, record) else { throw posixError() }
                (end, seq) = (end + off_t(record.count), 1)
            }
            if fcntl(new.fd, F_FULLFSYNC) == -1 { fsync(new.fd) }
            try keyStore.destroy(for: old.id)
        } catch {
            Darwin.close(new.fd)
            unlink(new.url.path)
            try? keyStore.destroy(for: new.id)
            Darwin.close(old.fd)
            throw error
        }
        unlink(old.url.path)  // noise now that its key is gone, so a failure here loses nothing
        Darwin.close(old.fd)
        return Journal(id: new.id, url: new.url, key: new.key, fd: new.fd, end: end, seq: seq, replay: edits,
                       unreadable: unreadable, keyStore: keyStore)
    }

    private init(id: UUID, url: URL, key: SymmetricKey, fd: Int32, end: off_t, seq: UInt64, replay: [Edit],
                 unreadable: [URL], keyStore: KeyStore) {
        self.sessionID = id
        self.fileURL = url
        self.key = key
        self.fd = fd
        self.end = end
        self.seq = seq
        self.replay = replay
        self.unreadable = unreadable
        self.keyStore = keyStore
    }

    deinit {
        if fd >= 0 { Darwin.close(fd) }
    }

    /// Queues an edit and returns. Edits appended within 50 ms of the first one go into one record, which is
    /// write()n at once (it then survives an app crash and force quit) and followed by a barrier. The window keeps
    /// the record count and sizes from following single keystrokes; the file holds no timestamps.
    public func append(_ edit: Edit) {
        queue.async { [self] in
            guard key != nil else { return }
            pending.append(edit)
            guard !windowOpen else { return }
            windowOpen = true
            queue.asyncAfter(deadline: .now() + .milliseconds(50)) { [self] in
                windowOpen = false
                if writePending() { sync(.barrier) }
            }
        }
    }

    /// Writes what is queued, then syncs at `level`. Blocks until done (on the M2 Pro of the research note, ≈0.2 ms
    /// for a barrier and ≈2 ms for a full flush): the app calls `.full` on quit, where it must finish first; for the
    /// idle flush it may call this from a background queue.
    public func flush(_ level: FlushLevel) {
        queue.sync {
            guard key != nil else { return }
            writePending()
            sync(level)
        }
    }

    /// Done: destroys the key, then deletes the file. Key first, so a crash in between leaves only unreadable
    /// noise. Queued edits are dropped: the text has been handed off. If the key store fails, the error is thrown
    /// and the file stays, so the session comes back on the next `open` rather than being lost.
    public func finish() throws {
        queue.sync {
            key = nil
            pending.removeAll()
        }
        // The lock is held until the file is gone, so no other `open` restores a session while it is being finished.
        defer { queue.sync { if fd >= 0 { Darwin.close(fd); fd = -1 } } }
        try keyStore.destroy(for: sessionID)
        if unlink(fileURL.path) != 0 && errno != ENOENT { throw posixError() }
    }

    /// Same as `finish` for v1.
    public func discard() throws {
        try finish()
    }

    /// Seals the queued edits into one record and writes it with one write(). On failure (disk full) the file is cut
    /// back to its last whole record and the edits stay queued for the next attempt, so the journal never has a gap.
    @discardableResult
    private func writePending() -> Bool {
        guard let key, !pending.isEmpty else { return false }
        guard let record = try? Format.record(pending, seq: seq, key: key), Self.writeAll(fd, record) else {
            ftruncate(fd, end)
            return false
        }
        pending.removeAll()
        seq += 1
        end += off_t(record.count)
        return true
    }

    private func sync(_ level: FlushLevel) {
        // Not every file system has these (network volumes): fsync at least reaches the drive there.
        if fcntl(fd, level == .full ? F_FULLFSYNC : F_BARRIERFSYNC) == -1 { fsync(fd) }
    }

    private static func writeAll(_ fd: Int32, _ data: Data) -> Bool {
        data.withUnsafeBytes { buf in
            var done = 0
            while done < buf.count {
                let n = Darwin.write(fd, buf.baseAddress! + done, buf.count - done)
                if n < 0 {
                    if errno == EINTR { continue }
                    return false
                }
                done += n
            }
            return true
        }
    }
}

private func posixError() -> POSIXError {
    POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
}

/// The file format, apart from the journal's state so tests can read and build files.
enum Format {
    static let magic = Data("FLOWJ2".utf8)
    /// Format 1, from before the caret could move (DESIGN.md B1): still read, and moved to format 2 on restore;
    /// written only by the tests.
    static let magicV1 = Data("FLOWJ1".utf8)
    static let headerSize = 6 + 16

    struct Batch<E: Codable>: Codable {
        var seq: UInt64
        var edits: [E]
    }

    static func header(_ id: UUID, magic: Data = magic) -> Data {
        magic + withUnsafeBytes(of: id.uuid) { Data($0) }
    }

    /// The format (1 or 2) and the session's UUID; nil when the header is not a journal's.
    static func header(in data: Data) -> (version: Int, id: UUID)? {
        guard data.count >= headerSize else { return nil }
        let version: Int
        switch data.prefix(magic.count) {
        case magic: version = 2
        case magicV1: version = 1
        default: return nil
        }
        return (version, data.withUnsafeBytes { UUID(uuid: $0.loadUnaligned(fromByteOffset: magic.count, as: uuid_t.self)) })
    }

    static func sessionID(in data: Data) -> UUID? { header(in: data)?.id }

    static func aad(_ seq: UInt64) -> Data {
        withUnsafeBytes(of: seq.littleEndian) { Data($0) }
    }

    /// One record: the length, then nonce ‖ ciphertext ‖ tag under a fresh random nonce.
    static func record<E: Codable>(_ edits: [E], seq: UInt64, key: SymmetricKey) throws -> Data {
        let payload = try JSONEncoder().encode(Batch(seq: seq, edits: edits))
        let sealed = try AES.GCM.seal(payload, using: key, authenticating: aad(seq)).combined!  // 12-byte nonce: never nil
        return withUnsafeBytes(of: UInt32(sealed.count).littleEndian) { Data($0) } + sealed
    }

    /// Opens the records in order and stops at the first that is short (a torn tail) or does not open (damage,
    /// reordering). nil when the header is not a journal's or a whole first record does not open (wrong key). A file
    /// of format 1 comes back as format 2's edits (`V1Edit.upgrade`).
    static func read(_ data: Data, key: SymmetricKey) -> (version: Int, edits: [Edit], end: Int, records: Int)? {
        guard let version = header(in: data)?.version else { return nil }
        if version == 1 {
            return records(data, key: key, as: V1Edit.self).map { (1, V1Edit.upgrade($0.edits), $0.end, $0.records) }
        }
        return records(data, key: key, as: Edit.self).map { (2, $0.edits, $0.end, $0.records) }
    }

    private static func records<E: Codable>(_ data: Data, key: SymmetricKey, as: E.Type)
        -> (edits: [E], end: Int, records: Int)? {
        let decoder = JSONDecoder()
        var edits: [E] = []
        var at = headerSize
        var seq: UInt64 = 0
        while at + 4 <= data.count {
            let n = Int(UInt32(littleEndian: data.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: at, as: UInt32.self) }))
            guard at + 4 + n <= data.count else { break }
            let start = data.startIndex + at + 4
            guard let box = try? AES.GCM.SealedBox(combined: data[start ..< start + n]),
                  let plain = try? AES.GCM.open(box, using: key, authenticating: aad(seq)),
                  let batch = try? decoder.decode(Batch<E>.self, from: plain), batch.seq == seq
            else {
                if seq == 0 { return nil }
                break
            }
            edits += batch.edits
            seq += 1
            at += 4 + n
        }
        return (edits, at, Int(seq))
    }
}

/// An edit of format 1: typing only at the end of the text, paragraphs apart by "\n". `insert` appended its text, a
/// newline of any kind in it ending a paragraph; `deleteBackward` took that many UTF-16 units off the last paragraph,
/// never past its start; `paragraphEnd` ended it.
enum V1Edit: Codable, Equatable {
    case insert(String)
    case deleteBackward(Int)
    case paragraphEnd

    /// Format 1's edits as format 2's: the text they leave, as one insert. They only ever appended or cut at the end,
    /// so nothing but that text can be recovered from them; and as one edit, its offsets need no Character counting
    /// of a text that format 1 cut in UTF-16 units. The cuts are NSString's, as format 1's app made them.
    static func upgrade(_ edits: [V1Edit]) -> [Edit] {
        var paragraphs = [""]
        for e in edits {
            switch e {
            case .insert(let s):
                for (k, part) in s.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline).enumerated() {
                    if k > 0 { paragraphs.append("") }
                    paragraphs[paragraphs.count - 1] += part
                }
            case .deleteBackward(let n):
                let last = paragraphs[paragraphs.count - 1] as NSString
                paragraphs[paragraphs.count - 1] = last.substring(to: max(last.length - n, 0))
            case .paragraphEnd:
                paragraphs.append("")
            }
        }
        let text = paragraphs.joined(separator: "\n")
        return text.isEmpty ? [] : [.insert(at: 0, text)]
    }
}
