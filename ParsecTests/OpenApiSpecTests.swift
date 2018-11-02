//
//  OpenApiSpecTests.swift
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

class OpenApiSpecTests: XCTestCase {
    
    func testExample() {
        let context = TestTools.shared.createContext(with: "Test_2_optionals")
        let model = context.persistentStoreCoordinator!.managedObjectModel
        
        do {
            let openApi = try OpenAPISpec(model: model, template: nil)
            let spec = try openApi.generate()
            let path = NSTemporaryDirectory() + "spec.yaml"
            
            try spec.write(toFile: path, atomically: true, encoding: .utf8)
            
            print("Spec is here: \(path)")
        } catch let error {
            XCTAssert(false, error.localizedDescription)
        }
    }
    
    func testPerformanceExample() {
        let context = TestTools.shared.createContext(with: "Test_2_optionals")
        let model = context.persistentStoreCoordinator!.managedObjectModel
        let openApi = try! OpenAPISpec(model: model, template: nil)
        self.measure {
            do {
                let _ = try openApi.generate()
            } catch {
                
            }
        }
    }
    
}
