# Vision

scenic-kernel exists to provide a small, trustworthy core for scenic simulation.

Time is explicit.  
Behavior is deterministic.  
Meaning is earned through observation rather than implied by framework conventions.

The kernel advances state only through declared steps, records what occurred as an
append-only event log, and exposes that history through pure, read-only projections.

By refusing access to clocks, randomness, I/O, and rendering, scenic-kernel remains
stable as surrounding tools evolve, allowing rich visual, interactive, or meditative
experiences to be built on top without contaminating the kernel with policy, platform
detail, or premature semantics.
