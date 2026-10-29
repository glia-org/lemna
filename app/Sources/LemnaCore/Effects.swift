// The Effects submenu (DESIGN.md F1 S1): which effects play, Off, and Reduce Motion; and every effect's magnitude in one
// table (`Effects.Tuning`). Free of AppKit, so the tests check it.
import CoreGraphics

/// The effects ticked and whether they play. Off keeps the ticks, as Sound ▸ Off keeps the pack; Reduce Motion stops the
/// ones that move (the submenu greys them) and leaves the others as ticked. The box's still accent border (B1) and the
/// glide's curve (G1) are no items: they are always so.
public struct Effects: Equatable {
    public enum Item: String, CaseIterable {
        /// P1, the box's open and close; K1, the newest glyph fading in (a pop-in until pass 18, `glyphPopIn`); H1 and
        /// C1, the hand-off's motion (`Handoff`; since pass 17b, where E1's sheen across the box was, `handOffSheen`);
        /// E2, the ` ¶ ` fading in on Return. Pass 18 removed B2 (the border warming with the keys, `borderWarms`) and
        /// K3 (a sheen along the border on Space, `wordSheen`): a kept tick of theirs is ignored.
        case pop, glyphFade, handOff, paragraphFade

        /// The submenu's item, in `allCases`' order.
        public var title: String {
            switch self {
            case .pop: "Pop"
            case .glyphFade: "Glyph fade"
            case .handOff: "Hand-off"
            case .paragraphFade: "Paragraph fade"
            }
        }

        /// The key its tick was kept under before, read when its own is missing: the glyph fade takes the pop-in's.
        var former: String? { self == .glyphFade ? "glyphPopIn" : nil }

        /// Moves something: a scale (the pop) or the glyphs and the box (the hand-off). Reduce Motion stops these; the
        /// glyph fade and the paragraph fade (opacity alone) move nothing and stay.
        public var moves: Bool { self == .pop || self == .handOff }
    }

    public private(set) var ticked: Set<Item>
    public private(set) var on: Bool

    /// A first launch: every effect ticked (the user's picks P1, K1, H1 and E2), on.
    public init() { (ticked, on) = (Set(Item.allCases), true) }

    /// As kept across launches (`kept`); an item or Off that is not in it (nor under its former key) is ticked, on.
    public init(kept: [String: Bool]?) {
        self.init()
        guard let kept else { return }
        for item in Item.allCases {
            let tick = kept[item.rawValue] ?? item.former.flatMap { kept[$0] } ?? true
            if tick { ticked.insert(item) } else { ticked.remove(item) }
        }
        on = kept[Self.onKey] ?? true
    }

    /// For UserDefaults: each item's tick under its raw value, and whether they play under "on".
    public var kept: [String: Bool] {
        var d = [Self.onKey: on]
        for item in Item.allCases { d[item.rawValue] = ticked.contains(item) }
        return d
    }
    static let onKey = "on"

    /// Whether `item` plays now: ticked, not Off, and not stopped by Reduce Motion.
    public func plays(_ item: Item, reduceMotion: Bool) -> Bool {
        on && ticked.contains(item) && Self.available(item, reduceMotion: reduceMotion)
    }

    /// Whether the submenu offers `item`: greyed when Reduce Motion stops it.
    public static func available(_ item: Item, reduceMotion: Bool) -> Bool { !(reduceMotion && item.moves) }

    /// Every effect's duration goes through here (Omarchy's `Style.duration`): `d` while `item` plays, else 0, so it
    /// happens at once.
    public func duration(_ item: Item, _ d: Double, reduceMotion: Bool) -> Double {
        plays(item, reduceMotion: reduceMotion) ? d : 0
    }

    /// An item from the submenu: while the effects play its tick turns over; while they are off they come back with
    /// it ticked (as a pack chosen while the sound is off turns the sound on).
    public mutating func choose(_ item: Item) {
        if on, ticked.contains(item) { ticked.remove(item) } else { ticked.insert(item) }
        on = true
    }

    /// Off: the effects stop, or, while they are off, come back with their ticks.
    public mutating func toggle() { on.toggle() }
}

extension Effects {
    /// Every magnitude of the effects in one place (F1). Pass 14b (the user, having tried pass 14 with every item ticked:
    /// "Where are the new animations, I can barely see anything.") made them plain to see; pass 14's values, the panel's,
    /// stand beside each as "subtle". Durations in seconds, all on the curve (`Curve`) unless said otherwise.
    public enum Tuning {
        /// P1, the box: open from `openScale` with a fade, close in a fade. Omarchy's released window open was 410 ms
        /// from 87 %. Subtle: 0.250 s from 0.95, close 0.160 s.
        public static let open = 0.300, openScale = 0.87, close = 0.200
        /// D1, the dim's opacity (the box's background at it). Unchanged.
        public static let dim: Float = 0.5
        /// K1, the newest glyph, fading in: opacity alone (pass 18; the glyph fade). Was the pop-in (pass 14b): 0.160 s
        /// from 70 % about its baseline-left, rising 3 pt from below the baseline (subtle: 0.120 s from 0.95, no rise).
        public static let glyphFade = 0.080
        /// E2, a Return's ` ¶ `, opacity alone. Subtle: 0.120 s.
        public static let paragraphFade = 0.200
        /// H1 and C1 (pass 17b), the hand-off (`Handoff`): each glyph travels `sendReach` of the box's width to the
        /// right (a paste) or `riseReach` of its height upward (a copy or a save) on the curve over `exit`, the one at the
        /// caret from the key-down's frame on, each further one `exitStagger` after its neighbour nearer the caret, those
        /// past `exitStaggerCap` all with the last (in the box on a 1512 pt screen about 19 glyphs show: 18 of them
        /// 7 ms apart, the faded rest at 120 ms; a cap of 0.060 would send the faded half as one block at 60 ms and
        /// empty the line by about 110 ms); the dim lifts from the key over `lift`; from `collapseAt` the box shrinks to
        /// `collapseScale` about its middle and fades over `collapse`: 280 ms in all. The panel's H1 had ease-in over
        /// ~220 ms, ~8 ms apart, the clause over at most 120 ms. Was E1 (pass 14b): a 45° band of light across the
        /// box, peak 0.35 over 0.350 s at an even pace, the close's fade from 0.150 s (subtle: peak 0.14 over 0.300 s).
        public static let exit = 0.200, exitStagger = 0.007, exitStaggerCap = 0.120
        public static let sendReach: CGFloat = 1.0, riseReach: CGFloat = 1.25
        public static let lift = 0.160, collapseAt = 0.120, collapse = 0.160, collapseScale = 0.9
        /// Removed in pass 18: K3's word sheen (0.300 s, peak 0.7) and B2's warming border (back in 0.150 s, cooling
        /// over 1.0 s from 0.5 s after the last key).
    }
}
