import CryptoKit
import Foundation
import Testing
@testable import FlowJournal

// Serialized: the tests are quick, and the timing test's numbers mean nothing with other tests syncing beside it.
@Suite(.serialized) final class JournalTests {
    let dir = FileManager.default.temporaryDirectory
        .appendingPathComponent("FlowJournalTests-\(UUID().uuidString)").appendingPathComponent("sessions")
    let store = MemoryKeyStore()

    deinit {
        try? FileManager.default.removeItem(at: dir.deletingLastPathComponent())
    }

    func open() throws -> Journal { try Journal.open(directory: dir, keyStore: store) }

    /// Runs a session and lets its journal go as a quit would: flushed, then released once its batch window's timer
    /// (which holds it) has fired. That closes the file and frees its lock for the next `open`.
    func session(in directory: URL? = nil, _ body: (Journal) throws -> Void = { _ in }) throws -> (id: UUID, url: URL) {
        var j: Journal? = try Journal.open(directory: directory ?? dir, keyStore: store)
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
                case 0: .paragraphEnd
                case 3: .deleteBackward(i % 3 + 1)
                default: .insert(words[i % words.count])
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
            for w in ["one ", "two ", "three"] {
                j.append(.insert(w))
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
            #expect(k.replay == [.insert("one "), .insert("two ")])
        }
        // The torn bytes were cut off, so what is typed after the restore follows the last whole record.
        _ = try session { k in
            #expect(k.sessionID == id)
            k.append(.insert("2"))
        }
        #expect(try open().replay == [.insert("one "), .insert("two "), .insert("2")])
    }

    @Test func finishedSessionIsNoise() throws {
        let j = try open()
        j.append(.insert("secret"))
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
        let (id, url) = try session { j in j.append(.insert("secret")) }
        try store.store(key: SymmetricKey(size: .bits256), for: id)
        let k = try open()
        #expect(k.sessionID != id)
        #expect(k.replay.isEmpty)
        #expect(k.unreadable.map(\.lastPathComponent) == [url.lastPathComponent])
        #expect(try Data(contentsOf: url).count > Format.headerSize)  // left alone, not cut
    }

    @Test func reorderedRecordsStopTheReplay() throws {
        let (id, url) = try session { j in
            for w in ["a", "b", "c", "d"] {
                j.append(.insert(w))
                j.flush(.barrier)
            }
        }
        let data = try Data(contentsOf: url)
        let r = records(url)
        try #require(r.count == 4)
        try (data.prefix(r[0].upperBound) + data[r[2]] + data[r[1]] + data[r[3]]).write(to: url)
        let k = try open()
        #expect(k.sessionID == id)
        #expect(k.replay == [.insert("a")])
    }

    @Test func aJournalInUseIsNotRestored() throws {
        let j = try open()
        j.append(.insert("mine"))
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
            j.append(.insert("\(i)"))
            usleep(450)
        }
        try #require(Date().timeIntervalSince(start) < 0.04, "the appends took longer than the window")
        Thread.sleep(forTimeInterval: 0.2)
        #expect(records(j.fileURL).count == 1)
        j.append(.insert("later"))
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
        #expect(k.replay == (0 ..< 40).map { .insert("w\($0) ") })
    }

    // Uses the login keychain, which may prompt: FLOW_KEYCHAIN_TEST=1 swift test ... --filter loginKeychain
    @Test(.enabled(if: ProcessInfo.processInfo.environment["FLOW_KEYCHAIN_TEST"] == "1"))
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
                j.append(.insert("w\(i) "))
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
            file += try Format.record([i % 6 == 5 ? .insert(" ") : .insert("e")], seq: UInt64(i), key: key)
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
