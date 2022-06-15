//
//  DefaultLoginNavigator.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/05/31.
//

import Foundation
import UIKit
import AuthenticationServices

protocol LoginNavigator {
    func toPosts()
    func toASAuth(request: [ASAuthorizationRequest])
}

final class DefaultLoginNavigator: LoginNavigator {
    private let navigationController: UINavigationController
    private weak var loginViewController: (ASAuthorizationControllerDelegate & ASAuthorizationControllerPresentationContextProviding)?
    private let vcFactory: ViewControllerProviderType

    init(navigationController: UINavigationController,
         loginViewController: ASAuthorizationControllerDelegate & ASAuthorizationControllerPresentationContextProviding,
         vcFactory: ViewControllerProviderType) {
        self.navigationController = navigationController
        self.loginViewController = loginViewController
        self.vcFactory = vcFactory
    }

    func toPosts() {
        navigationController.dismiss(animated: false)
    }
    
    func toASAuth(request: [ASAuthorizationRequest]) {
        let vc = vcFactory.makeAsAuthVc(request: request)
        vc.delegate = loginViewController
        vc.presentationContextProvider = loginViewController
        vc.performRequests()
    }
}
