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
    var champion2: String
    var text: String
    var date: String
    var docId: String
    var userId: String
    
    init(post:Post) {
        self.url = post.url
        self.champion1 = post.champion1
        self.champion2 = post.champion2
        self.text = post.text
        self.date = post.date
        self.docId = post.docId
        self.userId = post.userId
    }
    
    init(url: String, champion1: String, champion2: String, text: String, date: String, docId: String, userId: String) {
        self.url = url
        self.champion1 = champion1
        self.champion2 = champion2
        self.text = text
        self.date = date
        self.docId = docId
        self.userId = userId
    }
    
    func ViewPostToPost() -> Post {
        return Post(url: self.url, champion1: self.champion1, champion2: self.champion2, text: self.text, date: self.date, docId: self.docId, userId: self.userId)
//        return Post(url: "https://youtu.be/" + self.url, champion1: self.champion1, champion2: self.champion2, text: self.text, date: self.date, docId: self.docId, userId: self.userId)
    }
}

