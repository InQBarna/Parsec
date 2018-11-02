//
//  RelationshipSerializer.swift
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

enum RelationshipSerializerErrorCode: Int {
    case internalError
    case noDestinationRelationship
    case noNameInDestinationRelationship
    case noNamingConventionProvided
    case noRemoteIdsProvided
    case noRemoteIdFound
    case missingIds
    case multipleIds
    case unexpectedIds
    case wrongEntityInRelationship
    case malformedRelationshipObjectInJSON
    case missingMandatoryFieldInJSON
    case unexpectedTypeInJSON
    
    public func error(_ message: String) -> NSError {
        return NSError(domain: "Parsec.RelationshipSerializer", code: self.rawValue, userInfo: [NSLocalizedDescriptionKey : message])
    }
}

class RelationshipSerializer {
    let name: String
    let remoteName: String
    let destinationName: String
    let isToMany: Bool
    let isOrdered: Bool
    let isOptional: Bool
    
    weak var entity: EntitySerializer?
    
    var destination: EntitySerializer {
        guard let result = entity?.parsec?.entitiesByName[destinationName] else {
            fatalError()
        }
        return result
    }
    
    enum ErrorCode: Int {
        case entityWithoutName
        case modelNotSet
    }
    
    init(relationship: NSRelationshipDescription, entity: EntitySerializer) throws {
        guard let parsec = entity.parsec else {
            throw RelationshipSerializerErrorCode.internalError.error("Model not set")
        }
        
        guard let destinationName = relationship.destinationEntity?.name else {
            let message = String(format: "Entity of class '%@' has no name", relationship.destinationEntity?.managedObjectClassName ?? "-")
            throw RelationshipSerializerErrorCode.internalError.error(message)
        }
        
        self.isToMany = relationship.isToMany
        self.isOrdered = relationship.isOrdered
        self.isOptional = relationship.isOptional
        
        self.entity = entity
        self.destinationName = destinationName
        
        let name = relationship.name
        self.name = name
        
        if let remoteName = relationship.userInfo?[UserInfoKey.remoteName.rawValue] as? String {
            self.remoteName = remoteName
        } else {
            self.remoteName = parsec.naming.from(name)
        }
    }
    
    func serialize(_ value: RelationshipData) throws -> APIRelationship {
        
        guard let relValue = value.value else {
            return APIRelationship(type: value.entitySerializer.remoteName, value: .null)
        }
        
        if let object = relValue as? NSManagedObject {
            if let idValue = object.value(forKey: destination.idAttribute.name),
                let id = try destination.idAttribute.serialize(idValue).value as? AnyHashable
            {
                return APIRelationship(type: value.entitySerializer.remoteName, value: .toOne(id: id))
            } else {
                fatalError()
            }
        } else {
            var ids: [AnyHashable] = []
            let objects: [NSManagedObject]
            
            if let object = relValue as? NSSet {
                objects = object.allObjects as! [NSManagedObject]
            } else if let object = relValue as? NSOrderedSet {
                objects = object.array as! [NSManagedObject]
            } else {
                fatalError()
            }
            
            for o in objects {
                if let idValue = o.value(forKey: destination.idAttribute.name),
                    let id = try destination.idAttribute.serialize(idValue).value as? AnyHashable
                {
                    ids.append(id)
                } else {
                    fatalError()
                }
            }

            return APIRelationship(type: value.entitySerializer.remoteName, value: .toMany(ids: ids))
        }
        
    }
    
    func deserialize(_ apiRelationship: APIRelationship) throws -> RelationshipData {
        
        let destinationIdAttribute = destination.idAttribute!
        
        if let type = apiRelationship.type {
            guard destination.remoteName == type else {
                let message = String(format: "Wrong type '%@' for relationship '%@' (%@)", type, path, destination.remoteName)
                throw RelationshipSerializerErrorCode.wrongEntityInRelationship.error(message)
            }
        }
        
        switch apiRelationship.value {
        case .null:
            if isToMany {
                if isOrdered {
                    return RelationshipData(entitySerializer: destination, value: NSOrderedSet())
                } else {
                    return RelationshipData(entitySerializer: destination, value: NSSet())
                }
            } else {
                return RelationshipData(entitySerializer: destination, value: nil)
            }
            
            
        case .toOne(id: let id):
            
            guard !isToMany else {
                let message = String(format: "Got a single identifier for a toMany relationship '%@' (%@)", path, destination.remoteName)
                throw RelationshipSerializerErrorCode.wrongEntityInRelationship.error(message)
            }
            
            let jsonAttribute = try APIAttribute(value: id)
            let validatedId = try destinationIdAttribute.deserialize(jsonAttribute)
            return RelationshipData(entitySerializer: destination, value: validatedId)
            
        case .toMany(ids: let ids):
            
            guard isToMany else {
                let message = String(format: "Got a multiple identifiers for a toOne relationship '%@' (%@)", path, destination.remoteName)
                throw RelationshipSerializerErrorCode.wrongEntityInRelationship.error(message)
            }
            
            let result = try ids.map({ (id) -> Any in
                let jsonAttribute = try APIAttribute(value: id)
                return try destinationIdAttribute.deserialize(jsonAttribute)!
            })
            
            if isOrdered {
                return RelationshipData(entitySerializer: destination, value: NSOrderedSet(array: result))
            } else {
                return RelationshipData(entitySerializer: destination, value: NSSet(array: result))
            }
        }
    }
    
    private var path: String {
        return "\(entity?.name ?? "-").\(name)"
    }
    
}

