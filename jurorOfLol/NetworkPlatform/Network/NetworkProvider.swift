//
//  NetWorkProvider.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/05/15.
//

import Foundation

final class NetworkProvider {
    private let apiEndpoint: String

    public init() {
        apiEndpoint = "https://firestore.googleapis.com/v1/projects/lolcourt-554c8/databases/(default)/documents"
    }
    
    public func makePostsNetwork() -> PostsNetwork {
        return PostsNetwork(apiEndpoint)
    }
    
    public func makeVotesNetwork() -> VotesNetwork {
        return VotesNetwork(apiEndpoint)
    }
    
    public func makeLoginNetwork() -> LoginNetwork {
        return LoginNetwork(apiEndpoint)
    }
}


