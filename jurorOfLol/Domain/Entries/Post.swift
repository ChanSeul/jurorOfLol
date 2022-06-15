//
//  PostModel.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/04/30.
//
import Foundation

public struct Post: Codable {
    public let url: String
    public let champion1: String
    public let champion2: String
    public let vote1: Int
    public let vote2: Int
    public let text: String
    public let date: Double
    public let docID: String
    public let userID: String
    public let totalVotes: Int
    
    public init(url: String,
                champion1: String,
                champion2: String,
                vote1: Int,
                vote2: Int,
                totalVotes: Int,
                text: String,
                date: Double,
                docID: String,
                userID: String) {
        self.url = url
        self.champion1 = champion1
        self.champion2 = champion2
        self.vote1 = vote1
        self.vote2 = vote2
        self.totalVotes = totalVotes
        self.text = text
        self.date = date
        self.docID =  docID
        self.userID = userID
    }
    
    public init(url: String,
                champion1: String,
                champion2: String,
                text: String,
                docID: String = "",
                userID: String = "") {
        self.url = url
        self.champion1 = champion1
        self.champion2 = champion2
        self.vote1 = 0
        self.vote2 = 0
        self.totalVotes = 0
        self.text = text
        self.date = Date().timeIntervalSince1970
        self.docID = docID
        self.userID = userID
    }

}

extension Post: Equatable {
    public static func == (lhs: Post, rhs: Post) -> Bool {
        return lhs.docID == rhs.docID
    }
}
