//
//  JSONAPIParser.swift
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

public class JSONAPIParser: APIParser {
    
    public enum ErrorCode: Int {
        case malformedDocument
        case unsupported
        case unsupportedVersion
        case serverError
    }
    
    let supportedVersions = ["1.0"]
    let domain: String?
    
    init(domain: String? = nil) {
        self.domain = domain
    }
    
    public func parse(json: [String : Any]) throws -> APIDocument {
        
        try validateVersion(json)
        
        if let errors = try parseErrors(json) {
            return APIDocument(data: nil, included: nil, errors: errors, meta: nil)
        }
        
        var meta: [String : Any]? = nil
        if let metaObject = json["meta"] {
            guard let m = metaObject as? [String : Any] else {
                let message = "The value of each meta member MUST be an object (a “meta object”)"
                throw errorWithCode(.malformedDocument, localizedDescription: message)
            }
            meta = m
        }
        
        guard let dataObject = json["data"] else {
            if let meta = meta {
                return APIDocument(data: nil, included: nil, errors: nil, meta: meta)
            } else {
                let message = "A document MUST contain at least one of the following top-level members: data, errors, meta"
                throw errorWithCode(.malformedDocument, localizedDescription: message)
            }
        }
        
        var data: [APIObject] = []
        
        if let object = dataObject as? [String : Any] {
            
            data.append(try process(object: object))
            
        } else if let objects = dataObject as? [[String : Any]] {
            
            for object in objects {
                data.append(try process(object: object))
            }
            
        } else if dataObject is NSNull {
            
        } else {
            let message = "Primary data MUST be either: (a) A single resource object, a single resource identifier object, or null, for requests that target single resources. (b) An array of resource objects, an array of resource identifier objects, or an empty array ([]), for requests that target resource collections"
            throw errorWithCode(.malformedDocument, localizedDescription: message)
        }
        
        var included: [APIObject] = []
        if let includedObjects = json["included"] {
            guard let io = includedObjects as? [[String : Any]] else {
                let message = "All included resources MUST be represented as an array of resource objects in a top-level included member"
                throw errorWithCode(.malformedDocument, localizedDescription: message)
            }
            
            for object in io {
                included.append(try process(object: object))
            }
        }
        
        return APIDocument(data: data, included: included, errors: nil, meta: meta)
    }
    
    public func json(object: APIObject) throws -> [String : Any] {
        var result: [String : Any] = [:]

        result["type"] = object.type

        if let id = object.id {
            result["id"] = id
        }
        
        var attributes: [String : Any] = [:]
        for (name, att) in object.attributes {
            attributes[name] = att.value
        }
        result["attributes"] = attributes
        
        var relationships: [String : Any] = [:]
        for (name, relationship) in object.relationships {
            let type = relationship.type!
            switch relationship.value {
            case .null: relationships[name] = ["data" : NSNull()]
            case .toMany(ids: let ids):
                let tmp = ids.map { (id) -> [String : Any] in
                    return ["id" : id, "type": type]
                }
                
                relationships[name] = ["data" : tmp]
                
            case .toOne(id: let id): relationships[name] = ["data" : ["id": id, "type": type]]
            }
        }
        result["relationships"] = relationships
        
        return result
    }
    
    func process(object: [String : Any]) throws -> APIObject {
        
        let (type, id) = try processResourceObject(object)
        
        var att: [String : APIAttribute] = [:]
        if let attributesObject = object["attributes"] {
            guard let attributes = attributesObject as? [String : Any] else {
                let message = "The value of the attributes key MUST be an object (an “attributes object”)"
                throw errorWithCode(.malformedDocument, localizedDescription: message)
            }
            
            for (name, value) in attributes {
                att[name] = try APIAttribute(value: value)
            }
        }
        
        var rel: [String : APIRelationship] = [:]
        if let relationshipsObject = object["relationships"] {
            guard let relationships = relationshipsObject as? [String : Any] else {
                let message = "The value of the relationships key MUST be an object (a “relationships object”)"
                throw errorWithCode(.malformedDocument, localizedDescription: message)
            }
            
            for (name, relContent) in relationships {
                guard
                    let content = relContent as? [String : Any],
                    let data = content["data"] else
                {
                    let message = "Only relationships with data (resource linkage) is supported"
                    throw errorWithCode(.unsupported, localizedDescription: message)
                }
                
                if data is NSNull {
                    // Empty to-one relationship
                    rel[name] = APIRelationship(type: nil, value: .null)
                } else if let toOne = data as? [String : Any] {
                    let (relType, relId) = try processResourceObject(toOne)
                    rel[name] = APIRelationship(type: relType, value: .toOne(id: relId))
                } else if let toMany = data as? [[String : Any]] {
                    
                    var type: String?
                    var ids: [AnyHashable] = []
                    
                    for obj in toMany {
                        let (relType, relId) = try processResourceObject(obj)
                        if let type = type {
                            if type != relType {
                                let message = "Relationship '%@' includes objects of different types, which is not supported"
                                throw errorWithCode(.unsupported, localizedDescription: message)
                            }
                        } else {
                            type = relType
                        }
                        
                        ids.append(relId)
                    }
                    
                    rel[name] = APIRelationship(type: type, value: .toMany(ids: ids))
                } else {
                    let message = "Resource linkage MUST be represented as one of the following: (a) null for empty to-one relationships, (b) an empty array ([]) for empty to-many relationships. (c) a single resource identifier object for non-empty to-one relationships. (d) an array of resource identifier objects for non-empty to-many relationships."
                    throw errorWithCode(.malformedDocument, localizedDescription: message)
                }
            }
        }
        
        return APIObject(type: type, id: id, attributes: att, relationships: rel)
    }
    
