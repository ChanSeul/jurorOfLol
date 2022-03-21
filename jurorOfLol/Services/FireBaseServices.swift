//
//  FireBaseServices.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/03/01.
//

import Foundation
import Firebase
import RxSwift

protocol FirebaseServiceProtocol {
    func fetchInitial(completion: @escaping (Result<[post], Error>) -> Void)
    func fetchInitialRx() -> Observable<[post]>
    func fetchNext(completion: @escaping (Result<[post], Error>) -> Void)
    func fetchNextRx() -> Observable<[post]>
    func deletePost(docId: String, completion: @escaping () -> Void)
}

class FireBaseService: FirebaseServiceProtocol {
    let pageSize = 8
    var cursor: DocumentSnapshot?
    var query: Query?
    //var dataMayContinue = true
    
    func fetchInitial(completion: @escaping (Result<[post], Error>) -> Void) {
        let db = Firestore.firestore()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        self.query = db.collection("posts")
            .order(by: "date", descending: false)
            .limit(to: pageSize)
        var nextPosts = [post]()
        self.query?.getDocuments() { [weak self] (querySnapshot, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Error getting documents: \(error)")
                completion(.failure(error))
            } else {
                if querySnapshot!.count < self.pageSize {
                    self.cursor = nil
                } else {
                    self.cursor = querySnapshot!.documents.last
                    self.query = self.query?.start(afterDocument: self.cursor!)
                }
                for document in querySnapshot!.documents {
                    guard let url = document.data()["url"] as? String else { continue }
                    guard let champion1 = document.data()["champion1"] as? String else { continue }
                    guard let champion1Votes = document.data()["champion1Votes"] as? Double else { continue }
                    guard let champion2 = document.data()["champion2"] as? String else { continue }
                    guard let champion2Votes = document.data()["champion2Votes"] as? Double else { continue }
                    guard let text = document.data()["text"] as? String else { continue }
                    guard let date = document.data()["date"] as? Double else { continue }
                    guard let uid = document.data()["userID"] as? String else { continue }
                    nextPosts.append(post(url: url,
                                          champion1: champion1,
                                          champion2: champion2,
                                          champion1Votes: champion1Votes,
                                          champion2Votes: champion2Votes,
                                          text: text,
                                          date: formatter.string(from: Date(timeIntervalSince1970: date)),
                                          docId: document.documentID,
                                          userId: uid))
                }
                completion(.success(nextPosts))
            }
        }
    }
    func fetchInitialRx() -> Observable<[post]> {
        return Observable.create { (observer) -> Disposable in
            self.fetchInitial() { result in
                switch result {
                case .success(let data):
                    observer.onNext(data)
                case .failure(let error):
                    observer.onError(error)
                }
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
    func fetchNext(completion: @escaping (Result<[post], Error>) -> Void) {
        guard let _ = cursor, let _ = query else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        var nextPosts = [post]()
        
        self.query?.getDocuments { [weak self] (querySnapshot, error) in
            guard let self = self else { return }
            if let error = error {
                print("Error getting documents: \(error)")
                completion(.failure(error))
            } else {
                if querySnapshot!.count < self.pageSize {
                    self.cursor = nil
                } else {
                    self.cursor = querySnapshot!.documents.last
                    self.query = self.query?.start(afterDocument: self.cursor!)
                }
                for document in querySnapshot!.documents {
                    guard let url = document.data()["url"] as? String else { continue }
                    guard let champion1 = document.data()["champion1"] as? String else { continue }
                    guard let champion1Votes = document.data()["champion1Votes"] as? Double else { continue }
                    guard let champion2 = document.data()["champion2"] as? String else { continue }
                    guard let champion2Votes = document.data()["champion2Votes"] as? Double else { continue }
                    guard let text = document.data()["text"] as? String else { continue }
                    guard let date = document.data()["date"] as? Double else { continue }
                    guard let uid = document.data()["userID"] as? String else { continue }
                    nextPosts.append(post(url: url,
                                          champion1: champion1,
                                          champion2: champion2,
                                          champion1Votes: champion1Votes,
                                          champion2Votes: champion2Votes,
                                          text: text,
                                          date: formatter.string(from: Date(timeIntervalSince1970: date)),
                                          docId: document.documentID,
                                          userId: uid))
                }
                completion(.success(nextPosts))
            }
        }
    }
    func fetchNextRx() -> Observable<[post]> {
        return Observable.create { (observer) -> Disposable in
            self.fetchNext() { result in
                switch result {
                case .success(let data):
                    observer.onNext(data)
                case .failure(let error):
                    observer.onError(error)
                }
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
//    func fetchPosts(startIdx: Int, completion: @escaping (Result<[post], Error>) -> Void) {
//        let db = Firestore.firestore()
//        let formatter = DateFormatter()
//        formatter.dateFormat = "yyyy-MM-dd HH:mm"
//
//        if startIdx == 0 {
//            let first = db.collection("posts")
//                .order(by: "date")
//                .limit(to: 8)
//            var nextPosts = [post]()
//            first.getDocuments() { (querySnapshot, error) in
//                if let error = error {
//                    print("Error getting documents: \(error)")
//                } else {
//                    for document in querySnapshot!.documents {
//                        guard let url = document.data()["url"] as? String else {
//                            continue
//                        }
//                        guard let champion1 = document.data()["champion1"] as? String else {
//                            continue
//                        }
//                        guard let champion1Votes = document.data()["champion1Votes"] as? Double else {
//                            continue
//                        }
//                        guard let champion2 = document.data()["champion2"] as? String else {
//                            continue
//                        }
//                        guard let champion2Votes = document.data()["champion2Votes"] as? Double else {
//                            continue
//                        }
//                        guard let text = document.data()["text"] as? String else {
//                            continue
//                        }
//                        guard let date = document.data()["date"] as? Double else {
//                            continue
//                        }
//                        guard let uid = document.data()["userID"] as? String else {
//                            continue
//                        }
//                        nextPosts.append(post(url: url,
//                                              champion1: champion1,
//                                              champion2: champion2,
//                                              champion1Votes: champion1Votes,
//                                              champion2Votes: champion2Votes,
//                                              text: text,
//                                              date: formatter.string(from: Date(timeIntervalSince1970: date)),
//                                              docId: document.documentID,
//                                              userId: uid
//                                             )
//                        )
//                    }
//                }
//                completion(.success(nextPosts))
//            }
//        }
//        else {
//
//            let first = db.collection("posts")
//                .order(by: "date")
//                .limit(to: startIdx)
//            first.addSnapshotListener { (snapshot, error) in
//                guard let snapshot = snapshot else {
//                    print("Error retreving : \(error.debugDescription)")
//                    return
//                }
//                guard let lastSnapshot = snapshot.documents.last else {
//                    return
//                }
//                let next = db.collection("posts")
//                    .order(by: "date")
//                    .start(afterDocument: lastSnapshot)
//                    .limit(to: 8)
//                var nextPosts = [post]()
//                next.getDocuments() { (querySnapshot, error) in
//                    if let error = error {
//                        print("Error getting documents: \(error)")
//                    } else {
//                        for document in querySnapshot!.documents {
//                            guard let url = document.data()["url"] as? String else {
//                                continue
//                            }
//                            guard let champion1 = document.data()["champion1"] as? String else {
//                                continue
//                            }
//                            guard let champion1Votes = document.data()["champion1Votes"] as? Double else {
//                                continue
//                            }
//                            guard let champion2 = document.data()["champion2"] as? String else {
//                                continue
//                            }
//                            guard let champion2Votes = document.data()["champion2Votes"] as? Double else {
//                                continue
//                            }
//                            guard let text = document.data()["text"] as? String else {
//                                continue
//                            }
//                            guard let date = document.data()["date"] as? Double else {
//                                continue
//                            }
//                            guard let uid = document.data()["userID"] as? String else {
//                                continue
//                            }
//                            nextPosts.append(post(url: url,
//                                                  champion1: champion1,
//                                                  champion2: champion2,
//                                                  champion1Votes: champion1Votes,
//                                                  champion2Votes: champion2Votes,
//                                                  text: text,
//                                                  date: formatter.string(from: Date(timeIntervalSince1970: date)),
//                                                  docId: document.documentID,
//                                                  userId: uid
//                                                 )
//                            )
//                        }
//                    }
//                    completion(.success(nextPosts))
//                }
//            }
//
//        }
//    }

    func deletePost(docId: String, completion: @escaping () -> Void) {
        let db = Firestore.firestore()
        Task {
            let _ = await withTaskGroup(of: Void.self, body: { taskGroup in
                taskGroup.addTask {
                    let docRef = db.collection("posts").document(docId)
                    docRef.delete() { (error) in
                        if let _ = error {
                            print("Delete Post error occured")
                            return
                        }
                    }
                }
                taskGroup.addTask {
                    let docRef = db.collection("userSetForVoteByPost").document(docId)
                    docRef.delete() { (error) in
                        if let _ = error {
                            print("Delete Post error occured")
                            return
                        }
                    }
                }
            })
            completion()
        }
    }
}


