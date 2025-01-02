import XCTest
@testable import DataController

final class DataControllerTests: XCTestCase {
    func testExample() throws {
        let dataController = LiveDataController(config: .init(usernameWithRandomDigits: "test_user"))
        XCTAssertTrue(dataController is DataController)
    }
}
