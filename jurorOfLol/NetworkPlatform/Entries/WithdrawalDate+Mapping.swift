//
//  WithdrawalDate+Mapping.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/06/15.
//

import Foundation

extension WithdrawalDate {
    private enum CodingKeys: String, CodingKey {
        case fields
    }
    
    private enum FieldKeys: String, CodingKey {
        case date
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let fieldContainer = try container.nestedContainer(keyedBy: FieldKeys.self, forKey: .fields)
        date = try fieldContainer.decode(DoubleValue.self, forKey: .date).value
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        var fieldContainer = container.nestedContainer(keyedBy: FieldKeys.self, forKey: .fields)
        try fieldContainer.encode(DoubleValue(value: date), forKey: .date)
    }
}
