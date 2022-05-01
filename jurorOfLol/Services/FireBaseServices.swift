//
//  FireBaseServices.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/03/01.
//

import Foundation
import Firebase
import RxSwift
import FirebaseFirestore

enum FirebaseFetchType: String {
    case All
    case My
    case ByVotes
    case Next
}

protocol FirebaseServiceProtocol {
    func fetchRx(fetchType: FirebaseFetchType) -> Observable<[Post]>
    func fetchInitial(completion: @escaping (Result<[Post], Error>) -> Void)
    func fetchInitialByVotes(completion: @escaping (Result<[Post], Error>) -> Void)
    func fetchMyInitialPosts(completion: @escaping (Result<[Post], Error>) -> Void)
    func fetchNext(completion: @escaping (Result<[Post], Error>) -> Void)
    func deletePost(docId: String, completion: @escaping () -> Void)
    func uploadPost(post: Post) -> DocumentReference?
    func initializeVoteData(docId: String)
    func editPost(docId: String, post: Post)
    func updateTotalVotesofPost(docId: String, updataType: voteUpdateType)
    func updateVoteDataByUser(userId: String, docId: String, updataType: voteUpdateType)
    func updateVoteDataByPost(docId: String, updataType: voteUpdateType)
    func updateUserSetForVoteByPost(userId: String, docId: String, updataType: voteUpdateType)
    func fetchVoteDataOfCurrentUserForCurrentPost(userId: String, docId: String, fromPollNumber: Int, completion: @escaping (Int?,Int) -> Void)
    func fetchVoteCountOfCurrentPost(docId: String, completion: @escaping (Double,Double) -> Void)
}

class FireBaseService: FirebaseServiceProtocol {
    let pageSize = 8
    var cursor: DocumentSnapshot?
    var query: Query?
    
