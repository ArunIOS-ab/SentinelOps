# ADR 0001: Event log with vector-clock conflict resolution

**Status:** Accepted

## Context

Inspectors can modify the same incident while offline. A single server timestamp or last-write-wins record would lose causal information and make an unreliable clock decide safety evidence.

## Decision

Persist immutable domain events locally and synchronize them with per-incident version vectors. Use CRDT-like collection semantics and per-field causal registers; retain concurrent scalar values and surface safety-critical conflicts for review. Use deterministic tie-breaking only for display/convergence, not to erase audit history.

## Consequences

The system gains offline durability, replay, auditability, and convergence tests. It incurs metadata, compaction, upcasting, and merge complexity. We explicitly reject whole-record last-write-wins.
