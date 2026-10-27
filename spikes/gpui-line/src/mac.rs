//! What GPUI 0.3.8 does not expose, from AppKit and Metal directly: the key event's timestamp, Reduce Motion,
//! the presented time of each frame, and posting key events into the app's own event queue for --bench.

use std::ptr::NonNull;
use std::sync::OnceLock;
use std::sync::atomic::{AtomicBool, Ordering};

use block2::RcBlock;
use objc2::rc::Retained;
use objc2::runtime::{AnyClass, AnyObject, Imp, Sel};
use objc2::{MainThreadMarker, msg_send, sel};
use objc2_app_kit::{NSApplication, NSEvent, NSEventModifierFlags, NSEventType, NSScreen, NSWorkspace};
use objc2_foundation::{NSPoint, NSString};

use crate::measure::{now, rec};

/// The timestamp of the key event AppKit is dispatching (NSApp.currentEvent), if it is a key-down.
pub fn current_key_ts() -> Option<f64> {
    let event = NSApplication::sharedApplication(MainThreadMarker::new()?).currentEvent()?;
    (event.r#type() == NSEventType::KeyDown).then(|| event.timestamp())
}

pub fn reduce_motion() -> bool {
    NSWorkspace::sharedWorkspace().accessibilityDisplayShouldReduceMotion()
}

pub fn display_max_fps() -> isize {
    MainThreadMarker::new().and_then(NSScreen::mainScreen).map_or(0, |s| s.maximumFramesPerSecond())
}

pub fn window_number() -> isize {
    let Some(mtm) = MainThreadMarker::new() else { return 0 };
    NSApplication::sharedApplication(mtm).windows().firstObject().map_or(0, |w| w.windowNumber())
}

static ORIGINAL: OnceLock<usize> = OnceLock::new();
static QUIT_AFTER_FIRST: AtomicBool = AtomicBool::new(false);
pub static FIRST_PRESENTED: AtomicBool = AtomicBool::new(false);

type NextDrawable = unsafe extern "C-unwind" fn(*mut AnyObject, Sel) -> *mut AnyObject;

/// GPUI's renderer calls -[CAMetalLayer nextDrawable] once per frame, on the main thread, right after the
/// frame was painted and before it encodes and presents. The hook adds a presented handler to that drawable.
unsafe extern "C-unwind" fn next_drawable(layer: *mut AnyObject, cmd: Sel) -> *mut AnyObject {
    let original: NextDrawable = unsafe { std::mem::transmute(*ORIGINAL.get().unwrap()) };
    let drawable = unsafe { original(layer, cmd) };
    if drawable.is_null() {
        return drawable;
    }
    let id = rec().drawable(now());
    let handler = RcBlock::new(move |d: NonNull<AnyObject>| {
        let t: f64 = unsafe { msg_send![d.as_ptr(), presentedTime] };
        let main_ts = {
            let mut r = rec();
            r.presented(id, t);
            r.main_ts
        };
        if t > 0.0 && !FIRST_PRESENTED.swap(true, Ordering::SeqCst) && QUIT_AFTER_FIRST.load(Ordering::SeqCst) {
            println!("main-to-first-frame ms: {:.1} (presentedTime)", (t - main_ts) * 1e3);
            std::process::exit(0);
        }
    });
    let _: () = unsafe { msg_send![drawable, addPresentedHandler: &*handler] };
    drawable
}

/// Swizzles -[CAMetalLayer nextDrawable]; call before the window opens. False if the class or method is missing.
pub fn install_present_hook(quit_after_first_frame: bool) -> bool {
    QUIT_AFTER_FIRST.store(quit_after_first_frame, Ordering::SeqCst);
    let Some(method) = AnyClass::get(c"CAMetalLayer").and_then(|c| c.instance_method(sel!(nextDrawable))) else {
        return false;
    };
    let hook: Imp = unsafe { std::mem::transmute(next_drawable as NextDrawable) };
    let old = unsafe { method.set_implementation(hook) };
    ORIGINAL.set(old as usize).is_ok()
}

/// US ANSI virtual key code and shift state for the characters of the bench text.
fn key_code(c: char) -> Option<(u16, bool)> {
    const ROW: &str = "asdfhgzxcv\0bqweryt";
    let lower = c.to_ascii_lowercase();
    let code = match lower {
        ' ' => 49,
        ',' => 43,
        '.' => 47,
        'o' => 31,
        'u' => 32,
        'i' => 34,
        'p' => 35,
        'l' => 37,
        'j' => 38,
        'k' => 40,
        'n' => 45,
        'm' => 46,
        _ => ROW.find(lower).filter(|_| lower.is_ascii_lowercase())? as u16,
    };
    Some((code, c.is_ascii_uppercase()))
}

/// Whether the app's window is the key window, so posted key events reach it.
pub fn window_is_key() -> bool {
    MainThreadMarker::new().is_some_and(|mtm| NSApplication::sharedApplication(mtm).keyWindow().is_some())
}

/// --bench: posts a key-down for `c` into the app's event queue (NSApp.postEvent, where AppKit's OS events
/// arrive), timestamped now, as the AppKit half does. Main thread.
pub fn post_key(c: char) {
    let Some(mtm) = MainThreadMarker::new() else { return };
    if let Some(event) = key_event(c, window_number()) {
        NSApplication::sharedApplication(mtm).postEvent_atStart(&event, false);
    }
}

/// A key-down for `c` as the keyboard would send it on a US layout. AppKit inserts the event's characters
/// whatever the layout; GPUI derives its keystroke (for key bindings only) from the key code.
fn key_event(c: char, window: isize) -> Option<Retained<NSEvent>> {
    let (code, shift) = key_code(c)?;
    let chars = NSString::from_str(&c.to_string());
    let flags = if shift { NSEventModifierFlags::Shift } else { NSEventModifierFlags::empty() };
    NSEvent::keyEventWithType_location_modifierFlags_timestamp_windowNumber_context_characters_charactersIgnoringModifiers_isARepeat_keyCode(
        NSEventType::KeyDown, NSPoint::new(0.0, 0.0), flags, now(), window, None, &chars, &chars, false, code,
    )
}

#[cfg(test)]
mod tests {
    use super::*;
    use objc2::class;
    use objc2_foundation::NSSize;

    #[link(name = "Metal", kind = "framework")]
    unsafe extern "C" {
        fn MTLCreateSystemDefaultDevice() -> *mut AnyObject;
    }

    /// The hook runs inside -[CAMetalLayer nextDrawable], records a frame and attaches a presented handler
    /// (an offscreen layer: the handler itself only runs once a drawable reaches the screen).
    #[test]
    fn present_hook_tags_each_drawable() {
        assert!(install_present_hook(false));
        let before = rec().frame_count();
        unsafe {
            let device = MTLCreateSystemDefaultDevice();
            assert!(!device.is_null());
            let layer: *mut AnyObject = msg_send![class!(CAMetalLayer), new];
            let _: () = msg_send![layer, setDevice: device];
            let _: () = msg_send![layer, setDrawableSize: NSSize::new(64.0, 64.0)];
            let drawable: *mut AnyObject = msg_send![layer, nextDrawable];
            assert!(!drawable.is_null());
        }
        assert_eq!(rec().frame_count(), before + 1);
    }

    #[test]
    fn bench_keys_carry_their_characters() {
        for c in crate::BENCH_TEXT.chars() {
            let event = key_event(c, 0).expect("key event");
            assert_eq!(event.characters().unwrap().to_string(), c.to_string());
            assert_eq!(event.r#type(), NSEventType::KeyDown);
        }
    }
}
