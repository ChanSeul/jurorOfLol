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
import simd

protocol HomeTableViewCellViewModelType {
    var updateChampionVotesUsers: AnyObserver<(userId: String, docId: String, fromPollNumber: Int)> { get }
    var updateUsersVoteInfo: AnyObserver<(userId: String, docId: String, fromPollNumber: Int, updateType: voteUpdateType)> { get }
    var fetchUserInfoAboutVote: AnyObserver<(userId: String, docId: String, fromPollNumber: Int)> { get }
    var setActivating: AnyObserver<Bool> { get }
    
    var activated: Observable<Bool> { get }
    var voteInfoAboutPost: Observable<(voteInfo: Int?,fromPollNumber: Int)> { get }
}
class HomeTableViewCellViewModel: HomeTableViewCellViewModelType {
    let disposeBag = DisposeBag()
    let updateChampionVotesUsers: AnyObserver<(userId: String, docId: String, fromPollNumber: Int)>
    let updateUsersVoteInfo: AnyObserver<(userId: String, docId: String, fromPollNumber: Int, updateType: voteUpdateType)>
    let fetchUserInfoAboutVote: AnyObserver<(userId: String, docId: String, fromPollNumber: Int)>
    var setActivating: AnyObserver<Bool>
    
    let activated: Observable<Bool>
    let voteInfoAboutPost: Observable<(voteInfo: Int?,fromPollNumber: Int)>
    
    
    init() {
        let db = Firestore.firestore()
        let updatingChampionVotesUsers = PublishSubject<(userId: String, docId: String, fromPollNumber: Int)>()
        let updatingUsersVoteInfo = PublishSubject<(userId: String, docId: String, fromPollNumber: Int, updateType: voteUpdateType)>()
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
                
                let docRef = db.collection("userSetForVoteByPost").document(docId)
                if fromPollNumber == 1 {
                    docRef.updateData([
                        "champion1VotesUsers": FieldValue.arrayUnion([userId]),
                        "champion2VotesUsers": FieldValue.arrayRemove([userId])
                    ]) { err in
                        if let err = err {
                            print("updatingVotes1 postReferror occured")
                        }
                    }
                }
                else if fromPollNumber == 2 {
                    docRef.updateData([
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
            .subscribe(onNext: { (userId, docId, fromPollNumber, updataType) in
                Task {
                    let result = await withTaskGroup(of: Void.self, body: { taskGroup in
                        taskGroup.addTask {
                            let docRef = db.collection("voteDataByUsers").document(userId)
                            var update = [String:Any]()
                            update["voteData."+docId] = fromPollNumber
                            docRef.updateData(update) { err in
                                if let err = err { print("updatingUsersVoteInfo error occured") }
                            }
                        }
                        taskGroup.addTask {
                            let docRef = db.collection("voteDataByPost").document(docId)
                            switch updataType {
                            case .onlyAddFirst:
                                var update = [String:Any]()
                                update["champion1Votes"] = FieldValue.increment(Int64(1))
                                docRef.updateData(update) { (error) in
                                    if let error = error { print( "Updating voteDataByPost error occured")}
                                }
                            case .onlyAddSecond:
                                var update = [String:Any]()
                                update["champion2Votes"] = FieldValue.increment(Int64(1))
                                docRef.updateData(update) { (error) in
                                    if let error = error { print( "Updating voteDataByPost error occured")}
                                }
                            case .addFirstDecreaseSecond:
                                var update = [String:Any]()
                                update["champion1Votes"] = FieldValue.increment(Int64(1))
                                update["champion2Votes"] = FieldValue.increment(Int64(-1))
                                docRef.updateData(update) { (error) in
                                    if let error = error { print( "Updating voteDataByPost error occured")}
                                }
                            case .decreaseFirstAddSecond:
                                var update = [String:Any]()
                                update["champion1Votes"] = FieldValue.increment(Int64(-1))
                                update["champion2Votes"] = FieldValue.increment(Int64(1))
                                docRef.updateData(update) { (error) in
                                    if let error = error { print( "Updating voteDataByPost error occured")}
                                }
                            }
                        }
                        taskGroup.addTask {
                            let docRef = db.collection("userSetForVoteByPost").document(docId)
                            if fromPollNumber == 1 {
                                docRef.updateData([
                                    "champion1VotesUsers": FieldValue.arrayUnion([userId]),
                                    "champion2VotesUsers": FieldValue.arrayRemove([userId])
                                ]) { err in
                                    if let err = err {
                                        print("updating voteDataByPost(1) error occured")
                                    }
                                }
                            }
                            else if fromPollNumber == 2 {
                                docRef.updateData([
                                    "champion1VotesUsers": FieldValue.arrayRemove([userId]),
                                    "champion2VotesUsers": FieldValue.arrayUnion([userId])
                                ]) { err in
                                    if let err = err {
                                        print("updating voteDataByPost(2) error occured")
                                    }
                                }
                            }
                        }
                    })
                    activating.onNext(false)
                }
            })
            .disposed(by: disposeBag)

        fetchingUserInfo
            .subscribe(onNext: { userId, docId, fromPollNumber in
                let docRef = db.collection("voteDataByUsers").document(userId)
                docRef.getDocument() { [weak self] document, error in
                    if let document = document, document.exists {
                        let key = "voteData." + docId
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
