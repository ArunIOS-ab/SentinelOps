import CoreDomain
import XCTest

final class DomainEventsTests: XCTestCase {
    func testConcurrentClocksConflict() {
        let left = VectorClock(counters: ["inspector-a": 2, "inspector-b": 1])
        let right = VectorClock(counters: ["inspector-a": 1, "inspector-b": 2])
        XCTAssertTrue(left.isConflicting(with: right))
    }
}
