import CryptoKit
import Darwin
import Foundation

/// One change to the text, as the app's text model replays it. The journal holds edits, never the text.
public enum Edit: Codable, Equatable {
    case insert(String)
    case deleteBackward(Int)
    case paragraphEnd
}

public enum FlushLevel {
    /// `F_BARRIERFSYNC`: orders the journal on the drive, so after a power loss the file is a valid prefix.
    case barrier
    /// `F_FULLFSYNC`: drains the drive's cache; everything written so far survives a power loss.
    case full
}

/// A session's encrypted, append-only journal (DESIGN.md E2). One file per session, `<uuid>.journal`:
/// `FLOWJ1`, the session's UUID (16 bytes), then records. A record is a 4-byte little-endian length and an AES-GCM
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
    private let queue = DispatchQueue(label: "org.flow.journal")
    // Everything below is touched only on `queue`.
    private var key: SymmetricKey?  // nil once finished
    private var fd: Int32
    private var end: off_t  // the end of the last whole record: where a failed write is cut back to
    private var seq: UInt64  // the next record's sequence number
    private var pending: [Edit] = []
    private var windowOpen = false

    /// Restores the most recent unfinished session in `directory` (a journal whose key `keyStore` still has), or
    /// starts a new one. Creates the directory (0700) and marks it excluded from backups. Each journal holds an
    /// exclusive `flock` on its file for its lifetime; `open` skips files whose lock is held.
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
        var restored: (url: URL, id: UUID, key: SymmetricKey, edits: [Edit], end: Int, records: Int, size: Int, fd: Int32)?
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
            restored = (url, id, key, read.edits, read.end, read.records, data.count, fd)
        }

        if let r = restored {
            let fd = r.fd
            if r.end < r.size {
                // Cut the torn or unreadable tail, so what is typed next follows the last whole record.
                guard ftruncate(fd, off_t(r.end)) == 0 else { let e = posixError(); Darwin.close(fd); throw e }
                _ = fcntl(fd, F_BARRIERFSYNC)
            }
            return Journal(id: r.id, url: r.url, key: r.key, fd: fd, end: off_t(r.end), seq: UInt64(r.records),
                           replay: r.edits, unreadable: unreadable, keyStore: keyStore)
        }

        // A new session. The key reaches the store before the file has a byte, so no record is ever without it.
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
        return Journal(id: id, url: url, key: key, fd: fd, end: off_t(header.count), seq: 0,
                       replay: [], unreadable: unreadable, keyStore: keyStore)
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
    static let magic = Data("FLOWJ1".utf8)
    static let headerSize = 6 + 16

    struct Batch: Codable {
        var seq: UInt64
        var edits: [Edit]
    }

    static func header(_ id: UUID) -> Data {
        magic + withUnsafeBytes(of: id.uuid) { Data($0) }
    }

    static func sessionID(in data: Data) -> UUID? {
        guard data.count >= headerSize, data.prefix(magic.count) == magic else { return nil }
        return data.withUnsafeBytes { UUID(uuid: $0.loadUnaligned(fromByteOffset: magic.count, as: uuid_t.self)) }
    }

    static func aad(_ seq: UInt64) -> Data {
        withUnsafeBytes(of: seq.littleEndian) { Data($0) }
    }

    /// One record: the length, then nonce ‖ ciphertext ‖ tag under a fresh random nonce.
    static func record(_ edits: [Edit], seq: UInt64, key: SymmetricKey) throws -> Data {
        let payload = try JSONEncoder().encode(Batch(seq: seq, edits: edits))
        let sealed = try AES.GCM.seal(payload, using: key, authenticating: aad(seq)).combined!  // 12-byte nonce: never nil
        return withUnsafeBytes(of: UInt32(sealed.count).littleEndian) { Data($0) } + sealed
    }

    /// Opens the records in order and stops at the first that is short (a torn tail) or does not open (damage,
    /// reordering). nil when the header is not a journal's or a whole first record does not open (wrong key).
    static func read(_ data: Data, key: SymmetricKey) -> (edits: [Edit], end: Int, records: Int)? {
        guard sessionID(in: data) != nil else { return nil }
        let decoder = JSONDecoder()
        var edits: [Edit] = []
        var at = headerSize
        var seq: UInt64 = 0
        while at + 4 <= data.count {
            let n = Int(UInt32(littleEndian: data.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: at, as: UInt32.self) }))
            guard at + 4 + n <= data.count else { break }
            let start = data.startIndex + at + 4
            guard let box = try? AES.GCM.SealedBox(combined: data[start ..< start + n]),
                  let plain = try? AES.GCM.open(box, using: key, authenticating: aad(seq)),
                  let batch = try? decoder.decode(Batch.self, from: plain), batch.seq == seq
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
