//
//  NetworkVoteUseCase.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/05/29.
//

import Foundation
import RxSwift


final class NetworkVotesUseCase: DomainVotesUseCase {
    private let network: VotesNetwork

    init(network: VotesNetwork) {
        self.network = network
    }

    func getData() -> Observable<Vote> {
        network.getData()
    }
    
    func updateData(_ data: [String : Int]) -> Observable<Void> {
        network.updateData(data)
    }
}
