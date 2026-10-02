import XCTest

final class SentinelOpsUITests: XCTestCase {
    func testLaunches() {
        let app = XCUIApplication()
        app.launchEnvironment["SENTINELOPS_TEST_MODE"] = "YES"
        app.launch()
    }
}
