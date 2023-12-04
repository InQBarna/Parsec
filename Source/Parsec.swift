//
// Parsec.swift
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

/// Options that can be passed when initializing `Parsec`.
/// - remoteNaming:     Use a `NamingConvention`. If not specified, it defaults to `snakeCase`.
/// - remoteIdNames:    `[String]` with the name(s) of the resource id field in the JSON domain. 'id' and 'remoteId' are used by default.
/// - serializers:       A `[String : Serializer]` dictionary containing all serializers used in the model.
/// - defaultDateSerializer:    The `Serializer` that will be used when parsing `Date` objects (if no custom Serializer is set in the attribute). Defaults to `ISO8601DateSerializer`.
/// - defaultDataSerializer:       The `Serializer` that will be used when parsing `Data` objects (if no custom Serializer is set in the attribute). Defaults to `Base64DataSerializer`.
public enum OptionKey: String {
    case remoteNaming
    case remoteIdNames
    case serializers
    case defaultDateSerializer
    case defaultDataSerializer
}

/// `UserInfoKey` defines a set of keys that can be used in the `Entity`, `Attribute` and `Relationship` *User Info* section of the Core Data Modelling tool.
/// - isRemoteId:   Set it to *"true"* to mark the attribute as the *id* of the entity.
/// - remoteName:   Set the name of the entity/attribute/relationship for those cases where the general naming convention does not work.
/// - ignore:       Set it to *"true"* to mark the entity/attribute/relationship as a client side only. Parsec will ignore it when serializing/deserializing.
/// - serializer:   Set a serializer name that will be used to serialize/deserialize the attribute. The `Serializer` object has to be provided when initializing `Parsec` via the `serializers` `OptionKey`.
/// - endpoint:     TODO.
/// - operations:   TODO.
public enum UserInfoKey: String {
    case isRemoteId = "parsec.isRemoteId"
    case remoteName = "parsec.remoteName"
    case ignore = "parsec.ignore"
    case serializer = "parsec.serializer"
    case endpoint = "parsec.endpoint"
    case operations = "parsec.operations"
}

/// `NamingConvention` defines how NSManagedObject domain names (camelCase) to are converted to JSON domain names.
/// - none:         Uses the same name in both domains.
/// - snakeCase:    Converts names to snake_case notation.
/// - hyphen:       Converts names using hyphen as word separator (OneTwo -> one-two).
public enum NamingConvention: String {
    case none
    case snakeCase
    case hyphen

    /// Returns the `name` converted to the naming convetion..
    /// - parameter name:     The name to be converted.
    /// - returns: The converted name as `String`.
    public func from(_ name: String) -> String {
        switch self {
        case .none: return name
        case .snakeCase: return name.snakeCased() ?? name
        case .hyphen: return name.hyphenized() ?? name
        }
    }
}

/// `SerializerErrorCode` is the recommended error code thrown by `Serializer` objects.
/// - unexpectedObject:     The input object/value type was not the expected by the serializer. See the error message for more detail.
/// - failed:               The serializer failed. See the error message for more detail.
public enum SerializerErrorCode: Int {
    case unexpectedObject
    case failed

    /// Returns an `NSError` with the given `message` as localized description and the `SerializerErrorCode` code.
    /// - parameter message:     The description of the error.
    /// - returns: An `NSError`.
    public func error(_ message: String) -> NSError {
        return NSError(domain: "Parsec.Serializer", code: self.rawValue, userInfo: [NSLocalizedDescriptionKey: message])
    }
}

/// The protocol in which all custom serializers must conform to in order to serialize/deserialize a values from/to JSON domain.
public protocol Serializer {
    /// Deserializes a JSON domain value into a NSManagedObject domain value. Note that `nil` is a valid output value.
    /// - parameter value:  The JSON domain value to be deserialized.
    /// - returns: An `Any` or `nil`.
    func deserialize(_ value: APIAttribute) throws -> Any?

    /// Serializes a NSManagedObject domain value into a JSON domain value.
    /// - parameter value:  The NSManagedObject domain value to be serialized.
    /// - returns: An `Any`.
    func serialize(_ object: Any) throws -> APIAttribute
}

/// The protocol in which parsers must conform to in order to deserialize/serialize values from/to API domain.
public protocol APIParser: AnyObject {
    /// Parses the API response (`json`) into a `APIDocument`.
    /// - parameter json:  The API response to be parsed.
    /// - returns: An `APIDocument`.
    func parse(json: [String: Any]) throws -> APIDocument

    /// Converts an `APIObject` into a JSON object.
    /// - parameter object:  The API object to be converted.
    /// - returns: An dictionary (`[String : Any]`).
    func json(object: APIObject) throws -> [String: Any]
}

