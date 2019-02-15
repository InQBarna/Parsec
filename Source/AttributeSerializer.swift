//
//  AttributeSerializer.swift
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

enum AttributeSerializerErrorCode: Int {
    case internalError
    case missingOption
    case integerOverflow
    case nullInNonOptional
    case unexpectedType
    case invalidDateFormat
    case invalidDataFormat
    
    func error(_ message: String) -> NSError {
        return NSError(domain: "Parsec.AttributeSerializer", code: self.rawValue, userInfo: [NSLocalizedDescriptionKey : message])
    }
}

class AttributeSerializer {
    let name: String
    let remoteName: String
    let attributeType: NSAttributeType
    let serializer: Serializer
    weak var entity: EntitySerializer?
    let isOptional: Bool
    
    enum ErrorCode: Int {
        case modelNotSet
    }
    
    init(attribute: NSAttributeDescription, entity: EntitySerializer) throws {
        self.entity = entity
        
        guard let parsec = entity.parsec else {
            throw AttributeSerializerErrorCode.internalError.error("Model not set")
        }
        
        self.isOptional = attribute.isOptional
        self.entity = entity
        self.name = attribute.name
        self.attributeType = attribute.attributeType
        
        if let remoteName = attribute.userInfo?[UserInfoKey.remoteName.rawValue] as? String {
            self.remoteName = remoteName
        } else {
            self.remoteName = parsec.naming.from(name)
        }
        
        // serializer
        if
            let serializerName = attribute.userInfo?[UserInfoKey.serializer.rawValue] as? String,
            let s = parsec.serializers[serializerName]
        {
            serializer = s
        } else if let s = parsec.defaultSerializers[attributeType] {
            serializer = s
        } else {
            throw AttributeSerializerErrorCode.internalError.error("No default serializer for type \(attributeType.name)")
        }
    }
    
    func serialize(_ value: Any?) throws -> APIAttribute {
        guard let value = value else {
            return .null
        }

        return try serializer.serialize(value)
    }
    
    func deserialize(_ apiAttribute: APIAttribute) throws -> Any? {

        switch apiAttribute {
        case .null: return try nullOrThrow(apiAttribute)
        default: return try serializer.deserialize(apiAttribute)
        }
    }
    
    private var path: String {
        return "\(entity?.name ?? "-").\(name)"
    }
    
    private func nullOrThrow(_ apiAttribute: APIAttribute) throws -> Any? {
        
        switch apiAttribute {
        case .null:
            if !isOptional {
                let message = String(format: "Cannot set to 'null' non-optional attribute '%@' (%@)", path, attributeType.name)
                throw AttributeSerializerErrorCode.nullInNonOptional.error(message)
            } else {
                let null: Any? = nil
                return null
            }
            
        default:
            let valueString = (apiAttribute.value as? NSObject)?.description ?? "-"
            let message = String(format: "Cannot set '%@' to attribute '%@' (%@)", valueString, path, attributeType.name)
            throw AttributeSerializerErrorCode.unexpectedType.error(message)
        }
    }    
}

extension NSAttributeType {
    var name: String {
        switch self {
        case .integer16AttributeType: return "Int16"
        case .integer32AttributeType: return "Int32"
        case .integer64AttributeType: return "Int64"
        case .decimalAttributeType: return "Decimal"
        case .doubleAttributeType: return "Double"
        case .floatAttributeType: return "Float"
        case .stringAttributeType: return "String"
        case .booleanAttributeType: return "Boolean"
        case .dateAttributeType: return "Date"
        case .binaryDataAttributeType: return "Binary"
        case .UUIDAttributeType: return "UUID"
        case .URIAttributeType: return "URI"
        default: return "Unsupported"
        }
    }
}
