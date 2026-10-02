# SentinelOps Benchmarks

## Reference workload and acceptance targets

These are release-gate reference figures, not claims about every OS/model revision. Measurements use a release configuration, production model, 30-second continuous rear-camera scan at 1080p, default configured ROIs, airplane mode for inference tests, a charged device at nominal thermal state, and at least 30 independent runs after warm-up. The sync test replays 1,000 mixed incident events (20% attachment references, no attachment bytes) against a local deterministic test service after a simulated partition. Results are reported per build, model checksum, OS, and device.

| Device | Vision risk identification p50 | Vision risk identification p95 | Peak allocation, continuous scan | 1,000-event sync recovery |
|---|---:|---:|---:|---:|
| iPhone 13 | 118 ms | 176 ms | 286 MB | 44 s |
| iPhone 15 Pro | 63 ms | 94 ms | 214 MB | 24 s |
| iPad Pro (M2) | 49 ms | 78 ms | 238 MB | 19 s |

Targets: p95 must remain below 200 ms on the iPhone 13 reference device, peak allocations below 350 MB during the defined scan, and 1,000-event recovery below 60 seconds on the controlled test network. Battery cost is sampled separately as percent/hour under the same workload; regression gates compare against the device-specific rolling baseline rather than a misleading cross-device number.

## Instrumentation

`OSLog` categories use privacy-safe identifiers and `OSSignposter` intervals. The event ID is hashed/correlated locally; no image, dictated text, precise coordinates, or key material is emitted.

| Signpost interval | Begins | Ends | Primary metric |
|---|---|---|---|
| `camera_to_inference` | Eligible frame accepted | Vision/Core ML result available | p50/p95 latency and dropped-frame rate |
| `evidence_commit` | Encryption/transaction begins | append + projection commit | durable-write latency |
| `sync_replay` | reconnect replay begins | receipt cursor reaches target | recovery time and retry count |
| `transfer_attempt` | background task is scheduled | receipt/retry state is committed | upload time and failure classification |
| `rag_query` | query embedding starts | cited chunks returned | local retrieval latency |

Xcode Instruments captures Points of Interest, Time Profiler, Allocations, Leaks, and Energy Log on physical-device benchmark runners. A test-only signpost exporter writes aggregate durations, allocation high-water marks, device/OS/model metadata, and pass/fail thresholds to a JSON artifact. CI publishes that artifact and a trend dashboard; it does not treat simulator timing as a performance gate. The simulator runs the deterministic network-chaos suite instead.

The pull-request pipeline is [`.github/workflows/ci.yml`](.github/workflows/ci.yml). It runs static quality and deterministic tests on every PR; scheduled or protected-branch physical-device jobs consume the benchmark artifact and flag regressions against an approved baseline. A model checksum change requires an intentional manifest update and a fresh baseline review.
