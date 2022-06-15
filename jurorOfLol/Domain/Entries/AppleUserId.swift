//
//  AppleUserId.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/05/31.
//

import Foundation

public struct AppleUserId: Codable {
    let appleUserId: String
    
    public init(_ appleUserId: String) {
        self.appleUserId = appleUserId
    }
}
