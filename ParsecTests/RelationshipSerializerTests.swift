//
//  RelationshipTests.swift
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

class RelationshipTests: XCTestCase {
    
    // MARK: - To One
    
    func testToOne() {
        let context = TestTools.shared.createContext(with: "Test_2_optionals")
        guard let model = context.persistentStoreCoordinator?.managedObjectModel else {
            XCTAssert(false)
            return
        }
        
        do {
            let parsec = try Parsec(model: model)
            
            let entity = parsec.entitiesByName["Entity2A"]!
            guard let relationship = entity.relationshipsByName["toOne"] else {
                XCTAssert(false)
                return
            }
            
            let json = APIRelationship(type: "entity2_b", value: .toOne(id: "1"))
            
            let r = try relationship.deserialize(json)
            XCTAssert(r.entitySerializer.name == "Entity2B")
            XCTAssert(r.value is String)
            XCTAssert(r.value as! String == "1")
        } catch let error {
            XCTAssert(false, error.localizedDescription)
        }
    }
    
    // MARK: - To Many
    
    func testToMany() {
        let context = TestTools.shared.createContext(with: "Test_2_optionals")
        guard let model = context.persistentStoreCoordinator?.managedObjectModel else {
            XCTAssert(false)
            return
        }
        do {
            let parsec = try Parsec(model: model)
            
            let entity = parsec.entitiesByName["Entity2A"]!
            guard let relationship = entity.relationshipsByName["toMany"] else {
                XCTAssert(false)
                return
            }
            
            let json = APIRelationship(type: "entity2_b", value: .toMany(ids: ["1", "2", "3", "4"]))
            
            let r = try relationship.deserialize(json)
            XCTAssert(r.entitySerializer.name == "Entity2B")
            XCTAssert(r.value is NSSet)
            XCTAssert((r.value as! NSSet).isEqual(to: NSSet(array: ["1", "2", "3", "4"]) as! Set<AnyHashable>))
        } catch let error {
            XCTAssert(false, error.localizedDescription)
        }
    }
    
    func testToManyOrdered() {
        let context = TestTools.shared.createContext(with: "Test_2_optionals")
        guard let model = context.persistentStoreCoordinator?.managedObjectModel else {
            XCTAssert(false)
            return
        }
        do {
            let parsec = try Parsec(model: model)
            
            let entity = parsec.entitiesByName["Entity2A"]!
            guard let relationship = entity.relationshipsByName["toManyOrdered"] else {
                XCTAssert(false)
                return
            }
            
            let json = APIRelationship(type: "entity2_b", value: .toMany(ids: ["1", "2", "3", "4"]))
            
            let r = try relationship.deserialize(json)
            XCTAssert(r.entitySerializer.name == "Entity2B")
            XCTAssert(r.value is NSOrderedSet)
            XCTAssert((r.value as! NSOrderedSet).isEqual(to: NSOrderedSet(array: ["1", "2", "3", "4"])))
        } catch let error {
            XCTAssert(false, error.localizedDescription)
        }
    }
    
    // MARK: - Private methods
    
    private func check(_ error: Error, is code: RelationshipSerializerErrorCode) -> Bool {
        return (error as NSError).code == code.rawValue
    }
}
