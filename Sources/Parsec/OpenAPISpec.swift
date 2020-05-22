//
//  OpenAPISpec.swift
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
import CoreData

public struct Template {
    struct Info {
        struct License {
            let name: String?
            let url: String?
        }

        let title: String?
        let desc: String?
        let version: String?
        let termsOfService: String?
        let contact: String?
        let license: License?
    }

    let info: Info?
    let host: String?
    let basePath: String?
    let schemes: [String]?
}

public enum OpenAPISpecErrorCode: Int {
    case unsupportedType
    case multipleIds
    case noRemoteIdFound
    case noEndpoints
}

public class OpenAPISpec {

    private var model: NSManagedObjectModel
    private let remoteNaming: NamingConvention
    private let defaultIdNames: [String]
    private let template: Template?

    public init(model: NSManagedObjectModel, template: Template?, options: [OptionKey: Any]? = nil) throws {
        self.model = model
        self.remoteNaming = options?[.remoteNaming] as? NamingConvention ?? .hyphen
        self.defaultIdNames = (options?[.remoteIdNames] as? [String]) ?? ["id", "remoteId"]
        self.template = template
    }

    public func generate() throws -> String {
        var result: [String] = ["swagger: '2.0'"]

        result.append(contentsOf: try info())
        result.append(contentsOf: try host())
        result.append(contentsOf: try basePath())
        result.append(contentsOf: try tags())
        result.append(contentsOf: try schemes())
        result.append(contentsOf: try paths())
        result.append(contentsOf: try definitions())
        result.append(contentsOf: try responses())
        return result.joined(separator: "\n")
    }

