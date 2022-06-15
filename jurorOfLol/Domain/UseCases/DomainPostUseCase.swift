//
//  PostUseCase.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/05/15.
//

import Foundation
import RxSwift

public protocol DomainPostsUseCase {
    func getInitialPosts(orderBy: OrderBy) -> Observable<[Post]>
    func getNextPosts(orderBy: OrderBy) -> Observable<[Post]>
    func updateVoteOfPost(docId: String, voteUpdate: voteUpdateType) -> Observable<Void>
    func editPost(post: Post) -> Observable<Void>
    func save(post: Post) -> Observable<Void>
    func delete(docId: String) -> Observable<Void>
}

