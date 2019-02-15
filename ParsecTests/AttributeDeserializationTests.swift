//
//  AttributeDeserializationTests.swift
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

class AttributeDeserializationTests: XCTestCase {
    
    // MARK: - Non Optional Boolean tests
    
    func testNonOptionalBooleanTrue() {
        do {
            let result = try testAttribute(name: "aBoolean", json: ["a_boolean": true], isOptional: false)
            XCTAssert(result is Bool)
            XCTAssert((result as! Bool) == true)
        } catch let error {
            XCTAssert(false, (error as NSError).localizedDescription)
        }
    }
    
    func testNonOptionalBooleanFalse() {
        do {
            let result = try testAttribute(name: "aBoolean", json: ["a_boolean": false], isOptional: false)
            XCTAssert(result is Bool)
            XCTAssert((result as! Bool) == false)
        } catch let error {
            XCTAssert(false, (error as NSError).localizedDescription)
        }
    }
    
    func testNonOptionalBooleanNull() {
        do {
            let _ = try testAttribute(name: "aBoolean", json: ["a_boolean": NSNull()], isOptional: false)
            XCTAssert(false)
        } catch let error {
            XCTAssert(checkAttributeSerializer(error, is: .nullInNonOptional))
        }
    }
    
    func testNonOptionalBooleanString() {
        do {
            let _ = try testAttribute(name: "aBoolean", json: ["a_boolean": "fail"], isOptional: false)
            XCTAssert(false)
        } catch let error {
            XCTAssert(checkSerializer(error, is: .unexpectedObject))
        }
    }
    
    // MARK: - Optional Boolean tests
    
    func testOptionalBooleanTrue() {
        do {
            let result = try testAttribute(name: "aBoolean", json: ["a_boolean": true], isOptional: true)
            XCTAssert(result is Bool)
            XCTAssert((result as! Bool) == true)
        } catch let error {
            XCTAssert(false, (error as NSError).localizedDescription)
        }
    }
    
    func testOptionalBooleanFalse() {
        do {
            let result = try testAttribute(name: "aBoolean", json: ["a_boolean": false], isOptional: true)
            XCTAssert(result is Bool)
            XCTAssert((result as! Bool) == false)
        } catch let error {
            XCTAssert(false, (error as NSError).localizedDescription)
        }
    }
    
    func testOptionalBooleanNull() {
        do {
            let result = try testAttribute(name: "aBoolean", json: ["a_boolean": NSNull()], isOptional: true)
            XCTAssert(result == nil)
        } catch let error {
            XCTAssert(false, (error as NSError).localizedDescription)
        }
    }
    
    func testOptionalBooleanString() {
        do {
            let _ = try testAttribute(name: "aBoolean", json: ["a_boolean": "fail"], isOptional: true)
            XCTAssert(false)
        } catch let error {
            XCTAssert(checkSerializer(error, is: .unexpectedObject))
        }
    }
    
    // MARK: - Non Optional Double tests
    
    func testNonOptionalDouble() {
        do {
            let x: Double = 3.14
            let result = try testAttribute(name: "aDouble", json: ["a_double": x], isOptional: false)
            XCTAssert((result as? NSNumber) != nil)
            let val = result as! NSNumber
            XCTAssert(val.doubleValue == x)
        } catch let error {
            XCTAssert(false, (error as NSError).localizedDescription)
        }
    }
    
    func testNonOptionalDoubleNull() {
        do {
            let _ = try testAttribute(name: "aDouble", json: ["a_double": NSNull()], isOptional: false)
            XCTAssert(false)
        } catch let error {
            XCTAssert(checkAttributeSerializer(error, is: .nullInNonOptional))
        }
    }
    
    func testNonOptionalDoubleString() {
        do {
            let _ = try testAttribute(name: "aDouble", json: ["a_double": "fail"], isOptional: false)
            XCTAssert(false)
        } catch let error {
            XCTAssert(checkSerializer(error, is: .unexpectedObject))
        }
    }
    
    // MARK: - Optional Double tests
    
    func testOptionalDouble() {
        do {
            let x: Double = 3.14
            let result = try testAttribute(name: "aDouble", json: ["a_double": x], isOptional: true)
            XCTAssert((result as? NSNumber) != nil)
            let val = result as! NSNumber
            XCTAssert(val.doubleValue == x)
        } catch let error {
            XCTAssert(false, (error as NSError).localizedDescription)
        }
    }
    
    func testOptionalDoubleNull() {
        do {
            let result = try testAttribute(name: "aDouble", json: ["a_double": NSNull()], isOptional: true)
            XCTAssert(result == nil)
        } catch let error {
            XCTAssert(false, (error as NSError).localizedDescription)
        }
    }
    
    func testOptionalDoubleString() {
        do {
            let _ = try testAttribute(name: "aDouble", json: ["a_double": "fail"], isOptional: true)
            XCTAssert(false)
        } catch let error {
            XCTAssert(checkSerializer(error, is: .unexpectedObject))
        }
    }
    
    // MARK: - Integer Overflow tests
    
    func testNonOptionalInt16PositiveOverflow() {
        do {
            let _ = try testAttribute(name: "anInteger16", json: ["an_integer16": Int(INT16_MAX) + 1], isOptional: false)
            XCTAssert(false)
        } catch let error {
            XCTAssert(checkSerializer(error, is: .failed))
        }
    }
    
    func testNonOptionalInt16NegativeOverflow() {
        do {
            let _ = try testAttribute(name: "anInteger16", json: ["an_integer16": Int(INT16_MIN) - 1], isOptional: false)
            XCTAssert(false)
        } catch let error {
            XCTAssert(checkSerializer(error, is: .failed))
        }
    }
    
