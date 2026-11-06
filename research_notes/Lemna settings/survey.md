# Lemna settings: a settings window and changeable chords

Survey for `docs/design-panel-lemna-settings.html`, 2026-11-06. Lemna's code as of main 2f237e3; the apps and
libraries as their docs, source and issues stood on that day; three throwaway probes run on a Mac with macOS 26.5
(§6, §7). Nothing was built into Lemna. Sources are linked where they are used.

## 0. Takeaways

1. **Only the summon chord needs a control a menu cannot hold**, and it is the only global one. ⌃⌥Space collides with
   macOS's "Select next source in Input menu" (Apple lists it for Macs with more than one input source), Things'
   Quick Entry with Autofill and OmniFocus's quick entry (§8, DESIGN Open 7). Open 7 said to reconsider before a build
   goes to others; the README now offers a release download.
2. **Registration reports nothing.** `RegisterEventHotKey` returned 0 for every chord tried on 26.5, Spotlight's ⌘Space
   and a chord another app held included; Carbon hot keys are shared. A chord macOS holds registers and never fires
   (reports on 26 and 27, §5). Checking means reading the system's list (`CopySymbolicHotKeys`, public) and the app's
   own menu, as every library does; no public API tells whether another app holds a chord.
3. **A recorder never sees a held chord**: the other app opens, the input source switches. The app's own summon
   chord would fire in its own field, so recorders pause it (KeyboardShortcuts, Rectangle, Ice).
4. **The in-box chords are already changeable**: macOS's App Shortcuts rebind Lemna's hidden menu items, probed (§7).
5. **Every comparable utility has a settings window**, none keeps all its settings in a menu, and they use tabs or a
   sidebar (§2). Rectangle, the closest to Lemna, keeps a long menu of actions and puts the chord fields in the window.
6. **Windows of accessory apps fail at activation**: cooperative activation on 14, SwiftUI's Settings scene in
   menu-bar apps, focus bugs on 26 (Ice, CleanShot), ⌘W without a Close item (Hidden Bar). AppKit with Lemna's own
   `activateLemna()` and `handBack()` avoids the SwiftUI part (§3).
7. **A library brings a resource bundle that a script-built app crashes on**: SwiftPM's `Bundle.module` looks at the
   .app's root, not `Contents/Resources`; KeyboardShortcuts needs it even to draw "Space" (§4).
8. **⌥ chords are fragile**: macOS 15.0–15.1 refused ⌥ and ⌥⇧ alone (fixed in 15.2), and Secure Input silences
   single-key, ⌥ and ⌥⇧ chords; no Globe, no media keys, no modifier-only chords with Carbon (§5).
9. **↵ or ⌘↵ to send** is a known preference in chat tools; capture tools that write longer text keep ⌘↩ fixed, and in
   Lemna ↵ is a paragraph end (B4), so it is not a rebinding (§9).

## 1. Lemna today (main at 2f237e3)

- **The summon chord** is `Hotkey` in `app/Sources/Lemna/Summon.swift`: `kVK_Space` with `controlKey | optionKey`,
  registered once at launch with Carbon's `RegisterEventHotKey` (no options, so not exclusive), signature `'Lmna'`,
  on the application event target. No Accessibility or Input Monitoring grant is needed. If registration fails,
  `main.swift` writes one line to the system log; nothing on screen says so. The same chord is written a second time
  as the key equivalent of Show Lemna in the menu-bar item's menu (`Hotkey.equivalent`, `Hotkey.modifiers`).
- **The in-box chords** are key equivalents of the hidden main menu (`mainMenu()` in `main.swift`): Done ⌘⏎, Copy
  ⌘⇧⏎, Save… ⌘S (Session); Sound › Off ⌘K; Undo ⌘Z, Redo ⌘⇧Z, Cut ⌘X, Copy ⌘C, Paste ⌘V, Select All ⌘A (Edit);
  Open Window ⌃⌘F (View); Quit ⌘Q. The box is a non-activating panel, so `BoxPanel.sendEvent` hands every keyDown
  with ⌘ to `NSApp.mainMenu.performKeyEquivalent` itself. Esc (`cancelOperation:`), ⇧⏎ (`insertNewline:` with ⇧) and
  the caret moves come through AppKit's key bindings in `LineView`, not through menus.
