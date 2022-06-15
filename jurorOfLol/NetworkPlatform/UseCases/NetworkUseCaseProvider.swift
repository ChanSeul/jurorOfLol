//
//  NetworkUseCaseProvider.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/05/18.
//

import Foundation

public final class NetworkUseCaseProvider: DomainUseCaseProvider {
    private let networkProvider: NetworkProvider
    
    public init() {
        networkProvider = NetworkProvider()
    }
    
    public func makePostsUseCase() -> DomainPostsUseCase {
        return NetworkPostsUseCase(network: networkProvider.makePostsNetwork())
    }
    
    public func makeVotesUseCase() -> DomainVotesUseCase {
        return NetworkVotesUseCase(network: networkProvider.makeVotesNetwork())
    }
    
    public func makeLoginUseCase() -> DomainLoginUseCase {
        return NetworkLoginUseCase(network: networkProvider.makeLoginNetwork())
    }
}
