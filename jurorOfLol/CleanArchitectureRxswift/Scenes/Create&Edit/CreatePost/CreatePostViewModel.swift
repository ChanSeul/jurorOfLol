//
//  CreatePostViewModel.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/05/18.
//

import Foundation
import RxSwift
import Differentiator

final class CreatePostViewModel: ViewModelType {
    private let createPostUseCase: DomainPostsUseCase
    private let navigator: CreatePostNavigator

    init(createPostUseCase: DomainPostsUseCase, navigator: CreatePostNavigator) {
        self.createPostUseCase = createPostUseCase
        self.navigator = navigator
    }

    func transform(input: Input) -> Output {
        let postElements = Observable.combineLatest(input.url, input.champion1, input.champion2, input.detail).share(replay: 1)
        let activityIndicator = ActivityIndicator()
        let errorTracker = ErrorTracker()

        let canSave = Observable.combineLatest(postElements, activityIndicator.asObservable()) {
            return  $0.0.youTubeId != nil && !$0.0.isEmpty && !$0.1.isEmpty && !$0.2.isEmpty && !$0.3.isEmpty && !$1
        }

        let save = input.saveTrigger.withLatestFrom(postElements)
            .map { (url, champion1, champion2, detail) in
                return Post(url: url, champion1: champion1, champion2: champion2, text: detail, userID: UserDefaults.standard.getUserId() ?? "Error")
            }
            .flatMapLatest { [unowned self] in
                return self.createPostUseCase.save(post: $0)
                        .trackActivity(activityIndicator)
                        .trackError(errorTracker)
                        .catchErrorJustComplete()
            }
            .do(onNext: { NotificationCenter.default.post(name: .postUploadCompleted, object: nil) })

        let dismiss = Observable.of(save, input.cancelTrigger)
                .merge()
                .observe(on: MainScheduler.instance)
                .do(onNext: navigator.toPosts)

        return Output(dismiss: dismiss, saveEnabled: canSave, error: errorTracker.asObservable())
    }
    
    func CreatePostSections() -> Observable<[CreatePostSection]> {
        return Observable.of([CreatePostSection(model: "", items: ["url", "champion1", "champion2", "detail"])])
    }
}

extension CreatePostViewModel {
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
        let error: Observable<Error>
    }
}

typealias CreatePostSection = AnimatableSectionModel<String, String>

