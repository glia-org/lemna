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

#endif
