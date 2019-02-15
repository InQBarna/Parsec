//
//  StringSerializer.swift
//  Parsec
//
//  Created by David Romacho Rosell on 14/02/2019.
//  Copyright © 2019 InQBarna. All rights reserved.
//

import Foundation

public class StringSerializer: Serializer {

    public func serialize(_ object: Any) throws -> APIAttribute {
        guard let stringValue = object as? String else {
            throw NSError(domain: "StringSerializer", code: SerializerErrorCode.unexpectedObject.rawValue, userInfo: nil)
        }
        return try APIAttribute(value: stringValue)
    }

    public func deserialize(_ value: APIAttribute) throws -> Any? {

        switch value {
        case .string(let stringValue): return stringValue
        case .null: return nil
        default:
            throw NSError(domain: "StringSerializer", code: SerializerErrorCode.unexpectedObject.rawValue, userInfo: nil)
        }
    }
}
