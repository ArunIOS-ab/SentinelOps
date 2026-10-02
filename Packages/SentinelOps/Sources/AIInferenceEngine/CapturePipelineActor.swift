@preconcurrency import AVFoundation
import CoreImage
import Foundation

public struct InferenceResult: Sendable, Hashable {
    public let capturedAt: Date
    public let inputScale: CGFloat
    public let isDegraded: Bool
    public let labels: [String]

    public init(capturedAt: Date, inputScale: CGFloat, isDegraded: Bool, labels: [String]) {
        self.capturedAt = capturedAt
        self.inputScale = inputScale
        self.isDegraded = isDegraded
        self.labels = labels
    }
}

/// Owns mutable inference state. AVFoundation invokes its delegate on a capture
/// queue, so a small non-actor bridge forwards frames into this actor.
public actor CapturePipelineActor {
    private let minimumInterval: Duration = .milliseconds(300)
    private let clock: ContinuousClock
    private var lastAcceptedFrame: ContinuousClock.Instant
    private var inferenceInFlight = false
    private var continuation: AsyncStream<InferenceResult>.Continuation?

    public init() {
        let clock = ContinuousClock()
        self.clock = clock
        self.lastAcceptedFrame = clock.now - .seconds(1)
    }

    public func results() -> AsyncStream<InferenceResult> {
        AsyncStream { continuation in
            self.continuation = continuation
            continuation.onTermination = { [weak self] _ in
                Task { await self?.clearContinuation() }
            }
        }
    }

    /// The wrapper confines the non-Sendable AVFoundation reference to the
    /// framework boundary; it is consumed by this actor and never retained.
    fileprivate func receive(_ frame: UncheckedSampleBuffer) async {
        let now = clock.now
        guard !inferenceInFlight, now - lastAcceptedFrame >= minimumInterval else { return }
        guard ProcessInfo.processInfo.thermalState != .critical else { return }
        lastAcceptedFrame = now
        inferenceInFlight = true
        defer { inferenceInFlight = false }

        let thermalState = ProcessInfo.processInfo.thermalState
        let scale: CGFloat = thermalState == .serious ? 0.5 : 1.0
        // Replace this seam with VNCoreMLRequest/VNImageRequestHandler. Keeping
        // Vision work here means neither the delegate queue nor MainActor blocks.
        _ = frame.sampleBuffer
        continuation?.yield(InferenceResult(capturedAt: Date(), inputScale: scale, isDegraded: thermalState == .serious, labels: []))
    }

    private func clearContinuation() { continuation = nil }
}

/// AVFoundation's queue callback cannot directly expose actor state. This bridge
/// contains no mutable inference state and forwards each frame immediately.
public final class CaptureVideoOutputDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let pipeline: CapturePipelineActor
    public init(pipeline: CapturePipelineActor) { self.pipeline = pipeline }

    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        Task { await pipeline.receive(UncheckedSampleBuffer(sampleBuffer)) }
    }
}

/// This framework reference must not escape to detached work or long-lived storage.
fileprivate struct UncheckedSampleBuffer: @unchecked Sendable {
    let sampleBuffer: CMSampleBuffer
    init(_ sampleBuffer: CMSampleBuffer) { self.sampleBuffer = sampleBuffer }
}
