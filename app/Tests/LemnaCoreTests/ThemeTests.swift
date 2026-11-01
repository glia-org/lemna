// The themes (DESIGN.md TH1, DC1's tests): Lemna is today's look exactly, every theme names a pack and a mode that exist
// and reaches its contrast in each appearance, the appearance picks the palette, the font resolves (and Code's atlas
// stays monospaced), the preset leaves the sound's on or off alone, and Still opens and hands off by fades; since pass
// 22 Still's bundled face, its caret's rounded ends, the line clearing the bottom edge's note and the shaped tail in
// every theme's face, and Still in the window (editing-still-day.png, editing-still-night.png). Code on Still's day dim
// and the box at rest by day and night are in AmbienceTests. No Foundation here (see RenderTests.swift).
import CoreGraphics
import CoreText
import Darwin
import Testing
@testable import LemnaCore

/// The repository's bundled fonts (app/Fonts, which make-app.sh copies into Contents/Resources/Fonts), registered for
/// the tests' process once, before Still's font is first resolved (`stillFont`), so every test and render takes
/// Literata whatever order they run in; the files that did not register.
let unregistered = Theme.Typeface.register(fontsIn: String(renders.dropLast("/renders".count)) + "/Fonts")

/// Still's line font as the app resolves it, its bundled face registered.
var stillFont: CTFont? {
    _ = unregistered
    return Theme.still.type.font
}

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
    // Pass 22's fields keep today's: circular corners, a square caret, the accent under Increase Contrast too, the
    // glyphs smoothed.
    #expect(!t.box.continuous && t.box.caretEnds == 0 && p.accentContrast == nil && t.type.smoothed)
    #expect(Style(t, increasedContrast: true, font: font).caret == rgb(0x7aa7f0))
}

@Test func everyThemeNamesAPackAndAModeThatExist() {
    #expect(Set(Theme.all.map(\.id)).count == Theme.all.count && Set(Theme.all.map(\.title)).count == Theme.all.count)
    let packs = String(renders.dropLast("/app/renders".count)) + "/lib/LemnaClicks/Sources/LemnaClicks/"
    for t in Theme.all {
        let pack = t.defaults.pack
        #expect(SoundChoice.packs.contains { $0.folder == pack }, "\(t.id)")  // in Sound ▸
        #expect(access(packs + pack + "/pack.json", F_OK) == 0, "\(t.id)")  // and in the repository
        if let bed = t.defaults.bed {  // none, or a bed Sound ▸ has and the repository holds
            #expect(BedChoice(kept: bed).folder == bed, "\(t.id)")
            #expect(access(packs + "Beds/" + bed + "/bed.json", F_OK) == 0, "\(t.id)")
        }
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
            #expect(ratio(p.accent(increasedContrast: true), surface) >= 4.5, "\(t.id)")  // the caret, look §2.6
        }
    }
    // Still's as LK1 has them: text 8.7 and 12.4:1, the caret 4.6 and 8.0:1, the muted 3.4 and 4.7:1 (under Increase
    // Contrast 4.9 and 6.4:1), the hairline 1.30 and 1.33:1.
    func near(_ a: UInt32, _ p: Theme.Palette, _ r: Double) -> Bool { abs(ratio(rgb(a), rgb(p.surface)) - r) < 0.06 }
    let (d, n) = (Theme.still.day, Theme.still.night)
    #expect(near(d.text, d, 8.7) && near(d.accent, d, 4.6) && near(d.muted, d, 3.4) && near(d.mutedContrast, d, 4.9))
    #expect(near(n.text, n, 12.4) && near(n.accent, n, 8.0) && near(n.muted, n, 4.7) && near(n.mutedContrast, n, 6.4))
    #expect(near(d.line, d, 1.30) && near(n.line, n, 1.33))
    #expect(d.accentContrast.map { near($0, d, 6.3) } == true && n.accentContrast == nil)  // LK1: the day caret's 6.3:1
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
    // Under Increase Contrast the day caret is the darker green; the night's sage stays; the hairline stays a hairline.
    let dayIC = Style(.still, dark: false, increasedContrast: true, font: menlo)
    let nightIC = Style(.still, dark: true, increasedContrast: true, font: menlo)
    #expect(dayIC.caret == rgb(0x465e38) && nightIC.caret == rgb(0xa2b88e) && dayIC.border == rgb(0xd9d4c8))
    // Look §5's card: 1 pt hairline, 16 pt continuous corners, no shadow, the caret's ends rounded by 1 pt.
    let card = Theme.Shape(border: .hairline, borderWidth: 1, corner: 16, shadow: false, continuous: true, caretEnds: 1)
    #expect(Theme.still.box == card)
    // The ink: laid over on the light wash, added on the dark one (architecture §7).
    #expect(day.palette.ink.blend == .over && night.palette.ink.blend == .add)
    #expect(Theme.lemna.night.ink.blend == .add)
}

