//
//  Identifier.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/05/28.
//

import Foundation

public struct Identifier<T, ID>: RawRepresentable, Hashable where T: Codable & Hashable {
    public let rawValue: T

    public init(rawValue: T) {
        self.rawValue = rawValue
    }
}

extension Identifier: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        rawValue = try container.decode(T.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

