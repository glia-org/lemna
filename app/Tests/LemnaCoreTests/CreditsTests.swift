// The About panel's credits (pass 44): app/Credits.html, written for the app's user, against the maintainers' record
// (app/THIRD_PARTY.md, lib/LemnaClicks/THIRD_PARTY.md, the packs' pack.json and the beds' bed.json), so the two cannot
// drift apart; and, with Xcode's toolchain, the credits drawn as the panel draws them, in light and dark, to
// app/renders/.
import Darwin
import Testing
@testable import LemnaCore
#if canImport(_Testing_Foundation)  // the Command Line Tools ship that overlay without its module (RenderTests)
import AppKit
#endif

/// The repository's root, from app/renders.
private let repo = String(renders.dropLast("/app/renders".count))
private let creditsFile = repo + "/app/Credits.html"

/// A file's text; nil when it cannot be read.
private func read(_ path: String) -> String? {
    guard let f = fopen(path, "r") else { return nil }
    defer { fclose(f) }
    var bytes: [UInt8] = [], chunk = [UInt8](repeating: 0, count: 1 << 16)
    while true {
        let n = fread(&chunk, 1, chunk.count, f)
        if n == 0 { break }
        bytes += chunk[..<n]
    }
    return String(decoding: bytes, as: UTF8.self)
}

/// Runs of white space as one space, the ends trimmed: how HTML shows text, and how a quote wrapped in Markdown reads.
private func collapsed(_ s: some StringProtocol) -> String {
    s.split(whereSeparator: \.isWhitespace).joined(separator: " ")
}

/// The text a reader of the credits sees: the body without its tags.
private func shown(_ html: String) -> String {
    let body = html.split(separator: "<body>").last?.split(separator: "</body>").first ?? ""
    var text = "", inTag = false
    for c in body {
        if c == "<" { inTag = true } else if c == ">" { inTag = false } else if !inTag { text.append(c) }
    }
    return collapsed(text)
}

/// The http(s) URLs in a text, without the punctuation that ends a sentence or a cell.
private func urls(in s: String) -> [String] {
    s.split(whereSeparator: { " \n()`|\"<>".contains($0) }).compactMap { word in
        guard word.hasPrefix("http") else { return nil }
        return String(word.reversed().drop { ".,;".contains($0) }.reversed())
    }
}

/// The CC BY credit lines of lib/LemnaClicks/THIRD_PARTY.md: its quoted paragraphs that say "licensed under CC BY".
private func ccByLines(_ md: String) -> [String] {
    var lines: [String] = [], quote: [Substring] = []
    for line in md.split(separator: "\n", omittingEmptySubsequences: false) + [Substring("")] {
        let t = line.drop { $0 == " " }
        if t.hasPrefix(">") { quote.append(t.dropFirst()); continue }
        let paragraph = collapsed(quote.joined(separator: " "))
        if paragraph.contains("licensed under CC BY") { lines.append(paragraph) }
        quote = []
    }
    return lines
}

/// A pack.json's or bed.json's `attribution`, nil when it has none (the CC0 ones).
private func attribution(_ json: String) -> String? {
    guard let start = json.firstRange(of: "\"attribution\": \"") else { return nil }
    return json[start.upperBound...].split(separator: "\"", maxSplits: 1).first.map(String.init)
}

