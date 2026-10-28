// The Sound submenu (K1): the packs, the default, a choice, and ⌘K.
import Testing
@testable import LemnaCore

@Test func soundStartsOnTheKeychronUnlessAPackWasKept() {
    #expect(SoundChoice.packs.map(\.title) == ["Keychron", "Typewriter", "Soft", "Electric"])
    #expect(SoundChoice.packs.map(\.folder) == ["DefaultPack", "TypewriterPack", "SoftPack", "ElectricPack"])
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