/// Document containing the parsed API. This structure is based on the JSONAPI spec but is still generic enough to allow most Rest API responses to be parsed into such document.
public struct APIDocument {
    /// An array of `APIObject` or `nil` if there are errors. These objects are the main payload of the API response.
    public let data: [APIObject]?

    /// An array of `APIObject` or `nil` if there are errors. These objects are referenced by the objects in `data`.
    public let included: [APIObject]?

    /// An array of `Error` or `nil`. These errors are server side errors. A document with errors is still a valid document.
    public let errors: [Error]?

    /// An dictionary containing side information (i.e. pagination).
    public let meta: [String: Any]?

    public init(data: [APIObject]?, included: [APIObject]?, errors: [Error]?, meta: [String: Any]?) {
        self.data = data
        self.included = included
        self.errors = errors
        self.meta = meta
    }
}

/// Contains the information of one API object or resource.
public struct APIObject {
    /// API domain name of the resource.
    public let type: String

    /// API domain object id.
    public let id: AnyHashable?

    /// Dictionary containig the attributes of the object.
    public let attributes: [String: APIAttribute]

    /// Dictionary containig the relationships of the object.
    public let relationships: [String: APIRelationship]

    public init(type: String, id: AnyHashable?, attributes: [String: APIAttribute], relationships: [String: APIRelationship]) {
        self.type = type
        self.id = id
        self.attributes = attributes
        self.relationships = relationships
    }
}

/// Holds the value of one API object attribute. As *Parsec* is based on JSON, the valid values are those supported in JSON.
/// - string:   A string.
/// - number:   A number (integer, float,…).
/// - object:   A JSON object.
/// - array:    An array of JSON values.
/// - boolean:  A `Boolean`.
/// - null:     A `nil`.
public enum APIAttribute {
    case string(String)
    case number(NSNumber)
    case object([String: Any])
    case array([Any])
    case boolean(Bool)
    case null

    /// Creates a `APIAttribute`.
    /// - parameter value:  The value to be converted.
    /// - returns: An `APIAttribute`.
    public init(value: Any) throws {

        if value is NSNull {
            self = .null

        } else if let string = value as? String {
            self = .string(string)

        } else if let number = value as? NSNumber {
            let numberType = CFNumberGetType(number)
            switch numberType {
            case .charType: self = .boolean(number.boolValue)
            default: self = .number(number)
            }

        } else if let array = value as? [Any] {
            self = .array(array)

        } else if let object = value as? [String: Any] {
            self = .object(object)
        } else {
            throw NSError(domain: "Parsec.APIAttribute", code: 1, userInfo: [NSLocalizedDescriptionKey: String(format: "Unsupported value '%@'", (value as AnyObject).debugDescription)])
        }
    }

    /// Returns the value held in the `APIAttribute`.
    public var value: Any {
        switch self {
        case .string(let s): return s
        case .number(let n): return n
        case .object(let o): return o
        case .array(let a): return a
        case .boolean(let b): return b
        case .null: return NSNull()
        }
    }

    public var description: String {
        switch self {
        case .string: return "string"
        case .number: return "number"
        case .object: return "object"
        case .array: return "array"
        case .boolean: return "boolean"
        case .null: return "null"
        }
    }

}

/// Describes the relationship between API objects.
public struct APIRelationship {

    /// The value of the relationship can be either:
    /// - null:     Empty relationship. Used only in empty *to-one* relationships.
    /// - toOne:    To-one relationship. Holds the *id* of the related object.
    /// - toMany:   To-many relationship. Holds the array of *id*s of the related objects. Use an empty array to describe an empty *to-many* relationship.
    public enum Value {
        case null
        case toOne(id: AnyHashable)
        case toMany(ids: [AnyHashable])
    }

    /// Name of the destination resource name.
    public let type: String?

    /// The value of the relationship.
    public let value: Value

    public init(type: String?, value: Value) {
        self.type = type
        self.value = value
    }
}

/// *Parsec*
public class Parsec {

    public let parser: APIParser
    public let naming: NamingConvention
    public let serializers: [String: Serializer]
    public let defaultDateSerializer: Serializer
    public let defaultDataSerializer: Serializer
    public let defaultIdNames: [String]
    public var logger: Logger?

    private(set) var entitiesByName: [String: EntitySerializer]
    private(set) var entitiesByType: [String: EntitySerializer]

    internal let defaultSerializers: [NSAttributeType: Serializer]

