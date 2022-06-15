//
//  Vote.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/05/29.
//

import Foundation

public struct Vote: Codable {
    var data = [String: Int]()
    
    public init(data: [String: Int] = [String: Int]()) {
        self.data = data
    }
}
