//
//  Vote+Mapping.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/06/15.
//

import Foundation

extension Vote {
    private enum CodingKeys: String, CodingKey {
        case fields
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let dataDict = try container.decode([String: IntegerValue].self, forKey: .fields)
        for data in dataDict {
            self.data[data.key] = Int(data.value.value)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        var integerValueDict = [String: IntegerValue]()
        data.forEach {
            integerValueDict[$0.key] = IntegerValue(value: String($0.value))
        }
        try container.encode(integerValueDict, forKey: .fields)
    }
}
