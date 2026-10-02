# ADR 0002: TCA at feature boundaries, Clean Architecture beneath

**Status:** Accepted

## Context

The app has stateful capture, navigation, background work, and independently testable features, while storage, networking, and ML frameworks must remain replaceable.

## Decision

Use SwiftUI with TCA reducers for feature state/effects and Clean Architecture package rules for domain contracts and infrastructure. `AppShell` is the composition root; actor-backed clients are injected through dependency values.

## Consequences

Features receive deterministic state/effect tests and navigation-as-state. The team accepts reducer/dependency boilerplate and must prevent framework imports from leaking into `CoreDomain`.
