import SwiftUI

public struct IncidentView: View {
    public init() {}
    public var body: some View {
        ContentUnavailableView("No incident selected", systemImage: "exclamationmark.shield")
    }
}

#Preview {
    IncidentView()
}
