//
// LoggerTests.swift
//
// Copyright (c) 2020 InQBarna Kenkyuu Jo (http://inqbarna.com/)
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

class LoggerTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testLogger() {

        let attributes: [String: APIAttribute] = ["a_boolean": try! APIAttribute(value: true),
                                                  "a_date": try! APIAttribute(value: "2018-01-23T03:06:46Z"),
                                                  "a_decimal": try! APIAttribute(value: 1.65),
                                                  "a_double": try! APIAttribute(value: 2.323),
                                                  "a_float": try! APIAttribute(value: 3.456),
                                                  "an_integer16": try! APIAttribute(value: 1),
                                                  "an_integer32": try! APIAttribute(value: 2),
                                                  "an_integer64": try! APIAttribute(value: 3),
                                                  "a_string": try! APIAttribute(value: "lorem ipsum"),
                                                  "unknown_field": try! APIAttribute(value: "lorem ipsum"),
                                                  "an_uuid": try! APIAttribute(value: "b8c01b3c-525a-4e33-ab02-6d8cdbd1e427"),
                                                  "an_uri": try! APIAttribute(value: "https://jsonapi.org")]
        let relationships: [String: APIRelationship] = ["to_one": APIRelationship(type: "entity2_b", value: .toOne(id: "1")),
                                                        "to_many": APIRelationship(type: "entity2_b", value: .toMany(ids: ["1", "2", "3"]))]

        let object = APIObject(type: "entity2_a", id: "1", attributes: attributes, relationships: relationships)

        let context = TestTools.shared.createContext(with: "Test_2_optionals")
        let model = context.persistentStoreCoordinator!.managedObjectModel
        XCTAssert(context.persistentStoreCoordinator?.managedObjectModel != nil)

        do {
            let spy = SpyLogger(logMissing: true, logUnknown: true)
            let parsec = try Parsec(model: model)
            parsec.logger = spy
            let entity = parsec.entitiesByName["Entity2A"]!
            let objectChanges = try entity.deserialize(object)

            XCTAssert(objectChanges.entitySerializer == entity)
            XCTAssert(objectChanges.id is String)
            XCTAssert(objectChanges.id as! String == "1")
            XCTAssert(spy.lastLog != nil)
            XCTAssert(spy.logCount == 3)
        } catch {
            XCTAssert(false)
        }
    }
}

private class SpyLogger: Logger {
    let logUnknown: Bool
    let logMissing: Bool

    var lastLog: String?
    var logCount = 0

    init(logMissing: Bool, logUnknown: Bool) {
        self.logMissing = logMissing
        self.logUnknown = logUnknown
    }

    func log(_ level: LogLevel, _ text: @autoclosure () -> String) {
        let lastLog = text()
        logCount += 1
        self.lastLog = lastLog
    }
}
