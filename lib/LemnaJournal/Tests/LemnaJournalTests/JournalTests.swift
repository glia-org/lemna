import CryptoKit
import Foundation
import Security
import Testing
@testable import LemnaJournal

// Serialized: the tests are quick, and the timing test's numbers mean nothing with other tests syncing beside it.
@Suite(.serialized) final class JournalTests {
    let dir = FileManager.default.temporaryDirectory
        .appendingPathComponent("LemnaJournalTests-\(UUID().uuidString)").appendingPathComponent("sessions")
    let store = MemoryKeyStore()

    deinit {
        try? FileManager.default.removeItem(at: dir.deletingLastPathComponent())
    }

    func open() throws -> Journal { try Journal.open(directory: dir, keyStore: store) }

    /// Runs a session and lets its journal go as a quit would: flushed, then released once its batch window's timer
    /// (which holds it) has fired. That closes the file and frees its lock for the next `open`.
    func session(in directory: URL? = nil, keyStore: KeyStore? = nil, _ body: (Journal) throws -> Void = { _ in }) throws
        -> (id: UUID, url: URL) {
        var j: Journal? = try Journal.open(directory: directory ?? dir, keyStore: keyStore ?? store)
        try body(j!)
        j!.flush(.full)
        let ended = (j!.sessionID, j!.fileURL)
        weak var gone = j
        j = nil
        while gone != nil { usleep(1000) }
        return ended
    }

    @Test func roundTrip() throws {
        let words = ["a", "é ", "naïve ", "日本", "🙂", "\"q\"\\"]
        var edits: [Edit] = []
        let (id, url) = try session { j in
            #expect(j.replay.isEmpty)
            for i in 0 ..< 500 {
                let e: Edit = switch i % 7 {
                case 0: .insert(at: i, "\n")
                case 3: .delete(at: i / 2, count: i % 3 + 1)
                default: .insert(at: i / 3, words[i % words.count])
                }
                edits.append(e)
                j.append(e)
                if i % 50 == 49 { Thread.sleep(forTimeInterval: 0.07) }  // a pause that outlasts the batch window
            }
        }
        #expect(records(url).count >= 10)

        let k = try open()
        #expect(k.sessionID == id)
        #expect(k.fileURL == url)
        #expect(k.replay == edits)
        #expect(k.unreadable.isEmpty)

        let fm = FileManager.default
        #expect(try fm.attributesOfItem(atPath: dir.path)[.posixPermissions] as? Int == 0o700)
        #expect(try fm.attributesOfItem(atPath: url.path)[.posixPermissions] as? Int == 0o600)
        #expect(try dir.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup == true)
    }

    @Test func tornTailIsIgnored() throws {
        let (id, url) = try session { j in
            for (i, w) in ["one ", "two ", "three"].enumerated() {
                j.append(.insert(at: 4 * i, w))
                j.flush(.barrier)
            }
        }
        let whole = try Data(contentsOf: url)
        let last = try #require(records(url).last)
        // Every cut inside the last record, length prefix included, as a crash mid-write would leave it.
        for cut in last.lowerBound + 1 ..< last.upperBound {
            try whole.prefix(cut).write(to: url)
            let k = try open()
            #expect(k.sessionID == id)
            #expect(k.replay == [.insert(at: 0, "one "), .insert(at: 4, "two ")])
        }
        // The torn bytes were cut off, so what is typed after the restore follows the last whole record.
        _ = try session { k in
            #expect(k.sessionID == id)
            k.append(.insert(at: 8, "2"))
        }
        #expect(try open().replay == [.insert(at: 0, "one "), .insert(at: 4, "two "), .insert(at: 8, "2")])
    }