    // MARK: - Info object methods
    private func info() throws -> [String] {
        var result: [String] = ["info:"]

        result.append("  title: '\(template?.info?.title ?? "TODO")'")
        result.append("  description: '\(template?.info?.desc ?? "TODO")'")
        result.append("  version: '\(template?.info?.version ?? "0.0.0")'")
        result.append("  termsOfService: '\(template?.info?.termsOfService ?? "TODO")'")
        result.append("  contact:")
        result.append("    email: '\(template?.info?.contact ?? "me@you.com")'")
        result.append("  license:")
        result.append("    name: '\(template?.info?.license?.name ?? "TODO")'")
        result.append("    url: '\(template?.info?.license?.url ?? "http://todo.com")'")
        return result
    }

    // MARK: - Host object methods
    private func host() throws -> [String] {
        return ["host: '\(template?.host ?? "TODO")'"]
    }

    // MARK: - Base Path object methods
    private func basePath() throws -> [String] {
        return ["basePath: '\(template?.basePath ?? "/")'"]
    }

    // MARK: - Tags object methods
    private func tags() throws -> [String] {
        var result: [String] = ["tags:"]

        for (_, entity) in model.entitiesByName {
            guard let endpoint = entity.userInfo?[UserInfoKey.endpoint.rawValue] as? String else {
                continue
            }

            let remoteName = (entity.userInfo?[UserInfoKey.remoteName.rawValue] as? String) ?? remoteNaming.from(entity.name!)
            result.append("- name: '\(endpoint)'")
            result.append("  description: 'This endpoint gives access to `\(remoteName)` resources'")
        }

        return result
    }

    // MARK: - Schemes object methods
    private func schemes() throws -> [String] {
        guard let schemes = template?.schemes else {
            return []

        }

        var result: [String] = ["schemes:"]

        for s in schemes {
            result.append("- '\(s)'")
        }
        return result
    }

    // MARK: - Paths object methods

    private func paths() throws -> [String] {
        var result: [String] = ["paths:"]

        for (_, entity) in model.entitiesByName {

            guard let endpoint = entity.userInfo?[UserInfoKey.endpoint.rawValue] as? String else {
                continue
            }

            guard let operations = entity.userInfo?[UserInfoKey.operations.rawValue] as? String else {
                continue
            }

            var supports: [String] = []

            for o in operations.lowercased() {
                switch o {
                case "c":
                    supports.append("post")

                case "r":
                    supports.append("get")

                case "u":
                    supports.append("patch")

                case "d":
                    supports.append("delete")

                default:
                    break
                }
            }

            guard supports.count > 0 else {
                continue
            }

            let remoteName = (entity.userInfo?[UserInfoKey.remoteName.rawValue] as? String) ?? remoteNaming.from(entity.name!)

            if supports.contains("get") || supports.contains("post") {
                if supports.contains("get") {
                    result.append("  /\(endpoint):")
                    result.append("    get:")
                    result.append("      tags:")
                    result.append("      - '\(endpoint)'")
                    result.append("      summary: 'Lists \(remoteName) resources'")
                    result.append("      produces:")
                    result.append("      - 'application/vnd.api+json'")
                    result.append("      responses:")
                    result.append("        200:")
                    result.append("          $ref: '#/responses/successful_\(endpoint)_index'")
                    result.append("        400:")
                    result.append("          $ref: '#/responses/bad_request_error'")
                    result.append("        401:")
                    result.append("          $ref: '#/responses/unauthorized_error'")
                }
                if supports.contains("post") {
                    result.append("    post:")
                    result.append("      tags:")
                    result.append("      - '\(endpoint)'")
                    result.append("      summary: 'Creates a \(remoteName) resource'")
                    result.append("      produces:")
                    result.append("      - 'application/vnd.api+json'")
                    result.append("      parameters:")
                    result.append("      - in: body")
                    result.append("        name: data")
                    result.append("        schema:")
                    result.append("          $ref: '#/definitions/\(remoteName)'")
                    result.append("      responses:")
                    result.append("        200:")
                    result.append("          $ref: '#/responses/successful_\(remoteName)'")
                    result.append("        400:")
                    result.append("          $ref: '#/responses/bad_request_error'")
                    result.append("        401:")
                    result.append("          $ref: '#/responses/unauthorized_error'")
                    result.append("        404:")
                    result.append("          $ref: '#/responses/not_found_error'")
                }
            }

            if supports.contains("get") || supports.contains("patch") || supports.contains("delete") {
                let parameter = "\(remoteName)Id"
                result.append("  /\(endpoint)/{\(parameter)}:")

                if supports.contains("get") {
                    result.append("    get:")
                    result.append("      tags:")
                    result.append("      - '\(endpoint)'")
                    result.append("      summary: 'Return a single \(remoteName) resource'")
                    result.append("      produces:")
                    result.append("      - 'application/vnd.api+json'")
                    result.append("      parameters:")
                    result.append("      - name: '\(parameter)'")
                    result.append("        in: 'path'")
                    result.append("        description: 'Id of \(remoteName)'")
                    result.append("        required: true")
                    result.append("        type: string")
                    result.append("      responses:")
                    result.append("        200:")
                    result.append("          $ref: '#/responses/successful_\(remoteName)'")
                    result.append("        400:")
                    result.append("          $ref: '#/responses/bad_request_error'")
                    result.append("        401:")
                    result.append("          $ref: '#/responses/unauthorized_error'")
                    result.append("        404:")
                    result.append("          $ref: '#/responses/not_found_error'")
                }

                if supports.contains("patch") {
                    result.append("    patch:")
                    result.append("      tags:")
                    result.append("      - '\(endpoint)'")
                    result.append("      summary: 'Updates an existing \(remoteName) resource'")
                    result.append("      produces:")
                    result.append("      - 'application/vnd.api+json'")
                    result.append("      parameters:")
                    result.append("      - name: '\(parameter)'")
                    result.append("        in: 'path'")
                    result.append("        description: 'Id of \(remoteName)'")
                    result.append("        required: true")
                    result.append("        type: string")
                    result.append("      - in: body")
                    result.append("        name: data")
                    result.append("        schema:")
                    result.append("          $ref: '#/definitions/\(remoteName)'")
                    result.append("      responses:")
                    result.append("        200:")
                    result.append("          $ref: '#/responses/successful_\(remoteName)'")
                    result.append("        400:")
                    result.append("          $ref: '#/responses/bad_request_error'")
                    result.append("        401:")
                    result.append("          $ref: '#/responses/unauthorized_error'")
                    result.append("        404:")
                    result.append("          $ref: '#/responses/not_found_error'")
                }

                if supports.contains("delete") {
                    result.append("    delete:")
                    result.append("      tags:")
                    result.append("      - '\(endpoint)'")
                    result.append("      summary: 'Deletes an existing \(remoteName) resource'")
                    result.append("      produces:")
                    result.append("      - 'application/vnd.api+json'")
                    result.append("      parameters:")
                    result.append("      - name: '\(parameter)'")
                    result.append("        in: 'path'")
                    result.append("        description: 'Id of \(remoteName)'")
                    result.append("        required: true")
                    result.append("        type: string")
                    result.append("      responses:")
                    result.append("        204:")
                    result.append("          description: 'The resource was succesfully deleted.'")
                    result.append("        400:")
                    result.append("          $ref: '#/responses/bad_request_error'")
                    result.append("        401:")
                    result.append("          $ref: '#/responses/unauthorized_error'")
                    result.append("        404:")
                    result.append("          $ref: '#/responses/not_found_error'")
                }
            }

        }

        if result.count == 1 {
            throw errorWithCode(.noEndpoints, localizedDescription: "No endpoints defined")
        } else {
            return result
        }
    }

    // MARK: - Definitions object methods

    private func definitions() throws -> [String] {
        var result: [String] = ["definitions:"]

        result.append("  jsonapi:")
        result.append("    type: object")
        result.append("    required: ['version']")
        result.append("    properties:")
        result.append("      version:")
        result.append("        type: string")
        result.append("        enum:")
        result.append("        - '1.0'")

        result.append("  meta:")
        result.append("    type: object")
        result.append("    required: ['total', 'total-pages']")
        result.append("    properties:")
        result.append("      total:")
        result.append("        type: integer")
        result.append("        description: 'Total number of results for the request'")
        result.append("      total-pages:")
        result.append("        type: integer")
        result.append("        description: 'Total number of pages for the request'")

        result.append("  links:")
        result.append("    type: object")
        result.append("    properties:")
        result.append("      first:")
        result.append("        type: string")
        result.append("        format: url")
        result.append("        description: 'the first page of data'")
        result.append("      prev:")
        result.append("        type: string")
        result.append("        format: url")
        result.append("        description: 'the previous page of data'")
        result.append("      next:")
        result.append("        type: string")
        result.append("        format: url")
        result.append("        description: 'the next page of data'")
        result.append("      last:")
        result.append("        type: string")
        result.append("        format: url")
        result.append("        description: 'the last page of data'")

        for (_, entity) in model.entitiesByName {
            let lines = try entityDefinition(entity, indent: 2)
            result.append(contentsOf: lines)
        }
        return result
    }

    private func remoteId(_ entity: NSEntityDescription) throws -> NSAttributeDescription {
        var result: NSAttributeDescription?
        for (_, attribute) in entity.attributesByName {

            guard ((attribute.userInfo?[UserInfoKey.ignore.rawValue] as? String) ?? "false") != "true" else {
                continue
            }

            let isRemoteId = (attribute.userInfo?[UserInfoKey.isRemoteId.rawValue] as? String) ?? "false"
            if defaultIdNames.contains(attribute.name) || isRemoteId == "true" {
                if let result = result {
                    let message = String(format: "Mutliple remote ids '%@' for entity '%@'", [attribute.name, result.name].joined(separator: ", "), entity.name!)
                    throw errorWithCode(.multipleIds, localizedDescription: message)
                }
                result = attribute
                break
            }
        }

        guard let remoteId = result else {
            let message = String(format: "No remote id found for entity '%@'", entity.name!)
            throw errorWithCode(.noRemoteIdFound, localizedDescription: message)
        }

        return remoteId
    }

    private func entityDefinition(_ entity: NSEntityDescription, indent: Int = 0) throws -> [String] {
        var result: [String] = []

        guard (entity.userInfo?[UserInfoKey.ignore.rawValue] as? String) ?? "false" != "true" else {
            return []
        }

        let rId = try remoteId(entity)

        let remoteName = (entity.userInfo?[UserInfoKey.remoteName.rawValue] as? String) ?? remoteNaming.from(entity.name!)
        result.append("\(remoteName):")
        result.append("  type: object")
        result.append("  required: ['id', 'type']")
        result.append("  properties:")
        result.append(contentsOf: try rio(entity, indent: 4))

        // Attributes
        var attributeLines: [String] = []
        for (_, attribute) in entity.attributesByName {
            if rId == attribute {
                continue
            }

            let lines = try attributeDefinition(attribute, indent: 8)
            attributeLines.append(contentsOf: lines)
        }

        if attributeLines.count > 0 {
            result.append("    attributes:")
            result.append("      type: object")
            result.append("      properties:")
            result.append(contentsOf: attributeLines)
        }

        // Relationships
        var relationshipLines: [String] = []
        for (_, relationship) in entity.relationshipsByName {
            let lines = try relationshipDefinition(relationship, indent: 8)
            relationshipLines.append(contentsOf: lines)
        }

        if relationshipLines.count > 0 {
            result.append("    relationships:")
            result.append("      type: object")
            result.append("      properties:")
            result.append(contentsOf: relationshipLines)
        }

        return result.map({ (line) -> String in
            return line.indent(indent)
        })
    }

    private func attributeDefinition(_ attribute: NSAttributeDescription, indent: Int = 0) throws -> [String] {

        guard (attribute.userInfo?[UserInfoKey.ignore.rawValue] as? String) ?? "false" != "true" else {
            return []
        }

        var result: [String] = []

        let remoteName = (attribute.userInfo?[UserInfoKey.remoteName.rawValue] as? String) ?? remoteNaming.from(attribute.name)
        let (type, format) = try typeAndFormat(attribute.attributeType)
        result.append("\(remoteName):")
        result.append("  type: \(type)")

        if let format = format {
            result.append("  format: \(format)")
        }

        return result.map({ (line) -> String in
            return line.indent(indent)
        })
    }

    private func relationshipDefinition(_ relationship: NSRelationshipDescription, indent: Int = 0) throws -> [String] {

        guard (relationship.userInfo?[UserInfoKey.ignore.rawValue] as? String) ?? "false" != "true" else {
            return []
        }

        var result: [String] = []

        let remoteName = (relationship.userInfo?[UserInfoKey.remoteName.rawValue] as? String) ?? remoteNaming.from(relationship.name)

        result.append("\(remoteName):")
        result.append("  type: object")
        result.append("  description: 'TODO'")
        result.append("  properties:")
        result.append("    data:")

        if relationship.isToMany {
            result.append("      type: array")
            result.append("      items:")
            result.append("        required: ['id', 'type']")
            result.append("        properties:")
            result.append(contentsOf: try rio(relationship.destinationEntity!, indent: 10))
        } else {
            result.append("      type: object")
            result.append("      required: ['id', 'type']")
            result.append("      properties:")
            result.append(contentsOf: try rio(relationship.destinationEntity!, indent: 8))
        }

        return result.map({ (line) -> String in
            return line.indent(indent)
        })
    }

    private func rio(_ entity: NSEntityDescription, indent: Int = 0) throws -> [String] {
        var result: [String] = []

        let remoteName = (entity.userInfo?[UserInfoKey.remoteName.rawValue] as? String) ?? remoteNaming.from(entity.name!)

        result.append("id:")
        result.append("  type: string")
        result.append("type:")
        result.append("  type: string")
        result.append("  enum:")
        result.append("  - '\(remoteName)'")

        return result.map({ (line) -> String in
            return line.indent(indent)
        })
    }

    private func typeAndFormat(_ attributeType: NSAttributeType) throws -> (String, String?) {

        switch attributeType {
        case .integer16AttributeType: return ("integer", nil)
        case .integer32AttributeType: return ("integer", "int32")
        case .integer64AttributeType: return ("integer", "int64")
        case .decimalAttributeType: return ("number", "double")
        case .doubleAttributeType: return ("number", "double")
        case .floatAttributeType: return ("number", "float")
        case .stringAttributeType: return ("string", nil)
        case .booleanAttributeType: return ("boolean", nil)
        case .dateAttributeType: return ("string", "date-time")
        case .binaryDataAttributeType: return ("string", "binary")
        case .UUIDAttributeType: return ("string", nil)
        case .URIAttributeType: return ("string", "url")
        default:
            throw errorWithCode(.unsupportedType, localizedDescription: "Unsupported attribute type")
        }
    }

    // MARK: - Responses object methods

    private func responses() throws -> [String] {
        var result: [String] = ["responses:"]

        result.append(contentsOf: response("unauthorized_error", description: "API key is missing or invalid"))
        result.append(contentsOf: response("not_found_error", description: "The resource was not found"))
        result.append(contentsOf: response("bad_request_error", description: "The request could not be understood by the server due to malformed syntax"))

        result.append(contentsOf: response("forbidden_request_error", description: "The request was valid, but the server is refusing action. The user might not have the necessary permissions for a resource, or may need an account of some sort."))

        for (_, entity) in model.entitiesByName {
            let lines = try response(entity, indent: 2)
            result.append(contentsOf: lines)
        }
        return result
    }

    private func response(_ name: String, description: String) -> [String] {
        var result: [String] = []

        result.append("  \(name):")
        result.append("    description: '\(description)'")
        return result
    }

    private func response(_ entity: NSEntityDescription, indent: Int = 0) throws -> [String] {

        guard let endpoint = entity.userInfo?[UserInfoKey.endpoint.rawValue] as? String else {
            return []
        }

        let remoteName = (entity.userInfo?[UserInfoKey.remoteName.rawValue] as? String) ?? remoteNaming.from(entity.name!)
        var result: [String] = ["successful_\(endpoint)_index:"]

        result.append("  description: 'successful operation [\(endpoint) index]'")
        result.append("  schema:")
        result.append("    type: object")
        result.append("    required: ['data']")
        result.append("    properties:")
        result.append("      jsonapi:")
        result.append("        $ref: '#/definitions/jsonapi'")
        result.append("      meta:")
        result.append("        $ref: '#/definitions/meta'")
        result.append("      data:")
        result.append("        type: array")
        result.append("        items:")
        result.append("          $ref: '#/definitions/\(remoteName)'")
        result.append("      links:")
        result.append("        $ref: '#/definitions/links'")

        result.append("successful_\(remoteName):")
        result.append("  description: 'successful operation [\(remoteName)]'")
        result.append("  schema:")
        result.append("    type: object")
        result.append("    required: ['data']")
        result.append("    properties:")
        result.append("      jsonapi:")
        result.append("        $ref: '#/definitions/jsonapi'")
        result.append("      data:")
        result.append("        $ref: '#/definitions/\(remoteName)'")

        return result.map({ (line) -> String in
            return line.indent(indent)
        })
    }
}

extension String {
    func indent(_ count: Int) -> String {
        var result = ""

        for _ in 0..<count {
            result.append(" ")
        }

        result.append(self)

        return result
    }
}

private func errorWithCode(_ code: OpenAPISpecErrorCode, localizedDescription: String) -> NSError {
    return NSError(domain: "Parsec.OpenAPISpec",
                   code: code.rawValue,
                   userInfo: [NSLocalizedDescriptionKey: localizedDescription])
}
