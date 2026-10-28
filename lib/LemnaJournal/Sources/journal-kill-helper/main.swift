// The child process of the kill -9 test: `journal-kill-helper <directory> <count>` opens a journal, appends <count>
// edits, lets the batch window pass without any flush, prints "ready" and waits to be killed. Its key store is in
// this process, so it prints the key ("key <uuid> <base64>") for the test to restore with.
import CryptoKit
import LemnaJournal
import Foundation

final class PrintingKeyStore: KeyStore {
    func store(key: SymmetricKey, for session: UUID) throws {
        print("key \(session.uuidString) \(key.withUnsafeBytes { Data($0) }.base64EncodedString())")
    }
    func key(for session: UUID) throws -> SymmetricKey? { nil }
    func destroy(for session: UUID) throws {}
    func sessions() throws -> [UUID] { [] }
}

let journal = try Journal.open(directory: URL(fileURLWithPath: CommandLine.arguments[1]), keyStore: PrintingKeyStore())
var at = 0  // each word typed at the end: its offset is the Characters before it
for i in 0 ..< Int(CommandLine.arguments[2])! {
    journal.append(.insert(at: at, "w\(i) "))
    at += "w\(i) ".count
}
Thread.sleep(forTimeInterval: 0.3)  // past the 50 ms window: the batch is write()n, never flushed
print("ready")
fflush(stdout)
Thread.sleep(forTimeInterval: 60)
