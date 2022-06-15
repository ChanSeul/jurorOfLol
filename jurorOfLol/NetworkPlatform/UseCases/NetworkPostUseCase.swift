//
//  PostUseCase.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/05/16.
//

import Foundation
import RxSwift


final class NetworkPostsUseCase: DomainPostsUseCase {
    private let network: PostsNetwork

    init(network: PostsNetwork) {
        self.network = network
    }

    func getInitialPosts(orderBy: OrderBy) -> Observable<[Post]> {
        return network.getInitialPosts("lolCourt", orderBy: orderBy)
    }
    
    func getNextPosts(orderBy: OrderBy) -> Observable<[Post]> {
        return network.getNextPosts("lolCourt", orderBy: orderBy)
    }
    
    func updateVoteOfPost(docId: String, voteUpdate: voteUpdateType) -> Observable<Void> {
        return network.updateVoteOfPost("lolCourt", docId, voteUpdate)
    }
    
    func editPost(post: Post)  -> Observable<Void> {
        return network.editPost("lolCourt", post)
    }
    
    func save(post: Post) -> Observable<Void> {
        return network.createPost("lolCourt", post)
    }
//
    func delete(docId: String) -> Observable<Void> {
        return network.deletePost("lolCourt", docId)
    }
}
