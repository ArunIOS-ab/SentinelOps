# ADR 0003: Edge-first AI with approved cloud fallback

**Status:** Accepted

## Context

Field conditions are often offline, and imagery can contain personal or sensitive site information. Cloud-only detection is neither dependable nor acceptable for every tenant.

## Decision

Run Vision, Core ML, local language extraction, and manual retrieval on device by default. Allow cloud classification only after a deterministic policy evaluation, successful local redaction, usable network, tenant permission, and inspector approval. Cloud output is a cited suggestion, never a safety decision.

## Consequences

The app needs model lifecycle/performance management and accepts occasional lower-confidence local results. It gains resilience, privacy, and a defensible zero-retention boundary.
