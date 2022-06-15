//
//  PostsViewModel.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/05/16.
//

import Foundation
import RxSwift
import Differentiator

final class PostsViewModel: ViewModelType {
    private let postUseCase: DomainPostsUseCase
    private let voteUseCase: DomainVotesUseCase
    private let navigator: PostsNavigator
    private var orderBy: OrderBy // 게시물 정렬 타입
    private let isMain: Bool // 홈화면의 PostViewController만이 서버의 게시물과 유저의 데이터를 업데이트함
    
    private let disposeBag = DisposeBag()
    
    init(postUseCase: DomainPostsUseCase, voteUseCase: DomainVotesUseCase, navigator: PostsNavigator, orderBy: OrderBy, isMain: Bool) {
        self.postUseCase = postUseCase
        self.voteUseCase = voteUseCase
        self.navigator = navigator
        self.orderBy = orderBy
        self.isMain = isMain
    }
    
    func transform(input: Input) -> Output {
        let errorTracker = ErrorTracker()
        // 유저별 지금까지의 게시물들에 대한 투표 데이터 (비로그인시 빈 딕셔너리)
        let voteData = BehaviorSubject<[String: Int]>(value: [String: Int]())
        let fetching = BehaviorSubject<Bool>(value: false)
        // 다음 게시물이 존재하지 않으면 false
        let noMorePost = BehaviorSubject<Bool>(value: false)
        // 아래 4개의 Subject는 내부 Trigger
        // self.orderBy 변경후, Refetch Trigger
        let refetchPost = PublishSubject<Void>()
        // 게시물의 투표데이터 업데이트 Trigger
        let updateVoteOfPost = PublishSubject<(String, voteUpdateType)>()
        // 유저의 투표데이터 업데이트 Trigger
        let updateVoteOfUser = PublishSubject<[String: Int]>()
        // 게시물 삭제 Trigger
        let deletePost = PublishSubject<String>()
        
        enum Action {
            case append([PostItemViewModel])
            case reset([PostItemViewModel])
            case updateVote((PostItemViewModel.ID, Int))
            case delete(PostItemViewModel.ID)
            case edit(PostItemViewModel.ID)
        }
        
        let initialPosts = Observable.merge(input.fetchInitial, refetchPost)
            .withLatestFrom(fetching.asObservable())
            .filter { !$0 }
            .mapToVoid()
            .do(onNext: {
                fetching.onNext(true)
                noMorePost.onNext(false)
            })
            .flatMap { [unowned self] in
                return self.postUseCase.getInitialPosts(orderBy: self.orderBy)
                    .do(onError: { _ in
                        fetching.onNext(false)
                        noMorePost.onNext(true)
                    })
                    .trackError(errorTracker)
                    .catchErrorJustComplete()
                    .map { Action.reset($0.map { PostItemViewModel(with: $0) }) }
            }
            .do(onNext: { _ -> () in
                fetching.onNext(false)
            })
            .share(replay: 1)
        
        let nextPosts = input.fetchNext
            .withLatestFrom(noMorePost.asObservable())
            .filter { !$0 }
            .withLatestFrom(fetching.asObservable())
            .filter { !$0 }
            .mapToVoid()
            .do(onNext: {
                fetching.onNext(true)
            })
            .flatMap { [unowned self] in
                return self.postUseCase.getNextPosts(orderBy: self.orderBy)
                    .do(onError: { _ in // 더 이상의 게시물이 없으면 에러 발생
                        fetching.onNext(false)
                        noMorePost.onNext(true)
                    })
                    .trackError(errorTracker)
                    .catchErrorJustComplete()
                    .map { Action.append($0.map { PostItemViewModel(with: $0) }) }
            }
            .do(onNext: { _ -> () in
                fetching.onNext(false)
            })
            .share(replay: 1)
        
        let posts = Observable.merge(initialPosts,
                                     nextPosts,
                                     input.updateVote.map { Action.updateVote(($0.0, $0.1)) },
                                     input.delete.map { Action.delete($0) },
                                     input.edit.map { Action.edit($0) })
        .scan(into: [PostItemViewModel]()) { [unowned self] state, action in
            switch action {
            case .reset(let new):
                state = new
            case .append(let next):
                state.append(contentsOf: next)
            case .updateVote((let id, let from)):
                if !UserDefaults.standard.isLoggedIn() {
                    self.navigator.toLogin()
                    break
                }
                var voteUpdate: voteUpdateType?
                var voteDict: [String: Int]
                do {
                    try voteDict = voteData.value()
                } catch {
                    return
                }
                let preVote = voteDict[id.rawValue]
                if from == 1 {
                    switch preVote {
                    case 1:
                        voteDict[id.rawValue] = nil
                        voteUpdate = .onlyDecreaseFirst
                    case 2:
                        voteDict[id.rawValue] = 1
                        voteUpdate = .addFirstDecreaseSecond
                    case nil :
                        voteDict[id.rawValue] = 1
                        voteUpdate = .onlyAddFirst
                    default:
                        return
                    }
                } else if from == 2 {
                    switch preVote {
                    case 1:
                        voteDict[id.rawValue] = 2
                        voteUpdate = .decreaseFirstAddSecond
                    case 2:
                        voteDict[id.rawValue] = nil
                        voteUpdate = .onlyDecreaseSecond
                    case nil:
                        voteDict[id.rawValue] = 2
                        voteUpdate = .onlyAddSecond
                    default:
                        return
                    }
                }

                voteData.onNext(voteDict)
                
                if let index = state.firstIndex(where: { $0.id == id }), let voteUpdate = voteUpdate {
                    state[index].changeVotes(voteUpdate)
                }
                
                if self.isMain, let voteUpdate = voteUpdate {
                    // 홈 Vc만 서버 업데이트 트리거 작동
                    updateVoteOfPost.onNext((id.rawValue, voteUpdate))
                    updateVoteOfUser.onNext(voteDict)
                }
            case .delete(let id):
                guard let index = state.firstIndex(where: { $0.id == id }) else { break }
                deletePost.onNext(id.rawValue)
                state.remove(at: index)
            case .edit(let id):
                guard let index = state.firstIndex(where: { $0.id == id }) else { break }
                self.navigator.toEdit(state[index].post)
            }
        }
        .share(replay: 1)
        // 서버로부터 유저의 투표데이터를 가져옴
        input.fetchInitial
            .flatMap { [unowned self] in
                return self.voteUseCase.getData()
                    .trackError(errorTracker)
                    .catchErrorJustComplete()
                    .map { $0.data }
            }
            .subscribe(onNext: {
                voteData.onNext($0)
            }).disposed(by: disposeBag)
        // 게시물의 서버 투표데이터 업데이트
        updateVoteOfPost
            .flatMap { [unowned self] in
                return self.postUseCase.updateVoteOfPost(docId: $0.0, voteUpdate: $0.1)
                    .trackError(errorTracker)
                    .catchErrorJustComplete()
            }
            .subscribe()
            .disposed(by: disposeBag)
        // 유저의 서버 투표데이터 업데이트
        updateVoteOfUser
            .flatMap { [unowned self] in
                return self.voteUseCase.updateData($0)
                    .trackError(errorTracker)
                    .catchErrorJustComplete()
            }
            .subscribe()
            .disposed(by: disposeBag)
        // 게시물 서버 데이터 삭제
        deletePost
            .flatMap { [unowned self] in
                return self.postUseCase.delete(docId: $0)
                    .trackError(errorTracker)
                    .catchErrorJustComplete()
            }
            .subscribe()
            .disposed(by: disposeBag)
        // self.orderBy 변경후 Refetch Trigger 작동
        input.orderTrigger
            .filter { $0 != 0 }
            .do(onNext: { [unowned self] in
                print($0)
                switch $0 {
                case 1:
                    self.orderBy = .Time
                case 2:
                    self.orderBy = .Votes
                default:
                    return
                }
            })
            .subscribe(onNext: { _ in
                refetchPost.onNext(())
            })
            .disposed(by: disposeBag)
        
        input.uploadTrigger
            .do(onNext: { [unowned self] in
                if !UserDefaults.standard.isLoggedIn() {
                    self.navigator.toLogin()
                } else {
                    self.navigator.toCreate()
                }
            })
            .subscribe()
            .disposed(by: disposeBag)
        
        let uploadBtnHidden =
            Observable.just(orderBy)
                .map { $0 == .TimeFilteredByUserId }
                .share(replay: 1)
        
        let error = errorTracker.asObservable()
                
        return Output(
            fetching: fetching.asObservable(),
            posts: posts,
            voteData: voteData.asObservable(),
            uploadBtnHidden: uploadBtnHidden,
            error: error)
    }
    // 각 셀은 Post의 documentId를 기준으로 분류
    func PostItemViewModelSections(postItem: Observable<[PostItemViewModel]>) -> Observable<[PostItemViewModelSection]> {
        postItem
            .map { [PostItemViewModelSection(model: "", items: $0.map { $0.id })] }
    }
}

extension PostsViewModel {
    struct Input {
        let fetchInitial: Observable<Void>
        let fetchNext: Observable<Void>
        let orderTrigger: Observable<Int>
        let updateVote: Observable<(PostItemViewModel.ID, Int)>
        let uploadTrigger: Observable<Void>
        let delete: Observable<PostItemViewModel.ID>
        let edit: Observable<PostItemViewModel.ID>
    }
    
    struct Output {
        let fetching: Observable<Bool>
        let posts: Observable<[PostItemViewModel]>
        let voteData: Observable<[String: Int]>
        let uploadBtnHidden: Observable<Bool>
        let error: Observable<Error>
    }
}


extension Identifier: IdentifiableType {
    public var identity: Identifier { self }
}

typealias PostItemViewModelSection = AnimatableSectionModel<String, PostItemViewModel.ID>
