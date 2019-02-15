//
//  Int16Serializer.swift
//
// Copyright (c) 2019 InQBarna Kenkyuu Jo (http://inqbarna.com/)
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

import Foundation

public class Int16Serializer: Serializer {

    public func serialize(_ object: Any) throws -> APIAttribute {
        guard let numericValue = object as? NSNumber else {
            throw NSError(domain: "Int16Serializer", code: SerializerErrorCode.unexpectedObject.rawValue, userInfo: nil)
        }

        guard !numericValue.isReal() else {
            throw NSError(domain: "Int16Serializer",
                          code: SerializerErrorCode.failed.rawValue,
                          userInfo: [NSLocalizedDescriptionKey: "Could not serialize \(numericValue.doubleValue) into a Int16"])
        }
        return try APIAttribute(value: numericValue)
    }

    public func deserialize(_ value: APIAttribute) throws -> Any? {

        switch value {
        case .number(let n):
            guard !n.isReal() else {
                throw NSError(domain: "Int16Serializer",
                              code: SerializerErrorCode.failed.rawValue,
                              userInfo: [NSLocalizedDescriptionKey: "Could not deserialize \(n.doubleValue) into a Int16"])
            }

            let intValue = n.intValue
            guard
                intValue <= INT16_MAX,
                intValue >= INT16_MIN
                else {
                    throw NSError(domain: "Int16Serializer",
                                  code: SerializerErrorCode.failed.rawValue,
                                  userInfo: [NSLocalizedDescriptionKey: "Value '\(intValue)' overflows the capacity of an Int16"])
            }
            return Int16(intValue)

        case .null:
            return nil

        default:
            throw NSError(domain: "Int16Serializer", code: SerializerErrorCode.unexpectedObject.rawValue, userInfo: nil)
        }
    }
}
