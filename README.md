# scenic-kernel

**scenic-kernel** is a small, deterministic **recording kernel** for scenic and spatial systems.

It provides a **bounded, append-only, immutable event log** that external hosts can write to
and snapshot — nothing more.

The kernel is a *recording substrate*, not an engine.

---

## What It Does

scenic-kernel is concerned only with:

- maintaining an append-only event buffer
- enforcing deterministic ordering
- preserving immutability of recorded events
- exposing raw event bytes to external consumers

All storage is **bounded at construction**.  
If capacity is exceeded, appends fail cleanly and the kernel state remains unchanged.

The kernel does **not** interpret event payloads.  
All semantics belong to the host.

---

## What It Is Not

scenic-kernel is **not**:

- a renderer
- a scene graph
- a simulation engine
- a replay system
- a projection or query layer
- a persistence layer
- a framework

It has no access to clocks, randomness, I/O, threads, GPUs, or platform APIs.

---

## Design Principles

- **Append-only**: once written, events are never mutated
- **Immutable history**: no eviction, no rewriting
- **Bounded capacity**: flight-recorder model
- **Single-writer assumption**
- **Deterministic ordering**
- **Policy-free**: the kernel records *what happened*, not *what it means*

The kernel remains deliberately dumb and honest.

---

## Intended Use

scenic-kernel is designed to be embedded inside host applications
(e.g. Metal renderers, visualization tools, relaxation or meditation experiences)
as a low-level recording facility.

Hosts decide:
- what events mean
- how they are interpreted
- whether and how to persist them
- what to do when capacity is exhausted

---

## C ABI (Minimal)

scenic-kernel exposes a **small, opaque C ABI** so non-Zig hosts (e.g. Swift) can use it safely.

Only raw byte recording is exposed at the ABI boundary.

```c
typedef struct sk_kernel sk_kernel;

sk_kernel* sk_kernel_create(size_t max_bytes);
void sk_kernel_destroy(sk_kernel* kernel);

int sk_kernel_append_annotation(
    sk_kernel* kernel,
    const uint8_t* payload,
    size_t payload_len
);

const uint8_t* sk_kernel_event_bytes(
    const sk_kernel* kernel,
    size_t* out_len
);
```

Guarantees:

- payloads are treated as opaque bytes
- returned byte pointer is valid until the next append
- no copying is performed by the kernel

### Example (C)

```c
sk_kernel* k = sk_kernel_create(4096);

const uint8_t payload[] = { 0x01, 0x02, 0x03 };
sk_kernel_append_annotation(k, payload, sizeof(payload));

size_t len = 0;
const uint8_t* bytes = sk_kernel_event_bytes(k, &len);
/* bytes[0..len) now contains the raw event log */

sk_kernel_destroy(k);
```
This example is intentionally minimal and carries **no semantic meaning**.

## Repository Philosophy

This repository starts deliberately small.

Capabilities are added only when:

- their contracts are clear
- their behavior is enforceable by tests
- they do not introduce semantics, policy, or interpretation into the kernel

---

### Notes / Rationale

- Removed **“simulation core”** language — that no longer matches reality.
- Removed mention of **projections** and **replay**.
- Explicitly framed kernel as a *recording substrate*.
- ABI described factually, without hinting at future features.
- Example is minimal, non-opinionated, and safe.

If you want, next we can:
- add a **“Versioning & Stability”** section,
- add a **“Threading & Safety”** disclaimer,
- or keep the README exactly this lean and move on.
