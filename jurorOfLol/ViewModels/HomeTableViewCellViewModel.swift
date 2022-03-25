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
    //var updateChampionVotesUsers: AnyObserver<(userId: String, docId: String, fromPollNumber: Int)> { get }
    var updateData: AnyObserver<(userId: String, docId: String, fromPollNumber: Int, updateType: voteUpdateType)> { get }
    var fetchVoteDataOfCurrentUserForCurrentPost: AnyObserver<(userId: String, docId: String, fromPollNumber: Int)> { get }
    var fetchVoteCountOfCurrentPost: AnyObserver<String> { get }
    var setActivating: AnyObserver<Bool> { get }
    
    var activated: Observable<Bool> { get }
    var voteDataOfCurrentUserForCurrentPost: Observable<(voteData: Int?,fromPollNumber: Int)> { get }
    //var voteCountOfCurrentPost: Driver<(Double,Double)> { get }
    var VoteCountOfCurrentPost: BehaviorRelay<(Double, Double)> { get }
}
class HomeTableViewCellViewModel: HomeTableViewCellViewModelType {
    let disposeBag = DisposeBag()
    //let updateChampionVotesUsers: AnyObserver<(userId: String, docId: String, fromPollNumber: Int)>
    let updateData: AnyObserver<(userId: String, docId: String, fromPollNumber: Int, updateType: voteUpdateType)>
    let fetchVoteDataOfCurrentUserForCurrentPost: AnyObserver<(userId: String, docId: String, fromPollNumber: Int)>
    let fetchVoteCountOfCurrentPost: AnyObserver<String>
    var setActivating: AnyObserver<Bool>
    
    let activated: Observable<Bool>
    let voteDataOfCurrentUserForCurrentPost: Observable<(voteData: Int?,fromPollNumber: Int)>
    let VoteCountOfCurrentPost = BehaviorRelay<(Double, Double)>(value: (0.0, 0.0))
    //let voteCountOfCurrentPost: Driver<(Double,Double)>
    
    
    init() {
        let db = Firestore.firestore()
        
        //let updatingData = PublishSubject<(userId: String, docId: String, fromPollNumber: Int)>()
        let updatingData = PublishSubject<(userId: String, docId: String, fromPollNumber: Int, updateType: voteUpdateType)>()
        let fetchingVoteDataOfCurrentUserForCurrentPost = PublishSubject<(userId: String, docId: String, fromPollNumber: Int)>()
        let fetchingVoteCountOfCurrentPost = PublishSubject<String>()
        let activating = BehaviorSubject<Bool>(value: false)
        
        let fetchedVoteDataForCurrentPost = PublishSubject<(voteData: Int?, fromPollNumber: Int)>()
        
        
        //INPUT
        //updateChampionVotesUsers = updatingChampionVotesUsers.asObserver()
        updateData = updatingData.asObserver()
        fetchVoteDataOfCurrentUserForCurrentPost = fetchingVoteDataOfCurrentUserForCurrentPost.asObserver()
        fetchVoteCountOfCurrentPost = fetchingVoteCountOfCurrentPost.asObserver()
        setActivating = activating.asObserver()
        
        //OUTPUT
        activated = activating.asObservable()
        voteDataOfCurrentUserForCurrentPost = fetchedVoteDataForCurrentPost.asObservable()
        
        updatingData
            .subscribe(onNext: { (userId, docId, fromPollNumber, updataType) in
                Task {
                    let result = await withTaskGroup(of: Void.self, body: { taskGroup in
                        taskGroup.addTask {
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
                        taskGroup.addTask {
                            let docRef = db.collection("posts").document(docId)
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
                        taskGroup.addTask {
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
//                            if fromPollNumber == 1 {
//                                docRef.updateData([
//                                    "champion1VotesUsers": FieldValue.arrayUnion([userId]),
//                                    "champion2VotesUsers": FieldValue.arrayRemove([userId])
//                                ]) { err in
//                                    if let _ = err {
//                                        print("updating userSetForVoteByPost error occured")
//                                    }
//                                }
//                            }
//                            else if fromPollNumber == 2 {
//                                docRef.updateData([
//                                    "champion1VotesUsers": FieldValue.arrayRemove([userId]),
//                                    "champion2VotesUsers": FieldValue.arrayUnion([userId])
//                                ]) { err in
//                                    if let _ = err {
//                                        print("updating userSetForVoteByPost error occured")
//                                    }
//                                }
//                            }
                        }
                    })
                    activating.onNext(false)
                }
            })
            .disposed(by: disposeBag)

        fetchingVoteDataOfCurrentUserForCurrentPost
            .subscribe(onNext: { userId, docId, fromPollNumber in
                let docRef = db.collection("voteDataByUsers").document(userId)
                docRef.getDocument() { [weak self] document, error in
                    if let document = document, document.exists {
                        let key = "voteData." + docId
                        let voteData = document.get(key) as? Int
                        fetchedVoteDataForCurrentPost.onNext((voteData: voteData, fromPollNumber: fromPollNumber))
                    }
                    if let _ = error {
                        print("Getting document error occured in fetchingVoteDataOfCurrentUserForCurrentPost")
                    }
                }
            })
            .disposed(by: disposeBag)
        
        fetchingVoteCountOfCurrentPost
            .subscribe(onNext: { (docId) in
                let docRef = db.collection("posts").document(docId)
                docRef.getDocument{ [weak self] document, error in
                    if let document = document, document.exists {
                        guard let count1 = document.get("champion1Votes") as? Double else { print("fetchingVoteCountOfCurrentPost error"); return }
                        guard let count2 = document.get("champion2Votes") as? Double else { print("fetchingVoteCountOfCurrentPost error"); return }
                        self?.VoteCountOfCurrentPost.accept((count1, count2))
                    }
                }
            })
            .disposed(by: disposeBag)
    }
}
