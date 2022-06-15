//
//  Post+Mapping.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/05/15.
//

import Foundation

extension Post {
    private enum PostKeys: String, CodingKey {
        case fields
        case docID = "name"
    }
    
    private enum FieldKeys: String, CodingKey {
        case url
        case champion1
        case champion2
        case vote1
        case vote2
        case text
        case date
        case userID
        case totalVotes
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: PostKeys.self)
        let fieldContainer = try container.nestedContainer(keyedBy: FieldKeys.self, forKey: .fields)
        
        url = try fieldContainer.decode(StringValue.self, forKey: .url).value
        champion1 = try fieldContainer.decode(StringValue.self, forKey: .champion1).value
        champion2 = try fieldContainer.decode(StringValue.self, forKey: .champion2).value
        vote1 = try Int(fieldContainer.decode(IntegerValue.self, forKey: .vote1).value)!
        vote2 = try Int(fieldContainer.decode(IntegerValue.self, forKey: .vote2).value)!
        text = try fieldContainer.decode(StringValue.self, forKey: .text).value
        date = try fieldContainer.decode(DoubleValue.self, forKey: .date).value
        userID = try fieldContainer.decode(StringValue.self, forKey: .userID).value
        docID = try {
            let data = try container.decode(String.self, forKey: .docID)
            return data.components(separatedBy: "/").last!
        }()
        totalVotes = Int(try fieldContainer.decode(IntegerValue.self, forKey: .totalVotes).value )!
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: PostKeys.self)
        var fieldContainer = container.nestedContainer(keyedBy: FieldKeys.self, forKey: .fields)
        try fieldContainer.encode(StringValue(value: champion1), forKey: .champion1)
        try fieldContainer.encode(StringValue(value: champion2), forKey: .champion2)
        try fieldContainer.encode(IntegerValue(value: String(vote1)), forKey: .vote1)
        try fieldContainer.encode(IntegerValue(value: String(vote2)), forKey: .vote2)
        try fieldContainer.encode(DoubleValue(value: date), forKey: .date)
        try fieldContainer.encode(StringValue(value: text), forKey: .text)
        try fieldContainer.encode(IntegerValue(value: String(totalVotes)), forKey: .totalVotes)
        try fieldContainer.encode(StringValue(value: url), forKey: .url)
        try fieldContainer.encode(StringValue(value: userID), forKey: .userID)
    }
}

