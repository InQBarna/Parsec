//
//  Int32SerializerTests.swift
//
// Copyright (c) 2019 InQBarna Kenkyuu Jo (http://inqbarna.com/)
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

class Int32SerializerTests: XCTestCase {

    func testDeserialize() {

        let value = Int32(90000)
        let sut = Int32Serializer()

        do {
            let apiAttribute = try APIAttribute(value: value)
            let result = try sut.deserialize(apiAttribute)
            XCTAssertNotNil(result)
            XCTAssertNotNil(result! is Int32)
            XCTAssert((result! as! Int32) == value)
        } catch let error {
            XCTAssert(false, error.localizedDescription)
        }
    }

    func testDeserializeNull() {

        let sut = Int32Serializer()

        do {
            let apiAttribute = try APIAttribute(value: NSNull())
            let result = try sut.deserialize(apiAttribute)
            XCTAssertNil(result)
        } catch let error {
            XCTAssert(false, error.localizedDescription)
        }
    }

    func testDeserializeUnexpected() {

        let sut = Int32Serializer()

        do {
            let apiAttribute = try APIAttribute(value: "lorem ipsum dolor est")
            _ = try sut.deserialize(apiAttribute)
            XCTAssert(false)
        } catch let error {
            XCTAssert(TestTools.shared.check(error, is: .unexpectedObject))
        }
    }

    func testDeserializeReal() {

        let value = 2.5
        let sut = Int32Serializer()

        do {
            let apiAttribute = try APIAttribute(value: value)
            _ = try sut.deserialize(apiAttribute)
            XCTAssert(false)
        } catch let error {
            XCTAssert(TestTools.shared.check(error, is: .failed))
        }
    }

    func testDeserializeOverflow() {

        let value = 90000000000
        let sut = Int32Serializer()

        do {
            let apiAttribute = try APIAttribute(value: value)
            _ = try sut.deserialize(apiAttribute)
            XCTAssert(false)
        } catch let error {
            XCTAssert(TestTools.shared.check(error, is: .failed))
        }
    }

    func testDeserializeOverflowNegative() {

        let value = -90000000000
        let sut = Int32Serializer()

        do {
            let apiAttribute = try APIAttribute(value: value)
            _ = try sut.deserialize(apiAttribute)
            XCTAssert(false)
        } catch let error {
            XCTAssert(TestTools.shared.check(error, is: .failed))
        }
    }

    func testSerialize() {

        let value = 90000
        let sut = Int32Serializer()

        do {
            let result = try sut.serialize(value)
            XCTAssertNotNil(result)

            XCTAssert((result.value as! Int32) == Int32(value))
        } catch let error {
            XCTAssert(false, error.localizedDescription)
        }
    }

    func testSerializeUnexpected() {

        let sut = Int32Serializer()

        do {
            _ = try sut.serialize("lorem ipsum dolor est")
            XCTAssert(false)
        } catch let error {
            XCTAssert(TestTools.shared.check(error, is: .unexpectedObject))
        }
    }

    func testSerializeFailed() {

        let sut = Int32Serializer()

        do {
            _ = try sut.serialize(123.5)
            XCTAssert(false)
        } catch let error {
            XCTAssert(TestTools.shared.check(error, is: .failed))
        }
    }

}
