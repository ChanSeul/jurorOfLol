//
//  NetworkLoginUseCase.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/05/31.
//

import Foundation
import RxSwift


final class NetworkLoginUseCase: DomainLoginUseCase {
    private let network: LoginNetwork

    init(network: LoginNetwork) {
        self.network = network
    }

    func getAppleUserId() -> Observable<String> {
        network.getAppleUserId()
    }
    
    func updateAppleUserId(_ appleUserId: String) -> Observable<Void> {
        network.updateAppleUserId(appleUserId)
    }
    
    func getWithdrawalDate(_ appleUserId: String) -> Observable<Double> {
        network.getWithdrawalDate(appleUserId)
    }
    
    func updateWithdrawalDate(_ appleUserId: String) -> Observable<Void> {
        network.updateWithdrawalDate(appleUserId)
    }
}
