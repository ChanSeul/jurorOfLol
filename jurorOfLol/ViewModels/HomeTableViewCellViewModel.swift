//
//  HomeTableViewCellViewModel.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/03/06.
//

import UIKit
import Firebase
import FirebaseFirestore
import RxSwift
import RxRelay
import RxCocoa

protocol HomeTableViewCellViewModelType {
    var updateChampion1VotesUsers: AnyObserver<(userId: String, docId: String)> { get }
    var updateChampion2VotesUsers: AnyObserver<(userId: String, docId: String)> { get }
    var updateUsersVoteInfo: AnyObserver<(userId: String, docId: String, fromPollNumber: Int)> { get }
    var fetchUserInfoAboutVote: AnyObserver<(userId: String, docId: String, fromPollNumber: Int)> { get }
    var voteInfoAboutPost: Observable<(voteInfo: Int?,fromPollNumber: Int)> { get }
}
class HomeTableViewCellViewModel: HomeTableViewCellViewModelType {
    let disposeBag = DisposeBag()
    let updateChampion1VotesUsers: AnyObserver<(userId: String, docId: String)>
    let updateChampion2VotesUsers: AnyObserver<(userId: String, docId: String)>
    let updateUsersVoteInfo: AnyObserver<(userId: String, docId: String, fromPollNumber: Int)>
    let fetchUserInfoAboutVote: AnyObserver<(userId: String, docId: String, fromPollNumber: Int)>
    let voteInfoAboutPost: Observable<(voteInfo: Int?,fromPollNumber: Int)>
    
    init() {
        let db = Firestore.firestore()
        
        let updatingChampion1VotesUsers = PublishSubject<(userId: String, docId: String)>()
        let updatingChampion2VotesUsers = PublishSubject<(userId: String, docId: String)>()
        let updatingUsersVoteInfo = PublishSubject<(userId: String, docId: String, fromPollNumber: Int)>()
        let fetchingUserInfo = PublishSubject<(userId: String, docId: String, fromPollNumber: Int)>()
        
        let userVoteInfo = PublishSubject<(voteInfo: Int?, fromPollNumber: Int)>()
        
        //INPUT
        updateChampion1VotesUsers = updatingChampion1VotesUsers.asObserver()
        updateChampion2VotesUsers = updatingChampion2VotesUsers.asObserver()
        updateUsersVoteInfo = updatingUsersVoteInfo.asObserver()
        fetchUserInfoAboutVote = fetchingUserInfo.asObserver()
        
        //OUTPUT
        voteInfoAboutPost = userVoteInfo.asObservable()
        
        updatingChampion1VotesUsers
            .subscribe(onNext: { userID, docId in
                let postRef = db.collection("posts").document(docId)
                postRef.updateData([
                    "champion1VotesUsers": FieldValue.arrayUnion([userID]),
                    "champion2VotesUsers": FieldValue.arrayRemove([userID])
                ]){  err in
                    if let err = err {
                        print("updatingVotes1 postReferror occured")
                    }
                }
        })
            .disposed(by: disposeBag)
        
        updatingChampion2VotesUsers
            .subscribe(onNext: { userId, docId in
                let postRef = db.collection("posts").document(docId)
                postRef.updateData([
                    "champion1VotesUsers": FieldValue.arrayRemove([userId]),
                    "champion2VotesUsers": FieldValue.arrayUnion([userId])
                ]) { err in
                    if let err = err {
                        print("updatingVotes2 error occured")
                    }
                }
        })
            .disposed(by: disposeBag)
        
        updatingUsersVoteInfo
            .subscribe(onNext: { userId, docId, fromPollNumber in
                let docRef = db.collection("users").document(userId)
                let key = "voteInfo."+docId
                var update = [String:Any]()
                update[key] = fromPollNumber
                docRef.updateData(update) { err in
                                        if let err = err {
                                            print("updatingUsersVoteInfo error occured")
                                        }
                                    }
            })
            .disposed(by: disposeBag)
        
        fetchingUserInfo
            .subscribe(onNext: { userId, docId, fromPollNumber in
                let docRef = db.collection("users").document(userId)
                docRef.getDocument() { document, error in
                    if let document = document, document.exists {
                        let key = "voteInfo." + docId
                        let voteInfo = document.get(key) as? Int
                        userVoteInfo.onNext((voteInfo: voteInfo, fromPollNumber: fromPollNumber))
                    }
                    if let error = error {
                        print("Getting document error occured in fetchingUserInfo")
                    }
                }
            })
            .disposed(by: disposeBag)
    }
}
