// The Effects submenu (DESIGN.md F1 S1): which effects play, Off, and Reduce Motion. Free of AppKit, so the tests check
// it.

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
