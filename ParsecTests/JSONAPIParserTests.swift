//
//  JSONAPIParserTests.swift
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
@testable import Parsec

class JSONAPIParserTests: XCTestCase {
    
    func testEmptyDocument() {
        
        let json: [String : Any] = [:]
        
        let parser = JSONAPIParser()
        
        do {
            let _ = try parser.parse(json: json)
            XCTAssert(false)
        } catch let error {
            XCTAssert(check(error, is: .malformedDocument))
        }
    }
    
    // MARK: - Version tests
    
    func testWrongVersion() {
        
        let json: [String : Any] = ["jsonapi" : ["version" : "1.1"]]
        
        let parser = JSONAPIParser()
        
        do {
            let _ = try parser.parse(json: json)
            XCTAssert(false)
        } catch let error {
            XCTAssert(check(error, is: .unsupportedVersion))
        }
    }
    
    func testMalformedVersion() {
        
        let json: [String : Any] = ["jsonapi" : ["version" : 1]]
        
        let parser = JSONAPIParser()
        
        do {
            let _ = try parser.parse(json: json)
            XCTAssert(false)
        } catch let error {
            XCTAssert(check(error, is: .malformedDocument))
        }
    }
    
    // MARK: - Data tests
    
    func testWrongData() {
        
        let json: [String : Any] = ["data" : "dog"]
        
        let parser = JSONAPIParser()
        
        do {
            let _ = try parser.parse(json: json)
            XCTAssert(false)
        } catch let error {
            XCTAssert(check(error, is: .malformedDocument))
        }
    }
    
    func testNullData() {
        
        let json: [String : Any] = ["data" : NSNull()]
        
        let parser = JSONAPIParser()
        
        do {
            let document = try parser.parse(json: json)
            XCTAssert(document.errors == nil)
            XCTAssert(document.included?.count ?? 0 == 0)
            XCTAssert(document.data?.count ?? 0 == 0)
        } catch let error {
            XCTAssert(false, error.localizedDescription)
        }
    }
    
    func testOneData() {
        
        let json: [String : Any] = ["data" : ["type" : "pet", "id" : "1", "attributes" : ["age" : 1]]]
        
        let parser = JSONAPIParser()
        
        do {
            let document = try parser.parse(json: json)
            XCTAssert(document.errors == nil)
            XCTAssert(document.included?.count ?? 0 == 0)
            XCTAssert(document.data?.count ?? 0 == 1)
        } catch let error {
            XCTAssert(false, error.localizedDescription)
        }
    }
    
    func testManyData() {
        
        let json: [String : Any] = ["data" : [["type" : "pet", "id" : "1", "attributes" : ["age" : 1]],
                                              ["type" : "pet", "id" : "2", "attributes" : ["name" : "marlo"]]]]
        
        let parser = JSONAPIParser()
        
        do {
            let document = try parser.parse(json: json)
            XCTAssert(document.errors == nil)
            XCTAssert(document.included?.count ?? 0 == 0)
            XCTAssert(document.data?.count ?? 0 == 2)
        } catch let error {
            XCTAssert(false, error.localizedDescription)
        }
    }
    
    // MARK: - Resource Object
    
    func testMissingId() {
        
        let json: [String : Any] = ["data" : ["type" : "pet"]]
        
        let parser = JSONAPIParser()
        
        do {
            let _ = try parser.parse(json: json)
            XCTAssert(false)
        } catch let error {
            XCTAssert(check(error, is: .malformedDocument))
        }
    }
    
    func testMissingType() {
        
        let json: [String : Any] = ["data" : ["id" : "1"]]
        
        let parser = JSONAPIParser()
        
        do {
            let _ = try parser.parse(json: json)
            XCTAssert(false)
        } catch let error {
            XCTAssert(check(error, is: .malformedDocument))
        }
    }
    
    func testWrongId() {
        
        let json: [String : Any] = ["data" : ["type": "pet", "id" : 1]]
        
        let parser = JSONAPIParser()
        
        do {
            let _ = try parser.parse(json: json)
            XCTAssert(false)
        } catch let error {
            XCTAssert(check(error, is: .malformedDocument))
        }
    }
    
    func testWrongAttributes() {
        
        let json: [String : Any] = ["data" : ["type": "pet",
                                              "id" : "1",
                                              "attributes" : "old"]]
        
        let parser = JSONAPIParser()
        
        do {
            let _ = try parser.parse(json: json)
            XCTAssert(false)
        } catch let error {
            XCTAssert(check(error, is: .malformedDocument))
        }
    }
    
    func testWrongToOneRelationships() {
        
        let json: [String : Any] = ["data" : ["type": "pet",
                                              "id" : "1",
                                              "relationships" : "old"]]
        
        let parser = JSONAPIParser()
        
        do {
            let _ = try parser.parse(json: json)
            XCTAssert(false)
        } catch let error {
            XCTAssert(check(error, is: .malformedDocument))
        }
    }
    
