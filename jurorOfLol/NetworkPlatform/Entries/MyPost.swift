//
//  MyPost.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/06/06.
//

import Foundation

public struct MyPost: Encodable {
    let userId: String
    
    public init(userId: String) {
        self.userId = userId
    }
    
    private enum runQueryKeys: String, CodingKey {
        case structuredQuery
    }
    private enum structuredKeys: String, CodingKey {
        case from
        case filter = "where"
        case orderBy
    }
    private enum whereKeys: String, CodingKey {
        case fieldFilter
    }
    private enum fieldFilterKeys: String, CodingKey {
        case field
        case op
        case value
    }
    private struct CollectionId: Encodable {
        let value: String
        
        private enum CodingKeys: String, CodingKey {
            case value = "collectionId"
        }
        
        public init(value: String) {
            self.value = value
        }
    }

    private struct FieldPath: Encodable {
        let value: String
        
        private enum CodingKeys: String, CodingKey {
            case value = "fieldPath"
        }
        
        public init(value: String) {
            self.value = value
        }
    }
    private struct orderBy: Encodable {
        let value: String
        let direction: String
        
        private enum CodingKeys: String, CodingKey {
            case field
            case direction
        }
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(FieldPath(value: value), forKey: .field)
            try container.encode(direction, forKey: .direction)
        }
        
        public init(value: String, direction: String) {
            self.value = value
            self.direction = direction
        }
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: runQueryKeys.self)
        var structedContainer = container.nestedContainer(keyedBy: structuredKeys.self, forKey: .structuredQuery)
        try structedContainer.encode([CollectionId(value: "lolCourt")], forKey: .from)
        var whereContainer = structedContainer.nestedContainer(keyedBy: whereKeys.self, forKey: .filter)
        var fieldFilterContainer = whereContainer.nestedContainer(keyedBy: fieldFilterKeys.self, forKey: .fieldFilter)
        try fieldFilterContainer.encode(FieldPath(value: "userID"), forKey: .field)
        try fieldFilterContainer.encode("EQUAL", forKey: .op)
        try fieldFilterContainer.encode(StringValue(value: userId),forKey: .value)
        try structedContainer.encode([orderBy(value: "date", direction: "DESCENDING")], forKey: .orderBy)
    }
}

// Response
public struct Document: Decodable {
    let document: Post
    private enum ResponseKeys: String, CodingKey {
        case document
    }
}
