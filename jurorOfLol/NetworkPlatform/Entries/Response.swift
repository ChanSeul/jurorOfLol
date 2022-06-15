//
//  Response.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/05/20.
//

import Foundation

public struct PostsGetResponse: Codable {
    let posts: [Post]
    let nextPage: String?
    
    private enum CodingKeys: String, CodingKey {
        case posts = "documents"
        case nextPage = "nextPageToken"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        posts = try container.decode([Post].self, forKey: .posts)
        nextPage = try container.decodeIfPresent(String.self, forKey: .nextPage)
    }
}

public struct PostPostResponse: Codable {
    let docID: String

    private enum CodingKeys: String, CodingKey {
        case docID = "name"
    }
}
