// The themes (DESIGN.md TH1, DC1's tests): Lemna is today's look exactly, every theme names a pack and a mode that exist
// and reaches its contrast in each appearance, the appearance picks the palette, the font resolves (and Rain's atlas
// stays monospaced), the preset leaves the sound's on or off alone, and Still opens and hands off by fades. Rain on
// Still's day dim is in AmbienceTests. No Foundation here (see RenderTests.swift).
import CoreGraphics
import CoreText
import Darwin
import Testing
@testable import LemnaCore

@Test func lemnaIsTodaysLook() throws {
    let t = Theme.lemna, p = t.night
    #expect(Theme.all.first == t && Theme(kept: nil) == t && Theme(kept: "gone") == t && Theme(kept: "still") == .still)
    #expect(t.id == "lemna" && t.title == "Lemna" && t.appearance == .dark && t.day == t.night)
    // The literals pass 21 moved here, as they stood before it: Style's colours and Style.accent (Line.swift), the
    // hairline B1 replaced (F1's T2), Effects.Tuning.dim, Ambience.Tuning.text and .accent, main.swift's Menlo 28,
    // Face.borderWidth and .cornerRadius, the panel's shadow, P1's pop and H1's stream; the first launch's pack and
    // ambience.
    #expect([p.surface, p.text, p.muted, p.mutedContrast, p.accent, p.line, p.dim]
        == [0x0e1013, 0xd8dce3, 0x5c646f, 0x8d95a0, 0x7aa7f0, 0x262b32, 0x0e1013])
    #expect(p.dimAlpha == 0.5 && p.ink == Theme.Ink(text: 0xd8dce3, accent: 0x7aa7f0, blend: .add, alpha: 1))
    #expect(t.type == Theme.Typeface(face: Theme.Face(name: "Menlo", size: 28), bundled: false, fallback: nil))
    #expect(t.box == Theme.Shape(border: .accent, borderWidth: 1, corner: 10, shadow: true))
    #expect(t.motion == Theme.Motion(open: .pop, handOff: .stream))
    #expect(t.defaults == Theme.Defaults(pack: SoundChoice.packs[0].folder, bed: nil, ambience: Ambience().mode))
    #expect(t.defaults.pack == "DefaultPack" && t.defaults.ambience == nil)
    // Resolved as the app shows it, whatever the system's appearance: today's font and T2's colours, the border the
    // accent. The renders, drawn with `menlo`, are the same as before the theme layer.
    let font = try #require(t.type.font)
    #expect(CTFontCopyPostScriptName(font) as String == "Menlo-Regular" && CTFontGetSize(font) == 28 && CFEqual(font, menlo))
    for system in [false, true] {
        let s = Style(t, dark: t.dark(system: system), font: font)
        #expect(s.background == rgb(0x0e1013) && s.text == rgb(0xd8dce3) && s.muted == rgb(0x5c646f))
        #expect(s.caret == rgb(0x7aa7f0) && s.border == rgb(0x7aa7f0) && s.palette == p)
    }
}

@Test func everyThemeNamesAPackAndAModeThatExist() {
    #expect(Set(Theme.all.map(\.id)).count == Theme.all.count && Set(Theme.all.map(\.title)).count == Theme.all.count)
    let packs = String(renders.dropLast("/app/renders".count)) + "/lib/LemnaClicks/Sources/LemnaClicks/"
    for t in Theme.all {
        let pack = t.defaults.pack
        #expect(SoundChoice.packs.contains { $0.folder == pack }, "\(t.id)")  // in Sound ▸
        #expect(access(packs + pack + "/pack.json", F_OK) == 0, "\(t.id)")  // and in the repository
        #expect(t.defaults.bed == nil, "\(t.id)")  // no beds before pass 23
        let mode = t.defaults.ambience
        #expect(Ambience(kept: Ambience(mode).kept).mode == mode, "\(t.id)")  // a mode Ambience ▸ has, or Off
        #expect(Theme(kept: t.id) == t)
    }
}