- **Every other setting is a menu** in two copies of the same builders (`themeMenu`, `soundMenu`, `effectsMenu`,
  `ambienceMenu`): Session › Theme ▸ / Sound ▸ / Effects ▸ / Ambience ▸ in the hidden main menu and the same four in
  the menu-bar item's menu, which also holds Show Lemna, Open Window, Done, Copy, Save…, Discard…, Start at Login and
  Quit: 15 items and four submenus of 2 + 12 + 6 + 3 items. UserDefaults keys: `sound`, `soundPack`, `bed`, `effects`
  (a dictionary), `ambience`, `theme` (registered defaults since pass 32: sound on, Lab bed, Code, Still) and
  `SaveFolder`, which the save panel writes after each save (so a save folder needs no setting). Start at Login keeps
  nothing: its tick is `SMAppService.mainApp.status`.
- **Activation:** Lemna is an accessory app (LSUIElement). The box never activates it. The window (Open Window) and a
  sheet on the box do, through `activateLemna()`: `NSApp.activate()`, then `activate(ignoringOtherApps: true)` if
  Lemna is still not active 0.2 s later (macOS 14's cooperative activation does not promise the first). When a
  container goes, `handBack()` hides Lemna (`NSApp.hide`) if it is active, which brings back the app that was in front
  before. A Settings window would take the same two paths.
- **Credits:** About Lemna exists only in the hidden main menu (the standard panel, "no credits yet"), so it cannot be
  reached in an accessory app without a menu bar. The CC BY 4.0 credits (Electric pack, Lab bed) are in
  `THIRD_PARTY.md`, the packs' JSON and the site's footer, not in the app.
- **Open 7** in DESIGN.md: the user keeps ⌃⌥Space and will reconsider only before a build goes to others. The
  README now offers `Lemna-<version>.zip` from the releases, and v0.1.0 is tagged.

## 2. How comparable apps do it

| App | Settings live in | Layout | Summon default | Recorder | Library |
|---|---|---|---|---|---|
| Raycast | window (⌘,); the menu-bar icon optional | tabs (11) | ⌥Space | popover field; ✕ or ⌫ clears; a clash turns it red and names the owner, saving takes the chord from it; physical key or character; double-tap and one-sided modifiers; Globe once macOS's Globe key does nothing; F13–F18 alone | own |
| Alfred | a separate Preferences app | sidebar | ⌥Space | field; conflicting workflow hotkeys allowed, shown orange; double-tap a modifier | own |
| Rectangle | menu lists every action with its chord, plus Settings… | toolbar tabs (4) | none for summoning; ⌃⌥+arrows ("Recommended") or ⌘⌥+arrows offered at first launch | MASShortcut: F1–F20 alone, else a modifier, ⌥ alone only with Space or Esc; checks the app's menu and the system's chords and refuses with a reason; all its hotkeys unbound while recording | MASShortcut (the maintainer's fork) |
| Maccy | the popup (no menu) with Preferences ⌘, in its footer | toolbar tabs (5) | ⇧⌘C | KeyboardShortcuts; in-popup chords (pin ⌥P, delete ⌥⌫, preview ⌃Space) rebindable too | KeyboardShortcuts, Sauce, Settings |
| Ice | menu: Ice Settings… ⌘, and a few actions | sidebar (6) | none set | own: ⓧ clears, Esc cancels, no modifier or ⇧ alone beeps, a chord in `CopySymbolicHotKeys` → "Hotkey is reserved by macOS"; disables only the edited hotkey while recording | own, Carbon `RegisterEventHotKey` |
| Hidden Bar | right-click menu: Preferences, one toggle, Quit | two tabs | none set | a "Set Shortcut" button and Clear; any keyDown accepted, no check; layout-dependent characters; the old hotkey stays live while recording | soffes/HotKey |
| Shottr | menu lists captures, opens Settings | tabs, one is Hotkeys | ⇧⌘2 for an area (v1.3 notes) | not found; a button opens System Settings to turn off macOS's screenshot chords | not found |
| CleanShot X | menu → Settings… | tabs, one is Shortcuts | not found (primary) | "Use System Default Shortcuts"; changelog: F-keys (3.1), more layouts (4.2.2) and four more layout fixes | not found |
| Things 3 | app Settings › Quick Entry | — | Quick Entry ⌃Space, on; with Autofill ⌃⌥Space, opt-in | click the field, press; save ⌘↩, Esc discards, no option | not found |
| Drafts | app Preferences | — | capture ⇧⌘2 | re-assignable; save ⌘↩, no option | not found |

Sources: Raycast [settings](https://manual.raycast.com/settings.md), [hotkeys](https://manual.raycast.com/command-aliases-and-hotkeys.md), [AI chat](https://manual.raycast.com/ai/ai-chat.md);
Alfred [general](https://www.alfredapp.com/help/general/), [⌘Space](https://www.alfredapp.com/help/troubleshooting/cmd-space/), [hotkey trigger](https://www.alfredapp.com/help/workflows/triggers/hotkey/);
Rectangle [SettingsWindowController.swift](https://github.com/rxhanson/Rectangle/blob/main/Rectangle/SettingsWindow/SettingsWindowController.swift), [WelcomeView.swift](https://github.com/rxhanson/Rectangle/blob/main/Rectangle/WelcomeWindow/WelcomeView.swift), [ShortcutRecordingObserver.swift](https://github.com/rxhanson/Rectangle/blob/main/Rectangle/SettingsWindow/ShortcutRecordingObserver.swift), [MASShortcutValidator.m](https://github.com/rxhanson/MASShortcut/blob/master/Framework/Model/MASShortcutValidator.m);
Maccy [AppState.swift](https://github.com/p0deje/Maccy/blob/master/Maccy/Observables/AppState.swift), [KeyboardShortcuts.Name+Shortcuts.swift](https://github.com/p0deje/Maccy/blob/master/Maccy/Extensions/KeyboardShortcuts.Name+Shortcuts.swift), [Package.resolved](https://github.com/p0deje/Maccy/blob/master/Maccy.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved);
Ice [ControlItem.swift](https://github.com/jordanbaird/Ice/blob/main/Ice/MenuBar/ControlItem/ControlItem.swift), [SettingsWindow.swift](https://github.com/jordanbaird/Ice/blob/main/Ice/Settings/SettingsWindow.swift), [HotkeyRegistry.swift](https://github.com/jordanbaird/Ice/blob/main/Ice/Hotkeys/HotkeyRegistry.swift), [HotkeyRecorderModel.swift](https://github.com/jordanbaird/Ice/blob/main/Ice/UI/HotkeyRecorder/HotkeyRecorderModel.swift);
Hidden Bar [MANUAL.md](https://github.com/dwarvesf/hidden/blob/develop/docs/MANUAL.md), [PreferencesViewController.swift](https://github.com/dwarvesf/hidden/blob/develop/hidden/Features/Preferences/PreferencesViewController.swift), [Package.resolved](https://github.com/dwarvesf/hidden/blob/develop/Hidden%20Bar.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved);
Shottr [start guide](https://shottr.cc/kb/startguide), [site](https://shottr.cc/); CleanShot [changelog](https://cleanshot.com/changelog);
Things [Quick Entry](https://culturedcode.com/things/support/articles/2249437/), [shortcuts](https://culturedcode.com/things/support/articles/2785159/);
Drafts [capture window](https://docs.getdrafts.com/docs/extensions/capture-window).

**Window or menu.** Every app here that has a menu-bar item also has a settings window, and none keeps all its
settings in the menu. What the menu keeps differs: Rectangle lists every action with its chord; Ice and Hidden Bar
keep a few actions and one toggle; Maccy has no menu at all. Rectangle is the closest to Lemna: its menu is long
and does things, and its window holds what a menu cannot (chord fields, snap areas, behaviour with explanations).
**Tabs:** toolbar tabs (Rectangle, Maccy, Raycast, Hidden Bar) or a sidebar (Ice, Alfred) as soon as there is more
than one pane; none of the ones checked uses one long page.

## 3. A settings window in an accessory app

- macOS 14's cooperative activation: `NSApp.activate()` "doesn't guarantee app activation"; `yieldActivation(to:)`
  hands it on; `activate(ignoringOtherApps:)` is marked deprecated
  ([activate()](https://developer.apple.com/documentation/appkit/nsapplication/activate()),
  [yieldActivation(to:)](https://developer.apple.com/documentation/appkit/nsapplication/yieldactivation(to:))).
- What the apps do: Rectangle and Hidden Bar call `activate(ignoringOtherApps: true)` then show the window
  ([Rectangle AppDelegate.swift](https://github.com/rxhanson/Rectangle/blob/main/Rectangle/AppDelegate.swift),
  [Hidden Bar NSWindow+Extension.swift](https://github.com/dwarvesf/hidden/blob/develop/hidden/Extensions/NSWindow+Extension.swift));
  sindresorhus/Settings calls `NSApp.activate()` on 14+
  ([SettingsWindowController.swift](https://github.com/sindresorhus/Settings/blob/main/Sources/Settings/SettingsWindowController.swift)),
  Maccy adds `orderFrontRegardless`. Ice switches to `.regular` (Dock icon, ⌘Tab) after 0.1 s, activates, and on
  its first opening activates the Dock first and waits 0.2 s ("Hack to make sure the app properly activates"); on the
  last window's close it yields activation to the first other running app and goes back to `.accessory`
  ([AppState.swift](https://github.com/jordanbaird/Ice/blob/main/Ice/Main/AppState.swift)). Ice is the only one that
  hands focus back on purpose.
- SwiftUI's `Settings` scene in a menu-bar app: `showSettingsWindow:` stopped working on 14; `SettingsLink` and
  `openSettings` work only inside SwiftUI and not from a menu-style `MenuBarExtra`
  ([orchetect/SettingsAccess](https://github.com/orchetect/SettingsAccess)). One developer reports `openSettings`
  failing on 26 with the window behind other apps, and a workaround of a hidden `Window`, `.regular`, two delays and
  `orderFrontRegardless` ([steipete.me, 2025](https://steipete.me/posts/2025/showing-settings-from-macos-menu-bar-items/),
  not checked independently). AppKit's own `NSWindow` has none of this.
- Recent failures: Ice #931, a dialog takes no input after a reboot on 26.3.1
  ([issue](https://github.com/jordanbaird/Ice/issues/931)); CleanShot fixed a dialog "not receiving focus" on 26 twice
  (4.8.8, 4.8.10, [changelog](https://cleanshot.com/changelog)); Hidden Bar's ⌘W did nothing because its main menu
  had no File › Close ([PR #417](https://github.com/dwarvesf/hidden/pull/417), 2026-09) and ⌘, was asked for
  ([#178](https://github.com/dwarvesf/hidden/issues/178)). Drafts: a capture hotkey un-hides the app's main window,
  since the capture window belongs to the app ([forum](https://forums.getdrafts.com/t/quick-capture-shortcut-activating-main-window/9991)).
- For Lemna: AppKit, not SwiftUI; the window mode's `activateLemna()` (with its 0.2 s fallback) on open and
  `handBack()` on close, which hides Lemna so the app before comes back, as Ice's yield does; a Close item for ⌘W
  and Settings… ⌘, in the hidden menu. Lemna has no main window to un-hide, so Drafts' problem does not arise.

## 4. The recorder and the libraries

What the recorders do (sources in §2 and below): show the chord as glyphs in Apple's order ⌃⌥⇧⌘ and the key's name;
a ⓧ or ✕ and ⌫ clear, Esc cancels; no modifier beeps unless the key is a function key; ⇧ alone is refused; a chord
in the app's main menu or in the system's list is refused or warned about with a reason; the app's hotkeys pause
while recording. Raycast alone lets the user choose physical key or character; Alfred and Raycast add double-tap and
one-sided modifiers through their own event handling.

| | KeyboardShortcuts | HotKey | MASShortcut | ShortcutRecorder |
|---|---|---|---|---|
| Licence | MIT | MIT | BSD-2-Clause | CC BY 4.0 |
| Last release | 3.1.0, 2026-09-11, active | v0.2.1, 2024-12-29, barely maintained | 2.4.0, 2019-06-11; archived; last commit 2022 | 3.4.0, 2022-08-17; maintainer still answers |
| Language, size | Swift 6, 11 files, ≈ 4,700 lines | Swift, 6 files, ≈ 1,140 | Objective-C, ≈ 34 files, ≈ 2,240 | Objective-C, 27 files, ≈ 11,100 |
| SwiftPM | tools 6.2, macOS 10.15+ | tools 5.0 | manifest added after the last tag: pin a revision | yes |
| Resources | 17 `.lproj` via `Bundle.module` | none | 15 `.lproj` | 22 `.lproj`, an asset catalog (150 PNGs), its licence files |
| Recorder | `RecorderCocoa`, an AppKit `NSSearchField` (SwiftUI also offered) | none | yes | yes |
| Checks | main menu, `CopySymbolicHotKeys`; a policy block / warn / allow for each | helpers only, no validation | main menu, `CopySymbolicHotKeys`; ⌥ alone only with Space or Esc | main menu, a delegate, `CopySymbolicHotKeys` |
| Pauses own hotkeys while recording | yes (`isPaused`) | — | not found | yes (default) |
| Glyphs | current ASCII-capable layout, `UCKeyTranslate` | hard-coded US | ASCII-capable layout, `UCKeyTranslate` | current layout, `UCKeyTranslate` |
| Stored as | `KeyboardShortcuts_<name>`: a JSON string `{carbonKeyCode, carbonModifiers}` | `{keyCode, modifiers}`, the app persists | keyed archive, or `{keyCode, modifierFlags}` | keyed archive, or a dictionary with the characters |
| Registration | Carbon, options 0, a failure swallowed | Carbon, options 0, a failure ignored | Carbon, options 0 (exclusive dropped in 2015, [#56](https://github.com/cocoabits/MASShortcut/issues/56)) | Carbon; modifier-only chords through an event tap |

Licences and manifests: [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts/blob/main/license)
([Package.swift](https://github.com/sindresorhus/KeyboardShortcuts/blob/main/Package.swift),
[Shortcut.swift](https://github.com/sindresorhus/KeyboardShortcuts/blob/main/Sources/KeyboardShortcuts/Shortcut.swift),
[RecorderCocoa.swift](https://github.com/sindresorhus/KeyboardShortcuts/blob/main/Sources/KeyboardShortcuts/RecorderCocoa.swift),
[releases](https://github.com/sindresorhus/KeyboardShortcuts/releases)),
[HotKey](https://github.com/soffes/HotKey/blob/main/LICENSE)
([HotKeysController.swift](https://github.com/soffes/HotKey/blob/main/Sources/HotKey/HotKeysController.swift)),
[MASShortcut](https://github.com/shpakovski/MASShortcut/blob/master/LICENSE),
[ShortcutRecorder](https://github.com/Kentzo/ShortcutRecorder/blob/master/LICENSE.txt). Sizes are counts of the clones
at HEAD by the research pass, rounded.

**Layouts.** Storing the key code and showing the current layout's letter (KeyboardShortcuts, MASShortcut,
ShortcutRecorder) is the common answer, and it still confuses: a chord recorded on one layout shows another letter on
another, open as [KeyboardShortcuts #62](https://github.com/sindresorhus/KeyboardShortcuts/issues/62); CleanShot
shipped layout fixes in five releases; Maccy adds Sauce for the mapping; Hidden Bar shows raw characters.

**A script-built app and `Bundle.module`.** SwiftPM's generated accessor looks for `<Package>_<Target>.bundle` at
`Bundle.main.bundleURL` (the .app's root) and then at the absolute build path, else `fatalError`
([SwiftModuleBuildDescription.swift](https://github.com/swiftlang/swift-package-manager/blob/main/Sources/Build/BuildDescription/SwiftModuleBuildDescription.swift)).
So an app assembled by a script works on the Mac that built it and crashes on another. Apple wants resources in
`Contents/Resources` and warns that misplaced content can fail at signing or notarization
([Placing content in a bundle](https://developer.apple.com/documentation/bundleresources/placing-content-in-a-bundle)).
Seen with KeyboardShortcuts on 26.1 ([#231](https://github.com/sindresorhus/KeyboardShortcuts/issues/231); the app's fix
copies the bundle into `Contents/Resources` and patches the package to look there,
[patch](https://github.com/steipete/Trimmy/blob/main/Scripts/patch_keyboard_shortcuts.py)), ShortcutRecorder
([#154](https://github.com/Kentzo/ShortcutRecorder/issues/154)) and others
([CodeEditSymbols #22](https://github.com/CodeEditApp/CodeEditSymbols/issues/22),
[SwiftPM #8510](https://github.com/swiftlang/swift-package-manager/issues/8510)). KeyboardShortcuts loads the bundle
even to name the Space key, so showing "⌃⌥Space" alone needs it. ShortcutRecorder's asset catalog needs `actool`,
which the Command Line Tools do not have. Lemna builds with the Command Line Tools and `make-app.sh`, and has no
package dependency but its own two, by path.

## 5. Carbon hot keys on macOS 14 to 27

- **Supported, not deprecated.** No deprecation macro on `RegisterEventHotKey`, `CopySymbolicHotKeys` or
  `PushSymbolicHotKeyMode` in the Command Line Tools' macOS 26 SDK. Apple DTS (2023): "the one I like the most is
  RegisterEventHotKey. However, it's intimately tied to the legacy Carbon toolbox and thus I can't honestly recommend
  it", preferring a CGEventTap with Input Monitoring ([thread 735223](https://developer.apple.com/forums/thread/735223)).
  Nothing found on a new restriction in 26 or 27.
- **The ⌥ rule of macOS 15.0.** Chords whose only modifiers were ⌥ or ⌥⇧ failed with −9868; an Apple engineer:
  "intentional… to limit the ability of key-logging malware"; reversed in 15.2 beta 2: "now allows hotkeys with only
  Option (or Option-Shift)" ([thread 763878](https://developer.apple.com/forums/thread/763878),
  [answer](https://developer.apple.com/forums/thread/763878?answerId=813718022#813718022)). KeyboardShortcuts treats it
  as affecting sandboxed apps only and dropped its block for 15.2+ (2.2.4). On 26.3 ⌥+letter chords still fail now
  and then ([KeyboardShortcuts #235](https://github.com/sindresorhus/KeyboardShortcuts/issues/235)); Maccy's ⌥+`
  failed on 15.7.1 ([#1246](https://github.com/p0deje/Maccy/issues/1246)). Things: "As of macOS 15.2 (Sequoia),
  Apple is blocking shortcuts which include only ⇧ Shift as a modifier key"; Drafts' recorder stopped taking ⌃⇧Space
  in 2025 ([forum](https://forums.getdrafts.com/t/cant-set-quick-capture-to-ctrl-shift-space/16429)).
- **Secure Input.** While another app has Secure Keyboard Entry on, ⌥ chords stop firing (Rectangle
  [#1592](https://github.com/rxhanson/Rectangle/issues/1592), a password manager); a developer reports single-key, ⌥
  and ⌥⇧ chords lost and others kept ([KeyboardShortcuts #176](https://github.com/sindresorhus/KeyboardShortcuts/issues/176)).
- **Another app with the same chord.** The header says shared registrations all get the event; a third-party probe
  found only the first registrant did, an exclusive one beating an older shared one, and the held chord never
  reaching a recorder ([warble #109](https://github.com/LorcanChinnock/warble/issues/109)). Either way registration
  succeeds. No public API tells whether another app holds a chord ([electron #3808](https://github.com/electron/electron/issues/3808)).
- **A chord macOS holds.** Registers with noErr and never fires: ⌥A held by Show Notification Center on 27.0, working
  at once when that was unticked ([pelmet #55](https://github.com/fif7y/pelmet/issues/55)); ⌃⌥⌘. on 26.7.1, held by
  something in no list ([Mac-Mcp #59](https://github.com/Vansh3503/Mac-Mcp/issues/59)). Alfred and Raycast tell users
  to turn off Spotlight's ⌘Space first ([Alfred](https://www.alfredapp.com/help/troubleshooting/cmd-space/),
  [Raycast](https://manual.raycast.com/v1/hotkey)).
- **Limits.** F-keys alone register (the header allows zero modifiers since 10.3). Globe/Fn: not handled by the
  Carbon API in practice (Rectangle [#1605](https://github.com/rxhanson/Rectangle/issues/1605),
  ShortcutRecorder [#132](https://github.com/Kentzo/ShortcutRecorder/issues/132), HotKey
  [#31](https://github.com/soffes/HotKey/issues/31)); the probe's Fn-bit registration returned 0, untested by a press.
  Media keys are taken by the system ([KeyboardShortcuts #47](https://github.com/sindresorhus/KeyboardShortcuts/issues/47)).
  Modifier-only chords (double-tap ⌘) need a key code Carbon cannot do without: an `NSEvent` global monitor
  (Accessibility) or a CGEventTap (Input Monitoring) ([thread 707680](https://developer.apple.com/forums/thread/707680));
  double-press ⌘ is macOS's own Type to Siri ([Apple 102650](https://support.apple.com/en-us/102650)).
- **The system's list.** `CopySymbolicHotKeys` returns key code, Carbon modifiers and an enabled flag per system
  chord, no names, no app chords (header); all four libraries use it and nothing else. The plist
  `com.apple.symbolichotkeys` (`AppleSymbolicHotKeys`, entries `{enabled; value = {parameters = (char, keycode,
  modifiers)}}` with NSEvent modifier bits, [gist](https://gist.github.com/mattrighetti/24b02c00c8a3a53966bc04f7305f99aa))
  holds only entries the user changed (pelmet #55), so untouched defaults are missing from it. The numeric IDs (60 and
  61 the input sources, 64 and 65 Spotlight) and `CGSIsSymbolicHotKeyEnabled` / `CGSGetSymbolicHotKeyValue` are
  reverse-engineered and private ([CGSHotKeys.h](https://github.com/NUIKit/CGSInternal/blob/master/CGSHotKeys.h)).
  Neither adds what a check needs; a name for a warning comes from a small table of the well-known chords.

## 6. Probes (macOS 26.5, the Command Line Tools' macOS 26 SDK)

Three throwaway Swift programs, compiled with `swiftc -O` and run from a terminal (not kept in the repository).
They registered each chord, printed the `OSStatus` and unregistered at once; no key was pressed, so they show what
registration says, not which registrant a key press reaches. Lemna (non-exclusive ⌃⌥Space) was running.

| Chord | `RegisterEventHotKey`, options 0 | with `kEventHotKeyExclusive` |
|---|---|---|
| ⌃⌥Space (Lemna holds it) | 0 | 0 |
| ⌘Space (Spotlight, enabled) | 0 | −9878 `eventHotKeyExistsErr` |
| ⌘Tab (app switcher) | | −9878 |
| ⌃⌘Space (Character Viewer, enabled) | 0 | 0 |
| ⌘⇧3, ⌘⇧4 | | 0 |
| ⌃Space, ⌥⌘Space, ⌃⌥⌘L, ⌃K, ⇧K | 0 | |
| ⌥Space, ⌥⇧Space, ⌥K, ⌥⇧K (⌥ or ⌥⇧ only) | 0 | |
| K, F5 (no modifier) | 0 | |
| ⌃Fn-L (the Fn bit 0x20000 set) | 0 | |
| the same chord twice in one process | 0, then −9878 | |

- **Registration almost never fails.** A non-exclusive registration returned noErr for every chord tried, including
  Spotlight's ⌘Space and a chord another running app holds. The headers agree: "The same hot key can, however, be
  registered by multiple applications" (CarbonEvents.h, `RegisterEventHotKey`); `eventHotKeyExistsErr` is for a
  second registration in the same process or an exclusive one against another exclusive one (CarbonEventsCore.h).
  So "register and report failure" detects nothing a user would hit.
- **An exclusive trial registration is no detector either.** Over the 148 distinct chords of the system list it
  agreed with the enabled flag for 64: it failed for ⌘Space and ⌘Tab, and succeeded for 80 enabled ones, ⌃⌘Space
  among them. While held it would also keep other apps' non-exclusive registrations from firing.
- **⌥-only chords register on 26.5** (status 0); whether they fire was not tested (no key was pressed).
- **`CopySymbolicHotKeys`** (public, Carbon, macOS 10.3+, not deprecated in the 26 SDK) returned 230 entries, 161
  enabled, each only a key code, a Carbon modifier mask and an enabled flag; the header: "There is currently no way to
  determine which hotkey in the Keyboards preference pane corresponds to a specific dictionary". 104 of the enabled
  ones carry the Fn bit (0x20000): the function-key and arrow chords, so a check must compare with that bit masked.
  3.6 ms a call: fine at a save or a launch, not per key.
- **`RegisterEventHotKey` and `CopySymbolicHotKeys` carry no deprecation** in the macOS 26 SDK's HIToolbox headers
  (`AVAILABLE_MAC_OS_X_VERSION_10_0_AND_LATER`, `…_10_3_AND_LATER`).
- **`PushSymbolicHotKeyMode`** (disables the system's chords while a recorder listens) works only with the
  Accessibility grant: without it "the actual hotkey mode will not change" (CarbonEvents.h).

## 7. macOS's App Shortcuts already rebind Lemna's menu keys

System Settings › Keyboard › Keyboard Shortcuts › App Shortcuts writes `NSUserKeyEquivalents` into an app's defaults
domain; AppKit applies it to menu items by title, or by path for a title used twice. A throwaway accessory app with
Lemna's Session and Edit menus, given the dictionary through the argument domain (nothing written to any domain):

- `Done = "@~d"` turned Session › Done ⌘⏎ into ⌥⌘D, and also an item titled Done in a menu outside the main menu
  (the menu-bar item's menu is one); `Done = "^\U21a9"` gave ⌃↩.
- `"\033Session\033Copy" = "@~c"` changed Session › Copy (⌘⇧⏎) and left Edit › Copy (⌘C) alone; a bare `Copy` would
  hit both. An ESC-separated path applies to the main menu only.
- Untested: whether a chord without ⌘ reaches the menu from the box. `BoxPanel.sendEvent` hands only keyDowns with ⌘
  to the main menu, because Lemna is not active while the box has the keys.

So every in-box chord that is a menu item (Done, Copy, Save…, Sound Off, Undo, Redo, Cut, Copy, Paste, Select All,
Open Window, Quit) can be changed today by anyone who wants to, with no Lemna code, as in any Mac app.

## 8. Default chords and what they hit

macOS's own chords with Space ([HIG, Keyboards](https://developer.apple.com/design/human-interface-guidelines/keyboards),
[Apple 102650](https://support.apple.com/en-us/102650)):

| Chord | macOS |
|---|---|
| ⌘Space | Spotlight |
| ⌥⌘Space | Spotlight's Finder search window |
| ⌃⌘Space (also Fn-E) | Character Viewer |
| ⌃Space | Select the previous input source |
| ⌃⌥Space | Select next source in Input menu ("if you use multiple input sources"; whether it is on with one source: not found) |
| ⇧⌘Space | Siri AI (beta), per Apple's shortcut page as it reads for macOS 27 |

Summon defaults of other apps: ⌥Space (Raycast, Alfred), ⌃Space and ⌃⌥Space (Things' two Quick Entries), ⌃⌥Space
(OmniFocus's quick entry, DESIGN Open 7), ⇧⌘C (Maccy), ⇧⌘2 (Drafts' capture). The HIG has no guidance for global
chords; for app chords it says "Prefer the Command key as the main modifier", "Use the Option modifier sparingly" and
"Avoid using the Control key as a modifier. The system uses Control in many systemwide features". Rectangle's first
launch offers two sets of defaults and warns that one is "more likely to conflict"; Ice and Hidden Bar set none.

There is no free chord to be found from here: what is free depends on the apps on each Mac. Hence a check at launch
that says when the chord is taken, and a field to change it.

## 9. Which of Lemna's chords people would change

- **The summon chord, above all.** It is the only global one, and ⌃⌥Space is crowded: macOS's "Select next source in
  Input menu" ([Apple](https://support.apple.com/guide/mac-help/mchlp1406)), Things' Quick Entry with Autofill (opt-in)
  and OmniFocus's quick entry (DESIGN Open 7). Every app surveyed that has a summon chord lets it be changed, and the
  summon chords differ (⌥Space, ⇧⌘C, ⌃Space, ⇧⌘2), so a collision with something already on a given Mac is likely.
- **Send: ↵ or ⌘↵.** A known preference where a field sends: Raycast's AI chat has a setting (↵ or ⌘↵, ⇧↵ a new line;
  [manual](https://manual.raycast.com/ai/ai-chat.md), and v2.2 fixed Quick AI to respect it,
  [changelog](https://www.raycast.com/changelog/macos)); Slack has one ([help](https://slack.com/help/articles/115005523006));
  Cursor's request for ⌃↵ to submit drew 58 replies ([forum](https://forum.cursor.com/t/keybind-setting-to-submit-edit-in-command-k-and-chat/2993));
  ↵-to-send sends half-composed text for Japanese input-method users ([openai/codex #10209](https://github.com/openai/codex/issues/10209)).
  Capture tools that write longer text fix it at ⌘↩ with no option: Things' Quick Entry and Drafts' capture. Lemna is
  one of those: ↵ is a paragraph end and ⇧↵ a line break (DESIGN B4), so "↵ sends" would be a change to B4, not a
  rebinding, and ⌘↵ already avoids the input-method problem.
- **Copy ⇧⌘↩, Save… ⌘S, Sound ⌘K, Open Window ⌃⌘F:** no evidence anyone would. ⌃⌘F is Enter Full Screen in most apps;
  in Lemna it opens the window, which has its own green button.
- **Esc, ⇧↵, ⌘Z and the Edit chords:** the Mac's conventions; B4 takes standard macOS text editing as the spec.
- **What covers the rest:** App Shortcuts (§7) for the menu chords; Things documents the same route for its in-app
  chords ([shortcuts](https://culturedcode.com/things/support/articles/2785159/)).

## 10. How this was gathered

Two research passes on the web (docs, GitHub source and issues, Apple's forums and pages), the Lemna code read at
2f237e3, the HIToolbox headers of the Command Line Tools' SDK read, and three probes (§6, §7) compiled with `swiftc`
from the scratch folder and deleted with it. Lines marked "not found" were looked for and not found; claims from a
single report (warble #109, steipete.me, the macOS 27 page) are marked as such where they are used. No key was pressed
and no setting of the probe Mac was changed or recorded.
