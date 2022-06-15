//
//  DomainVotesUseCase.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/05/29.
//

import Foundation
import RxSwift

public protocol DomainVotesUseCase {
    func getData() -> Observable<Vote>
    func updateData(_ data: [String: Int]) -> Observable<Void>
}
