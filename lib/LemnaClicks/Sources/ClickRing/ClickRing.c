#include "ClickRing.h"

#include <stdatomic.h>
#include <stdlib.h>

// 64 pending clicks is ~5 s of typing at 12 keys/s: the render thread drains the ring every few
// milliseconds, so the ring only fills if audio has stopped.
#define CAPACITY 64u

struct click_ring {
    _Atomic uint32_t head;  // written by the producer
    _Atomic uint32_t tail;  // written by the consumer
    click_trigger slots[CAPACITY];
};

click_ring *click_ring_create(void) { return calloc(1, sizeof(click_ring)); }

void click_ring_destroy(click_ring *ring) { free(ring); }

bool click_ring_push(click_ring *ring, click_trigger trigger) {
    uint32_t head = atomic_load_explicit(&ring->head, memory_order_relaxed);
    uint32_t tail = atomic_load_explicit(&ring->tail, memory_order_acquire);
    if (head - tail == CAPACITY) return false;
    ring->slots[head % CAPACITY] = trigger;
    // Release: the slot is written before the consumer can see the new head.
    atomic_store_explicit(&ring->head, head + 1, memory_order_release);
    return true;
}

bool click_ring_pop(click_ring *ring, click_trigger *out) {
    uint32_t tail = atomic_load_explicit(&ring->tail, memory_order_relaxed);
    uint32_t head = atomic_load_explicit(&ring->head, memory_order_acquire);
    if (head == tail) return false;
    *out = ring->slots[tail % CAPACITY];
    atomic_store_explicit(&ring->tail, tail + 1, memory_order_release);
    return true;
}

uint32_t click_ring_popped(click_ring *ring) { return atomic_load_explicit(&ring->tail, memory_order_acquire); }
