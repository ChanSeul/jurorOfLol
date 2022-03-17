//
//  PostViewModel.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/03/01.
//

import Foundation
import SwiftUI


enum voteUpdateType: String {
    case onlyAddFirst
    case onlyDecreaseFirst
    case onlyAddSecond
    case onlyDecreaseSecond
    case addFirstDecreaseSecond
    case decreaseFirstAddSecond
}

struct ViewPost {
    var url: String
    var champion1: String
    var champion1Votes: Double
    var champion2: String
    var champion2Votes: Double
    var text: String
    var date: String
    var docId: String
    var userId: String
    
    init(post:post) {
        self.url = post.url
        self.champion1 = post.champion1
        self.champion1Votes = post.champion1Votes
        self.champion2 = post.champion2
        self.champion2Votes = post.champion2Votes
        self.text = post.text
        self.date = post.date
        self.docId = post.docId
        self.userId = post.userId
    }

}