@Test func eachThemesFontResolvesAndCodesAtlasStaysMonospaced() throws {
    let font = try #require(stillFont)  // Literata, bundled (TY1)
    #expect(CTFontCopyFamilyName(font) as String == "Literata" && CTFontGetSize(font) == 30)
    // A face the Mac lacks is not taken for the one Core Text gives instead (Helvetica): the fallback is, Still's
    // Charter 31 when Literata is not in the bundle, else nothing.
    let missing = Theme.Face(name: "No Such Face", size: 30)
    #expect(Theme.Typeface(face: missing, bundled: false, fallback: nil).font == nil)
    let charter = try #require(Theme.Typeface(face: missing, bundled: true, fallback: Theme.still.type.fallback).font)
    #expect(CTFontCopyFamilyName(charter) as String == "Charter" && CTFontGetSize(charter) == 31)
    // Code's grid in a monospaced face: Menlo at the line's size under a proportional line, the line's own else.
    let atlas = Ambience.Glyphs.atlasFont(for: font)
    #expect(CTFontCopyFamilyName(atlas) as String == "Menlo" && CTFontGetSize(atlas) == CTFontGetSize(font))
    #expect(CFEqual(Ambience.Glyphs.atlasFont(for: menlo), menlo))
}

@Test func thePresetSetsThePackAndLeavesTheSoundOnOrOff() {
    var off = SoundChoice(pack: nil, on: false)  // ⌘K'd off
    off.preset(Theme.still.defaults.pack)
    #expect(off == SoundChoice(pack: "StonePack", on: false))  // off still (choosing the pack would turn it on)
    var on = SoundChoice(pack: "SoftPack", on: true)
    on.preset(Theme.lemna.defaults.pack)
    #expect(on == SoundChoice(pack: "DefaultPack", on: true))
    on.preset("NoSuchPack")
    #expect(on == SoundChoice(pack: "DefaultPack", on: true))
}

