//
//  SettingsViewModel.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/06/05.
//

import Foundation
import RxSwift
import Differentiator

final class SettingViewModel: ViewModelType {
    private let navigator: SettingsNavigator
    private let loginUseCase: DomainLoginUseCase
    private let postUseCase: DomainPostsUseCase
    
    init(navigator: SettingsNavigator, loginUseCase: DomainLoginUseCase, postUseCase: DomainPostsUseCase) {
        self.navigator = navigator
        self.loginUseCase = loginUseCase
        self.postUseCase = postUseCase
    }
    
    func transform(input: Input) -> Output {
        let errorTracker = ErrorTracker()
        
        let sections = input.isLogin
            .flatMap { [unowned self] in
                self.SettingSections($0)
            }
        
        let signIn =
        input.signInTrigger
            .do(onNext: navigator.toLogin)
                
        let signOut =
        input.signOutTrigger
            .flatMap {
                LoginService.signOut()
                    .trackError(errorTracker)
                    .catchErrorJustComplete()
            }
                
        let withdrawal =
        input.withdrawalTrigger
            .flatMap { [unowned self] in
                self.loginUseCase.getAppleUserId()
                    .trackError(errorTracker)
                    .catchErrorJustComplete()
            }
            .flatMap { [unowned self] appleUserId in
                self.loginUseCase.updateWithdrawalDate(appleUserId)
                    .trackError(errorTracker)
                    .catchErrorJustComplete()
            }
            .flatMap {
                LoginService.signOut()
                    .trackError(errorTracker)
                    .catchErrorJustComplete()
            }
                
        let viewMyPost =
        input.viewMyPostTrigger
            .do(onNext: navigator.toUsersPosts)

        return Output(sections: sections,
                      signIn: signIn,
                      signOut: signOut,
                      withdrawal: withdrawal,
                      viewMyPost: viewMyPost,
                      error: errorTracker.asObservable())
    }
    
    func SettingSections(_ isLogin: Bool) -> Observable<[SettingSection]> {
        if isLogin {
            return Observable.just([SettingSection(model: "계정", items: ["로그아웃", "회원 탈퇴"]),
                                    SettingSection(model: "내가 올린 글", items: ["내가 올린 글"])])
        }
        return Observable.just([SettingSection(model: "계정", items: ["로그인"])])
    }
}

extension SettingViewModel {
    struct Input {
        let isLogin: Observable<Bool>
        let signInTrigger: Observable<Void>
        let signOutTrigger: Observable<Void>
        let withdrawalTrigger: Observable<Void>
        let viewMyPostTrigger: Observable<Void>
    }
    
    struct Output {
        let sections: Observable<[SettingSection]>
        let signIn: Observable<Void>
        let signOut: Observable<Void>
        let withdrawal: Observable<Void>
        let viewMyPost: Observable<Void>
        let error: Observable<Error>
    }
}

typealias SettingSection = SectionModel<String, String>
