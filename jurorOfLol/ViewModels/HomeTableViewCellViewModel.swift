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
    var updateChampionVotesUsers: AnyObserver<(userId: String, docId: String, fromPollNumber: Int)> { get }
    var updateUsersVoteInfo: AnyObserver<(userId: String, docId: String, fromPollNumber: Int)> { get }
    var fetchUserInfoAboutVote: AnyObserver<(userId: String, docId: String, fromPollNumber: Int)> { get }
    var setActivating: AnyObserver<Bool> { get }
    
    var activated: Observable<Bool> { get }
    var voteInfoAboutPost: Observable<(voteInfo: Int?,fromPollNumber: Int)> { get }
}
class HomeTableViewCellViewModel: HomeTableViewCellViewModelType {
    let disposeBag = DisposeBag()
    let updateChampionVotesUsers: AnyObserver<(userId: String, docId: String, fromPollNumber: Int)>
    let updateUsersVoteInfo: AnyObserver<(userId: String, docId: String, fromPollNumber: Int)>
    let fetchUserInfoAboutVote: AnyObserver<(userId: String, docId: String, fromPollNumber: Int)>
    var setActivating: AnyObserver<Bool>
    
    let activated: Observable<Bool>
    let voteInfoAboutPost: Observable<(voteInfo: Int?,fromPollNumber: Int)>
    
    
    init() {
        let db = Firestore.firestore()
        let updatingChampionVotesUsers = PublishSubject<(userId: String, docId: String, fromPollNumber: Int)>()
        let updatingUsersVoteInfo = PublishSubject<(userId: String, docId: String, fromPollNumber: Int)>()
        let fetchingUserInfo = PublishSubject<(userId: String, docId: String, fromPollNumber: Int)>()
        let activating = BehaviorSubject<Bool>(value: false)
        let userVoteInfo = PublishSubject<(voteInfo: Int?, fromPollNumber: Int)>()
        
        //INPUT
        updateChampionVotesUsers = updatingChampionVotesUsers.asObserver()
        updateUsersVoteInfo = updatingUsersVoteInfo.asObserver()
        fetchUserInfoAboutVote = fetchingUserInfo.asObserver()
        setActivating = activating.asObserver()
        
        //OUTPUT
        activated = activating.asObservable()
        voteInfoAboutPost = userVoteInfo.asObservable()
        
        
        updatingChampionVotesUsers
            .subscribe(onNext: { [weak self] userId, docId, fromPollNumber in
                
                let postRef = db.collection("posts").document(docId)
                if fromPollNumber == 1 {
                    postRef.updateData([
                        "champion1VotesUsers": FieldValue.arrayUnion([userId]),
                        "champion2VotesUsers": FieldValue.arrayRemove([userId])
                    ]){ err in
                        if let err = err {
                            print("updatingVotes1 postReferror occured")
                        }
                    }
                }
                else if fromPollNumber == 2 {
                    postRef.updateData([
                        "champion1VotesUsers": FieldValue.arrayRemove([userId]),
                        "champion2VotesUsers": FieldValue.arrayUnion([userId])
                    ]) { err in
                        if let err = err {
                            print("updatingVotes2 error occured")
                        }
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
                    if let err = err { print("updatingUsersVoteInfo error occured") }
                    else { activating.onNext(false); print("햿잖아")}
                }
            })
            .disposed(by: disposeBag)

        fetchingUserInfo
            .subscribe(onNext: { userId, docId, fromPollNumber in
                let docRef = db.collection("users").document(userId)
                docRef.getDocument() { [weak self] document, error in
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
