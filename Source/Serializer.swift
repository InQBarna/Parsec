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

public class ISO8601DateSerializer: Serializer {
    
    private static let shared: ISO8601DateFormatter = {
        return ISO8601DateFormatter()
    }()

    public init() {
    }

    public func deserialize(_ value: Any) throws -> Any? {
        guard let value = value as? String else {
            throw SerializerErrorCode.unexpectedObject.error("Object should be a String")
        }
        
        // ISO8601DateFormatter doesn't support milliseconds
        let trimmedValue = value.replacingOccurrences(of: "\\.\\d+", with: "", options: .regularExpression)
        
        guard let date = ISO8601DateSerializer.shared.date(from: trimmedValue) else {
            throw SerializerErrorCode.failed.error(String(format: "Could not convert '%@' to Date", value))
        }
        return date
    }
    
    public func serialize(_ object: Any) throws -> Any {
        guard let date = object as? Date else {
            throw SerializerErrorCode.unexpectedObject.error("Object should be a Date")
        }
        return ISO8601DateSerializer.shared.string(from: date)
    }
}

public class Base64DataSerializer: Serializer {
    
    public func deserialize(_ value: Any) throws -> Any? {
        guard let value = value as? String else {
            throw SerializerErrorCode.unexpectedObject.error("Object should be a String")
        }
        
        guard let data = Data(base64Encoded: value, options: .ignoreUnknownCharacters) else {
            throw SerializerErrorCode.failed.error(String(format: "Could not convert '%@' to Data", value))
        }
        return data
    }
    
    public func serialize(_ object: Any) throws -> Any {
        guard let data = object as? Data else {
            throw SerializerErrorCode.unexpectedObject.error("Object should be a Data")
        }
        return data.base64EncodedString()
    }
}

public class UnixTimestampSerializer: Serializer {
    public func serialize(_ object: Any) throws -> Any {
        guard let date = object as? Date else {
            throw NSError(domain: "UnixTimestampSerializer", code: SerializerErrorCode.unexpectedObject.rawValue, userInfo: nil)
        }
        
        return date.timeIntervalSince1970
    }
    
    public func deserialize(_ value: Any) throws -> Any? {
        guard let value = value as? Double else {
            throw NSError(domain: "UnixTimestampSerializer", code: SerializerErrorCode.unexpectedObject.rawValue, userInfo: nil)
        }
        
        return Date(timeIntervalSince1970: TimeInterval(value))
    }
}
