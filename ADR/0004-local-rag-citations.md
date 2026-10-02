# ADR 0004: Local RAG with source-bound citations

**Status:** Accepted

## Context

Inspectors need safety-manual guidance in disconnected locations, and compliance teams must trace guidance to a specific revision and page.

## Decision

Index signed manuals locally with encrypted vector storage and chunk metadata. Filter before ranking, return source-bound citations, and make cloud drafting optional only after retrieval and policy approval.

## Consequences

Manual imports consume storage and require version/index migration. Offline policy lookup works, and generated summaries remain reviewable against their actual source.
