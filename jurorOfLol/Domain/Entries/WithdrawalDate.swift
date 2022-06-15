//
//  withdrawalDate.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/05/31.
//

import Foundation

public struct WithdrawalDate: Codable {
    let date: Double
    
    public init() {
        self.date = Date().timeIntervalSince1970
    }
}