    @Test func finishedSessionIsNoise() throws {
        let j = try open()
        j.append(.insert(at: 0, "secret"))
        j.flush(.full)
        let copy = try Data(contentsOf: j.fileURL)
        try j.finish()
        #expect(!FileManager.default.fileExists(atPath: j.fileURL.path))
        #expect(try store.key(for: j.sessionID) == nil)

        // A copy that outlived the key (a snapshot, a backup) replays nothing; `open` starts a new session.
        try copy.write(to: j.fileURL)
        let k = try open()
        #expect(k.sessionID != j.sessionID)
        #expect(k.replay.isEmpty)
        #expect(k.unreadable.map(\.lastPathComponent) == [j.fileURL.lastPathComponent])
    }

    @Test func wrongKeyIsNoise() throws {
        let (id, url) = try session { j in j.append(.insert(at: 0, "secret")) }
        try store.store(key: SymmetricKey(size: .bits256), for: id)
        let k = try open()
        #expect(k.sessionID != id)
        #expect(k.replay.isEmpty)
        #expect(k.unreadable.map(\.lastPathComponent) == [url.lastPathComponent])
        #expect(try Data(contentsOf: url).count > Format.headerSize)  // left alone, not cut
    }

    @Test func reorderedRecordsStopTheReplay() throws {
        let (id, url) = try session { j in
            for (i, w) in ["a", "b", "c", "d"].enumerated() {
                j.append(.insert(at: i, w))
                j.flush(.barrier)
            }
        }
        let data = try Data(contentsOf: url)
        let r = records(url)
        try #require(r.count == 4)
        try (data.prefix(r[0].upperBound) + data[r[2]] + data[r[1]] + data[r[3]]).write(to: url)
        let k = try open()
        #expect(k.sessionID == id)
        #expect(k.replay == [.insert(at: 0, "a")])
    }

    @Test func aJournalInUseIsNotRestored() throws {
        let j = try open()
        j.append(.insert(at: 0, "mine"))
        j.flush(.full)
        let k = try open()  // j still holds its file's lock
        #expect(k.sessionID != j.sessionID)
        #expect(k.replay.isEmpty)
        #expect(k.unreadable.isEmpty)  // in use is not noise
    }

    @Test func editsWithinAWindowShareOneRecord() throws {
        let j = try open()
        let start = Date()
        for i in 0 ..< 20 {
            j.append(.insert(at: i, "\(i)"))
            usleep(450)
        }
        try #require(Date().timeIntervalSince(start) < 0.04, "the appends took longer than the window")
        Thread.sleep(forTimeInterval: 0.2)
        #expect(records(j.fileURL).count == 1)
        j.append(.insert(at: 0, "later"))
        Thread.sleep(forTimeInterval: 0.2)
        #expect(records(j.fileURL).count == 2)
    }

    @Test func survivesKill9WithoutAFlush() throws {
        let helper = Bundle(for: BundleMarker.self).bundleURL.deletingLastPathComponent()
            .appendingPathComponent("journal-kill-helper")
        let p = Process()
        p.executableURL = helper
        p.arguments = [dir.path, "40"]
        let out = Pipe()
        p.standardOutput = out
        try p.run()
        defer { if p.isRunning { p.terminate() } }
        var text = ""
        while !text.contains("ready\n") {
            let chunk = out.fileHandleForReading.availableData
            if chunk.isEmpty { break }
            text += String(decoding: chunk, as: UTF8.self)
        }
        kill(p.processIdentifier, SIGKILL)
        p.waitUntilExit()
        #expect(p.terminationReason == .uncaughtSignal)

        let line = try #require(text.split(separator: "\n").first { $0.hasPrefix("key ") }).split(separator: " ")
        let id = try #require(UUID(uuidString: String(line[1])))
        try store.store(key: SymmetricKey(data: try #require(Data(base64Encoded: String(line[2])))), for: id)
        let k = try open()
        #expect(k.sessionID == id)
        var at = 0  // the helper types each word at the end
        #expect(k.replay == (0 ..< 40).map { i in
            defer { at += "w\(i) ".count }
            return .insert(at: at, "w\(i) ")
        })
    }

