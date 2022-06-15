//
//  LoginViewModel.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/05/31.
//

import Foundation
import RxSwift
import AuthenticationServices

final class LoginViewModel: ViewModelType {
    private let navigator: LoginNavigator
    private let useCase: DomainLoginUseCase
    
    private let disposeBag = DisposeBag()
    
    init(useCase: DomainLoginUseCase, navigator: LoginNavigator) {
        self.navigator = navigator
        self.useCase = useCase
    }
    
    func transform(input: Input) -> Output {
        let errorTracker = ErrorTracker()
        let withdrawalHistory = PublishSubject<(isWithdrawal: Bool, date: Double)>() // isWithdrawal : 탈퇴 유무, date: 탈퇴 날짜
        let showAlert = PublishSubject<Void>() // 탈퇴한지 1주일 미만일 때 Alert Trigger
        let startSignInWithAppleFlow =
        input.authBtnTapped
            .flatMap {
                LoginService.startSignInWithAppleFlow()
                    .trackError(errorTracker)
                    .catchErrorJustComplete()
            }
            .do(onNext: navigator.toASAuth)
            .mapToVoid()
                
        let credenitalAndAppleId =
        input.didCompleteApppleSignIn
            .flatMap {
                LoginService.makeCredential(didCompleteWithAuthorization: $0)
                    .trackError(errorTracker)
                    .catchErrorJustComplete()
            }
            .share(replay: 1)
            
        
        credenitalAndAppleId.flatMap { [unowned self] in
            self.useCase.getWithdrawalDate($0.appleUserId)
                .do(onNext: { date in
                    withdrawalHistory.onNext((true, date))
                }, onError: { _ in
                    withdrawalHistory.onNext((false, -1))
                })
                .catchErrorJustComplete()
        }
        .subscribe()
        .disposed(by: disposeBag)
        
        let startSignInWithFirebaseFlow =
        withdrawalHistory
            .do(onNext: { //가입하고 탈퇴한적이 있으며, 아직 1주일이 지나지 않은 경우.
                if $0.isWithdrawal, Date().timeIntervalSince1970 - $0.date < 604800 {
                    showAlert.onNext(())
                }
            }) // 그 외에는 로그인
            .filter { !($0.isWithdrawal && (Date().timeIntervalSince1970 - $0.date < 604800)) }
            .withLatestFrom(credenitalAndAppleId)
            .flatMap {
                LoginService.startSignInWithFirebaseFlow(credential: $0.credential)
                    .trackError(errorTracker)
                    .catchErrorJustComplete()
            }
            .withLatestFrom(credenitalAndAppleId)
            .flatMap { [unowned self] in
                self.useCase.updateAppleUserId($0.appleUserId)
                    .trackError(errorTracker)
                    .catchErrorJustComplete()
            }

        let dismiss = input.dismissTrigger.do(onNext: navigator.toPosts)
        
        return Output(
            signInWithAppleFlow: startSignInWithAppleFlow,
            signInWithFirebaseFlow: startSignInWithFirebaseFlow,
            showAlert: showAlert,
            dismiss: dismiss
        )
    }
    
    
}

extension LoginViewModel {
    struct Input {
        let authBtnTapped: Observable<Void>
        let didCompleteApppleSignIn: Observable<ASAuthorization>
        let dismissTrigger: Observable<Void>
    }
    struct Output {
        let signInWithAppleFlow: Observable<Void>
        let signInWithFirebaseFlow: Observable<Void>
        let showAlert: Observable<Void>
        let dismiss: Observable<Void>
    }
}

extension LoginViewModel {
    func dismiss() {
        navigator.toPosts()
    }
}
