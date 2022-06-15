//
//  PostNavigator.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/05/18.
//

import Foundation
import UIKit

protocol PostsNavigator {
    func toPosts(_ orderBy: OrderBy, isMain: Bool, title: String)
    func toLogin()
    func toCreate()
    func toEdit(_ post: Post)
}

class DefaultPostsNavigator: PostsNavigator {
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
    
    func toPosts(_ orderBy: OrderBy, isMain: Bool = false, title: String) {
        let vc = vcFactory.makeHomeVc()
        vc.viewModel = PostsViewModel(postUseCase: services.makePostsUseCase(), voteUseCase: services.makeVotesUseCase(), navigator: self, orderBy: orderBy, isMain: isMain)
        vc.navigationItem.setTitleView(title: title)
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
    
    func toCreate() {
        let navigator = DefaultCreatePostNavigator(navigationController: navigationController)
        let viewModel = CreatePostViewModel(createPostUseCase: services.makePostsUseCase(), navigator: navigator)
        let vc = vcFactory.makeCreateVc()
        vc.viewModel = viewModel
        let nc = UINavigationController(rootViewController: vc)
        nc.modalPresentationStyle = .overFullScreen
        navigationController.present(nc, animated: true, completion: nil)
    }
    
    func toEdit(_ post: Post) {
        let navigator = DefaultEditPostNavigator(navigationController: navigationController)
        let viewModel = EditPostViewModel(post: post, editPostUseCase: services.makePostsUseCase(), navigator: navigator)
        let vc = vcFactory.makeEditVc()
        vc.viewModel = viewModel
        let nc = UINavigationController(rootViewController: vc)
        nc.modalPresentationStyle = .overFullScreen
        navigationController.present(nc, animated: true, completion: nil)
    }
}