    @Test func v2RoundTripWithEditsInTheMiddle() throws {
        // Typed "naïve 🙂 café", then a word put in the middle, a typo cut from it, a paragraph end before the last
        // word: Character offsets, so é, ï and 🙂 are one each.
        let edits: [Edit] = [.insert(at: 0, "naïve 🙂 café"), .insert(at: 6, "very "), .delete(at: 7, count: 2),
                             .insert(at: 7, "er"), .insert(at: 13, "\n"), .delete(at: 0, count: 1)]
        let (_, url) = try session { j in
            for e in edits {
                j.append(e)
                j.flush(.barrier)
            }
        }
        #expect(try Data(contentsOf: url).prefix(6) == Data("FLOWJ2".utf8))
        #expect(try open().replay == edits)
    }

    /// A file as format 1 wrote it: its header, then records of its edits, its key in `store`.
    func writeV1(_ batches: [[V1Edit]]) throws -> (id: UUID, url: URL) {
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let id = UUID(), key = SymmetricKey(size: .bits256)
        try store.store(key: key, for: id)
        var file = Format.header(id, magic: Format.magicV1)
        for (seq, b) in batches.enumerated() { file += try Format.record(b, seq: UInt64(seq), key: key) }
        let url = dir.appendingPathComponent("\(id.uuidString).journal")
        try file.write(to: url)
        return (id, url)
    }

    @Test func v1ReplaysAsTheTextItLeft() {
        // Format 1's own rules: appends; a newline of any kind ends a paragraph; deleteBackward counts UTF-16 units
        // (🙂 is two) and stops at the paragraph's start.
        let v1: [V1Edit] = [.insert("one"), .paragraphEnd, .insert("cafe"), .deleteBackward(1), .insert("é 🙂"),
                            .deleteBackward(2), .insert("x\r\ny"), .deleteBackward(9), .insert("z"), .paragraphEnd]
        #expect(V1Edit.upgrade(v1) == [.insert(at: 0, "one\ncafé x\nz\n")])
        #expect(V1Edit.upgrade([]) == [])
        #expect(V1Edit.upgrade([.insert("a"), .deleteBackward(1)]) == [])
    }

