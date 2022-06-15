//
//  UseCaseProvider.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/05/16.
//

import Foundation

public protocol DomainUseCaseProvider {
    func makePostsUseCase() -> DomainPostsUseCase
    func makeVotesUseCase() -> DomainVotesUseCase
    func makeLoginUseCase() -> DomainLoginUseCase
}
