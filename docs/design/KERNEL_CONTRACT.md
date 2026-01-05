# Kernel Contract

This document captures the *minimal, enforceable contracts* of scenic-kernel.

Each contract clause exists only if it is enforced by at least one test.
Contracts are added incrementally and removed if no longer justified by use.

The kernel is defined as much by what it refuses to do as by what it does.

---

## Core Invariants

Clauses marked **Enforced by tests** are normative; unmarked clauses document format constraints that become enforceable once relevant capabilities exist.

### KC-01: Kernel Construction Has No Side Effects

Kernel construction performs no implicit work.

A newly created kernel must:
- not advance time
- not emit events
- not perform hidden initialization

All observable kernel behavior must occur only after an explicit step.

**Enforced by tests:**
- [`tests/kernel/kernel_contract_test.zig` — KC-01](../../tests/kernel/kernel_contract_test.zig)

### KC-02: Explicit Time Advancement

The kernel advances only when explicitly stepped.

- Progression requires an explicit call to `step(dt)`.
- `dt` must be strictly positive.
- Calling `step` with zero or negative `dt` is rejected.
- Kernel construction does not imply any time advancement.

All observable effects of time advancement must occur only as a result of a
successful `step(dt)` call.

**Enforced by tests:**
- [`tests/kernel/kernel_contract_test.zig` — KC-02](../../tests/kernel/kernel_contract_test.zig)

### KC-03: Append-Only Event Log

The kernel exposes an ordered, append-only event log as its sole observable
record of what has occurred.

- Events, once present in the log, are never removed or mutated.
- Successful kernel operations may append new event data.
- Failed operations must not modify the event log.

A successful kernel advancement must result in at least one append-only
addition to the event log.

The event log represents history, not current state.
Any notion of state must be derived from this history.

**Enforced by tests:**
- [`tests/kernel/kernel_contract_test.zig` — KC-03](../../tests/kernel/kernel_contract_test.zig)

### KC-04: Atomic, Self-Delimiting Events

The event log is composed of a sequence of atomic, self-delimiting events.

Each event must be encoded such that its boundary can be determined
without interpreting the event’s semantic meaning.

- Events must be laid out contiguously in the event log.
- Given the start of an event, the start of the next event must be computable.
- Event boundaries must not depend on external state or prior interpretation.
- Kernel operations must append whole events atomically.
- Partial or malformed events must never appear in the log.

This contract guarantees that the event log can be safely:
- traversed sequentially,
- skipped or replayed,
- and evolved in format over time,

without requiring knowledge of event semantics.

**Enforced by tests:**
- [`tests/kernel/kernel_contract_test.zig` — KC-04](../../tests/kernel/kernel_contract_test.zig)

### KC-05: Fixed-Width, Bounded Event Length

Each event in the event log uses a fixed-width length field to describe
its payload size.

- The event length field is exactly one byte (`u8`).
- Event payload length is therefore bounded to the range 0–255 bytes.
- Payload lengths greater than 255 bytes are invalid and must not be encoded.
- Large logical data must be represented using multiple events.

This constraint is intentional.

A fixed-width, bounded length field ensures:
- constant-size event headers,
- trivial traversal and skipping,
- predictable memory behavior,
- and long-term format stability.

The kernel does not provide facilities for encoding or interpreting
multi-event payloads. Such composition is the responsibility of
higher-level layers.

This clause documents a **format constraint**.
It becomes enforceable only once payload-bearing events exist.

---

This contract is enforced by tests.
Changes to this document must be justified by failing tests and real usage.
