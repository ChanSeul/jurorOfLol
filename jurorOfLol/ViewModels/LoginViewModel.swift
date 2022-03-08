//
//  SettingsViewModel.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/03/03.
//

import UIKit
import RxSwift
import RxRelay
import RxCocoa


protocol LoginViewModelType {
    var isLogin: BehaviorRelay<Bool> { get }
}

class LoginViewModel: LoginViewModelType {
    static let shared = LoginViewModel()

    let isLogin: BehaviorRelay<Bool>
    
    init() {
        isLogin = BehaviorRelay<Bool>(value: false)
    }
}
