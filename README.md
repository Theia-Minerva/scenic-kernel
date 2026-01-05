# scenic-kernel

**scenic-kernel** is a small, deterministic simulation core for scenic and spatial systems.

It is concerned only with:
- advancing simulation state given explicit time steps
- emitting an append-only event log
- providing deterministic, read-only projections of that log

It is **not**:
- a renderer
- a scene editor
- a game engine
- a framework

The kernel has no access to clocks, randomness, I/O, GPUs, or platform APIs.  
All time, input, and interpretation are supplied explicitly by the caller.

The intent is to build a stable, testable core that can support multiple front-ends
(rendering, visualization, relaxation or meditation experiences) without embedding
policy or semantics in the kernel itself.

This repository starts deliberately small.  
Capabilities are added only when their contracts are clear and enforceable by tests.
