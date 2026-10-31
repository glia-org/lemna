// The Sound submenu (K1): the packs, the default, a choice, and ⌘K; since pass 23 the bed (BD1): kept, chosen, and when
// it plays.
import Testing
@testable import LemnaCore

@Test func soundStartsOnTheKeychronUnlessAPackWasKept() {
    #expect(SoundChoice.packs.map(\.title) == ["Keychron", "Typewriter", "Soft", "Electric", "Stone"])
    #expect(SoundChoice.packs.map(\.folder) == ["DefaultPack", "TypewriterPack", "SoftPack", "ElectricPack", "StonePack"])
    let first = SoundChoice(pack: nil, on: true)  // a first launch, or a build before the submenu
    #expect(first.pack == "DefaultPack" && first.index == 0 && first.on)
    let kept = SoundChoice(pack: "SoftPack", on: false)
    #expect(kept.pack == "SoftPack" && kept.index == 2 && !kept.on)
    #expect(SoundChoice(pack: "GonePack", on: true).pack == "DefaultPack")  // a pack since removed
}

@Test func choosingAPackTurnsTheSoundOnAndCommandKBringsItBack() {
    var s = SoundChoice(pack: nil, on: true)
    s.choose("TypewriterPack")
    #expect(s == SoundChoice(pack: "TypewriterPack", on: true))
    s.toggle()  // ⌘K, or Off
    #expect(s == SoundChoice(pack: "TypewriterPack", on: false))
    s.toggle()  // ⌘K again: the last pack, not the default
    #expect(s == SoundChoice(pack: "TypewriterPack", on: true))
    s.toggle()
    s.choose("ElectricPack")  // a pack while off: on, with that pack
    #expect(s == SoundChoice(pack: "ElectricPack", on: true) && s.index == 3)
    s.choose("NoSuchPack")
    #expect(s == SoundChoice(pack: "ElectricPack", on: true))
}

@Test func theBedIsNoneUnlessOneWasKept() {
    #expect(BedChoice.beds.map(\.title) == ["Rain bed"] && BedChoice.beds.map(\.folder) == ["Rain"])
    let first = BedChoice(kept: nil)  // a first launch, or a build before the beds
    #expect(first.folder == nil && first.index == nil)
    let kept = BedChoice(kept: "Rain")
    #expect(kept.folder == "Rain" && kept.index == 0)
    #expect(BedChoice(kept: "Pond").folder == nil)  // a bed since removed, or never shipped
    var b = kept
    b.choose(nil)  // No bed
    #expect(b == BedChoice(kept: nil))
    b.choose("Rain")
    #expect(b == kept)
    b.choose("NoSuchBed")
    #expect(b == kept)
}

@Test func theBedPlaysOnlyWhileWritingInAContainerOnScreenWithTheSoundOn() {
    let rain = BedChoice(kept: "Rain"), none = BedChoice(kept: nil)
    #expect(rain.plays(onScreen: true, writing: true, sound: true))  // the summon, the box or the window
    #expect(!none.plays(onScreen: true, writing: true, sound: true))  // No bed
    #expect(!rain.plays(onScreen: false, writing: true, sound: true))  // Esc, a click outside, the hotkey, a paste
    #expect(!rain.plays(onScreen: true, writing: false, sound: true))  // a hand-off's key-down: ⌘⏎, Copy, Save…
    #expect(!rain.plays(onScreen: true, writing: true, sound: false))  // ⌘K
    #expect(!rain.plays(onScreen: false, writing: false, sound: false))
}
