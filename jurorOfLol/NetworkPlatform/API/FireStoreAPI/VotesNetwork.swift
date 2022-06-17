//
//  VoteDataNetwork.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/05/29.
//

import Foundation
import Alamofire
import RxAlamofire
import RxSwift

final class VotesNetwork {
    private let endPoint: String
    private let scheduler: ConcurrentDispatchQueueScheduler
    
    init(_ endPoint: String) {
        self.endPoint = endPoint
        self.scheduler = ConcurrentDispatchQueueScheduler(qos: DispatchQoS(qosClass: DispatchQoS.QoSClass.background, relativePriority: 1))
    }
    
    func getData() -> Observable<Vote> {
        guard let userId = UserDefaults.standard.getUserId() else {
            return Observable.just(Vote())
        }
        let absolutePath = "\(endPoint)/voteDataByUsers/\(userId)"
        return RxAlamofire
            .data(.get, absolutePath)
            .observe(on: scheduler)
            .map({ data -> Vote in
                let response = try JSONDecoder().decode(Vote.self, from: data)
                return response
            })
    }
    
    func updateData(_ data: [String: Int]) -> Observable<Void> {
        guard let userId = UserDefaults.standard.getUserId() else {
            return Observable.error(RxError.unknown)
        }
        let absolutePath = "\(endPoint)/voteDataByUsers/\(userId)"
        var request = URLRequest(url: URL(string: absolutePath)!)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            let body = Vote(data: data)
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            print("http Body Error")
        }
        return RxAlamofire
            .request(request as URLRequestConvertible)
            .data()
            .observe(on: scheduler)
            .map { data -> Vote in
                let response = try JSONDecoder().decode(Vote.self, from: data)
                return response
            }
            .mapToVoid()
    }
}
