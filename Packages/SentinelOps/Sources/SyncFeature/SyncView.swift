import SwiftUI

public struct SyncView: View {
    public init() {}
    public var body: some View {
        ContentUnavailableView("No pending sync", systemImage: "arrow.triangle.2.circlepath")
    }
}

#Preview {
    SyncView()
}