    @Test func v1SessionMovesToV2() throws {
        let (oldID, oldURL) = try writeV1([[.insert("hello"), .paragraphEnd], [.insert("wörld"), .deleteBackward(1)]])
        // The order: when the old key goes, the new file already holds the text, and the old file is still there.
        let watching = Watching(store)
        watching.onDestroy = { [dir] id in
            guard id == oldID else { return }
            let files = (try? FileManager.default.contentsOfDirectory(atPath: dir.path)) ?? []
            let new = files.map { dir.appendingPathComponent($0) }.filter { $0 != oldURL }
            #expect(files.contains(oldURL.lastPathComponent))
            #expect(new.count == 1)
            let data = new.first.flatMap { try? Data(contentsOf: $0) }
            let key = data.flatMap(Format.sessionID).flatMap { try? self.store.key(for: $0) }
            #expect(data.flatMap { d in key.flatMap { Format.read(d, key: $0) } }?.edits
                    == [.insert(at: 0, "hello\nwörl")])
        }
        var j: Journal? = try Journal.open(directory: dir, keyStore: watching)
        #expect(watching.destroyed == [oldID])
        #expect(j!.sessionID != oldID)
        #expect(j!.replay == [.insert(at: 0, "hello\nwörl")])
        #expect(!FileManager.default.fileExists(atPath: oldURL.path))
        #expect(try store.key(for: oldID) == nil)
        #expect(try Data(contentsOf: j!.fileURL).prefix(6) == Data("FLOWJ2".utf8))
        // Writing goes on in the new file, and the next open restores it.
        j!.append(.insert(at: 10, "d"))
        j!.flush(.full)
        let newID = j!.sessionID
        weak var gone = j
        j = nil
        while gone != nil { usleep(1000) }
        let k = try open()
        #expect(k.sessionID == newID)
        #expect(k.replay == [.insert(at: 0, "hello\nwörl"), .insert(at: 10, "d")])
    }

    @Test func aV1SessionWhoseKeyWillNotGoStaysAsItWas() throws {
        let (oldID, oldURL) = try writeV1([[.insert("kept")]])
        let refusing = Watching(store)
        refusing.refuse = oldID
        #expect(throws: KeychainError.self) { try Journal.open(directory: dir, keyStore: refusing) }
        // Nothing new is left behind: the old file and its key, as before; the next open moves it.
        #expect(try FileManager.default.contentsOfDirectory(atPath: dir.path) == [oldURL.lastPathComponent])
        #expect(try store.sessions() == [oldID])
        #expect(try open().replay == [.insert(at: 0, "kept")])
    }

    /// The app was called Flow until 2026-10-28: a session it left unfinished, in its folder and under its key store,
    /// comes along into the new ones, and `open` restores it there.
    @Test func adoptBringsAnUnfinishedSessionAlong() throws {
        let old = dir.deletingLastPathComponent().appendingPathComponent("old"), oldStore = MemoryKeyStore()
        let (id, url) = try session(in: old, keyStore: oldStore) { $0.append(.insert(at: 0, "kept")) }
        // A store that will not answer (a keychain question denied): nothing moves, and the next call tries again.
        let locked = Watching(oldStore)
        locked.locked = true
        #expect(throws: KeychainError.self) { try Journal.adopt(from: old, keyStore: locked, into: dir, keyStore: store) }
        #expect(FileManager.default.fileExists(atPath: url.path))
        #expect(try store.sessions().isEmpty)
        try Journal.adopt(from: old, keyStore: oldStore, into: dir, keyStore: store)
        #expect(!FileManager.default.fileExists(atPath: url.path))
        #expect(try oldStore.sessions().isEmpty)
        let j = try open()
        #expect(j.sessionID == id)
        #expect(j.replay == [.insert(at: 0, "kept")])
    }

    @Test func adoptLeavesAnEmptySessionAndOneInUse() throws {
        let old = dir.deletingLastPathComponent().appendingPathComponent("old"), oldStore = MemoryKeyStore()
        let empty = try session(in: old, keyStore: oldStore)
        try Journal.adopt(from: old, keyStore: oldStore, into: dir, keyStore: store)
        // Nothing typed, nothing to bring: the file and its key stay, and the old store is not asked for the key.
        #expect(FileManager.default.fileExists(atPath: empty.url.path))
        #expect(try oldStore.sessions() == [empty.id] && store.sessions().isEmpty)
        // Typed into while the old app still runs (its lock held): left until that has let go, then brought along,
        // also when the new folder has a session of its own by then.
        let ours = try session()
        var j: Journal? = try Journal.open(directory: old, keyStore: oldStore)
        #expect(j!.sessionID == empty.id)
        j!.append(.insert(at: 0, "late"))
        j!.flush(.full)
        try Journal.adopt(from: old, keyStore: oldStore, into: dir, keyStore: store)
        #expect(FileManager.default.fileExists(atPath: empty.url.path))
        weak var gone = j
        j = nil
        while gone != nil { usleep(1000) }
        try Journal.adopt(from: old, keyStore: oldStore, into: dir, keyStore: store)
        #expect(!FileManager.default.fileExists(atPath: empty.url.path))
        #expect(Set(try store.sessions()) == [ours.id, empty.id])
        let key = try #require(try store.key(for: empty.id))
        let moved = try Data(contentsOf: dir.appendingPathComponent(empty.url.lastPathComponent))
        #expect(Format.read(moved, key: key)?.edits == [.insert(at: 0, "late")])
    }

    // Uses the login keychain, which may prompt: LEMNA_KEYCHAIN_TEST=1 swift test ... --filter loginKeychain
    @Test(.enabled(if: ProcessInfo.processInfo.environment["LEMNA_KEYCHAIN_TEST"] == "1"))
    func loginKeychain() throws {
        let keychain = KeychainKeyStore()
        let id = UUID()
        let key = SymmetricKey(size: .bits256)
        try keychain.store(key: key, for: id)
        defer { try? keychain.destroy(for: id) }
        #expect(try keychain.key(for: id) == key)
        #expect(try keychain.sessions().contains(id))
        try keychain.destroy(for: id)
        #expect(try keychain.key(for: id) == nil)
        #expect(try !keychain.sessions().contains(id))
        try keychain.destroy(for: id)  // already gone: no error
    }

    // Prints, does not assert: the cost on this Mac of a record with each flush level, and of a long restore.
    @Test func timing() throws {
        for level in [FlushLevel.barrier, .full] {
            let j = try Journal.open(directory: dir.appendingPathComponent("\(level)"), keyStore: store)
            var us: [Double] = []
            for i in 0 ..< 300 {
                j.append(.insert(at: 3 * i, "w\(i) "))
                let t0 = DispatchTime.now().uptimeNanoseconds
                j.flush(level)
                us.append(Double(DispatchTime.now().uptimeNanoseconds - t0) / 1000)
            }
            print("timing: one record + flush(.\(level)): " + percentiles(us))
        }

        // Two hours at 5 keys/s with keys further apart than the window: one record per key.
        let restoreDir = dir.appendingPathComponent("restore")
        let (id, url) = try session(in: restoreDir)
        let key = try #require(try store.key(for: id))
        var file = Format.header(id)
        for i in 0 ..< 36_000 {
            file += try Format.record([Edit.insert(at: i, i % 6 == 5 ? " " : "e")], seq: UInt64(i), key: key)
        }
        try file.write(to: url)
        let t0 = DispatchTime.now().uptimeNanoseconds
        let k = try Journal.open(directory: restoreDir, keyStore: store)
        let ms = Double(DispatchTime.now().uptimeNanoseconds - t0) / 1e6
        #expect(k.replay.count == 36_000)
        print(String(format: "timing: restore of 36000 records (%.1f MB): %.0f ms", Double(file.count) / 1e6, ms))
    }
}

