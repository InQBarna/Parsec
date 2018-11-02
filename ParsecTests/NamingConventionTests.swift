//
//  NamingConventionTests.swift
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

class NamingConventionTests: XCTestCase {
    
    func testNone() {
        
        let convention = NamingConvention.none
        
        let dictionary = ["test", "value", "oneTwo", "one-Two", "one_two"]
        
        for word in dictionary {
            XCTAssert(convention.from(word) == word)
        }
    }

    func testSnakeCase() {
        
        let convention = NamingConvention.snakeCase
        
        let dictionary = ["test" : "test",
                          "value" : "value",
                          "oneTwo" : "one_two",
                          "one_two" : "one_two",
                          "oneTwoThree" : "one_two_three",
                          "one2Three" : "one2_three"]
        
        for (word, result) in dictionary {
            let r = convention.from(word)
            XCTAssert(r == result)
        }
    }
    
    func testHyphen() {
        
        let convention = NamingConvention.hyphen
        
        let dictionary = ["test" : "test",
                          "value" : "value",
                          "oneTwo" : "one-two",
                          "one_two" : "one_two",
                          "oneTwoThree" : "one-two-three",
                          "one2Three" : "one2-three"]
        
        for (word, result) in dictionary {
            let r = convention.from(word)
            XCTAssert(r == result)
        }
    }

}
