//
//  ContextUpdater.swift
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

struct ObjectData {
    let id: AnyHashable?
    let entitySerializer: EntitySerializer
    let attributes: [String : Any?]
    let relationships: [String : RelationshipData]
}

struct RelationshipData {
    let entitySerializer: EntitySerializer
    let value: Any?
}

class ContextUpdater {

    public enum ErrorCode: Int {
        case nilId
    }

    let context: NSManagedObjectContext
    
    private let cache: ContextCache
    
    init(context: NSManagedObjectContext) {
        self.context = context
        self.cache = ContextCache(context: context)
    }
    
    func computeRequired(changes: [ObjectData]) throws {
        for cs in changes {
            guard let id = cs.id else {
                throw errorWithCode(.nilId, localizedDescription: "Object data with null id")
            }

            cache.require(cs.entitySerializer.name, remoteId: cs.entitySerializer.idAttribute.remoteName, ids: [id])
            
            for (_, rel) in cs.relationships {
                guard let value = rel.value else {
                    continue
                }
                
                if let ids = value as? NSOrderedSet {
                    cache.require(rel.entitySerializer.name, remoteId: cs.entitySerializer.idAttribute.remoteName, ids: ids.array as! [AnyHashable])
                } else if let ids = value as? NSSet {
                    cache.require(rel.entitySerializer.name, remoteId: cs.entitySerializer.idAttribute.remoteName, ids: ids.allObjects as! [AnyHashable])
                } else if let id = value as? AnyHashable {
                    cache.require(rel.entitySerializer.name, remoteId: cs.entitySerializer.idAttribute.remoteName, ids: [id])
                }
            }
        }
        
        try cache.fetch()
    }
    
    func apply(_ changes: [ObjectData]) throws {
        for cs in changes {
            
            guard let entity = context.persistentStoreCoordinator?.managedObjectModel.entitiesByName[cs.entitySerializer.name] else {
                fatalError()
            }

            guard let id = cs.id else {
                throw errorWithCode(.nilId, localizedDescription: "Object data with null id")
            }

            guard let object = try cache.object(entity, id: id) else {
                fatalError()
            }
            
            for (name, value) in cs.attributes {
                let oldValue = object.value(forKey: name)
                
                if let attributeType = cs.entitySerializer.attributesByName[name]?.attributeType {
                    switch attributeType {
                    case .booleanAttributeType:
                        if
                            let oldValue = oldValue as? NSNumber,
                            let value = value as? NSNumber,
                            oldValue.boolValue == value.boolValue
                        {
                            continue
                        }
                        
                    case .floatAttributeType:
                        break
                    default: break
                    }
                }
                
                if
                    let oldValue = oldValue as? AnyHashable,
                    let value = value as? AnyHashable,
                    oldValue == value
                {
                    continue
                    
                } else if
                    oldValue == nil,
                    value == nil
                {
                    continue
                }
                object.setValue(value, forKey: name)
            }
            
            for (name, rel) in cs.relationships {
                
                let oldValue: AnyHashable? = object.value(forKey: name) as? AnyHashable
                
                guard let value = rel.value else {
                    if oldValue != nil {
                        object.setValue(nil, forKey: name)
                    }
                    continue
                }
                
                var newValue: AnyHashable!
                
                guard let relEntity = context.persistentStoreCoordinator?.managedObjectModel.entitiesByName[rel.entitySerializer.name] else {
                    fatalError()
                }

                if let ids = value as? NSOrderedSet {
                    if let objects = try cache.objects(relEntity, ids: ids.array as! [AnyHashable]) {
                        newValue = NSOrderedSet(array: objects)
                    }
                } else if let ids = value as? NSSet {
                    if let objects = try cache.objects(relEntity, ids: ids.allObjects as! [AnyHashable]) {
                        newValue = NSSet(array: objects)
                    }
                } else if let id = value as? AnyHashable {
                    if let o = try cache.object(relEntity, id: id) {
                        newValue = o
                    }
                } else {
                    fatalError()
                }
                
                if
                    let oldValue = oldValue,
                    oldValue == newValue
                {
                    continue
                }
                
                object.setValue(newValue, forKey: name)
            }
        }
    }
    
    func update(changes: [ObjectData]) throws {
        
        try computeRequired(changes: changes)
        try apply(changes)
        
    }

    fileprivate func errorWithCode(_ code: ErrorCode, localizedDescription: String) -> NSError {
        return NSError(domain: "Parsec.JSONAPIParser",
                       code: code.rawValue,
                       userInfo: [NSLocalizedDescriptionKey : localizedDescription])
    }

}
