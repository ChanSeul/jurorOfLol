//
//  LoginConnection.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/06/09.
//

import Foundation
import RxSwift
import RxCocoa

extension LoginViewController {
    func connect() {
        let authBtnTapped = appleAuthButton.rx.tapGesture().when(.ended).mapToVoid()
        let dismiss =
        Observable.merge(
            dimmedView.rx.tapGesture().when(.recognized).mapToVoid(),
            xbtn.rx.tap.mapToVoid())
            .do(onNext: { [unowned self] in
                self.animateDismissView()
            })
        let input = LoginViewModel.Input(authBtnTapped: authBtnTapped, didCompleteApppleSignIn: appleSignInComplete, dismissTrigger: dismiss)
        let output = viewModel.transform(input: input)
        
        output.signInWithAppleFlow.asSignalOnErrorJustComplete().emit().disposed(by: disposeBag)
                
        output.signInWithFirebaseFlow.asSignalOnErrorJustComplete().emit(onNext: { [unowned self] in
            self.animateDismissView()
            self.viewModel.dismiss()
        })
        .disposed(by: disposeBag)
                
        output.showAlert.asSignalOnErrorJustComplete().emit(onNext: { [unowned self] in
            let alertVC = UIAlertController(title: "알림", message: "탈퇴 처리된 ID는 7일동안 재가입이 불가능합니다.", preferredStyle: .alert)
            alertVC.addAction(UIAlertAction(title: "확인", style: .default) { _ in
                self.viewModel.dismiss()
            })
            self.present(alertVC, animated: true, completion: nil)
        })
        .disposed(by: disposeBag)
                
        output.dismiss.asSignalOnErrorJustComplete().emit().disposed(by: disposeBag)
    }
}

