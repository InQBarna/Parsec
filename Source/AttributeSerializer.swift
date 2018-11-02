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
    let serializer: Serializer?
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
        switch attributeType {
        case .dateAttributeType:
            if let serializerName = attribute.userInfo?[UserInfoKey.serializer.rawValue] as? String {
                serializer = parsec.serializers[serializerName]
            } else {
                serializer = parsec.defaultDateSerializer
            }
            
        case .binaryDataAttributeType:
            if let serializerName = attribute.userInfo?[UserInfoKey.serializer.rawValue] as? String {
                serializer = parsec.serializers[serializerName]
            } else {
                serializer = parsec.defaultDataSerializer
            }
            
        default:
            serializer = nil
        }
    }
    
    func serialize(_ value: Any?) throws -> APIAttribute {
        guard let value = value else {
            return .null
        }
        
        switch attributeType {
        case .stringAttributeType:
            return try APIAttribute(value: value)
            
        case .dateAttributeType:
            
            guard let defaultSerializer = entity?.parsec?.defaultDateSerializer else {
                throw AttributeSerializerErrorCode.missingOption.error("No Date serializer provided")
            }
            
            let serializer = self.serializer ?? defaultSerializer
            let v = try serializer.serialize(value)
            return try APIAttribute(value: v)
            
        case .binaryDataAttributeType:
            
            guard let defaultSerializer = entity?.parsec?.defaultDataSerializer else {
                throw AttributeSerializerErrorCode.invalidDateFormat.error("No Data serializer provided")
            }
            
            let serializer = self.serializer ?? defaultSerializer
            let v = try serializer.serialize(value)
            return try APIAttribute(value: v)
            
        case .UUIDAttributeType:
            return try APIAttribute(value: (value as! UUID).uuidString)
            
        case .URIAttributeType:
            return try APIAttribute(value: (value as! URL).absoluteString)
            
        case .integer16AttributeType, .integer32AttributeType, .integer64AttributeType:
            return try APIAttribute(value: value)
            
        case .decimalAttributeType:
            return try APIAttribute(value: value)
            
        case .doubleAttributeType:
            return try APIAttribute(value: value)
            
        case .floatAttributeType:
            return try APIAttribute(value: value)
            
        case .booleanAttributeType:
            return try APIAttribute(value: value)
            
        default:
            fatalError()
        }
    }
    
    func deserialize(_ apiAttribute: APIAttribute) throws -> Any? {
        
        switch attributeType {
        case .stringAttributeType:
            switch apiAttribute {
            case .string(let s): return s
            default: return try nullOrThrow(apiAttribute)
            }
            
        case .dateAttributeType:
            
            guard let defaultSerializer = entity?.parsec?.defaultDateSerializer else {
                throw AttributeSerializerErrorCode.missingOption.error("No Date serializer provided")
            }
            
            let serializer = self.serializer ?? defaultSerializer
            
            let value = apiAttribute.value
            if value is NSNull {
                return try nullOrThrow(apiAttribute)
            }
            
            do {
                let object = try serializer.deserialize(value)
                
                guard let data = object as? Date else {
                    let message = String(format: "Could not parse '%@' into '%@' (%@) with the provided date serializer", (value as AnyObject).debugDescription, path, attributeTypeName)
                    throw AttributeSerializerErrorCode.invalidDateFormat.error(message)
                }
                return data
                
            } catch {
                let message = String(format: "Could not parse '%@' into '%@' (%@) with the provided date serializer", (value as AnyObject).debugDescription, path, attributeTypeName)
                throw AttributeSerializerErrorCode.invalidDateFormat.error(message)
            }
            
            
        case .binaryDataAttributeType:
            
            guard let defaultSerializer = entity?.parsec?.defaultDataSerializer else {
                throw AttributeSerializerErrorCode.invalidDateFormat.error("No Data serializer provided")
            }
            
            let serializer = self.serializer ?? defaultSerializer
            
            let value = apiAttribute.value
            if value is NSNull {
                return try nullOrThrow(apiAttribute)
            }
            
            do {
                let object = try serializer.deserialize(value)
                
                guard let data = object as? Data else {
                    let message = String(format: "Could not parse '%@' into '%@' (%@) with the provided data serializer", (value as AnyObject).debugDescription, path, attributeTypeName)
                    throw AttributeSerializerErrorCode.invalidDataFormat.error(message)
                }
                return data
                
            } catch {
                let message = String(format: "Could not parse '%@' into '%@' (%@) with the provided data serializer", (value as AnyObject).debugDescription, path, attributeTypeName)
                throw AttributeSerializerErrorCode.invalidDataFormat.error(message)
            }
            
        case .UUIDAttributeType:
            switch apiAttribute {
            case .string(let s):
                if let uuid = UUID(uuidString: s) {
                    return uuid
                } else {
                    return try nullOrThrow(apiAttribute)
                }
                
            default: return try nullOrThrow(apiAttribute)
            }
            
        case .URIAttributeType:
            switch apiAttribute {
            case .string(let s):
                if let url = URL(string: s) {
                    return url
                } else {
                    return try nullOrThrow(apiAttribute)
                }
                
            default: return try nullOrThrow(apiAttribute)
            }
            
            
        case .integer16AttributeType:
            
            switch apiAttribute {
            case .number(let n):
                if !n.isReal() {
                    let intValue = n.intValue
                    if intValue > INT16_MAX || intValue < INT16_MIN {
                        let message = String(format: "Value '%d' overflows the capacity of attribute '%@' (%@)", intValue, path, attributeTypeName)
                        throw AttributeSerializerErrorCode.integerOverflow.error(message)
                    }
                    return intValue
                } else {
                    return try nullOrThrow(apiAttribute)
                }
                
            default: return try nullOrThrow(apiAttribute)
            }
            
        case .integer32AttributeType:
            switch apiAttribute {
            case .number(let n):
                if !n.isReal() {
                    let intValue = n.intValue
                    if intValue > INT32_MAX || intValue < -INT32_MAX {
                        let message = String(format: "Value '%d' overflows the capacity of attribute '%@' (%@)", intValue, path, attributeTypeName)
                        throw AttributeSerializerErrorCode.integerOverflow.error(message)
                    }
                    return intValue
                } else {
                    return try nullOrThrow(apiAttribute)
                }
                
            default: return try nullOrThrow(apiAttribute)
            }
            
        case .integer64AttributeType:
            switch apiAttribute {
            case .number(let n):
                if !n.isReal() {
                    return n.int64Value
                } else {
                    return try nullOrThrow(apiAttribute)
                }
                
            default: return try nullOrThrow(apiAttribute)
            }
            
        case .decimalAttributeType:
            switch apiAttribute {
            case .number(let n): return NSDecimalNumber(value: n.doubleValue)
            default: return try nullOrThrow(apiAttribute)
            }
            
        case .doubleAttributeType:
            switch apiAttribute {
            case .number(let n): return n
            default: return try nullOrThrow(apiAttribute)
            }
            
        case .floatAttributeType:
            switch apiAttribute {
            case .number(let n): return NSNumber(floatLiteral: n.doubleValue)
            default: return try nullOrThrow(apiAttribute)
            }
            
        case .booleanAttributeType:
            switch apiAttribute {
            case .boolean(let b): return b
            default: return try nullOrThrow(apiAttribute)
            }
            
        default:
            fatalError()
        }
    }
    
    private var path: String {
        return "\(entity?.name ?? "-").\(name)"
    }
    
    private func nullOrThrow(_ apiAttribute: APIAttribute) throws -> Any? {
        
        switch apiAttribute {
        case .null:
            if !isOptional {
                let message = String(format: "Cannot set to 'null' non-optional attribute '%@' (%@)", path, attributeTypeName)
                throw AttributeSerializerErrorCode.nullInNonOptional.error(message)
            } else {
                let null: Any? = nil
                return null
            }
            
        default:
            let valueString = (apiAttribute.value as? NSObject)?.description ?? "-"
            let message = String(format: "Cannot set '%@' to attribute '%@' (%@)", valueString, path, attributeTypeName)
            throw AttributeSerializerErrorCode.unexpectedType.error(message)
        }
    }
    
    private var attributeTypeName: String {
        switch attributeType {
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
