//
//  Color24Tests.swift
//  
//
//  Created by David Fearon on 06/11/2023.
//

import XCTest
@testable import ScalesCore

final class Color24Tests: XCTestCase {

    func testPacked565() throws {
        let sut = Color24(red: 0b10101010, green: 0b00001111, blue: 0b11110000)
        print(String(sut.packed565, radix: 2))
        XCTAssertEqual(sut.packed565, 0b1010100001111110)
    }
}