    func testNonOptionalInt32PositiveOverflow() {
        do {
            let _ = try testAttribute(name: "anInteger32", json: ["an_integer32": Int(INT32_MAX) + 1], isOptional: false)
            XCTAssert(false)
        } catch let error {
            XCTAssert(checkSerializer(error, is: .failed))
        }
    }
    
    func testNonOptionalInt32NegativeOverflow() {
        do {
            let _ = try testAttribute(name: "anInteger32", json: ["an_integer32": -(Int(INT32_MAX) + 1)], isOptional: false)
            XCTAssert(false)
        } catch let error {
            XCTAssert(checkSerializer(error, is: .failed))
        }
    }
    
    // MARK: - Integer tests
    
    func testNonOptionalInt16Real() {
        do {
            let _ = try testAttribute(name: "anInteger16", json: ["an_integer16": 3.14], isOptional: false)
            XCTAssert(false)
        } catch let error {
            XCTAssert(checkSerializer(error, is: .failed))
        }
    }
    
    func testNonOptionalInt32Real() {
        do {
            let _ = try testAttribute(name: "anInteger32", json: ["an_integer32": 3.14], isOptional: false)
            XCTAssert(false)
        } catch let error {
            XCTAssert(checkSerializer(error, is: .failed))
        }
    }
    
    func testNonOptionalInt64Real() {
        do {
            let _ = try testAttribute(name: "anInteger64", json: ["an_integer64": 3.14], isOptional: false)
            XCTAssert(false)
        } catch let error {
            XCTAssert(checkSerializer(error, is: .failed))
        }
    }
    
    // MARK: - Date tests
    
    func testNonOptionalDate() {
        do {
            let dateSerializer = ISO8601DateFormatter()
            let result = try testAttribute(name: "aDate", json: ["a_date": "2018-01-23T03:06:46Z"], isOptional: false)
            XCTAssert(result is Date)
            XCTAssert((result as! Date) == dateSerializer.date(from: "2018-01-23T03:06:46Z"))
        } catch let error {
            XCTAssert(false, (error as NSError).localizedDescription)
        }
    }
    
    func testNonOptionalDateError() {
        do {
            let _ = try testAttribute(name: "aDate", json: ["a_date": "lorem"], isOptional: false)
            XCTAssert(false)
        } catch let error {
            XCTAssert(checkSerializer(error, is: .failed))
        }
    }
    
    // MARK: - Data tests
    
    func testNonOptionalData() {
        do {
            let result = try testAttribute(name: "aData", json: ["a_data": "dGVzdGluZw=="], isOptional: false)
            XCTAssert(result is Data)
            
            let data = result as! Data
            let string = String(data: data, encoding: .utf8)
            XCTAssert(string == "testing")
        } catch let error {
            XCTAssert(false, (error as NSError).localizedDescription)
        }
    }
    
    func testNonOptionalDataError() {
        do {
            let _ = try testAttribute(name: "aData", json: ["a_data": "lorem"], isOptional: false)
            XCTAssert(false)
        } catch let error {
            XCTAssert(checkSerializer(error, is: .failed))
        }
    }
    
    // MARK: - URI tests
    
    func testNonOptionalURI() {
        do {
            let result = try testAttribute(name: "anURI", json: ["an_uri": "http://jsonapi.org"], isOptional: false)
            XCTAssert(result is URL)
        } catch let error {
            XCTAssert(false, (error as NSError).localizedDescription)
        }
    }
    
    func testNonOptionalURIError() {
        do {
            let _ = try testAttribute(name: "anURI", json: ["an_uri": "tfr;\\re"], isOptional: false)
            XCTAssert(false)
        } catch let error {
            XCTAssert(checkSerializer(error, is: .failed))
        }
    }
    
    // MARK: - Private methods
    
    private func testAttribute(name: String, json: [String : Any], isOptional: Bool) throws -> Any? {
        
        if isOptional {
            let context = TestTools.shared.createContext(with: "Test_2_optionals")
            guard let model = context.persistentStoreCoordinator?.managedObjectModel else {
                XCTAssert(false)
                return nil
            }
            
            let parsec = try! Parsec(model: model)
            let entity = parsec.entitiesByName["Entity2A"]!
            guard let attribute = entity.attributesByName[name] else {
                XCTAssert(false)
                return nil
            }
            
            guard let val = json[attribute.remoteName] else {
                XCTAssert(false)
                return nil
            }
            
            let jsonAttribute = try APIAttribute(value: val)
            return try attribute.deserialize(jsonAttribute)
            
        } else {
            let context = TestTools.shared.createContext(with: "Test_1_non_optionals")
            XCTAssert(context.persistentStoreCoordinator?.managedObjectModel != nil)

            guard let model = context.persistentStoreCoordinator?.managedObjectModel else {
                XCTAssert(false)
                return nil
            }
            
            let parsec = try! Parsec(model: model)
            let entity = parsec.entitiesByName["Entity1A"]!

            guard let attribute = entity.attributesByName[name] else {
                XCTAssert(false)
                return nil
            }

            guard let val = json[attribute.remoteName] else {
                XCTAssert(false)
                return nil
            }
            
            let jsonAttribute = try APIAttribute(value: val)
            return try attribute.deserialize(jsonAttribute)
        }
    }
    
    // MARK: - Private methods

    private func checkSerializer(_ error: Error, is code: SerializerErrorCode) -> Bool {
        print(code.rawValue)
        return (error as NSError).code == code.rawValue
    }

    private func checkAttributeSerializer(_ error: Error, is code: AttributeSerializerErrorCode) -> Bool {
        print(code.rawValue)
        return (error as NSError).code == code.rawValue
    }
}
