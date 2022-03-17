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
    var fetchPosts: AnyObserver<Void> { get }
    var clearPosts: AnyObserver<Void> { get }
    //var refetchPosts: AnyObserver<(row: Int, docId: String)> { get }
    
    var activated: Observable<Bool> { get }
    var errorMessage: Observable<NSError> { get }
    var allPosts: Observable<[ViewPost]> { get }
    
}

class HomeViewModel: HomeViewModelType {
    let disposeBag = DisposeBag()
    
    // INPUT
    let fetchPosts: AnyObserver<Void>
    let clearPosts: AnyObserver<Void>
    //let refetchPosts: AnyObserver<(row: Int, docId: String)>
    
    // OUTPUT
    let activated: Observable<Bool>
    let errorMessage: Observable<NSError>
    let allPosts: Observable<[ViewPost]>
    
    
    init(fireBaseService: FirebaseServiceProtocol = FireBaseService()) {
        let fetchingPosts = PublishSubject<Void>()
        let clearing = PublishSubject<Void>()
        //let refetching = PublishSubject<(row: Int, docId: String)>()
        let activating = BehaviorSubject<Bool>(value: false)
        let error = PublishSubject<Error>()
        let posts = BehaviorRelay<[ViewPost]>(value: [])
        
        
        
        // INPUT
        
        fetchPosts = fetchingPosts.asObserver()
        
        fetchingPosts
            .do(onNext: { _ in activating.onNext(true) })
            .withLatestFrom(posts)
            .map { $0.count }
            .flatMap{ (count) -> Observable<[post]> in
                    fireBaseService.fetchPostsRx(startIdx: count) }
            .map { $0.map { ViewPost(post: $0) } }
            .do(onNext: { _ in activating.onNext(false) })
            .do(onError: { err in error.onNext(err) })
            .subscribe(onNext: { newPosts in
                let oldPosts = posts.value
                posts.accept(oldPosts + newPosts)
            })
            .disposed(by: disposeBag)
                
        clearPosts = clearing.asObserver()
        
        clearing
            .subscribe(onNext: {
                posts.accept([])
            })
            .disposed(by: disposeBag)
        
    
        // OUTPUT
        
        activated = activating.distinctUntilChanged()
        errorMessage = error.map { $0 as NSError }
        allPosts = posts.asObservable()
        
    }
}

