//
//  EntitySerializer.swift
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

enum EntitySerializerErrorCode: Int {
    case missingId
    case multipleIds
    case noRemoteIdFound
    case nullId
    case missingType
    case missingName
    case missingParsecInfo
    case typeMissmatch
    case unknownType
    case unknownEntity

    func error(_ message: String) -> NSError {
        return NSError(domain: "Parsec.EntitySerializer", code: self.rawValue, userInfo: [NSLocalizedDescriptionKey: message])
    }
}

class EntitySerializer: NSObject {
    let name: String
    let remoteName: String
    private(set) var idAttribute: AttributeSerializer!
    private(set) var attributesByName: [String: AttributeSerializer]!
    private(set) var relationshipsByName: [String: RelationshipSerializer]!
    weak var parsec: Parsec?

    init(entity: NSEntityDescription, parsec: Parsec) throws {
        guard let name = entity.name else {
            let message = String(format: "Entity of class '%@' has no name", entity.managedObjectClassName)
            throw EntitySerializerErrorCode.missingName.error(message)
        }

        self.name = name
        self.remoteName = (entity.userInfo?[UserInfoKey.remoteName.rawValue] as? String) ?? parsec.naming.from(name)
        self.parsec = parsec

        super.init()

        // Id and ignored attributes
        var ignoredAttributes: [String] = []
        var idAttribute: AttributeSerializer?

        for (name, attribute) in entity.attributesByName {
            guard ((attribute.userInfo?[UserInfoKey.ignore.rawValue] as? String) ?? "false") != "true" else {
                ignoredAttributes.append(name)
                continue
            }

            if (attribute.userInfo?[UserInfoKey.isRemoteId.rawValue] as? String) ?? "false" == "true" {
                guard idAttribute == nil else {
                    let message = String(format: "Mutliple remote ids (%@) for entity '%@'", [idAttribute!.name, name].joined(separator: ", "), name)
                    throw EntitySerializerErrorCode.multipleIds.error(message)
                }
                idAttribute = try AttributeSerializer(attribute: attribute, entity: self)
                break
            }
        }

        if let idAttribute = idAttribute {
            self.idAttribute = idAttribute
        } else {
            let commonElements = Array(Set(parsec.defaultIdNames).intersection(Set(Array(entity.attributesByName.keys))))
            guard commonElements.count == 1 else {
                if commonElements.count > 1 {
                    let message = String(format: "Mutliple remote ids (%@) for entity '%@'", commonElements.joined(separator: ", "), name)
                    throw EntitySerializerErrorCode.multipleIds.error(message)
                } else {
                    let message = String(format: "No remote id found for entity '%@'", name)
                    throw EntitySerializerErrorCode.missingId.error(message)
                }
            }

            if
                let name = commonElements.first,
                let attribute = entity.attributesByName[name]
            {
                self.idAttribute = try AttributeSerializer(attribute: attribute, entity: self)
            } else {
                fatalError()
            }
        }
        ignoredAttributes.append(self.idAttribute.name)

        // Attributes
        var attributesByName: [String: AttributeSerializer] = [:]

        for (name, attribute) in entity.attributesByName {
            guard !ignoredAttributes.contains(name) else {
                continue
            }
            attributesByName[name] = try AttributeSerializer(attribute: attribute, entity: self)
        }
        self.attributesByName = attributesByName

        // Relationships
        var relationshipsByName: [String: RelationshipSerializer] = [:]

        for (name, relationship) in entity.relationshipsByName {
            guard ((relationship.userInfo?[UserInfoKey.ignore.rawValue] as? String) ?? "false") != "true" else {
                continue
            }
            relationshipsByName[name] = try RelationshipSerializer(relationship: relationship, entity: self)
        }

        self.relationshipsByName = relationshipsByName
    }

    func serialize(_ object: ObjectData) throws -> APIObject {

        var attributes: [String: APIAttribute] = [:]

        for (name, serializer) in attributesByName {

            let v = object.attributes[name]!

            if v == nil || v is NSNull {
                attributes[serializer.remoteName] = .null
                continue
            }

            let value = v!
            attributes[serializer.remoteName] = try serializer.serialize(value)
        }

        var relationships: [String: APIRelationship] = [:]

        for (name, serializer) in relationshipsByName {
            guard let relData = object.relationships[name] else {
                fatalError()
            }

            relationships[serializer.remoteName] = try serializer.serialize(relData)
        }

        var id: AnyHashable?

        if
            let objectId = object.id,
            let o = try idAttribute.serialize(objectId).value as? AnyHashable
        {
            id = o
        }

        return APIObject(type: remoteName,
                         id: id,
                         attributes: attributes,
                         relationships: relationships)
    }

    func deserialize(_ object: APIObject) throws -> ObjectData {

        guard object.type == remoteName else {
            let message = String(format: "Missmatch in type. Found '%@', expected '%@'", object.type, remoteName)
            throw EntitySerializerErrorCode.typeMissmatch.error(message)
        }

        var validatedAttributes: [String: Any?] = [:]

        for (name, attribute) in self.attributesByName {
            guard name != idAttribute.name else {
                continue
            }

            if let value = object.attributes[attribute.remoteName] {
                validatedAttributes[name] = try attribute.deserialize(value)
            }
        }

        var validatedRelationships: [String: RelationshipData] = [:]

        for (name, relationship) in self.relationshipsByName {
            if let rel = object.relationships[relationship.remoteName] {
                validatedRelationships[name] = try relationship.deserialize(rel)
            }
        }

        return ObjectData(id: object.id,
                          entitySerializer: self,
                          attributes: validatedAttributes,
                          relationships: validatedRelationships)
    }

}
