//
//  UserDefaults.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/05/29.
//

import Foundation

extension UserDefaults {
    func setIsLoggedIn(value: Bool, userId: String?) {
        set(userId, forKey: "userId")
        set(value, forKey: "isLoggedIn")
        synchronize()
    }
    
    func isLoggedIn() -> Bool {
        return bool(forKey: "isLoggedIn")
    }
    
    func getUserId() -> String? {
        return string(forKey: "userId")
    }
}
