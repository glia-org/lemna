// The themes (DESIGN.md TH1; TH1 DC1 LK1 TY1 MO1 of docs/design-panel-lemna-themes.html, the user's picks of
// 2026-10-31): one look per theme as a Swift literal (DC1), beside `Effects.Tuning` and `SoundChoice.packs`, and what
// choosing one writes into the other menus' keys (TH1, the preset). `Style` is a theme as it shows now: its palette for
// the system's appearance (LK1) and Increase Contrast, and the line's font. Free of AppKit, so the tests check every
// theme.
import CoreGraphics
import CoreText

/// Session › Theme ▸: the look of the box, the line, the dim and the ambience's ink, and a preset for Sound ▸ and
/// Ambience ▸, whose menus go on overriding it until the next theme is chosen. The first of `all` is the default.
public struct Theme: Equatable {
    /// Which palette shows: the system's appearance picks day or night (LK1), or one shows always.
    public enum Appearance: Equatable { case followsSystem, dark, light }

    /// One appearance's colours, as 0xRRGGBB: the box's surface; the text; the muted grey (the ` ¶ `, the bottom edge)
    /// and its variant under Increase Contrast; the accent (the caret, and the border where that is the accent); the
    /// line (the tonal hairline); the dim over every screen, its colour and opacity (D1); and the ambience's ink.
    public struct Palette: Equatable {
        public var surface, text, muted, mutedContrast, accent, line, dim: UInt32
        public var dimAlpha: Float
        public var ink: Ink

        /// The muted grey, or its variant under Increase Contrast.
        public func muted(increasedContrast: Bool) -> CGColor { rgb(increasedContrast ? mutedContrast : muted) }
    }

    /// The ambience's colours on the dim (A1's C1): `text` for the glyphs, the rings and the grid's lines (Rain's
    /// heads), `accent` for the lit cells (Rain's trails); `blend`, how the sprites combine in the ambience's layer:
    /// added, light spilling onto a dark dim, or laid over, ink on a light one, where added light shows nothing
    /// (`research_notes/Lemna themes/architecture.md` §7); `alpha` scales every sprite's.
    public struct Ink: Equatable {
        public enum Blend: Equatable { case add, over }
        public var text, accent: UInt32, blend: Blend, alpha: Double
    }

    /// A face by its family (or PostScript) name, at a size in points.
    public struct Face: Equatable {
        public var name: String, size: CGFloat
    }

    /// The line's type: its face; whether the face ships in the app (Contents/Resources/Fonts) rather than with macOS;
    /// the face taken while it is missing.
    public struct Typeface: Equatable {
        public var face: Face, bundled: Bool, fallback: Face?
    }

    /// The box: its edge in the accent (B1) or in the palette's tonal hairline, the edge's width, the corners' radius,
    /// and whether the panel has the system's shadow.
    public struct Shape: Equatable {
        public enum Border: Equatable { case accent, hairline }
        public var border: Border, borderWidth: CGFloat, corner: CGFloat, shadow: Bool
    }

    /// How the box opens (P1: grown from `Effects.Tuning.openScale` with the fade, or the fade alone; the close is a
    /// fade either way) and how a hand-off leaves (H1 and C1: the glyphs streaming off the box, or the box's fade, with
    /// MO1's ring on the water at a paste since pass 24, `Handoff.rings`).
    public struct Motion: Equatable {
        public enum Open: Equatable { case pop, fade }
        public enum HandOff: Equatable { case stream, fade }
        public var open: Open, handOff: HandOff
    }

    /// What choosing the theme writes (TH1, the preset): the sound pack's folder (`SoundChoice.packs`), the sound bed's
    /// (nil: none; the key is unread until the beds come, pass 23) and the ambience's mode (nil: Off). The Effects
    /// ticks and ⌘K's on or off are the user's and stay.
    public struct Defaults: Equatable {
        public var pack: String, bed: String?, ambience: Ambience.Mode?
    }

    public let id: String, title: String, appearance: Appearance
    public let day: Palette, night: Palette
    public let type: Typeface, box: Shape, motion: Motion, defaults: Defaults

    /// Whether the night palette shows, given whether the system's appearance is dark.
    public func dark(system: Bool) -> Bool {
        switch appearance {
        case .followsSystem: system
        case .dark: true
        case .light: false
        }
    }

    /// As kept across launches (`theme`, its `id`); none, or one since removed, is the first.
    public init(kept: String?) { self = Self.all.first { $0.id == kept } ?? Self.all[0] }

