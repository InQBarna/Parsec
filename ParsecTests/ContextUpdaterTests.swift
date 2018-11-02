//
//  ContextUpdaterTests.swift
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

class ContextUpdaterTests: XCTestCase {
    
    func testExample() {
        let attributes: [String : APIAttribute] = ["a_boolean": try! APIAttribute(value: true),
                                          "a_date": try! APIAttribute(value: "2018-01-23T03:06:46Z"),
                                          "a_decimal": try! APIAttribute(value: 1.65),
                                          "a_double": try! APIAttribute(value: 2.323),
                                          "a_float": try! APIAttribute(value: 3.456),
                                          "an_integer16": try! APIAttribute(value: 1),
                                          "an_integer32": try! APIAttribute(value: 2),
                                          "an_integer64": try! APIAttribute(value: 3),
                                          "a_string": try! APIAttribute(value: "lorem ipsum"),
                                          "an_uuid": try! APIAttribute(value: "b8c01b3c-525a-4e33-ab02-6d8cdbd1e427"),
                                          "an_uri": try! APIAttribute(value: "https://jsonapi.org")]
        let relationships: [String : APIRelationship] = ["to_one": APIRelationship(type: "entity2_b", value: .toOne(id: "1")),
                                                          "to_many": APIRelationship(type: "entity2_b", value: .toMany(ids: ["1", "2", "3"]))]
        
        let object = APIObject(type: "entity2_a", id: "1", attributes: attributes, relationships: relationships)
        let context = TestTools.shared.createContext(with: "Test_2_optionals")
        
        do {
            let parsec = try Parsec(model: context.persistentStoreCoordinator!.managedObjectModel)
            let entity = parsec.entitiesByName["Entity2A"]!
            let objectChanges = try entity.deserialize(object)
            
            let updater = ContextUpdater(context: context)
            
            try updater.update(changes: [objectChanges])
            
            XCTAssert(context.hasChanges)
            XCTAssert(context.insertedObjects.count == 4)
            
            let request: NSFetchRequest<Entity2A> = NSFetchRequest(entityName: Entity2A.entity().name!)
            request.predicate = NSPredicate(format: "id = %@", "1")
            
            let r = try context.fetch(request)
            
            XCTAssert(r.count == 1)
            let e = r.first!
            XCTAssert(e.id! == "1")
            
            XCTAssert(e.toOne?.id ?? "" == "1")
            XCTAssert(e.toMany?.count ?? 0 == 3)
            XCTAssert(e.toManyOrdered?.count ?? 0 == 0)
            
            XCTAssert(context.updatedObjects.count == 0)
            XCTAssert(context.deletedObjects.count == 0)
        } catch let error {
            XCTAssert(false, error.localizedDescription)
        }
    }
    
    // MARK: - Performance
    
    func testPerformance() {
        
        var objects: [[String : Any]] = []
        
        for id in 1..<1000 {
            let o = TestTools.shared.jsonEntity2A(id: String(id), max: 1000)
            objects.append(o)
        }
        
        let json: [String : Any] = ["data" : objects]
        
        let context = TestTools.shared.createContext(with: "Test_2_optionals")
        let model = context.persistentStoreCoordinator!.managedObjectModel
        
        let parser = JSONAPIParser()
        guard let document = try? parser.parse(json: json) else {
            XCTAssert(false)
            return
        }

        let parsec = try! Parsec(model: model, parser: nil, options: nil)
        let objectChanges = try! parsec.deserialize(document: document)

        self.measure {
            do {
                let ctxt = TestTools.shared.createContext(with: "Test_2_optionals")
                let updater = ContextUpdater(context: ctxt)
                try updater.update(changes: objectChanges)
            } catch let error {
                XCTAssert(false, error.localizedDescription)
            }
        }
    }
    
    func testCachePerformance() {
        
        var objects: [[String : Any]] = []
        
        for id in 1..<1000 {
            let o = TestTools.shared.jsonEntity2A(id: String(id), max: 1000)
            objects.append(o)
        }
        
        let json: [String : Any] = ["data" : objects]
        
        let context = TestTools.shared.createContext(with: "Test_2_optionals")
        let model = context.persistentStoreCoordinator!.managedObjectModel
        
        let parser = JSONAPIParser()
        guard let document = try? parser.parse(json: json) else {
            XCTAssert(false)
            return
        }
        
        let parsec = try! Parsec(model: model)
        let objectChanges = try! parsec.deserialize(document: document)
        
        self.measure {
            do {
                let ctxt = TestTools.shared.createContext(with: "Test_2_optionals")
                let updater = ContextUpdater(context: ctxt)
                try updater.computeRequired(changes: objectChanges)
            } catch let error {
                XCTAssert(false, error.localizedDescription)
            }
        }
    }
    
    func testApplyChangesPerformance() {
        
        var objects: [[String : Any]] = []
        
        for id in 1..<1000 {
            let o = TestTools.shared.jsonEntity2A(id: String(id), max: 1000)
            objects.append(o)
        }
        
        let json: [String : Any] = ["data" : objects]
        
        let context = TestTools.shared.createContext(with: "Test_2_optionals")
        let model = context.persistentStoreCoordinator!.managedObjectModel
        
        let parser = JSONAPIParser()
        guard let document = try? parser.parse(json: json) else {
            XCTAssert(false)
            return
        }
        
        let parsec = try! Parsec(model: model)
        let objectChanges = try! parsec.deserialize(document: document)

        let ctxt = TestTools.shared.createContext(with: "Test_2_optionals")
        let updater = ContextUpdater(context: ctxt)
        try? updater.computeRequired(changes: objectChanges)
        
        self.measure {
            do {
                try updater.apply(objectChanges)
            } catch let error {
                XCTAssert(false, error.localizedDescription)
            }
        }
    }
}
