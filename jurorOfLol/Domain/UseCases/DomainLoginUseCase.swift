//
//  DomainLoginUseCase.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/05/31.
//

import Foundation
import RxSwift

public protocol DomainLoginUseCase {
    func getAppleUserId() -> Observable<String>
    func updateAppleUserId(_ appleUserId: String) -> Observable<Void>
    func getWithdrawalDate(_ appleUserId: String) -> Observable<Double>
    func updateWithdrawalDate(_ appleUserId: String) -> Observable<Void>
}
