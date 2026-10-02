# SentinelOps Security

## Security posture

SentinelOps minimizes collection, encrypts incident material locally, keeps cloud fallback opt-in and redacted, and fails closed when security policy cannot be evaluated. A threat model is maintained for lost devices, malicious networks, tenant boundary errors, compromised credentials, and accidental cloud disclosure. Security decisions are auditable without recording plaintext images, dictated notes, or precise location in logs.

## Data at rest

The event database, projections, vector index, attachment metadata, and manual corpus use SQLCipher (or a database encryption layer with equivalent independently verified whole-file/page encryption). SwiftData alone is not treated as encryption; if used for object modeling, its persistent store resides in the encrypted database/container. Large evidence files are encrypted before write using CryptoKit AES-GCM with a unique random nonce and authenticated metadata (tenant ID, incident ID, content hash, schema version). Thumbnails, exports, and temporary redaction files receive the same treatment and are deleted through coordinated lifecycle cleanup after use.

Each installation creates a random data-encryption key (DEK); the DEK is stored only as a Keychain item protected by `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`. The keychain item uses an access-control policy requiring user presence/biometric authentication via `LocalAuthentication` for opening protected evidence. A per-tenant wrapped key hierarchy may support authorized rotation, but raw keys never enter `UserDefaults`, logs, backups, or analytics. Key rotation creates a new DEK/key version and re-encrypts in resumable batches; old keys remain only until all reachable data is verified under the new version.

The app marks sensitive files `NSFileProtectionComplete`, excludes caches from backup, prohibits plaintext exports by default, and clears decrypted in-memory buffers/caches as soon as practical. The app treats device compromise as outside a normal iOS application trust boundary, while reducing exposure through least-privilege entitlements and no secrets in the bundle.

## Data in transit

All service traffic requires TLS 1.3 (with platform-supported secure fallback only where explicitly approved) and ATS. `URLSession` delegates evaluate the normal certificate chain, hostname, validity, and revocation posture before enforcing SPKI/public-key pinning against a signed pin set. Pins include current and next keys; a pin manifest is signed, versioned, bounded by an expiry, and delivered only over an already pinned connection. Rotation overlaps old/new pins before certificate deployment. An expired manifest or pin mismatch blocks cloud transmission and records a non-sensitive diagnostic; it never falls back to an unpinned connection.

Before any cloud evaluation, the device runs local face detection and configurable PII detection/redaction on the candidate crop. Redaction is applied to pixels, not merely metadata; the redacted derivative is visually validated where possible and carries a hash and redaction manifest. If required detectors fail, confidence is insufficient, or masks intersect a hazard of interest, the policy engine offers local/deferred review instead of upload. Full-resolution evidence and unrelated image regions do not leave the device.

Requests use short-lived scoped credentials, DPoP/device-bound credentials where the deployment supports them, request correlation IDs, payload integrity hashes, and replay-resistant idempotency keys. Sensitive headers and body fields are redacted from client/server logs. See [OFFLINE_SYNC.md](OFFLINE_SYNC.md) for transfer durability.

## Zero-retention cloud fallback

Cloud fallback is a processor of a user-approved redacted derivative, not a general evidence repository. The request contract specifies: no training, no human review except an explicitly contracted security incident process, no secondary use, no persistent prompt/image storage, and a fixed short processing TTL. The service discards request bytes, transient crops, embeddings, and model intermediates immediately after generating the response; it retains only an aggregate non-identifying operational metric where contractually necessary.

The response includes an attested request ID, processing region, model version, deletion/expiry status, and expiry timestamp. SentinelOps stores that receipt and the local request hash—not a cloud copy—to support audit. The policy engine blocks fallback when a tenant’s data residency, retention, consent, or site classification does not permit it. Supervisors can disable fallback tenant-wide; users can revoke a pending request before submission. Contractual deletion guarantees are backed by vendor review, audit rights, and periodic deletion-evidence checks.

Security-relevant changes require review and are tracked in [ADR 0003](ADR/0003-edge-first-ai-routing.md).
