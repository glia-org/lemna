// Harper in the app (DESIGN.md R2): offline English suggestions for the review, from lib/FlowHarper, linted off the
// main thread and handed to the review as FlowCore's plain values.
import FlowCore
import FlowHarper
import Foundation

final class Lint {
    /// Every lint runs here, one at a time, from the warm-up at launch on. Harper also caches per sentence and per
    /// thread: the same 1,000 words lint again in 19 ms on the thread that linted them, in 40 ms on another (README.md,
    /// Pass 7b). A serial queue usually stays on its thread, but GCD may move it when other work runs in a pause; a
    /// re-lint then costs those 20 ms more, which the review does not notice.
    private let queue = DispatchQueue(label: "org.flow.harper", qos: .userInitiated)

    /// The first lint in a process builds Harper's linter (about 0.25 s): once after launch, so the first review does
    /// not wait for it.
    func warmUp() { queue.async { _ = Harper.lint("Warm up.") } }

    /// Harper's suggestions for `text`, numbered in text order; `done` gets them on the main thread.
    func lint(_ text: String, done: @escaping ([FlowCore.Suggestion]) -> Void) {
        queue.async {
            let found = Harper.lint(text).enumerated().map { i, s in
                FlowCore.Suggestion(number: i + 1, in: text, range: s.range, replacements: s.replacements, kind: s.kind,
                                    message: s.message)
            }
            DispatchQueue.main.async { done(found) }
        }
    }
}
