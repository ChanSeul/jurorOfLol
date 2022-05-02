//
//  Singleton.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/04/30.
//

import Foundation
import RxSwift
import RxRelay

class Singleton {
    static let shared = Singleton()
    
    let refreshHomeTableView: PublishRelay<Bool>
    
    let isLogin: BehaviorRelay<Bool>
    let showLoginModal: PublishRelay<Bool>
    
    let showEditModal: PublishRelay<(docId: String, userId: String, prepost: ViewPost)>
    
    let renewCellHeight: PublishRelay<Bool>
    
    let becomeActive: PublishRelay<Bool>
    
    var timeStamp: Double
    
    init() {
        refreshHomeTableView = PublishRelay<Bool>()
        
        isLogin = BehaviorRelay<Bool>(value: false)
        showLoginModal = PublishRelay<Bool>()
        
        showEditModal = PublishRelay<(docId: String, userId: String, prepost: ViewPost)>()
        
        renewCellHeight = PublishRelay<Bool>()
        
        becomeActive = PublishRelay<Bool>()
        
        timeStamp = Date().timeIntervalSince1970
    }
}
