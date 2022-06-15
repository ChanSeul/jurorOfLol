//
//  PostsViewModel.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/05/16.
//

import Foundation

public struct PostItemViewModel {
    public let post: Post
    public let url: String
    public let champion1: String
    public let champion2: String
    public var vote1: Int
    public var vote2: Int
    public var totalVotes: Int
    public let text: String
    public let date: Double
    public let docID: String
    public let userID: String
    public let id: Identifier<String, PostItemViewModel>
    
    init (with post: Post) {
        self.post = post
        self.url = post.url
        self.champion1 = post.champion1
        self.champion2 = post.champion2
        self.vote1 = post.vote1
        self.vote2 = post.vote2
        self.totalVotes = post.totalVotes
        self.text = post.text
        self.date = post.date
        self.docID =  post.docID
        self.userID = post.userID
        self.id = ID(rawValue: self.docID)
    }
    
    mutating func changeVotes(_ type: voteUpdateType) {
        switch type {
        case .onlyAddFirst:
            vote1 += 1
            totalVotes += 1
        case .onlyDecreaseFirst:
            vote1 -= 1
            totalVotes -= 1
        case .onlyAddSecond:
            vote2 += 1
            totalVotes += 1
        case .onlyDecreaseSecond:
            vote2 -= 1
            totalVotes -= 1
        case .addFirstDecreaseSecond:
            vote1 += 1
            vote2 -= 1
        case .decreaseFirstAddSecond:
            vote1 -= 1
            vote2 += 1
        }
    }
}

extension PostItemViewModel: Equatable, Identifiable {
    public static func == (lhs: PostItemViewModel, rhs: PostItemViewModel) -> Bool {
        return lhs.id == rhs.id
    }
}

public enum voteUpdateType: String {
    case onlyAddFirst
    case onlyDecreaseFirst
    case onlyAddSecond
    case onlyDecreaseSecond
    case addFirstDecreaseSecond
    case decreaseFirstAddSecond
}
