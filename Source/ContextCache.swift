//
//  ContextCache.swift
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

class ContextCache {
    
    let context: NSManagedObjectContext
    
    private struct EntityRequirement {
        let remoteId: String
        let ids: NSMutableSet
    }
    
    private var required: [NSEntityDescription : EntityRequirement] = [:]
    private var fetched: [NSEntityDescription : [AnyHashable : NSManagedObject]] = [:]
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func require(_ entityName: String, remoteId: String, ids: [AnyHashable]) {
        guard let entity = context.persistentStoreCoordinator?.managedObjectModel.entitiesByName[entityName] else {
            fatalError()
        }
        
        if let requirement = required[entity] {
            requirement.ids.addObjects(from: ids)
        } else {
            required[entity] = EntityRequirement(remoteId: remoteId, ids: NSMutableSet(array: ids))
        }
    }
    
    func fetch() throws {
        
        for (entity, requirement) in required {
            
            guard let entityName = entity.name else {
                fatalError()
            }

            let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: entityName)
            request.predicate = NSPredicate(format: "%K IN %@", requirement.remoteId, requirement.ids.allObjects)
            
            let missing = requirement.ids.mutableCopy() as! NSMutableSet
            
            let objects = try context.fetch(request)
            
            var out: [AnyHashable : NSManagedObject] = [:]
            for o in objects {
                if let id = o.value(forKey: requirement.remoteId) as? AnyHashable {
                    out[id] = o
                    missing.remove(id)
                }
            }
            
            for id in missing {
                guard let id = id as? AnyHashable else {
                    continue
                }
                
                let o = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context)
                o.setValue(id, forKey: requirement.remoteId)
                
                out[id] = o
            }
            fetched[entity] = out
        }
    }
    
    func object(_ entity: NSEntityDescription, id: AnyHashable) throws -> NSManagedObject? {
        guard let objects = fetched[entity] else {
            return nil
        }
        
        guard let result = objects[id] else {
            return nil
        }
        
        return result
    }
    
    func objects(_ entity: NSEntityDescription, ids: [AnyHashable]) throws -> [NSManagedObject]? {
        guard let objects = fetched[entity] else {
            return nil
        }
        
        let result = ids.map { (id) -> NSManagedObject in
            return objects[id]!
        }
        
        return result
    }
}
