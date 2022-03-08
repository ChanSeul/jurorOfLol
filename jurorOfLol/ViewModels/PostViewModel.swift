//
//  PostViewModel.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/03/01.
//

import Foundation
import SwiftUI
import AVFoundation

struct ViewPost {
    private let post:post
    
    var url: String? {
        return post.url
    }
    var chapion1: String? {
        return post.champion1
    }
    var champion1Votes: Double? {
        return post.champion1Votes
    }
    var champion2: String? {
        return post.champion2
    }
    var champion2Votes: Double? {
        return post.champion2Votes
    }
    var text: String? {
        return post.text
    }
    var date: String? {
        return post.date
    }
    var docId: String? {
        return post.docId
    }
    
    init(post:post) {
        self.post = post
    }
    
}

