// An Objective-C exception, caught (DESIGN.md A1): Swift cannot catch one, and one that crosses a Core Animation
// callback aborts the app (pass 15: `-[CAMetalLayer nextDrawable]` raised inside the ambience's display link). The
// header imports nothing, so a Swift test file that imports it does not pull in Foundation beside Testing.
#ifndef LEMNA_CATCH_H
#define LEMNA_CATCH_H

/// Runs `block`. Returns 1 if it raised an Objective-C exception, and then writes its name and reason ("name: reason",
/// cut to fit, NUL-terminated) into `message` when given; else 0.
int LemnaCatch(void (__attribute__((noescape)) ^ _Nonnull block)(void), char *_Nullable message, unsigned long size);

#endif
