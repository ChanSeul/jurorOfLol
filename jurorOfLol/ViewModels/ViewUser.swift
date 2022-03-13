//
//  ViewUser.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/03/12.
//

import Foundation

struct ViewUser {
    private let userModel: User
    
    var voteInfo: [String: Int] {
        return userModel.voteInfo
    }
    
    init(userModel: User) {
        self.userModel = userModel
    }
}
