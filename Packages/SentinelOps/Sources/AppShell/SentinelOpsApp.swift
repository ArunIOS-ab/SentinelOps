import SwiftUI

/// Package-owned root view. The iOS host target owns process startup and injection.
public struct AppShellRoot: View {
    public init() {}

    public var body: some View {
        ContentUnavailableView("SentinelOps", systemImage: "shield.lefthalf.filled")
    }
}
