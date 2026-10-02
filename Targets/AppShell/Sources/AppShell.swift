import CoreUI
import SwiftUI

public struct AppShellView: View {
    public init() {}
    public var body: some View {
        VStack {
            SentinelOpsBadge()
            Text("SentinelOps")
        }
    }
}