@Test func everyThemeReachesItsContrastInEachAppearance() {
    for t in Theme.all {
        for p in [t.day, t.night] {
            let surface = rgb(p.surface)
            #expect(ratio(rgb(p.text), surface) >= 4.5, "\(t.id)")  // readability, WCAG 1.4.3 (AA)
            #expect(ratio(rgb(p.accent), surface) >= 3, "\(t.id)")  // the caret, WCAG 1.4.11 (non-text)
            #expect(ratio(p.muted(increasedContrast: true), surface) >= 4.5, "\(t.id)")  // the HIG's, under Increase Contrast
        }
    }
    // Still's as LK1 has them: text 8.7 and 12.4:1, the caret 4.6 and 8.0:1, the muted 3.4 and 4.7:1 (under Increase
    // Contrast 4.9 and 6.4:1), the hairline 1.30 and 1.33:1.
    func near(_ a: UInt32, _ p: Theme.Palette, _ r: Double) -> Bool { abs(ratio(rgb(a), rgb(p.surface)) - r) < 0.06 }
    let (d, n) = (Theme.still.day, Theme.still.night)
    #expect(near(d.text, d, 8.7) && near(d.accent, d, 4.6) && near(d.muted, d, 3.4) && near(d.mutedContrast, d, 4.9))
    #expect(near(n.text, n, 12.4) && near(n.accent, n, 8.0) && near(n.muted, n, 4.7) && near(n.mutedContrast, n, 6.4))
    #expect(near(d.line, d, 1.30) && near(n.line, n, 1.33))
}

@Test func theAppearancePicksStillsDayOrNight() {
    #expect(!Theme.still.dark(system: false) && Theme.still.dark(system: true))  // LK1: as the system's
    #expect(Theme.lemna.dark(system: false) && Theme.lemna.dark(system: true))  // dark always
    let day = Style(.still, dark: false, font: menlo), night = Style(.still, dark: true, font: menlo)
    #expect(day.palette == Theme.still.day && night.palette == Theme.still.night)
    #expect(day.background == rgb(0xf3f0e8) && day.text == rgb(0x46433d) && day.caret == rgb(0x577446))
    #expect(night.background == rgb(0x1c1b18) && night.text == rgb(0xe2daca) && night.caret == rgb(0xa2b88e))
    #expect(day.border == rgb(0xd9d4c8) && night.border == rgb(0x34312c))  // the hairline, not the accent
    #expect(Style(.still, dark: false, increasedContrast: true, font: menlo).muted == rgb(0x6b675f))
    // The ink: laid over on the light wash, added on the dark one (architecture §7).
    #expect(day.palette.ink.blend == .over && night.palette.ink.blend == .add)
    #expect(Theme.lemna.night.ink.blend == .add)
}

@Test func eachThemesFontResolvesAndRainsAtlasStaysMonospaced() throws {
    let font = try #require(Theme.still.type.font)  // Literata once bundled; until then Charter, installed with macOS
    if CTFontCopyFamilyName(font) as String == "Literata" {
        #expect(CTFontGetSize(font) == 30)
    } else {
        #expect(CTFontCopyFamilyName(font) as String == "Charter" && CTFontGetSize(font) == 31)
    }
    // A face the Mac lacks is not taken for the one Core Text gives instead (Helvetica).
    let missing = Theme.Face(name: "No Such Face", size: 30)
    #expect(Theme.Typeface(face: missing, bundled: false, fallback: nil).font == nil)
    // Rain's grid in a monospaced face: Menlo at the line's size under a proportional line, the line's own else.
    let atlas = Ambience.Glyphs.atlasFont(for: font)
    #expect(CTFontCopyFamilyName(atlas) as String == "Menlo" && CTFontGetSize(atlas) == CTFontGetSize(font))
    #expect(CFEqual(Ambience.Glyphs.atlasFont(for: menlo), menlo))
}

@Test func thePresetSetsThePackAndLeavesTheSoundOnOrOff() {
    var off = SoundChoice(pack: nil, on: false)  // ⌘K'd off
    off.preset(Theme.still.defaults.pack)
    #expect(off == SoundChoice(pack: "SoftPack", on: false))  // off still (choosing the pack would turn it on)
    var on = SoundChoice(pack: "SoftPack", on: true)
    on.preset(Theme.lemna.defaults.pack)
    #expect(on == SoundChoice(pack: "DefaultPack", on: true))
    on.preset("NoSuchPack")
    #expect(on == SoundChoice(pack: "DefaultPack", on: true))
}

@Test func stillOpensAndHandsOffByFades() {
    #expect(Theme.still.motion == Theme.Motion(open: .fade, handOff: .fade))
    // Its hand-off plays as P1's close on Hand-off's tick, and goes at once where Lemna's would.
    #expect(Handoff.leaving(Effects(), reduceMotion: false, handOff: .fade) == .fade(Effects.Tuning.close))
    #expect(Handoff.leaving(Effects(), reduceMotion: true, handOff: .fade) == .atOnce)
    var off = Effects()
    off.toggle()
    #expect(Handoff.leaving(off, reduceMotion: false, handOff: .fade) == .atOnce)
    // The stream drops the box's shadow at its first frame, which only a dark dim hides (architecture §7): a theme
    // that may show a light dim fades its box instead, or has no shadow.
    for t in Theme.all {
        #expect(t.motion.handOff == .fade || !t.box.shadow || t.appearance == .dark, "\(t.id)")
    }
}
