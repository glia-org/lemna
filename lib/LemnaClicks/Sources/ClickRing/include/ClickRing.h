// A single-producer, single-consumer queue of click requests: the key handler pushes, the audio
// render thread pops. Lock-free and allocation-free after create, so neither side ever waits on
// the other (a lock taken on the render thread can make the audio drop out).
#ifndef CLICK_RING_H
#define CLICK_RING_H

#include <stdbool.h>
#include <stdint.h>

typedef struct {
    uint32_t sample;  // index into the player's sample table
    float rate;       // playback rate, 1 = as recorded
} click_trigger;

typedef struct click_ring click_ring;

click_ring *click_ring_create(void);
void click_ring_destroy(click_ring *ring);
// Producer only. False when full (the audio thread has stalled): the click is dropped.
bool click_ring_push(click_ring *ring, click_trigger trigger);
// Consumer only. False when empty.
bool click_ring_pop(click_ring *ring, click_trigger *out);
// How many clicks the consumer has taken so far (any thread; for tests and diagnostics).
uint32_t click_ring_popped(click_ring *ring);

// The bed's fade: the level it moves to and the step per frame it moves by, set together by the main thread and read
// by the render thread as one 64-bit atomic, so a new target never meets an old step. Zero (silent) after create.
typedef struct click_fade click_fade;

click_fade *click_fade_create(void);
void click_fade_destroy(click_fade *fade);
void click_fade_set(click_fade *fade, float target, float step);
void click_fade_get(click_fade *fade, float *target, float *step);

#endif