@Test func thePresetSetsTheBedAndTheThemeSaysSo() {
    var bed = BedChoice(kept: nil)
    bed.choose(Theme.still.defaults.bed)
    #expect(bed.folder == "Rain")  // the rain bed; the sound's on or off is SoundChoice's, untouched
    bed.choose(Theme.lemna.defaults.bed)
    #expect(bed.folder == nil)
    // Never a bed unasked (TH1, sound.md §5): a theme whose preset turns one on names it in its item.
    #expect(Theme.lemna.menuTitle == "Lemna" && Theme.still.menuTitle == "Still (rain bed)")
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

/// TY1: the bundled Literata registers from app/Fonts, its licence beside it, and Still's type resolves to it at 30 pt,
/// its regular weight and its optical size the size (Core Text sets a font's opsz axis to the size it is made at).
@Test func theBundledFontRegistersAndResolves() throws {
    let folder = String(renders.dropLast("/renders".count)) + "/Fonts/Literata/"
    #expect(access(folder + "Literata[opsz,wght].ttf", R_OK) == 0 && access(folder + "OFL.txt", R_OK) == 0)
    #expect(unregistered.isEmpty)  // every file in app/Fonts
    let font = try #require(stillFont)
    #expect(Theme.still.type.bundled && Theme.still.type.face == Theme.Face(name: "Literata", size: 30))
    #expect(CTFontCopyPostScriptName(font) as String == "Literata-Regular" && CTFontGetSize(font) == 30)
    let opsz = 0x6f70737a, wght = 0x77676874  // 'opsz', 'wght'
    let variation = try #require(CTFontCopyVariation(font) as? [Int: Double])
    #expect(variation[opsz] == 30 && (variation[wght] ?? 400) == 400)
    // Again, and from a folder that is not there: nothing fails.
    #expect(Theme.Typeface.register(fontsIn: String(folder.dropLast())).isEmpty)
    #expect(Theme.Typeface.register(fontsIn: "/no/such/folder").isEmpty)
}

/// Look §2.6: Still's caret is the 2 pt bar with ends rounded by 1 pt, Lemna's square. Drawn alone on a band at 2× in
/// the same 30 pt face (the bar on whole points), the bar's corner pixel is the caret's colour under Lemna and partly
/// the surface under Still; its middle the caret's colour in both.
@Test func stillsCaretHasRoundedEnds() throws {
    let font = try #require(stillFont), band = CGRect(x: 0, y: 0, width: 200, height: 60)
    func pixel(_ style: Style, _ x: CGFloat, _ y: CGFloat) -> [UInt8] {
        let c = Line.context(width: 400, height: 120, rowBytes: 1600, scale: 2, data: nil)
        Line.draw(Shaped(), before: 0, after: 0, in: c, band: band, style: style)
        let px = c.data!.assumingMemoryBound(to: UInt8.self), i = 4 * ((119 - Int(y * 2)) * 400 + Int(x * 2))
        return Array(UnsafeBufferPointer(start: px + i, count: 4))
    }
    let still = Style(.still, dark: false, font: font), lemna = Style(.lemna, font: font)
    let bar = Line.caretRect(in: band, style: still), mark = Line.caretRect(in: band, style: lemna)
    #expect(bar == mark && bar == CGRect(x: 120, y: 12, width: 2, height: 36))  // on whole points: its pixels its own
    let green: [UInt8] = [0x46, 0x74, 0x57, 0xff], blue: [UInt8] = [0xf0, 0xa7, 0x7a, 0xff]  // BGRA
    #expect(pixel(still, bar.midX, bar.midY) == green && pixel(lemna, mark.midX, mark.midY) == blue)
    #expect(pixel(lemna, mark.minX + 0.25, mark.maxY - 0.25) == blue)  // square
    let corner = pixel(still, bar.minX + 0.25, bar.maxY - 0.25)
    #expect(corner != green && corner[1] > green[1])  // rounded: the paper shows through
    #expect(pixel(still, bar.minX + 0.25, bar.midY) == green)  // the sides straight
}

/// TY1 as the panel showed it: Still's line unsmoothed, with the ink of the mockup's browser (`-webkit-font-smoothing:
/// antialiased`; measured in pass 22: "slowly" in Literata 30 on the day paper, 391,222 units of darkness in the blue
/// channel at 2× in a screenshot of the panel, 392,473 drawn unsmoothed, 458,356 smoothed, Core Graphics' default,
/// 17 % heavier).
@Test func stillsTextHasThePanelsWeight() throws {
    let font = try #require(stillFont), s = Theme.still
    let smoothed = Theme(id: "x", title: "x", appearance: .light, day: s.day, night: s.night,
                         type: Theme.Typeface(face: s.type.face, bundled: true, fallback: nil), box: s.box,
                         motion: s.motion, defaults: s.defaults)
    let band = CGRect(x: 0, y: 0, width: 300, height: 60)
    func ink(_ theme: Theme) -> Int {
        let c = Line.context(width: 600, height: 120, rowBytes: 2400, scale: 2, data: nil)
        let style = Style(theme, dark: false, font: font), left = Int(2 * Line.caretRect(in: band, style: style).minX)
        let line = Line.shape(Text("slowly"), marked: "", font: font)
        Line.draw(line, before: 0, after: 0, in: c, band: band, style: style)
        let px = c.data!.assumingMemoryBound(to: UInt8.self)
        var n = 0
        for y in 0..<120 {
            for x in 0..<left { n += 0xe8 - Int(px[4 * (y * 600 + x)]) }  // the blue channel, left of the caret
        }
        return n
    }
    #expect(!s.type.smoothed)
    let (plain, heavy) = (ink(.still), ink(smoothed))
    print("slowly in Still: \(plain) unsmoothed, \(heavy) smoothed")
    #expect(Double(heavy) > 1.1 * Double(plain))
}

/// Literata joins f and i, f and t, T and h into one glyph; never across the caret, where the text before it is
/// clipped and the text after it starts (`Line.shape`).
@Test func noLigatureSpansTheCaret() throws {
    let font = try #require(stillFont)
    #expect(Line.shape(Text("fi"), marked: "", font: font).glyphs.count == 1)  // the ligature, before the caret
    for word in ["fi", "Th", "ft"] {
        let line = Line.shape(Text(word, caret: 1), marked: "", font: font)
        #expect(line.glyphs.map(\.after) == [false, true], "\(word)")
        #expect(abs(line.caret - Line.width(String(word.prefix(1)), font: font)) < 0.5, "\(word)")  // kerning aside
    }
}

/// The bottom edge's note (`EdgeView`: 12 pt type, its label 15 pt tall from 12 pt up, so its top 27 pt up) stays clear
/// of the line in the box for every theme's face and Still's fallback: the band two em tall in the box's inside (4 em
/// less two borders), the glyphs' ascent and descent centred in it as `Line.draw` puts them; the lowest a glyph reaches
/// is its descent under the baseline. Literata's line is the tallest (1.49 em; Menlo's 1.16, Charter's 1.22).
@Test func theBottomEdgesNoteClearsEveryThemesLine() throws {
    let noteTop: CGFloat = 12 + 15
    let fallback = try #require(Theme.Typeface(face: Theme.Face(name: "No Such Face", size: 30), bundled: true,
                                               fallback: Theme.still.type.fallback).font)
    for (theme, font) in [(Theme.lemna, try #require(Theme.lemna.type.font)), (.still, try #require(stillFont)),
                          (.still, fallback)] {
        let style = Style(theme, font: font), edge = theme.box.borderWidth
        let inside = CGSize(width: 600, height: BoxFrame.height(fontSize: style.size) - 2 * edge)
        let band = Line.band(in: inside, style: style)
        let ascent = CTFontGetAscent(font), descent = CTFontGetDescent(font)
        let lowest = band.midY - (ascent - descent) / 2 - descent
        print("\(CTFontCopyPostScriptName(font)) \(style.size): band from \(band.minY) pt up, lowest glyph \(lowest)")
        #expect(lowest >= band.minY, "\(font)")  // nothing cut at the band's bottom
        #expect(lowest - noteTop >= 6, "\(font)")  // the note well under it
    }
}

