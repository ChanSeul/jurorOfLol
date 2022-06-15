//
//  NetWork.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/05/15.
//

import Foundation
import Alamofire
import RxAlamofire
import RxSwift

final class PostsNetwork {
    private let endPoint: String
    private let scheduler: ConcurrentDispatchQueueScheduler
    private var nextPage: String?
    private var isEnded: Bool // 더 이상 fetch할 post가 없는지

    init(_ endPoint: String) {
        self.endPoint = endPoint
        self.scheduler = ConcurrentDispatchQueueScheduler(qos: DispatchQoS(qosClass: DispatchQoS.QoSClass.background, relativePriority: 1))
        self.isEnded = false
    }
    
    func getInitialPosts(_ path: String, orderBy: OrderBy) -> Observable<[Post]> {
        let absolutePath = "\(endPoint)/\(path)"
        let parameters: [String: Any]
        
        isEnded = false
        
        switch orderBy {
        case .Time:
            parameters = ["pageSize": 4, "orderBy": "date desc"]
        case .Votes:
            parameters = ["pageSize": 4, "orderBy": "totalVotes desc"]
        case .TimeFilteredByUserId:
            return batchUsersPost()
        }
        
        return RxAlamofire
            .data(.get, absolutePath, parameters: parameters)
//            .debug()
            .observe(on: scheduler)
            .map({ [weak self] data -> [Post] in
                let response = try JSONDecoder().decode(PostsGetResponse.self, from: data)
                if response.nextPage == nil {
                    self?.isEnded = true
                }
                self?.nextPage = response.nextPage
                return response.posts
            })
    }
    
    func getNextPosts(_ path: String, orderBy: OrderBy) -> Observable<[Post]> {
        if isEnded {
            return Observable.error(RxError.unknown)
        }
        let absolutePath = "\(endPoint)/\(path)"
        let parameters: [String: Any]
        switch orderBy {
        case .Time:
            parameters = ["pageSize": 4, "orderBy": "date desc", "pageToken": nextPage!]
        case .Votes:
            parameters = ["pageSize": 4, "orderBy": "totalVotes desc", "pageToken": nextPage!]
        case .TimeFilteredByUserId:
            return Observable.error(RxError.unknown)
        }

        return RxAlamofire
            .data(.get, absolutePath, parameters: parameters)
//            .debug()
            .observe(on: scheduler)
            .map({ [weak self] data -> [Post] in
                let response = try JSONDecoder().decode(PostsGetResponse.self, from: data)
                if response.nextPage == nil {
                    self?.isEnded = true
                }
                self?.nextPage = response.nextPage
                return response.posts
            })
    }
    
    func batchUsersPost() -> Observable<[Post]> {
        guard let userId = UserDefaults.standard.getUserId() else { return Observable.error(RxError.unknown) }
        let absolutePath = "\(endPoint):runQuery"
        var request = URLRequest(url: URL(string: absolutePath)!)
        request.httpMethod = "POST"
        do {
            request.httpBody = try JSONEncoder().encode(MyPost(userId: userId))
        } catch {
            print("http Body Error")
        }
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        return RxAlamofire
            .request(request as URLRequestConvertible)
            .data()
            .observe(on: scheduler)
            .map { [unowned self] data -> [Post] in
                let response = try JSONDecoder().decode([Document].self, from: data)
                self.isEnded = true
                return response.map { $0.document }
            }
    }
    // Post의 vote1, vote2 , totlaVotes 업데이트
    func updateVoteOfPost(_ path: String, _ docId: String, _ voteUpdate: voteUpdateType) -> Observable<Void> {
        let absolutePath = "\(endPoint):commit"
        var request = URLRequest(url: URL(string: absolutePath)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            request.httpBody = try JSONEncoder().encode(Transform(path, docId, voteUpdate))
        } catch {
            print("http Body Error")
        }
        
        return RxAlamofire
            .request(request as URLRequestConvertible)
            .observe(on: scheduler)
            .mapToVoid()
    }
    
    // Post의 url, champion1, champion2, text 업데이트할 때
    func editPost(_ path: String, _ post: Post) -> Observable<Void> {
        let absolutePath = "\(endPoint):commit"
        var request = URLRequest(url: URL(string: absolutePath)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            request.httpBody = try JSONEncoder().encode(Transform(path, post))
        } catch {
            print("http Body Error")
        }
        
        return RxAlamofire
            .request(request as URLRequestConvertible)
            .observe(on: scheduler)
            .mapToVoid()
    }
    
    func createPost(_ path: String, _ post: Post) -> Observable<Void> {
        let absolutePath = "\(endPoint)/\(path)"
        var request = URLRequest(url: URL(string: absolutePath)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            request.httpBody = try JSONEncoder().encode(post)
        } catch {
            print("http Body Error")
        }
        
        return RxAlamofire
            .request(request as URLRequestConvertible)
            .observe(on: scheduler)
            .mapToVoid()
    }
    
    func deletePost(_ path: String, _ docId: String) -> Observable<Void> {
        let absolutePath = "\(endPoint)/\(path)/\(docId)"
        var request = URLRequest(url: URL(string: absolutePath)!)
        request.httpMethod = "DELETE"
        
        return RxAlamofire
            .request(request as URLRequestConvertible)
            .observe(on: scheduler)
            .mapToVoid()
    }
}

