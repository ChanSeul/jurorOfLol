//
//  HomeTableViewModel.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/03/01.
//

import Foundation
import RxSwift
import RxRelay
import RxCocoa
import Firebase

protocol HomeViewModelType {
    var fetchInitial: AnyObserver<Void> { get }
    var fetchNext: AnyObserver<Void> { get }
    var fetchInitialByVotes: AnyObserver<Void> { get }
    var clearPosts: AnyObserver<Void> { get }
    var deletePost: AnyObserver<String> { get }
    
    var activated: Observable<Bool> { get }
    var errorMessage: Observable<NSError> { get }
    var allPosts: Observable<[ViewPost]> { get }
    
}

class HomeViewModel: HomeViewModelType {
    let disposeBag = DisposeBag()
    
    // INPUT
    let fetchInitial: AnyObserver<Void>
    let fetchNext: AnyObserver<Void>
    let fetchInitialByVotes: AnyObserver<Void>
    let clearPosts: AnyObserver<Void>
    let deletePost: AnyObserver<String>
    
    // OUTPUT
    let activated: Observable<Bool>
    let errorMessage: Observable<NSError>
    let allPosts: Observable<[ViewPost]>
    
    
    init(fireBaseService: FirebaseServiceProtocol = FireBaseService()) {
        let fetchingInitial = PublishSubject<Void>()
        let fetchingNext = PublishSubject<Void>()
        let fetchingInitialByVotes = PublishSubject<Void>()
        let clearing = PublishSubject<Void>()
        let deletingPost = PublishSubject<String>()
        let activating = BehaviorSubject<Bool>(value: false)
        let error = PublishSubject<Error>()
        let posts = BehaviorRelay<[ViewPost]>(value: [])
        
        
        
        // INPUT
        fetchInitial = fetchingInitial.asObserver()
        
        fetchingInitial
            .do(onNext: { _ in activating.onNext(true) })
            .flatMap{ fireBaseService.fetchInitialRx() }
            .map { $0.map { ViewPost(post: $0) } }
            .do(onNext: { _ in activating.onNext(false) })
            .do(onError: { err in error.onNext(err) })
            .subscribe(onNext: { (initialPosts) in
                posts.accept(initialPosts)
            })
            .disposed(by: disposeBag)
        
        fetchNext = fetchingNext.asObserver()
        
        fetchingNext
            .do(onNext: { _ in activating.onNext(true) })
            .flatMap{ fireBaseService.fetchNextRx() }
            .map { $0.map { ViewPost(post: $0) } }
            .do(onNext: { _ in activating.onNext(false) })
            .do(onError: { err in error.onNext(err) })
            .subscribe(onNext: { newPosts in
                let oldPosts = posts.value
                posts.accept(oldPosts + newPosts)
            })
            .disposed(by: disposeBag)
                
        fetchInitialByVotes = fetchingInitialByVotes.asObserver()
                
        fetchingInitialByVotes
            .do(onNext: { _ in activating.onNext(true) })
            .flatMap{ fireBaseService.fetchInitialByVotesRx() }
            .map { $0.map { ViewPost(post: $0) } }
            .do(onNext: { _ in activating.onNext(false) })
            .do(onError: { err in error.onNext(err) })
            .subscribe(onNext: { (initialPosts) in
                posts.accept(initialPosts)
            })
            .disposed(by: disposeBag)
                    
        clearPosts = clearing.asObserver()
        
        clearing
            .subscribe(onNext: {
                posts.accept([])
            })
            .disposed(by: disposeBag)
        
        deletePost = deletingPost.asObserver()
                
        deletingPost
            .subscribe(onNext: { (docId) in
                fireBaseService.deletePost(docId: docId) {
                    fetchingInitial.onNext(())
                }
            })
            .disposed(by: disposeBag)
    
        // OUTPUT
        
        activated = activating.distinctUntilChanged()
        errorMessage = error.map { $0 as NSError }
        allPosts = posts.asObservable()
        
    }
}