    /// Initializes a `Parsec` instance.
    ///
    /// - parameter model:      The `NSManagedObjectModel` that describes your data model.
    /// - parameter parser:     The parser that is able to work with the API. By default a JSONAPI compliant parser is used.
    /// - parameter options:    Options for creating the `Parsec` instance. See `OptionKey`.
    public init(model: NSManagedObjectModel, parser: APIParser? = nil, options: [OptionKey: Any]? = nil) throws {

        self.parser = parser ?? JSONAPIParser()

        naming = ((options?[OptionKey.remoteNaming]) as? NamingConvention) ?? .snakeCase
        serializers = ((options?[OptionKey.serializers]) as? [String: Serializer]) ?? [:]
        defaultIdNames = ((options?[OptionKey.remoteIdNames]) as? [String]) ?? ["id", "remoteId"]
        defaultDateSerializer = ((options?[OptionKey.defaultDateSerializer]) as? Serializer) ?? ISO8601DateSerializer()
        defaultDataSerializer = ((options?[OptionKey.defaultDataSerializer]) as? Serializer) ?? Base64DataSerializer()

        var defaultSerializers: [NSAttributeType: Serializer] = [.integer16AttributeType: Int16Serializer(),
                                                                 .integer32AttributeType: Int32Serializer(),
                                                                 .integer64AttributeType: Int64Serializer(),
                                                                 .decimalAttributeType: DecimalSerializer(),
                                                                 .doubleAttributeType: DoubleSerializer(),
                                                                 .floatAttributeType: FloatSerializer(),
                                                                 .stringAttributeType: StringSerializer(),
                                                                 .booleanAttributeType: BooleanSerializer(),
                                                                 .dateAttributeType: defaultDateSerializer,
                                                                 .binaryDataAttributeType: defaultDataSerializer]
        if #available(iOS 11.0, *) {
            defaultSerializers[.UUIDAttributeType] = UUIDSerializer()
            defaultSerializers[.URIAttributeType] = URISerializer()
        }

        self.defaultSerializers = defaultSerializers

        self.entitiesByName = [:]
        self.entitiesByType = [:]

        var entitiesByName: [String: EntitySerializer] = [:]
        var entitiesByType: [String: EntitySerializer] = [:]
        for (name, entity) in model.entitiesByName {
            guard ((entity.userInfo?[UserInfoKey.ignore.rawValue] as? String) ?? "false") != "true" else {
                continue
            }

            let entitySerializer = try EntitySerializer(entity: entity, parsec: self)
            entitiesByName[name] = entitySerializer
            entitiesByType[entitySerializer.remoteName] = entitySerializer
        }