private final class BundleMarker {}

/// A key store that reports each destroy before it happens, and can refuse one, or every key.
private final class Watching: KeyStore {
    let inner: KeyStore
    var onDestroy: (UUID) -> Void = { _ in }
    var refuse: UUID?
    var locked = false  // `key(for:)` throws, as a locked keychain or a denied question does
    private(set) var destroyed: [UUID] = []
    init(_ inner: KeyStore) { self.inner = inner }

    func store(key: SymmetricKey, for session: UUID) throws { try inner.store(key: key, for: session) }
    func key(for session: UUID) throws -> SymmetricKey? {
        if locked { throw KeychainError(status: errSecInteractionNotAllowed) }
        return try inner.key(for: session)
    }
    func sessions() throws -> [UUID] { try inner.sessions() }
    func destroy(for session: UUID) throws {
        if session == refuse { throw KeychainError(status: errSecInteractionNotAllowed) }
        onDestroy(session)
        try inner.destroy(for: session)
        destroyed.append(session)
    }
}

/// The byte ranges of the file's records (length prefix included), read from the length prefixes alone.
private func records(_ url: URL) -> [Range<Int>] {
    guard let data = try? Data(contentsOf: url) else { return [] }
    var out: [Range<Int>] = []
    var at = Format.headerSize
    while at + 4 <= data.count {
        let n = Int(UInt32(littleEndian: data.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: at, as: UInt32.self) }))
        guard at + 4 + n <= data.count else { break }
        out.append(at ..< at + 4 + n)
        at += 4 + n
    }
    return out
}

private func percentiles(_ us: [Double]) -> String {
    let s = us.sorted()
    let p = { (q: Double) in s[min(s.count - 1, Int(q * Double(s.count)))] }
    return String(format: "p50 %.0f µs, p90 %.0f µs, p99 %.0f µs, max %.0f µs (n=%d)", p(0.5), p(0.9), p(0.99), s.last!, s.count)
}
