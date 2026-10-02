import SwiftUI

/// Feature inputs are values, allowing previews/tests to provide deterministic
/// behavior without a process-wide camera or engine singleton.
public struct CaptureFeatureDependencies: Sendable {
    public var cameraAvailable: @Sendable () -> Bool

    public init(cameraAvailable: @escaping @Sendable () -> Bool) {
        self.cameraAvailable = cameraAvailable
    }

    public static func preview() -> Self {
        Self(cameraAvailable: { false })
    }
}

public struct CaptureView: View {
    private let dependencies: CaptureFeatureDependencies

    public init(dependencies: CaptureFeatureDependencies) {
        self.dependencies = dependencies
    }

    public var body: some View {
        if dependencies.cameraAvailable() {
            ContentUnavailableView("Camera ready", systemImage: "camera")
        } else {
            ContentUnavailableView("Camera unavailable", systemImage: "camera")
        }
    }
}

#Preview {
    CaptureView(dependencies: .preview())
}
