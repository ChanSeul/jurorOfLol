//
//  LoginNetwork.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/05/31.
//

import Foundation
import RxSwift
import RxAlamofire
import Alamofire

final class LoginNetwork {
    private let endPoint: String
    private let scheduler: ConcurrentDispatchQueueScheduler
    
    init(_ endPoint: String) {
        self.endPoint = endPoint
        self.scheduler = ConcurrentDispatchQueueScheduler(qos: DispatchQoS(qosClass: DispatchQoS.QoSClass.background, relativePriority: 1))
    }
    
    func getAppleUserId() -> Observable<String> {
        guard let userId = UserDefaults.standard.getUserId() else { return Observable.error(RxError.unknown) }
        let absolutePath = "\(endPoint)/appleUserIdByUsers/\(userId)"
        return RxAlamofire
            .data(.get, absolutePath)
            .observe(on: scheduler)
            .map({ data -> String in
                let response = try JSONDecoder().decode(AppleUserId.self, from: data)
                return response.appleUserId
            })
    }
    
    func updateAppleUserId(_ appleUserId: String) -> Observable<Void> {
        guard let userId = UserDefaults.standard.getUserId() else { return Observable.error(RxError.unknown) }
        let absolutePath = "\(endPoint)/appleUserIdByUsers/\(userId)"
        var request = URLRequest(url: URL(string: absolutePath)!)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            let body = AppleUserId(appleUserId)
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            print("http Body Error")
        }
        return RxAlamofire
            .request(request as URLRequestConvertible)
            .data()
            .observe(on: scheduler)
            .map { data -> String in
                let response = try JSONDecoder().decode(AppleUserId.self, from: data)
                return response.appleUserId
            }
            .mapToVoid()
    }
    
    func getWithdrawalDate(_ appleUserId: String) -> Observable<Double> {
        let absolutePath = "\(endPoint)/withdrawalList/\(appleUserId)"
        return RxAlamofire
            .data(.get, absolutePath)
            .observe(on: scheduler)
            .map({ data -> Double in
                let response = try JSONDecoder().decode(WithdrawalDate.self, from: data)
                return response.date
            })
    }
    
    func updateWithdrawalDate(_ appleUserId: String) -> Observable<Void> {
        let absolutePath = "\(endPoint)/withdrawalList/\(appleUserId)"
        var request = URLRequest(url: URL(string: absolutePath)!)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            let body = WithdrawalDate()
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            print("http Body Error")
            return Observable.empty()
        }
        return RxAlamofire
            .request(request as URLRequestConvertible)
            .observe(on: scheduler)
            .mapToVoid()
//        AF.request(request).responseDecodable(of: WithdrawalDate.self) { response in
//            switch response.result {
//            case .success(let result):
//                print(result.date)
//            case .failure(let error):
//                print(error.localizedDescription)
//            }
//        }
    }
}