    private func attribute(_ value: Any) throws -> APIAttribute {
        return try APIAttribute(value: value)
        /*
        if value is NSNull {
            return .null
            
        } else if value is Bool {
            return .boolean(value as! Bool)
        } else if let s = value as? String {
            return .string(s)
            
        } else if let b = value as? NSNumber {
            return .number(b)
            
        } else if let a = value as? [Any] {
            return .array(a)
            
        } else if let o = value as? [String : Any] {
            return .object(o)
        }
        
        fatalError()
 */
    }
    
    private func validateVersion(_ json: [String : Any]) throws {
        if let versionObject = json["jsonapi"] {
            guard let vo = versionObject as? [String : Any] else {
                let message = "The value of the jsonapi member MUST be an object (a “jsonapi object”)"
                throw errorWithCode(.malformedDocument, localizedDescription: message)
            }
            
            if let version = vo["version"] {
                guard let v = version as? String else {
                    let message = "The jsonapi object MAY contain a version member whose value is a string indicating the highest JSON API version supported"
                    throw errorWithCode(.malformedDocument, localizedDescription: message)
                }
                
                guard supportedVersions.contains(v) else {
                    let message = String(format: "Version '%@' of JSON API not supported", v)
                    throw errorWithCode(.unsupportedVersion, localizedDescription: message)
                }
            }
        }
    }
    
    private func processResourceObject(_ object: [String : Any]) throws -> (String ,String) {
        guard
            let typeObject = object["type"],
            let idObject = object["id"]
            else {
                let message = "Every resource object MUST contain an id member and a type member"
                throw errorWithCode(.malformedDocument, localizedDescription: message)
        }
        
        guard
            let type = typeObject as? String,
            let id = idObject as? String
            else {
                let message = "The values of the id and type members MUST be strings"
                throw errorWithCode(.malformedDocument, localizedDescription: message)
        }
        
        return (type, id)
    }
    
    private func parseErrors(_ json: [String : Any]) throws -> [Error]? {
        if let errorsObject = json["errors"] {
            
            guard let errors = errorsObject as? [[String : Any]] else {
                let message = "Error objects MUST be returned as an array keyed by errors in the top level of a JSON API document."
                throw errorWithCode(.malformedDocument, localizedDescription: message)
            }
            
            guard json["data"] == nil else {
                let message = "The members data and errors MUST NOT coexist in the same document"
                throw errorWithCode(.malformedDocument, localizedDescription: message)
            }
            
            var result: [Error] = []
            for error in errors {
                result.append(serverError(error, domain: domain))
            }
            
            return result
        } else {
            return nil
        }
    }
    
    fileprivate func serverError(_ error: [String : Any], domain: String?) -> NSError {
        
        var userInfo = error
        
        if let title = error["title"] as? String {
            userInfo[NSLocalizedDescriptionKey] = title
        }
        
        return NSError(domain: domain ?? "unspecified",
                       code: ErrorCode.serverError.rawValue,
                       userInfo: userInfo)
    }
    
    fileprivate func errorWithCode(_ code: ErrorCode, localizedDescription: String) -> NSError {
        return NSError(domain: "Parsec.JSONAPIParser",
                       code: code.rawValue,
                       userInfo: [NSLocalizedDescriptionKey : localizedDescription])
    }
}

