//
//  UploadViewModel.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/03/14.
//
import Foundation
import RxSwift
import RxCocoa
import Firebase
import FirebaseFirestore

protocol UploadViewModelType {
    var uploadPost: AnyObserver<Void> { get }
    var editPost: AnyObserver<String> { get }
    var writePost: AnyObserver<ViewPost> { get }
    var writtenPost: Observable<ViewPost> { get }
}

class UploadViewModel: UploadViewModelType{
    var disposeBag = DisposeBag()
    let uploadPost: AnyObserver<Void>
    let editPost: AnyObserver<String>
    let writePost: AnyObserver<ViewPost>
    let writtenPost: Observable<ViewPost>
    
    init(fireBaseService: FirebaseServiceProtocol = FireBaseService()) {
        let uploadingPost = PublishSubject<Void>()
        let initializingVoteData = PublishSubject<String>()
        let editingPost = PublishSubject<String>()
        let writtingPost = PublishSubject<ViewPost>()
        let currentWrittenPost = BehaviorSubject<ViewPost>(value: ViewPost(url: "", champion1: "", champion2: "", text: "", date: "", docId: "", userId: ""))
        
        //INPUT
        uploadPost = uploadingPost.asObserver()
        
        uploadingPost
            .withLatestFrom(currentWrittenPost)
            .subscribe(onNext: { (currentWrittenPost) in
                if let docRef = fireBaseService.uploadPost(post: currentWrittenPost.ViewPostToPost()) {
                    initializingVoteData.onNext(docRef.documentID)
                }
            })
            .disposed(by: disposeBag)
        
        initializingVoteData
            .subscribe(onNext: { (docId) in
                fireBaseService.initializeVoteData(docId: docId)
            })
            .disposed(by: disposeBag)
        
        editPost = editingPost.asObserver()
        
        editingPost
            .withLatestFrom(currentWrittenPost) { ($0, $1) }
            .subscribe(onNext: { (docId, currentWrittenPost) in
                fireBaseService.editPost(docId: docId, post: currentWrittenPost.ViewPostToPost())
            })
            .disposed(by: disposeBag)
        
        writePost = writtingPost.asObserver()
        
        writtingPost
            .subscribe(onNext: { (newWritten) in
                currentWrittenPost.onNext(newWritten)
            })
            .disposed(by: disposeBag)
        
        //OUTPUT
        writtenPost = currentWrittenPost.asObservable()
    }
}