/// `Line.tail`: the characters shaped on each side of the caret span the visible 35 % of a window 10,000 pt wide in
/// every theme's face: prose takes about 13 pt a character at Still's 30 pt, Menlo 28's cell 16.9.
@Test func theShapedTailCoversA10000PointWindow() throws {
    let prose = String(repeating: "It was the season of light, it was the spring of hope; the boats sat low in the "
                                  + "water and the reeds bent over them. ", count: 4)
    let tail = String(prose.prefix(Line.tail))
    for font in [try #require(Theme.lemna.type.font), try #require(stillFont),
                 CTFontCreateWithName("Charter" as CFString, 31, nil)] {
        let span = Line.width(tail, font: font)
        print("\(CTFontCopyPostScriptName(font)): \(Line.tail) characters span \(span) pt")
        #expect(span >= 0.35 * 10_000, "\(font)")
    }
}

/// Still in the window (W2), by day and by night: its paper or near-black background behind the line with the caret
/// back in the text (B4), the text after it fading out toward 95 % of the width, as `editing.png` is Lemna's
/// (app/renders/editing-still-day.png, editing-still-night.png).
@Test func stillInTheWindow() throws {
    let font = try #require(stillFont), text = Text("The line glides left and the old words fade.\nNext one", caret: 15)
    for (dark, name) in [(false, "editing-still-day.png"), (true, "editing-still-night.png")] {
        let style = Style(.still, dark: dark, font: font)
        let frame = render(text, offset: 0, style: style, name: name)
        let surface: [UInt8] = dark ? [0x18, 0x1b, 0x1c, 0xff] : [0xe8, 0xf0, 0xf3, 0xff]  // BGRA
        #expect(Array(frame[0..<4]) == surface)
        let ink = inkedColumns(frame)
        #expect(ink.upperBound < 2 * 1140 && ink.lowerBound >= 2 * 300 - 40)  // inside the fades: 25 % to 95 %
    }
}
