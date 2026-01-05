# Architecture

This document describes the architectural structure of scenic-kernel.

It is descriptive, not aspirational.
All claims here reflect behavior enforced by code and tests.

## Design Goals

scenic-kernel is designed to:

- record facts, not interpretations
- remain deterministic under re-consumption
- support forward-compatible evolution
- separate structure from meaning
- allow multiple independent consumers

## The Kernel

The kernel is responsible only for:

- accepting explicit advancement (`step(dt)`)
- recording append-only, self-delimiting event data
- enforcing basic validity constraints

The kernel does not:
- maintain derived state
- interpret events
- expose semantic APIs
- perform implicit work

## Event Log

The event log is the sole observable output of the kernel.

It is:
- append-only
- ordered
- self-delimiting
- byte-addressable

The log represents history, not state.
All state is derived externally by consumers.

## Structural Consumers

Structure is derived from the event log by consumers that do not
interpret event semantics.

### DelimiterCursor
Identifies structural delimiter offsets by scanning the event log.

### DelimiterIndex
Indexes delimiter offsets deterministically.

### Segmenter
Partitions the log into contiguous byte-range segments between delimiters.

### EventIterator
Provides safe, local iteration within a segment.

## Meaning and Interpretation

Event semantics, state derivation, and application logic are not part
of the kernel.

Consumers may:
- interpret event tags
- parse payloads
- derive state
- ignore events entirely

The kernel and structural consumers remain unchanged as meaning evolves.

## Determinism

Given the same event log:
- delimiter detection is deterministic
- segmentation is deterministic
- consumer-derived state is deterministic

Re-consumption is achieved by consumers that read history, not by kernel replay.

## Evolution Strategy

The architecture supports evolution by:

- tolerating unknown event tags
- using self-delimiting encodings
- deriving meaning externally
- avoiding kernel semantic growth

New capabilities are introduced by adding consumers, not kernel logic.

---

This document describes architectural intent and structure.
Normative, enforceable guarantees are specified in KERNEL_CONTRACT.md.