/// Every CC BY line (Electric, Lab) appears in the credits word for word, as THIRD_PARTY.md and its pack's or bed's
/// json have it, each of its URLs a link; every source the THIRD_PARTY files list (a page on Freesound or GitHub; not
/// the licences' pages, nor where a preview was downloaded from) is linked; each pack and background sound is there
/// under its menu name; and Literata's copyright line from its OFL.txt.
@Test func theCreditsCarryEveryCCBYLineAndLinkEverySource() throws {
    let html = try #require(read(creditsFile)), text = shown(html)
    let clicks = try #require(read(repo + "/lib/LemnaClicks/THIRD_PARTY.md"))
    let font = try #require(read(repo + "/app/THIRD_PARTY.md"))

    let lines = ccByLines(clicks)
    let sources = repo + "/lib/LemnaClicks/Sources/LemnaClicks/"
    let jsons = try SoundChoice.packs.map { try #require(read(sources + $0.folder + "/pack.json"), "\($0.folder)") }
        + BedChoice.beds.map { try #require(read(sources + "Beds/" + $0.folder + "/bed.json"), "\($0.folder)") }
    #expect(lines.count == 2 && Set(lines) == Set(jsons.compactMap(attribution)))  // the record and the json agree
    for line in lines {
        #expect(text.contains(line), "\(line.prefix(40))")
        for url in urls(in: line) { #expect(html.contains("href=\"\(url)\""), "\(url)") }
    }

    let listed = Set(urls(in: clicks + font).filter {
        $0.hasPrefix("https://freesound.org/") || $0.hasPrefix("https://github.com/")
    })
    #expect(listed.count >= 34)  // pass 44's 34: the recordings' and packs' pages, VCSL's folders, Literata's repo
    for url in listed.sorted() { #expect(html.contains("href=\"\(url)\""), "\(url)") }

    for title in SoundChoice.packs.map(\.title) + BedChoice.beds.map(\.title) {
        #expect(html.contains("<b>\(title)</b>"), "\(title)")
    }
    let ofl = try #require(read(repo + "/app/Fonts/Literata/OFL.txt"))
    #expect(text.contains(collapsed(try #require(ofl.split(separator: "\n").first))))
}

#if canImport(_Testing_Foundation)
/// The credits as AppKit reads Credits.html and the About panel shows them (an NSTextView mapping its colours for Dark
/// Mode, NSApplication.h's note on the credits option), 280 pt wide, at 2×: app/renders/credits-light.png and
/// credits-dark.png, for a look by eye. The reader's text keeps the CC BY lines, its curly quotes included (the file's
/// charset is read), and every link is a URL.
@MainActor @Test func theCreditsRenderInLightAndDark() throws {
    let credits = try NSAttributedString(url: URL(fileURLWithPath: creditsFile), options: [:], documentAttributes: nil)
    let html = try #require(read(creditsFile)), clicks = try #require(read(repo + "/lib/LemnaClicks/THIRD_PARTY.md"))
    for line in ccByLines(clicks) { #expect(collapsed(credits.string).contains(line), "\(line.prefix(40))") }
    var links = 0
    credits.enumerateAttribute(.link, in: NSRange(location: 0, length: credits.length)) { value, _, _ in
        guard let value else { return }
        links += 1
        #expect(value is URL, "\(value)")
    }
    #expect(links == html.split(separator: "href=\"").count - 1)  // every anchor

    for (name, look) in [("light", NSAppearance.Name.aqua), ("dark", .darkAqua)] {
        let view = NSTextView(frame: NSRect(x: 0, y: 0, width: 280, height: 0))
        view.appearance = NSAppearance(named: look)
        view.usesAdaptiveColorMappingForDarkAppearance = true
        view.isEditable = false
        view.backgroundColor = .windowBackgroundColor
        view.textStorage?.setAttributedString(credits)
        view.isVerticallyResizable = true
        view.maxSize = NSSize(width: 280, height: CGFloat.greatestFiniteMagnitude)
        view.textContainer?.containerSize = NSSize(width: 280, height: CGFloat.greatestFiniteMagnitude)
        view.sizeToFit()
        let rep = try #require(view.bitmapImageRepForCachingDisplay(in: view.bounds))
        view.cacheDisplay(in: view.bounds, to: rep)
        mkdir(renders, 0o755)  // fails harmlessly once it exists
        try #require(rep.representation(using: .png, properties: [:]))
            .write(to: URL(fileURLWithPath: renders + "/credits-\(name).png"))
    }
}
#endif
