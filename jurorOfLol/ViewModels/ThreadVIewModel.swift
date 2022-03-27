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
    var isBackground: BehaviorRelay<Bool> { get }
}

class ThreadViewModel: ThreadViewModelType {
    static let shared = ThreadViewModel()

    let isBackground: BehaviorRelay<Bool>
    
    init() {
        isBackground = BehaviorRelay<Bool>(value: false)
    }
}
