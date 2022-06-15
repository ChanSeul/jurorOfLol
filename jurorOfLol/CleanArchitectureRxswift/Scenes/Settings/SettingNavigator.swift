//
//  SettingNavigator.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/06/05.
//

import Foundation
import UIKit

protocol SettingsNavigator {
    func toSettings()
    func toLogin()
    func toUsersPosts()
}

class DefaultSettingsNavigator: SettingsNavigator {
    private let vcFactory: ViewControllerProviderType
    private let navigationController: UINavigationController
    private let services: DomainUseCaseProvider
    
    init(services: DomainUseCaseProvider,
         navigationController: UINavigationController,
         vcFactory: ViewControllerProviderType) {
        self.services = services
        self.navigationController = navigationController
        self.vcFactory = vcFactory
    }
    
    func toSettings() {
        let vc = vcFactory.makeSettingsVc()
        vc.viewModel = SettingViewModel(navigator: self, loginUseCase: services.makeLoginUseCase(), postUseCase: services.makePostsUseCase())
        navigationController.pushViewController(vc, animated: true)
    }
    
    func toLogin() {
        let vc = vcFactory.makeLoginVc()
        let navigator = DefaultLoginNavigator(navigationController: navigationController, loginViewController: vc, vcFactory: vcFactory)
        let viewModel = LoginViewModel(useCase: services.makeLoginUseCase(), navigator: navigator)
        vc.viewModel = viewModel
        let nc = UINavigationController(rootViewController: vc)
        nc.modalPresentationStyle = .overFullScreen
        nc.isNavigationBarHidden = true
        navigationController.present(nc, animated: false, completion: nil)
    }
    
    func toUsersPosts() {
        let nv = DefaultPostsNavigator(services: services, navigationController: navigationController, vcFactory: vcFactory)
        nv.toPosts(.TimeFilteredByUserId, title: "내 동영상")
    }
}
