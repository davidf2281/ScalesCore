
import XCTest
@testable import ScalesCore

final class Color24Tests: XCTestCase {

    func testPacked565() throws {
        let sut = Color24(red: 0b10101010, green: 0b00001111, blue: 0b11110000)
        XCTAssertEqual(sut.packed565, 0b1010100001111110)
    }
}
