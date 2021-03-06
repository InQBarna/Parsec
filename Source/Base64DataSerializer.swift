//
//  Serializer.swift
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

import Foundation

public class Base64DataSerializer: Serializer {

    public func deserialize(_ value: APIAttribute) throws -> Any? {
        switch value {
        case .string(let stringValue):
            guard let data = Data(base64Encoded: stringValue, options: .ignoreUnknownCharacters) else {
                throw SerializerErrorCode.failed.error(String(format: "Could not convert '%@' to Data", stringValue))
            }
            return data

        case .null: return nil

        default:
            throw SerializerErrorCode.unexpectedObject.error("Object should be a String")
        }
    }

    public func serialize(_ object: Any) throws -> APIAttribute {
        guard let data = object as? Data else {
            throw SerializerErrorCode.unexpectedObject.error("Object should be a Data")
        }

        let stringValue = data.base64EncodedString()
        return try APIAttribute(value: stringValue)
    }
}
