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
    var writePost: AnyObserver<post> { get }
    var writtenPost: Observable<post> { get }
}

class UploadViewModel: UploadViewModelType{
    var disposeBag = DisposeBag()
    
    let uploadPost: AnyObserver<Void>
    let editPost: AnyObserver<String>
    let writePost: AnyObserver<post>
    
    let writtenPost: Observable<post>
    
    init() {
        let uploadingPost = PublishSubject<Void>()
        let uploadingVoteData = PublishSubject<String>()
        let editingPost = PublishSubject<String>()
        let writtingPost = PublishSubject<post>()
        let currentWrittenPost = BehaviorSubject<post>(value: post(url: "", champion1: "", champion2: "", text: "", date: "", docId: "", userId: ""))
        
        //INPUT
        uploadPost = uploadingPost.asObserver()
        
        uploadingPost
            .withLatestFrom(currentWrittenPost)
            .subscribe(onNext: { (currentWrittenPost) in
                guard let user = Auth.auth().currentUser else { return }
                let db = Firestore.firestore()
                let docRef = db.collection("posts").addDocument(data: ["userID": user.uid,
                                                                       "url": currentWrittenPost.url.youTubeId!,
                                                                       "champion1": currentWrittenPost.champion1,
                                                                       "champion2": currentWrittenPost.champion2,
                                                                       "champion1Votes": 0,
                                                                       "champion2Votes": 0,
                                                                       "text": currentWrittenPost.text,
                                                                       "date": Date().timeIntervalSince1970])
                
                uploadingVoteData.onNext(docRef.documentID)
            })
            .disposed(by: disposeBag)
        
        uploadingVoteData
            .subscribe(onNext: { (docId) in
                let db = Firestore.firestore()
                db.collection("userSetForVoteByPost").document(docId).setData(["champion1VotesUsers": [],
                                                                               "champion2VotesUsers": []])
//                guard let user = Auth.auth().currentUser else { return }
//                var initial = [String:Any]()
//                initial["voteData."+docId] = 0
//                db.collection("voteDataByUsers").document(user.uid).setData(["voteData": nil])
//                db.collection("voteDataByPost").document(docId).setData(["champion1Votes": 0,
//                                                                         "champion2Votes": 0])
            })
            .disposed(by: disposeBag)
        
        editPost = editingPost.asObserver()
        
        editingPost
            .withLatestFrom(currentWrittenPost) { ($0, $1) }
            .subscribe(onNext: { (docId, currentWrittenPost) in
                let db = Firestore.firestore()
                let docRef = db.collection("posts").document(docId)
                var update = [String: Any]()
                update["url"] = currentWrittenPost.url.youTubeId!
                update["champion1"] = currentWrittenPost.champion1
                update["champion2"] = currentWrittenPost.champion2
                update["text"] = currentWrittenPost.text
                docRef.updateData(update) { error in
                    if let _ = error { print("Editng post error occured") }
                }
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
