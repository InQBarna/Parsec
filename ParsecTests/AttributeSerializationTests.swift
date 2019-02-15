//
//  AttributeSerializationTests.swift
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
import CoreData
@testable import Parsec

class AttributeSerializationTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExample() {

        let context = TestTools.shared.createContext(with: "Test_2_optionals")
        guard let model = context.persistentStoreCoordinator?.managedObjectModel else {
            XCTAssert(false)
            return
        }

        let parsec = try! Parsec(model: model)
        let entity = TestTools.shared.entity2A(id: "1", max: 1, context: context)

        let json = try! parsec.json(entity)

        let data = try! JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted])
        let txt = String(data: data, encoding: .utf8)!
        NSLog(txt)

        XCTAssert((json["id"] as! String) == "1")
        XCTAssert((json["type"] as! String) == "entity2_a")

        let attributes = json["attributes"] as! [String: Any]

        XCTAssert((attributes["a_double"] as! NSNumber) == entity.aDouble)
        XCTAssert((attributes["a_decimal"] as! NSNumber) == entity.aDecimal)
        XCTAssert((attributes["a_boolean"] as! NSNumber) == entity.aBoolean)
        XCTAssert((attributes["an_integer16"] as! NSNumber) == entity.anInteger16)
        XCTAssert((attributes["an_integer32"] as! NSNumber) == entity.anInteger32)
        XCTAssert((attributes["an_integer64"] as! NSNumber) == entity.anInteger64)
        XCTAssert((attributes["an_uri"] as! String) == entity.anURI?.absoluteString)
        XCTAssert((attributes["an_uuid"] as! String) == entity.anUUID?.uuidString)
        XCTAssert((attributes["a_string"] as! String) == entity.aString)
        XCTAssert((attributes["a_data"] as! String) == "SGkgdGhlcmUh")
    }

}
