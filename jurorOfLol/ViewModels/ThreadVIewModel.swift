//
//  ThreadVIewModel.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/03/27.
//

import UIKit
import RxSwift
import RxRelay
import RxCocoa


protocol ThreadViewModelType {
    var becomeActive: BehaviorRelay<Bool> { get }
}

class ThreadViewModel: ThreadViewModelType {
    static let shared = ThreadViewModel()

    let becomeActive: BehaviorRelay<Bool>
    
    init() {
        becomeActive = BehaviorRelay<Bool>(value: false)
    }
}
