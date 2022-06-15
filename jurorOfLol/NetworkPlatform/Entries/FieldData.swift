//
//  FieldData.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/05/20.
//

import Foundation

public struct StringValue: Codable {
    let value: String
    
    private enum CodingKeys: String, CodingKey {
        case value = "stringValue"
    }
    
    public init(value: String) {
        self.value = value
    }
}
public struct IntegerValue: Codable {
    let value: String
    
    private enum CodingKeys: String, CodingKey {
        case value = "integerValue"
    }
}
public struct DoubleValue: Codable {
    let value: Double
    
    private enum CodingKeys: String, CodingKey {
        case value = "doubleValue"
    }
    
    public init(value: Double) {
        self.value = value
    }
}
