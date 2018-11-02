//
//  TestTools.swift
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

import CoreData

class TestTools {
    static let shared = TestTools()
    
    func createContext(with model: String) -> NSManagedObjectContext {
        let bundle = Bundle(for: type(of: self))
        let url = bundle.url(forResource: model, withExtension: "momd")!
        let model = NSManagedObjectModel(contentsOf: url)!
        let psc = NSPersistentStoreCoordinator(managedObjectModel: model)
        //let path = NSTemporaryDirectory().appending("/test.sqlite")
        let _ = try! psc.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: [:])
        let result = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        result.persistentStoreCoordinator = psc
        
        return result
    }
    
    func loadJson(_ name: String) -> [String : Any] {
        
        let dataUrl = Bundle.main.url(forResource: name, withExtension: "json")!
        let data = try! Data(contentsOf: dataUrl)
        let result = try! JSONSerialization.jsonObject(with: data, options: []) as! [String : Any]
        return result
    }
    
    func jsonEntity2A(id: String, max: Int) -> [String : Any] {
        
        let date = Date(timeIntervalSinceNow: TimeInterval(arc4random_uniform(1000000)))
        let dateFormatter = ISO8601DateFormatter()
        let attributes: [String : Any] = ["a_boolean": (arc4random() % 2) == 0 ? true : false,
                                          "a_date": dateFormatter.string(from: date),
                                          "a_decimal": Double(arc4random()) / 0xFFFFFFFF,
                                          "a_double": Double(arc4random()) / 0xFFFFFFFF,
                                          "an_integer16": Int(arc4random_uniform(65535)) - 32768,
                                          "an_integer32": Int(arc4random_uniform(10000000)) - 5000000,
                                          "an_integer64": Int64(arc4random()),
                                          "a_string": "lorem ipsum",
                                          "an_uuid": UUID().uuidString,
                                          "an_uri": "https://jsonapi.org",
                                          //"a_float": 3.456
        ]
        
        let m = UInt32(max)
        let toOne = rio(id: String((arc4random() % m) + 1), type: "entity2_b")
        
        var toMany: [[String : Any]] = []
        
        for _ in 0..<((arc4random() % 100)) {
            let r = rio(id: String((arc4random() % m) + 1), type: "entity2_b")
            toMany.append(r)
        }
        
        
        var toManyOrdered: [[String : Any]] = []
        
        for _ in 0..<((arc4random() % 100)) {
            let r = rio(id: String((arc4random() % m) + 1), type: "entity2_b")
            toManyOrdered.append(r)
        }
        
        let relationships: [String : Any] = ["to_one": ["data" : toOne],
                                             "to_many":["data" : toMany],
                                             "to_many_ordered": ["data" : toManyOrdered]]
        
        let json: [String : Any] = ["type" : "entity2_a",
                                    "id" : id,
                                    "attributes" : attributes,
                                    "relationships" : relationships]
        
        return json
    }

    func entity2A(id: String, max: Int, context: NSManagedObjectContext) -> Entity2A {
        
        let result = NSEntityDescription.insertNewObject(forEntityName: "Entity2A", into: context) as! Entity2A
        result.id = id
        result.aData = Data(base64Encoded: "SGkgdGhlcmUh")!
        result.aDate = Date(timeIntervalSinceNow: TimeInterval(arc4random_uniform(1000000)))
        result.aBoolean = (arc4random() % 2) == 0 ? true : false
        result.aDecimal = NSDecimalNumber(value: 3.1416)
        result.aDouble = NSNumber(value: 3.1416)
        result.anInteger16 = NSNumber(value: 16)
        result.anInteger32 = NSNumber(value: 32)
        result.anInteger64 = NSNumber(value: 64)
        result.aString = "lorem ipsum"
        result.anUUID = UUID()
        result.anURI = URL(string: "https://jsonapi.org")!
        
        let toOne = NSEntityDescription.insertNewObject(forEntityName: "Entity2B", into: context) as! Entity2B
        toOne.id = id
        result.toOne = toOne
        
        var toMany: [Entity2B] = []
        
        for i in 0..<((arc4random() % 100)) {
            let r = NSEntityDescription.insertNewObject(forEntityName: "Entity2B", into: context) as! Entity2B
            r.id = String(format: "%@-%d-toMany", id, i)
            toMany.append(r)
        }
        result.toMany = NSSet(array: toMany)
        
        var toManyOrdered: [Entity2B] = []
        for i in 0..<((arc4random() % 100)) {
            let r = NSEntityDescription.insertNewObject(forEntityName: "Entity2B", into: context) as! Entity2B
            r.id = String(format: "%@-%d-toManyOrdered", id, i)
            toManyOrdered.append(r)
        }
        result.toManyOrdered = NSOrderedSet(array: toManyOrdered)

        return result
    }

    private func rio(id: String, type: String) -> [String : Any] {
        return ["id" : id,
                "type" : "entity2_b"]
    }
}
