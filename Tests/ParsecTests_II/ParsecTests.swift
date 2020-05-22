import XCTest
@testable import Parsec

final class ParsecTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Parsec().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
