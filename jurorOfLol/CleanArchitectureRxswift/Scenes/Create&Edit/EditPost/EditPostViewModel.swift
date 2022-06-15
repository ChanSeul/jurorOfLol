//
//  EditPostViewController.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/06/04.
//

import Foundation
import RxSwift
import Differentiator

final class EditPostViewModel: ViewModelType {
    private let post: Post
    private let editPostUseCase: DomainPostsUseCase
    private let navigator: EditPostNavigator

    init(post: Post, editPostUseCase: DomainPostsUseCase, navigator: EditPostNavigator) {
        self.post = post
        self.editPostUseCase = editPostUseCase
        self.navigator = navigator
    }

    func transform(input: Input) -> Output {
        let activityIndicator = ActivityIndicator()
        let errorTracker = ErrorTracker()
        
        let postElements = Observable.combineLatest(input.url, input.champion1, input.champion2, input.detail).share(replay: 1)

        let canSave = Observable.combineLatest(postElements, activityIndicator.asObservable()) {
            return $0.0.youTubeId != nil && !$0.0.isEmpty && !$0.1.isEmpty && !$0.2.isEmpty && !$0.3.isEmpty && !$1
        }
        
        let prePost = Observable.just(self.post).share(replay: 1)
        
        let post = Observable.combineLatest(prePost, postElements) { (post, postElements) -> Post in
            return Post(url: postElements.0, champion1: postElements.1, champion2: postElements.2, text: postElements.3, docID: post.docID)
        }
            .startWith(self.post)
            .share(replay: 1)
        
        let edit = input.saveTrigger.withLatestFrom(post)
            .flatMapLatest { [unowned self] post in
                return self.editPostUseCase.editPost(post: post)
                        .trackActivity(activityIndicator)
                        .trackError(errorTracker)
                        .catchErrorJustComplete()
            }
            .do(onNext: { NotificationCenter.default.post(name: .postUploadCompleted, object: nil) })

        let dismiss = Observable.of(edit, input.cancelTrigger)
                .merge()
                .observe(on: MainScheduler.instance)
                .do(onNext: navigator.toPosts)

        return Output(dismiss: dismiss, saveEnabled: canSave, edit: edit, error: errorTracker.asObservable(), prePost: prePost)
    }
    
    func EditPostSections() -> Observable<[EditPostSection]> {
        Observable.of([EditPostSection(model: "", items: ["url", "champion1", "champion2", "detail"])])
    }
}

extension EditPostViewModel {
    struct Input {
        let cancelTrigger: Observable<Void>
        let saveTrigger: Observable<Void>
        let url: Observable<String>
        let champion1: Observable<String>
        let champion2: Observable<String>
        let detail: Observable<String>
    }

    struct Output {
        let dismiss: Observable<Void>
        let saveEnabled: Observable<Bool>
        let edit: Observable<Void>
        let error: Observable<Error>
        let prePost: Observable<Post>
    }
}

typealias EditPostSection = AnimatableSectionModel<String, String>


