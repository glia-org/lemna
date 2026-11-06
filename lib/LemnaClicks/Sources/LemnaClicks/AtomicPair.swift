import ClickRing

/// Two floats one thread sets and another reads, together, without a lock or an allocation: the bed's fade cell
/// (ClickRing's `click_fade`, one 64-bit atomic), for an app's own render code. Lemna's other-sound tap (DESIGN.md DK1)
/// hands its shade's target and step to its IO block in one, and the block's counts back in another.
public final class AtomicPair: @unchecked Sendable {
    private let cell: OpaquePointer

    /// Both zero.
    public init() { cell = click_fade_create()! }

    deinit { click_fade_destroy(cell) }

    /// One writer at a time; a reader sees both values of one `set`, never one of each.
    public func set(_ a: Float, _ b: Float) { click_fade_set(cell, a, b) }

    public func get() -> (Float, Float) {
        var a: Float = 0, b: Float = 0
        click_fade_get(cell, &a, &b)
        return (a, b)
    }
}
