//
//  SerializerTests.swift
//
// Copyright (c) 2018 InQBarna Kenkyuu Jo (http://inqbarna.com/)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

import XCTest

class SerializerTests: XCTestCase {

    func testDeserialize() {

        let date = Date(timeIntervalSince1970: 0)
        let value = "1970-01-01T00:00:00Z"

        let dateSerializer = ISO8601DateSerializer()

        do {
            let apiAttribute = try APIAttribute(value: value)
            let result = try dateSerializer.deserialize(apiAttribute)
            XCTAssertNotNil(result)
            XCTAssertNotNil(result! is Date)
            XCTAssert((result! as! Date) == date)
        } catch let error {
            XCTAssert(false, error.localizedDescription)
        }
    }

    func testDeserializeUnexpected() {

        let dateSerializer = ISO8601DateSerializer()

        do {
            let apiAttribute = try APIAttribute(value: 123)
            _ = try dateSerializer.deserialize(apiAttribute)
            XCTAssert(false)
        } catch let error {
            XCTAssert(check(error, is: .unexpectedObject))
        }
    }

    // MARK: - Private methods

    private func check(_ error: Error, is code: SerializerErrorCode) -> Bool {
        return (error as NSError).code == code.rawValue
    }
}
