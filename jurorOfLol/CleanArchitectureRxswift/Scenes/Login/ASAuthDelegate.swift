//
//  LoginLogic.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/05/30.
//

import Foundation
import AuthenticationServices

@available(iOS 13.0, *)
extension LoginViewController: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        appleSignInComplete.onNext(authorization)
    }
}

@available(iOS 13.0, *)
extension LoginViewController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}