    func fetchInitial(completion: @escaping (Result<[Post], Error>) -> Void) {
        let db = Firestore.firestore()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        self.query = db.collection("posts")
            .order(by: "date", descending: true)
            .limit(to: pageSize)
        var nextPosts = [Post]()
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
                    guard let champion2 = document.data()["champion2"] as? String else { continue }
                    guard let text = document.data()["text"] as? String else { continue }
                    guard let date = document.data()["date"] as? Double else { continue }
                    guard let uid = document.data()["userID"] as? String else { continue }
                    nextPosts.append(Post(url: url,
                                          champion1: champion1,
                                          champion2: champion2,
                                          text: text,
                                          date: formatter.string(from: Date(timeIntervalSince1970: date)),
                                          docId: document.documentID,
                                          userId: uid))
                }
                completion(.success(nextPosts))
            }
        }
    }
    func fetchRx(fetchType: FirebaseFetchType) -> Observable<[Post]> {
        return Observable.create { [weak self] (observer) -> Disposable in
            guard let self = self else { return Disposables.create() }
            
            switch fetchType {
            case .All:
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
            case .My:
                self.fetchMyInitialPosts() { result in
                    switch result {
                    case .success(let data):
                        observer.onNext(data)
                    case .failure(let error):
                        observer.onError(error)
                    }
                    observer.onCompleted()
                }
                return Disposables.create()
            case .ByVotes:
                self.fetchInitialByVotes() { result in
                    switch result {
                    case .success(let data):
                        observer.onNext(data)
                    case .failure(let error):
                        observer.onError(error)
                    }
                    observer.onCompleted()
                }
                return Disposables.create()
            case .Next:
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
    }
    func fetchNext(completion: @escaping (Result<[Post], Error>) -> Void) {
        guard let _ = cursor, let _ = query else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        var nextPosts = [Post]()
        
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
                    guard let champion2 = document.data()["champion2"] as? String else { continue }
                    guard let text = document.data()["text"] as? String else { continue }
                    guard let date = document.data()["date"] as? Double else { continue }
                    guard let uid = document.data()["userID"] as? String else { continue }
                    nextPosts.append(Post(url: url,
                                          champion1: champion1,
                                          champion2: champion2,
                                          text: text,
                                          date: formatter.string(from: Date(timeIntervalSince1970: date)),
                                          docId: document.documentID,
                                          userId: uid))
                }
                completion(.success(nextPosts))
            }
        }
    }

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
    
    func fetchMyInitialPosts(completion: @escaping (Result<[Post], Error>) -> Void) {
        let db = Firestore.firestore()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        guard let user = Auth.auth().currentUser else { return }
        
        self.query = db.collection("posts")
            .whereField("userID", isEqualTo: user.uid)
            .order(by: "date", descending: true)
            .limit(to: pageSize)
        var nextPosts = [Post]()
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
                    guard let champion2 = document.data()["champion2"] as? String else { continue }
                    guard let text = document.data()["text"] as? String else { continue }
                    guard let date = document.data()["date"] as? Double else { continue }
                    guard let uid = document.data()["userID"] as? String else { continue }
                    nextPosts.append(Post(url: url,
                                          champion1: champion1,
                                          champion2: champion2,
                                          text: text,
                                          date: formatter.string(from: Date(timeIntervalSince1970: date)),
                                          docId: document.documentID,
                                          userId: uid))
                }
                completion(.success(nextPosts))
            }
        }
    }

    func fetchInitialByVotes(completion: @escaping (Result<[Post], Error>) -> Void) {
        let db = Firestore.firestore()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        self.query = db.collection("posts")
            .order(by: "totalVotes", descending: true)
            .limit(to: pageSize)
        var nextPosts = [Post]()
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
                    guard let champion2 = document.data()["champion2"] as? String else { continue }
                    guard let text = document.data()["text"] as? String else { continue }
                    guard let date = document.data()["date"] as? Double else { continue }
                    guard let uid = document.data()["userID"] as? String else { continue }
                    nextPosts.append(Post(url: url,
                                          champion1: champion1,
                                          champion2: champion2,
                                          text: text,
                                          date: formatter.string(from: Date(timeIntervalSince1970: date)),
                                          docId: document.documentID,
                                          userId: uid))
                }
                completion(.success(nextPosts))
            }
        }
    }
    func uploadPost(post: Post) -> DocumentReference? {
        var docRef: DocumentReference?
        if let user = Auth.auth().currentUser {
            let db = Firestore.firestore()
            docRef = db.collection("posts").addDocument(data: ["userID": user.uid,
                                                                   "url": post.url.youTubeId!,
                                                                   "champion1": post.champion1,
                                                                   "champion2": post.champion2,
                                                                   "text": post.text,
                                                                   "date": Date().timeIntervalSince1970,
                                                                   "totalVotes": 0])
        }
        return docRef
    }
    func initializeVoteData(docId: String) {
        let db = Firestore.firestore()
        db.collection("userSetForVoteByPost").document(docId).setData(["champion1VotesUsers": [],
                                                                       "champion2VotesUsers": []])
        db.collection("voteDataByPost").document(docId).setData(["champion1Votes": 0,
                                                                 "champion2Votes": 0,
                                                                 "totalVotes": 0])
    }
    func editPost(docId: String, post: Post) {
        let db = Firestore.firestore()
        let docRef = db.collection("posts").document(docId)
        var update = [String: Any]()
        update["url"] = post.url.youTubeId!
        update["champion1"] = post.champion1
        update["champion2"] = post.champion2
        update["text"] = post.text
        docRef.updateData(update) { error in
            if let _ = error { print("Editng post error occured") }
        }
    }
    func updateTotalVotesofPost(docId: String, updataType: voteUpdateType) {
        let db = Firestore.firestore()
        let docRef = db.collection("posts").document(docId)
        var update = [String:Any]()
        switch updataType {
        case .onlyAddFirst:
            update["totalVotes"] = FieldValue.increment(Int64(1))
        case .onlyDecreaseFirst:
            update["totalVotes"] = FieldValue.increment(Int64(-1))
        case .onlyAddSecond:
            update["totalVotes"] = FieldValue.increment(Int64(1))
        case .onlyDecreaseSecond:
            update["totalVotes"] = FieldValue.increment(Int64(-1))
        case .addFirstDecreaseSecond:
            break
        case .decreaseFirstAddSecond:
            break
        }
        docRef.updateData(update) { err in
            if let _ = err { print("updating posts error occured") }
        }
    }
    func updateVoteDataByUser(userId: String, docId: String, updataType: voteUpdateType) {
        let db = Firestore.firestore()
        let docRef = db.collection("voteDataByUsers").document(userId)
        var update = [String:Any]()
        switch updataType {
        case .onlyAddFirst:
            update["voteData."+docId] = 1
        case .onlyDecreaseFirst:
            update["voteData."+docId] = FieldValue.delete()
        case .onlyAddSecond:
            update["voteData."+docId] = 2
        case .onlyDecreaseSecond:
            update["voteData."+docId] = FieldValue.delete()
        case .addFirstDecreaseSecond:
            update["voteData."+docId] = 1
        case .decreaseFirstAddSecond:
            update["voteData."+docId] = 2
        }
        docRef.updateData(update) { err in
            if let _ = err { print("updating voteDataByUsers error occured") }
        }
    }
    func updateVoteDataByPost(docId: String, updataType: voteUpdateType) {
        let db = Firestore.firestore()
        let docRef = db.collection("voteDataByPost").document(docId)
        var update = [String:Any]()
        switch updataType {
        case .onlyAddFirst:
            update["champion1Votes"] = FieldValue.increment(Int64(1))
            update["totalVotes"] = FieldValue.increment(Int64(1))
        case .onlyDecreaseFirst:
            update["champion1Votes"] = FieldValue.increment(Int64(-1))
            update["totalVotes"] = FieldValue.increment(Int64(-1))
        case .onlyAddSecond:
            update["champion2Votes"] = FieldValue.increment(Int64(1))
            update["totalVotes"] = FieldValue.increment(Int64(1))
        case .onlyDecreaseSecond:
            update["champion2Votes"] = FieldValue.increment(Int64(-1))
            update["totalVotes"] = FieldValue.increment(Int64(-1))
        case .addFirstDecreaseSecond:
            update["champion1Votes"] = FieldValue.increment(Int64(1))
            update["champion2Votes"] = FieldValue.increment(Int64(-1))
        case .decreaseFirstAddSecond:
            update["champion1Votes"] = FieldValue.increment(Int64(-1))
            update["champion2Votes"] = FieldValue.increment(Int64(1))
        }
        docRef.updateData(update) { (error) in
            if let _ = error { print( "Updating voteDataByPost error occured")}
        }
    }
    func updateUserSetForVoteByPost(userId: String, docId: String, updataType: voteUpdateType) {
        let db = Firestore.firestore()
        let docRef = db.collection("userSetForVoteByPost").document(docId)
        switch updataType {

        case .onlyAddFirst:
            docRef.updateData([
                "champion1VotesUsers": FieldValue.arrayUnion([userId]),
            ]) { err in
                if let _ = err {
                    print("updating userSetForVoteByPost error occured")
                }
            }
        case .onlyDecreaseFirst:
            docRef.updateData([
                "champion1VotesUsers": FieldValue.arrayRemove([userId])
            ]) { err in
                if let _ = err {
                    print("updating userSetForVoteByPost error occured")
                }
            }
        case .onlyAddSecond:
            docRef.updateData([
                "champion2VotesUsers": FieldValue.arrayUnion([userId])
            ]) { err in
                if let _ = err {
                    print("updating userSetForVoteByPost error occured")
                }
            }
        case .onlyDecreaseSecond:
            docRef.updateData([
                "champion2VotesUsers": FieldValue.arrayRemove([userId])
            ]) { err in
                if let _ = err {
                    print("updating userSetForVoteByPost error occured")
                }
            }
        case .addFirstDecreaseSecond:
            docRef.updateData([
                "champion1VotesUsers": FieldValue.arrayUnion([userId]),
                "champion2VotesUsers": FieldValue.arrayRemove([userId])
            ]) { err in
                if let _ = err {
                    print("updating userSetForVoteByPost error occured")
                }
            }
        case .decreaseFirstAddSecond:
            docRef.updateData([
                "champion1VotesUsers": FieldValue.arrayRemove([userId]),
                "champion2VotesUsers": FieldValue.arrayUnion([userId])
            ]) { err in
                if let _ = err {
                    print("updating userSetForVoteByPost error occured")
                }
            }
        }
    }
    func fetchVoteDataOfCurrentUserForCurrentPost(userId: String, docId: String, fromPollNumber: Int, completion: @escaping (Int?,Int) -> Void) {
        let db = Firestore.firestore()
        let docRef = db.collection("voteDataByUsers").document(userId)
        docRef.getDocument() { (document, error) in
            if let document = document, document.exists {
                let key = "voteData." + docId
                let voteData = document.get(key) as? Int
                completion(voteData, fromPollNumber)
            }
            if let _ = error {
                print("Getting document error occured in fetchingVoteDataOfCurrentUserForCurrentPost")
            }
        }
    }
    func fetchVoteCountOfCurrentPost(docId: String, completion: @escaping (Double,Double) -> Void) {
        let db = Firestore.firestore()
        let docRef = db.collection("voteDataByPost").document(docId)
        docRef.getDocument{ document, error in
            if let document = document, document.exists {
                guard let count1 = document.get("champion1Votes") as? Double else { print("fetchingVoteCountOfCurrentPost error"); return }
                guard let count2 = document.get("champion2Votes") as? Double else { print("fetchingVoteCountOfCurrentPost error"); return }
                completion(count1,count2)
                
            }
        }
    }
}