        self.entitiesByName = entitiesByName
        self.entitiesByType = entitiesByType
    }

    /// Updates a `NSManagedObjectContext` with the objects described in the API response.
    ///
    /// The update is done without performing any `save` operation on the context. Also, only the attributes/relationships that have changed are modified. This means that for instance, if the object description from the API matches the content of the context, after the update, the context will be untouched.
    ///
    /// - parameter context:    The `NSManagedObjectContext` to be updated.
    /// - parameter json:       The API response to be processed.
    public func update(_ context: NSManagedObjectContext, with json: [String: Any]) throws {
        let document = try parser.parse(json: json)
        try update(context, with: document)
    }

    /// Updates a `NSManagedObjectContext` with the objects described in the document.
    ///
    /// The update is done without performing any `save` operation on the context. Also, only the attributes/relationships that have changed are modified. This means that for instance, if the object description from the API matches the content of the context, after the update, the context will be untouched.
    ///
    /// - parameter context:    The `NSManagedObjectContext` to be updated.
    /// - parameter document:   The API document to be processed.
    public func update(_ context: NSManagedObjectContext, with document: APIDocument) throws {
        let objects = try deserialize(document: document)
        let updater = ContextUpdater(context: context)
        try updater.update(changes: objects)
    }

    /// Creates an API representation of an object.
    /// - parameter object:     A `NSManagedObject`.
    /// - returns: A dictionary with the API representation of the object.
    public func json(_ object: NSManagedObject) throws -> [String: Any] {
        guard let entityName = object.entity.name else {
            let message = String(format: "Entity of class '%@' has no name", object.entity.managedObjectClassName)
            throw EntitySerializerErrorCode.missingName.error(message)

        }
        guard let serializer = entitiesByName[entityName] else {
            let message = String(format: "No serializer found for entity '%@'", entityName)
            throw EntitySerializerErrorCode.unknownEntity.error(message)
        }

        let objectData = try objectDataFor(object, serializer: serializer)
        let apiObject = try serializer.serialize(objectData)
        return try parser.json(object: apiObject)
    }

    /// Returns an NSManagedObject from Context given its RemoteID and RemoteName
    /// - parameter remoteID:     A `String` representing the id of the object.
    /// - parameter remoteName:   A `String` representing the API name of the resource.
    /// - parameter context:      The `NSManagedObjectContext` we want to request the object from.
    /// - returns:                (Optional)The `NSManagedObject` or nil if no object for the given id is found.
    public func managedObject(with remoteID: AnyHashable, remoteName: String, context: NSManagedObjectContext) throws -> NSManagedObject? {

        guard let serializer = entitiesByType[remoteName] else {
            let message = String(format: "No serializer found for remote name '%@'", remoteName)
            throw EntitySerializerErrorCode.unknownType.error(message)
        }

        let fr: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: serializer.name)
        fr.predicate = NSPredicate(format: "id IN %@", [remoteID])

        do {
            let managedObjects = try context.fetch(fr)

            guard managedObjects.count <= 1 else {
                throw NSError(domain: "Parsec.Parsec", code: 1, userInfo: [NSLocalizedDescriptionKey: "Multiple objects with remoteId '\(remoteID)' and type '\(remoteName)'"])
            }

            return managedObjects.first
        } catch {
            throw error
        }
    }

    /// Returns an NSManagedObject array from Context given an APIObject array keeping the same order
    /// - parameter apiObjects:   A `[APIObject]` representing the list of  `APIObject` returned from the API.
    /// - parameter context:      The `NSManagedObjectContext` we want to request the objects from.
    /// - returns:                A `[NSManagedObject]`, empty if APIObjects is empty, order by apiObjects array id order.
    public func managedObjectsFrom(_ apiObjects: [APIObject], context: NSManagedObjectContext) throws -> [NSManagedObject] {

        let apiObjectsIDs: [AnyHashable] = try apiObjects.map {
            guard let remoteId = $0.id else {
                throw NSError(domain: "Parsec.Parsec", code: 2, userInfo: [NSLocalizedDescriptionKey: "APIObject (type '\($0.type)') without valid 'id'"])
            }
            return remoteId
        }

        guard let apiObject = apiObjects.first else {
            return [NSManagedObject]()
        }

        guard let serializer = entitiesByType[apiObject.type] else {
            let message = String(format: "No serializer found for type '%@'", apiObject.type)
            throw EntitySerializerErrorCode.unknownType.error(message)
        }

        let fr: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: serializer.name)
        fr.predicate = NSPredicate(format: "id IN %@", apiObjectsIDs)

        let managedObjects = try context.fetch(fr)
        try context.obtainPermanentIDs(for: managedObjects)

        guard apiObjectsIDs.count == managedObjects.count else {
            let apiName = apiObjects.first?.type ?? "unknown"
            let managedName = managedObjects.first?.entity.name ?? "unknown"
            throw NSError(domain: "Parsec.Parsec", code: 3, userInfo: [NSLocalizedDescriptionKey: "APIObjects (\(apiObjectsIDs.count) \(apiName)) array and ManagedObjects (\(managedObjects.count) \(managedName)) retrieved must contains the same number of items"])
        }

        let map: [AnyHashable: NSManagedObject] = try managedObjects.reduce([:]) { (res, obj) -> [AnyHashable: NSManagedObject] in
            guard let remoteID = obj.value(forKey: "id") as? AnyHashable else {
                throw NSError(domain: "Parsec.Parsec", code: 4, userInfo: [NSLocalizedDescriptionKey: "Stored ManagedObject without valid 'id'"])
            }

            return res.merging([remoteID: obj]) { (obj1, obj2) -> NSManagedObject in
                obj1
            }
        }

        let result = try apiObjectsIDs.map { (remoteId) -> NSManagedObject in
            guard let obj = map[remoteId] else {
                throw NSError(domain: "Parsec.Parsec", code: 5, userInfo: [NSLocalizedDescriptionKey: "Missing object with 'id'='\(remoteId)'"])
            }

            return obj
        }

        return result
    }

    func deserialize(document: APIDocument) throws -> [ObjectData] {

        var objects = document.included ?? []
        if let data = document.data {
            objects.append(contentsOf: data)
        }

        var result: [ObjectData] = []

        for object in objects {
            guard let entity = entitiesByType[object.type] else {
                let message = String(format: "No entity found for remote type '%@'", object.type)
                throw EntitySerializerErrorCode.unknownType.error(message)
            }

            let cs = try entity.deserialize(object)
            result.append(cs)
        }

        return result
    }

    private func objectDataFor(_ managedObject: NSManagedObject, serializer: EntitySerializer) throws -> ObjectData {
        var attributes: [String: Any?] = [:]
        for (name, _) in serializer.attributesByName {
            attributes[name] = managedObject.value(forKey: name)
        }

        var relationships: [String: RelationshipData] = [:]

        for (name, relationship) in serializer.relationshipsByName {
            relationships[name] = RelationshipData(entitySerializer: relationship.destination,
                                                   value: managedObject.value(forKey: name))
        }

        let id = managedObject.value(forKey: serializer.idAttribute.name) as? AnyHashable

        return ObjectData(id: id,
                          entitySerializer: serializer,
                          attributes: attributes,
                          relationships: relationships)
    }
}
