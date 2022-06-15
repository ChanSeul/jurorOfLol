//
//  ViewModelType.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/05/16.
//

import Foundation

protocol ViewModelType {
    associatedtype Input
    associatedtype Output
    func transform(input: Input) -> Output
}