    init(id: String, title: String, appearance: Appearance, day: Palette, night: Palette, type: Typeface, box: Shape,
         motion: Motion, defaults: Defaults) {
        (self.id, self.title, self.appearance, self.day, self.night) = (id, title, appearance, day, night)
        (self.type, self.box, self.motion, self.defaults) = (type, box, motion, defaults)
    }
}

extension Theme {
    /// Session › Theme ▸'s themes in its order; the first is the default.
    public static let all: [Theme] = [.lemna, .still]

    /// Today's look, the user's "nerd mode": Lemna's own colours (F1's T2), dark always; Menlo 28; the still 1 pt
    /// accent border (B1) on 10 pt corners with the system's shadow; the dim the box's colour at 0.5 (D1); the pop
    /// (P1) and the glyphs' stream (H1, C1); the ambience in the text and the accent, added (A1's C1). The preset: the
    /// Keychron pack, no bed, Ambience Off, the first launch's.
    public static let lemna: Theme = {
        let p = Palette(surface: 0x0e1013, text: 0xd8dce3, muted: 0x5c646f, mutedContrast: 0x8d95a0, accent: 0x7aa7f0,
                        line: 0x262b32, dim: 0x0e1013, dimAlpha: 0.5,
                        ink: Ink(text: 0xd8dce3, accent: 0x7aa7f0, blend: .add, alpha: 1))
        return Theme(id: "lemna", title: "Lemna", appearance: .dark, day: p, night: p,
                     type: Typeface(face: Face(name: "Menlo", size: 28), bundled: false, fallback: nil),
                     box: Shape(border: .accent, borderWidth: 1, corner: 10, shadow: true),
                     motion: Motion(open: .pop, handOff: .stream),
                     defaults: Defaults(pack: "DefaultPack", bed: nil, ambience: nil))
    }()

    /// Still (LK1 TY1 MO1; the name is the panel's placeholder), the mindful look, following the system's appearance:
    /// by day a warm paper box on a pale sage wash, by night a warm near-black on a deep green-black; no border but a
    /// tonal hairline, 16 pt corners, no shadow (LK1: none until a soft one is decided); Literata 30, Charter 31 while
    /// its file is not in the bundle (TY1); opened and closed by fades, the hand-off the box's fade (MO1); the ink one
    /// colour (LK1's), laid over at 0.6 of the alphas by day, added at 0.5 by night. A stub in pass 21, there to
    /// exercise the light-only paths: its preset names what exists today (the Soft pack, no bed, Rain); passes 23 and
    /// 24 fill in the Stone pack, the light rain bed and Still water, and pass 22 the look's last values.
    public static let still = Theme(
        id: "still", title: "Still", appearance: .followsSystem,
        day: Palette(surface: 0xf3f0e8, text: 0x46433d, muted: 0x86817a, mutedContrast: 0x6b675f, accent: 0x577446,
                     line: 0xd9d4c8, dim: 0xd3d8ce, dimAlpha: 0.74,
                     ink: Ink(text: 0x3f4a3c, accent: 0x3f4a3c, blend: .over, alpha: 0.6)),
        night: Palette(surface: 0x1c1b18, text: 0xe2daca, muted: 0x8c8476, mutedContrast: 0xa69d8e, accent: 0xa2b88e,
                       line: 0x34312c, dim: 0x0f1412, dimAlpha: 0.62,
                       ink: Ink(text: 0xc9d3c4, accent: 0xc9d3c4, blend: .add, alpha: 0.5)),
        type: Typeface(face: Face(name: "Literata", size: 30), bundled: true, fallback: Face(name: "Charter", size: 31)),
        box: Shape(border: .hairline, borderWidth: 1, corner: 16, shadow: false),
        motion: Motion(open: .fade, handOff: .fade),
        defaults: Defaults(pack: "SoftPack", bed: nil, ambience: .water))
}

extension Theme.Typeface {
    /// The line's font: the face, else the fallback (Still's Charter until Literata is bundled); nil when this Mac has
    /// neither (the app then takes the monospaced system font at the face's size). Core Text gives another face for a
    /// name it lacks, so the one it gave is checked.
    public var font: CTFont? {
        for f in [face] + (fallback.map { [$0] } ?? []) {
            let font = CTFontCreateWithName(f.name as CFString, f.size, nil)
            if CTFontCopyFamilyName(font) as String == f.name || CTFontCopyPostScriptName(font) as String == f.name {
                return font
            }
        }
        return nil
    }
}
