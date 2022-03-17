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
    func fetchPostsRx(startIdx: Int) -> Observable<[post]>
    func fetchPosts(startIdx: Int, completion: @escaping (Result<[post], Error>) -> Void)
    func deletePost(docId: String, completion: @escaping () -> Void)
}

class FireBaseService: FirebaseServiceProtocol {
    func fetchPostsRx(startIdx: Int) -> Observable<[post]> {
        return Observable.create { (observer) -> Disposable in
            
            self.fetchPosts(startIdx: startIdx) { result in
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
    func fetchPosts(startIdx: Int, completion: @escaping (Result<[post], Error>) -> Void) {
        let db = Firestore.firestore()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        if startIdx == 0 {
            let first = db.collection("posts")
                .order(by: "date")
                .limit(to: 8)
            var nextPosts = [post]()
            first.getDocuments() { (querySnapshot, error) in
                if let error = error {
                    print("Error getting documents: \(error)")
                } else {
                    for document in querySnapshot!.documents {
                        guard let url = document.data()["url"] as? String else {
                            continue
                        }
                        guard let champion1 = document.data()["champion1"] as? String else {
                            continue
                        }
                        guard let champion1Votes = document.data()["champion1Votes"] as? Double else {
                            continue
                        }
                        guard let champion2 = document.data()["champion2"] as? String else {
                            continue
                        }
                        guard let champion2Votes = document.data()["champion2Votes"] as? Double else {
                            continue
                        }
                        guard let text = document.data()["text"] as? String else {
                            continue
                        }
                        guard let date = document.data()["date"] as? Double else {
                            continue
                        }
                        guard let uid = document.data()["userID"] as? String else {
                            continue
                        }
                        nextPosts.append(post(url: url,
                                              champion1: champion1,
                                              champion2: champion2,
                                              champion1Votes: champion1Votes,
                                              champion2Votes: champion2Votes,
                                              text: text,
                                              date: formatter.string(from: Date(timeIntervalSince1970: date)),
                                              docId: document.documentID,
                                              userId: uid
                                             )
                        )
                    }
                }
                completion(.success(nextPosts))
            }
        }
        else {
            
            let first = db.collection("posts")
                .order(by: "date")
                .limit(to: startIdx)
            first.addSnapshotListener { (snapshot, error) in
                guard let snapshot = snapshot else {
                    print("Error retreving : \(error.debugDescription)")
                    return
                }
                guard let lastSnapshot = snapshot.documents.last else {
                    return
                }
                let next = db.collection("posts")
                    .order(by: "date")
                    .start(afterDocument: lastSnapshot)
                    .limit(to: 8)
                var nextPosts = [post]()
                next.getDocuments() { (querySnapshot, error) in
                    if let error = error {
                        print("Error getting documents: \(error)")
                    } else {
                        for document in querySnapshot!.documents {
                            guard let url = document.data()["url"] as? String else {
                                continue
                            }
                            guard let champion1 = document.data()["champion1"] as? String else {
                                continue
                            }
                            guard let champion1Votes = document.data()["champion1Votes"] as? Double else {
                                continue
                            }
                            guard let champion2 = document.data()["champion2"] as? String else {
                                continue
                            }
                            guard let champion2Votes = document.data()["champion2Votes"] as? Double else {
                                continue
                            }
                            guard let text = document.data()["text"] as? String else {
                                continue
                            }
                            guard let date = document.data()["date"] as? Double else {
                                continue
                            }
                            guard let uid = document.data()["userID"] as? String else {
                                continue
                            }
                            nextPosts.append(post(url: url,
                                                  champion1: champion1,
                                                  champion2: champion2,
                                                  champion1Votes: champion1Votes,
                                                  champion2Votes: champion2Votes,
                                                  text: text,
                                                  date: formatter.string(from: Date(timeIntervalSince1970: date)),
                                                  docId: document.documentID,
                                                  userId: uid
                                                 )
                            )
                        }
                    }
                    completion(.success(nextPosts))
                }
            }
            
        }
    }
    
    func deletePost(docId: String, completion: @escaping () -> Void) {
        let db = Firestore.firestore()
        Task {
            let result = await withTaskGroup(of: Void.self, body: { taskGroup in
                taskGroup.addTask {
                    let docRef = db.collection("posts").document(docId)
                    docRef.delete() { (error) in
                        if let error = error {
                            print("Delete Post error occured")
                            return
                        }
                    }
                }
                taskGroup.addTask {
                    let docRef = db.collection("userSetForVoteByPost").document(docId)
                    docRef.delete() { (error) in
                        if let error = error {
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


