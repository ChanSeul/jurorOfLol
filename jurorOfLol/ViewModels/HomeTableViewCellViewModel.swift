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
    var updateData: AnyObserver<(userId: String, docId: String, fromPollNumber: Int, updateType: voteUpdateType)> { get }
    var fetchVoteDataOfCurrentUserForCurrentPost: AnyObserver<(userId: String, docId: String, fromPollNumber: Int)> { get }
    var fetchVoteCountOfCurrentPost: AnyObserver<String> { get }
    var setActivating: AnyObserver<Bool> { get }
    
    var activated: Observable<Bool> { get }
    var voteDataOfCurrentUserForCurrentPost: Observable<(voteData: Int?,fromPollNumber: Int)> { get }
    var VoteCountOfCurrentPost: BehaviorRelay<(Double, Double)> { get }
}
class HomeTableViewCellViewModel: HomeTableViewCellViewModelType {
    let disposeBag = DisposeBag()
    
    let updateData: AnyObserver<(userId: String, docId: String, fromPollNumber: Int, updateType: voteUpdateType)>
    let fetchVoteDataOfCurrentUserForCurrentPost: AnyObserver<(userId: String, docId: String, fromPollNumber: Int)>
    let fetchVoteCountOfCurrentPost: AnyObserver<String>
    var setActivating: AnyObserver<Bool>
    
    let activated: Observable<Bool>
    let voteDataOfCurrentUserForCurrentPost: Observable<(voteData: Int?,fromPollNumber: Int)>
    let VoteCountOfCurrentPost = BehaviorRelay<(Double, Double)>(value: (0.0, 0.0))
    
    
    init(fireBaseService: FirebaseServiceProtocol = FireBaseService()) {
        let updatingData = PublishSubject<(userId: String, docId: String, fromPollNumber: Int, updateType: voteUpdateType)>()
        let fetchingVoteDataOfCurrentUserForCurrentPost = PublishSubject<(userId: String, docId: String, fromPollNumber: Int)>()
        let fetchingVoteCountOfCurrentPost = PublishSubject<String>()
        let activating = BehaviorSubject<Bool>(value: false)
        
        let fetchedVoteDataForCurrentPost = PublishSubject<(voteData: Int?, fromPollNumber: Int)>()
        
        
        //INPUT
        updateData = updatingData.asObserver()
        fetchVoteDataOfCurrentUserForCurrentPost = fetchingVoteDataOfCurrentUserForCurrentPost.asObserver()
        fetchVoteCountOfCurrentPost = fetchingVoteCountOfCurrentPost.asObserver()
        setActivating = activating.asObserver()
        
        //OUTPUT
        activated = activating.asObservable()
        voteDataOfCurrentUserForCurrentPost = fetchedVoteDataForCurrentPost.asObservable()
        
        updatingData
            .subscribe(onNext: { (userId, docId, _, updataType) in
                Task {
                    let _ = await withTaskGroup(of: Void.self, body: { taskGroup in
                        taskGroup.addTask {
                            fireBaseService.updateTotalVotesofPost(docId: docId, updataType: updataType)
                        }
                        taskGroup.addTask {
                            fireBaseService.updateVoteDataByUser(userId: userId, docId: docId, updataType: updataType)
                        }
                        taskGroup.addTask {
                            fireBaseService.updateVoteDataByPost(docId: docId, updataType: updataType)
                        }
                        taskGroup.addTask {
                            fireBaseService.updateUserSetForVoteByPost(userId: userId, docId: docId, updataType: updataType)
                        }
                    })
                    activating.onNext(false)
                }
            })
            .disposed(by: disposeBag)

        fetchingVoteDataOfCurrentUserForCurrentPost
            .subscribe(onNext: { userId, docId, fromPollNumber in
                fireBaseService.fetchVoteDataOfCurrentUserForCurrentPost(userId: userId, docId: docId, fromPollNumber: fromPollNumber) { (voteData, fromPollNumber) in
                    fetchedVoteDataForCurrentPost.onNext((voteData: voteData, fromPollNumber: fromPollNumber))
                }
            })
            .disposed(by: disposeBag)
        
        fetchingVoteCountOfCurrentPost
            .subscribe(onNext: { [weak self] (docId) in
                fireBaseService.fetchVoteCountOfCurrentPost(docId: docId) { (count1, count2) in
                    self?.VoteCountOfCurrentPost.accept((count1, count2))
                }
            })
            .disposed(by: disposeBag)
    }
}
