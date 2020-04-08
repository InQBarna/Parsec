//
//  ParsecTests.swift
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

class ParsecTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testManagedObjectWith() {
        let context = TestTools.shared.createContext(with: "Test_2_optionals")
        let model = context.persistentStoreCoordinator!.managedObjectModel
        try! createObjects(count: 5, context: context)

        let sut = try! Parsec(model: model)
        let result = try! sut.managedObject(with: "1", remoteName: "entity2_a", context: context)

        XCTAssert(result is Entity2A)
        guard
            let r = result as? Entity2A,
            let id = r.value(forKey: "id") as? String,
            id == "1"
        else {
            XCTAssert(false)
            fatalError()
        }
    }

    func testManagedObjectMissing() {
        let context = TestTools.shared.createContext(with: "Test_2_optionals")
        let model = context.persistentStoreCoordinator!.managedObjectModel

        let sut = try! Parsec(model: model)
        let result = try! sut.managedObject(with: "1", remoteName: "entity2_a", context: context)
        XCTAssert(result == nil)
    }

    func testManagedObjectWithWrongRemoteName() {
        let context = TestTools.shared.createContext(with: "Test_2_optionals")
        let model = context.persistentStoreCoordinator!.managedObjectModel

        let sut = try! Parsec(model: model)
        XCTAssertThrowsError(try sut.managedObject(with: "1", remoteName: "UnknownClass", context: context))
    }

    func testManagedObjectsWithSuccess() {
        let context = TestTools.shared.createContext(with: "Test_2_optionals")
        let model = context.persistentStoreCoordinator!.managedObjectModel
        try! createObjects(count: 10, context: context)

        let ids = ["8", "1", "7"]
        let apiObjects = ids.map { (id) -> APIObject in
            APIObject(type: "entity2_a", id: id, attributes: [:], relationships: [:])
        }

        let sut = try! Parsec(model: model)
        let result = try! sut.managedObjectsFrom(apiObjects, context: context)
        let resultIds = result.compactMap({$0.value(forKey: "id") as? String} )
        XCTAssert(resultIds == ids)
    }

    func testManagedObjectsWithFailure() {
        let context = TestTools.shared.createContext(with: "Test_2_optionals")
        let model = context.persistentStoreCoordinator!.managedObjectModel
        try! createObjects(count: 10, context: context)

        let ids = ["8", "1", "17"]
        let apiObjects = ids.map { (id) -> APIObject in
            APIObject(type: "entity2_a", id: id, attributes: [:], relationships: [:])
        }

        let sut = try! Parsec(model: model)
        XCTAssertThrowsError(try sut.managedObjectsFrom(apiObjects, context: context))
    }

    private func createObjects(count: Int, context: NSManagedObjectContext) throws {
        for i in 1..<count {
            let object = NSEntityDescription.insertNewObject(forEntityName: "Entity2A", into: context) as! Entity2A

            object.id = String(i)
        }
        try context.save()
    }
}
