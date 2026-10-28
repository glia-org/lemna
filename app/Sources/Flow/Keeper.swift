// The session's journal in the app (DESIGN.md E2): opens or silently restores it, appends each edit, and flushes it
// fully on 1 s idle (a coalescing timer on a background queue), on deactivate, on Done and on quit.
import FlowCore
import FlowJournal
import Foundation

final class Keeper {
    /// `.noindex` keeps Spotlight out; the journal marks the folder excluded from backups on every open.
    static let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("Flow/sessions.noindex", isDirectory: true)

    private(set) var journal: Journal?
    /// Why the session is not kept, when it is not: for the alert.
    private(set) var problem: String?

    private let queue = DispatchQueue(label: "org.flow.flush", qos: .utility)
    private let idle: DispatchSourceTimer
    private var target: Journal?  // the journal the flushes on `queue` reach; touched only there

    init() {
        idle = DispatchSource.makeTimerSource(queue: queue)
        idle.setEventHandler { [unowned self] in self.target?.flush(.full) }
        idle.schedule(deadline: .distantFuture)
        idle.activate()
    }

    /// Restores the most recent unfinished session, or starts one; returns its text. On failure (keychain locked or
    /// refused, folder not writable) there is no journal and `problem` says why; writing goes on.
    func open() -> Text {
        do {
            let j = try Journal.open(directory: Self.directory, keyStore: KeychainKeyStore())
            use(j)
            problem = nil
            return Text(replaying: j.replay)
        } catch {
            use(nil)
            problem = describe(error)
            return Text()
        }
    }

    /// One edit, on the key event: queued in the journal (written within 50 ms), and the idle flush moved to 1 s on.
    func append(_ e: Edit) {
        guard let journal else { return }
        journal.append(e)
        idle.schedule(deadline: .now() + 1)
    }

    /// A full flush off the main thread: deactivate, Done.
    func flushSoon() { queue.async { [self] in target?.flush(.full) } }

    /// A full flush that returns when it is on the drive: quit.
    func flushNow() { journal?.flush(.full) }

    /// The session is over: key destroyed, then file deleted. The journal is spent either way; when the key store
    /// refuses, this throws and the file stays for the next open, so nothing is lost.
    func end(discard: Bool) throws {
        defer { use(nil) }
        do {
            if discard { try journal?.discard() } else { try journal?.finish() }
        } catch {
            problem = describe(error)
            throw error
        }
    }

    private func use(_ j: Journal?) {
        journal = j
        queue.async { [self] in target = j }
    }
}

/// An error in a few words for the alert and the footer.
func describe(_ error: Error) -> String {
    if let k = error as? KeychainError { return "the keychain refused (\(k))" }
    return (error as NSError).localizedFailureReason ?? error.localizedDescription
}