    func testNullToOneRelationships() {
        
        let json: [String : Any] = ["data" : ["type": "pet",
                                              "id" : "1",
                                              "relationships" : ["owner" : ["data": NSNull()]]]]
        
        let parser = JSONAPIParser()
        
        do {
            let document = try parser.parse(json: json)
            XCTAssert(document.errors == nil)
            XCTAssert(document.included?.count ?? 0 == 0)
            XCTAssert(document.data?.count ?? 0 == 1)
            let object = document.data![0]
            let rel = object.relationships["owner"]!
            XCTAssert(rel.type == nil)
            
            switch rel.value {
            case .null:
                break
            default:
                XCTAssert(false)
            }
        } catch let error {
            XCTAssert(false, error.localizedDescription)
        }
    }
    
    func testToOneRelationships() {
        
        let json: [String : Any] = ["data" : ["type": "pet",
                                              "id" : "1",
                                              "relationships" : ["owner" : ["data": ["type": "person", "id" : "1"]]]]]
        
        let parser = JSONAPIParser()
        
        do {
            let document = try parser.parse(json: json)
            XCTAssert(document.errors == nil)
            XCTAssert(document.included?.count ?? 0 == 0)
            XCTAssert(document.data?.count ?? 0 == 1)
            let object = document.data![0]
            let rel = object.relationships["owner"]!
            XCTAssert(rel.type! == "person")
            
            switch rel.value {
            case .toOne(id: let id):
                XCTAssert(id is String)
                let idString = id as! String
                XCTAssert(idString == "1")
            default:
                XCTAssert(false)
            }
        } catch let error {
            XCTAssert(false, error.localizedDescription)
        }
    }
    
    func testEmptyToManyRelationships() {
        
        let json: [String : Any] = ["data" : ["type": "pet",
                                              "id" : "1",
                                              "relationships" : ["friends" : ["data": []]]]]
        
        let parser = JSONAPIParser()
        
        do {
            let document = try parser.parse(json: json)
            XCTAssert(document.errors == nil)
            XCTAssert(document.included?.count ?? 0 == 0)
            XCTAssert(document.data?.count ?? 0 == 1)
            let object = document.data![0]
            let rel = object.relationships["friends"]!
            XCTAssert(rel.type == nil)
            
            switch rel.value {
            case .toMany(ids: let ids):
                XCTAssert(ids.count == 0)
                
            default:
                XCTAssert(false)
            }
        } catch let error {
            XCTAssert(false, error.localizedDescription)
        }
    }
    
    func testToManyRelationships() {
        
        let json: [String : Any] = ["data" : ["type": "pet",
                                              "id" : "1",
                                              "relationships" : ["owners" : ["data": [["type": "person", "id" : "1"],
                                                                                      ["type": "person", "id" : "2"]]]]]]
        
        let parser = JSONAPIParser()
        
        do {
            let document = try parser.parse(json: json)
            XCTAssert(document.errors == nil)
            XCTAssert(document.included?.count ?? 0 == 0)
            XCTAssert(document.data?.count ?? 0 == 1)
            let object = document.data![0]
            let rel = object.relationships["owners"]!
            XCTAssert(rel.type! == "person")
            
            switch rel.value {
            case .toMany(ids: let ids):
                XCTAssert(ids.count == 2)
                XCTAssert((ids as? [String]) != nil)
                let idStrings = ids as! [String]
                XCTAssert(idStrings == ["1", "2"])
            default:
                XCTAssert(false)
            }
            
        } catch let error {
            XCTAssert(false, error.localizedDescription)
        }
    }
    
    // MARK: - Included
    
    func testWrongIncluded() {
        
        let json: [String : Any] = ["data" : [],
                                    "included" : "hi"]
        
        let parser = JSONAPIParser()
        
        do {
            let _ = try parser.parse(json: json)
            XCTAssert(false)
        } catch let error {
            XCTAssert(check(error, is: .malformedDocument))
        }
    }
    
    func testIncluded() {
        
        let json: [String : Any] = ["data" : [],
                                    "included" : [["type" : "pet", "id" : "1", "attributes" : ["age" : 1]],
                                                  ["type" : "person", "id" : "2", "attributes" : ["name" : "marlo"]]]]
        
        let parser = JSONAPIParser()
        
        do {
            let document = try parser.parse(json: json)
            XCTAssert(document.errors == nil)
            XCTAssert(document.included?.count ?? 0 == 2)
            XCTAssert(document.data?.count ?? 0 == 0)
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
        
        self.measure {
            let parser = JSONAPIParser()
            
            do {
                let _ = try parser.parse(json: json)
            } catch let error {
                XCTAssert(false, error.localizedDescription)
            }
        }
    }
    
    // MARK: - Private
    
    private func check(_ error: Error, is code: JSONAPIParser.ErrorCode) -> Bool {
        return (error as NSError).code == code.rawValue
    }
}
