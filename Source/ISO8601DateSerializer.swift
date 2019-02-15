//
//  ISO8601DateSerializer.swift
//  Parsec
//
//  Created by David Romacho Rosell on 14/02/2019.
//  Copyright © 2019 InQBarna. All rights reserved.
//

import Foundation

public class ISO8601DateSerializer: Serializer {

    private static let shared: ISO8601DateFormatter = {
        return ISO8601DateFormatter()
    }()

    public init() {
    }

    public func deserialize(_ value: APIAttribute) throws -> Any? {
        switch value {
        case .string(let stringValue):
            // ISO8601DateFormatter doesn't support milliseconds
            let trimmedValue = stringValue.replacingOccurrences(of: "\\.\\d+", with: "", options: .regularExpression)

            guard let date = ISO8601DateSerializer.shared.date(from: trimmedValue) else {
                throw SerializerErrorCode.failed.error(String(format: "Could not convert '%@' to Date", stringValue))
            }
            return date

        case .null: return nil

        default:
            throw SerializerErrorCode.unexpectedObject.error("Object should be a String")
        }
    }

    public func serialize(_ object: Any) throws -> APIAttribute {
        guard let date = object as? Date else {
            throw SerializerErrorCode.unexpectedObject.error("Object should be a Date")
        }
        let stringValue = ISO8601DateSerializer.shared.string(from: date)
        return try APIAttribute(value: stringValue)
    }
}
