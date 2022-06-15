//
//  ViewControllerProvider.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/05/18.
//

import Foundation
import AuthenticationServices

protocol ViewControllerProviderType {
    func makeHomeVc() -> PostsViewController
    func makeLoginVc() -> LoginViewController
    func makeAsAuthVc(request: [ASAuthorizationRequest]) -> ASAuthorizationController
    func makeCreateVc() -> CreatePostViewController
    func makeEditVc() -> EditPostViewController
    func makeSettingsVc() -> SettingViewController
}

final class ViewControllerProvider: ViewControllerProviderType {
    func makeHomeVc() -> PostsViewController {
        return PostsViewController()
    }
    
    func makeLoginVc() -> LoginViewController {
        return LoginViewController()
    }
    
    func makeAsAuthVc(request: [ASAuthorizationRequest]) -> ASAuthorizationController {
        return ASAuthorizationController(authorizationRequests: request)
    }
    
    func makeCreateVc() -> CreatePostViewController {
        return CreatePostViewController()
    }
    
    func makeEditVc() -> EditPostViewController {
        return EditPostViewController()
    }

    func makeSettingsVc() -> SettingViewController {
        return SettingViewController()
    }
}
