// The Effects submenu (DESIGN.md F1 S1): which effects play, Off, and Reduce Motion; and every effect's magnitude in one
// table (`Effects.Tuning`). Free of AppKit, so the tests check it.
import CoreGraphics

/// The effects ticked and whether they play. Off keeps the ticks, as Sound ▸ Off keeps the pack; Reduce Motion stops the
/// ones that move (the submenu greys them) and leaves the others as ticked. The box's still accent border (B1) and the
/// glide's curve (G1) are no items: they are always so.
public struct Effects: Equatable {
    public enum Item: String, CaseIterable {
        /// P1, the box's open and close; B2, the border warming with the keys; K1, the newest glyph's pop-in; K3, a sheen
        /// along the border on Space; E1, a sheen across the box at a hand-off; E2, the ` ¶ ` fading in on Return.
        case pop, borderWarms, glyphPopIn, wordSheen, handOffSheen, paragraphFade

        /// The submenu's item, in `allCases`' order.
        public var title: String {
            switch self {
            case .pop: "Pop"
            case .borderWarms: "Border warms"
            case .glyphPopIn: "Glyph pop-in"
            case .wordSheen: "Word sheen"
            case .handOffSheen: "Hand-off sheen"
            case .paragraphFade: "Paragraph fade"
            }
        }

        /// Ticked at a first launch: the user's picks P1, K1, E1 and E2; B2 and K3 are opt-in.
        public var byDefault: Bool { self != .borderWarms && self != .wordSheen }

        /// Moves something: a scale (the pop, the glyph's pop-in) or a sweep (the sheens). Reduce Motion stops these; the
        /// paragraph fade (opacity alone) and the border's warmth (a colour) move nothing and stay.
        public var moves: Bool { self != .borderWarms && self != .paragraphFade }
    }

    public private(set) var ticked: Set<Item>
    public private(set) var on: Bool

    /// A first launch: the defaults, on.
    public init() { (ticked, on) = (Set(Item.allCases.filter(\.byDefault)), true) }

    /// As kept across launches (`kept`); an item or Off that is not in it takes its default.
    public init(kept: [String: Bool]?) {
        self.init()
        guard let kept else { return }
        for item in Item.allCases {
            if kept[item.rawValue] ?? item.byDefault { ticked.insert(item) } else { ticked.remove(item) }
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
        /// K1, the newest glyph: from `popInScale` about its baseline-left, rising `popInRise` points from below the
        /// baseline, fading in. Subtle: 0.120 s from 0.95, no rise.
        public static let popIn = 0.160, popInScale = 0.70, popInRise = 3.0
        /// E2, a Return's ` ¶ `, opacity alone. Subtle: 0.120 s.
        public static let paragraphFade = 0.200
        /// E1, the band of light across the box at a hand-off, at an even pace; the close's fade waits so that both
        /// end together. Subtle: peak 0.14 over 0.300 s.
        public static let handOffSheen = 0.350, handOffPeak = 0.35
        /// K3, the same band along the border alone, on Space. Subtle: peak 0.35 (the duration as it was).
        public static let wordSheen = 0.300, wordPeak = 0.7
        /// B2: the border `warm` (the accent at full) while keys come, back in `warmIn` at the first key after a
        /// pause; `coolAfter` after the last key it cools evenly (not on the curve) to `cooled` over `coolOver`.
        /// Subtle: the same, but cooling over 1.5 s.
        public static let warmIn = 0.150, coolAfter = 0.5, coolOver = 1.0
        public static let warm = Style.accent, cooled = Style.line
    }
}
