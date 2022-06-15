//
//  Application.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/05/18.
//

import Foundation
import UIKit

final class Application {
    static let shared = Application()
    
    private let networkUseCaseProvider: DomainUseCaseProvider
    
    private let vcProvider: ViewControllerProviderType
    
    private init() {
        self.networkUseCaseProvider = NetworkUseCaseProvider()
        self.vcProvider = ViewControllerProvider()
    }
    
    func configureMainInterface(in window: UIWindow) {
        let homeNavigationController = UINavigationController()
        
        homeNavigationController.tabBarItem = UITabBarItem(title: "홈", image: UIImage(systemName: "house")?.applyingSymbolConfiguration(.init(weight: .thin)), selectedImage: UIImage(systemName: "house.fill")?.applyingSymbolConfiguration(.init(weight: .thin)))
        let homeNavigator = DefaultPostsNavigator(services: networkUseCaseProvider, navigationController: homeNavigationController, vcFactory: vcProvider)
        
        let settingsNavigationController = UINavigationController()
        settingsNavigationController.tabBarItem = UITabBarItem(title: "계정", image: UIImage(systemName: "person")?.applyingSymbolConfiguration(.init(weight: .thin)), selectedImage: UIImage(systemName: "person.fill")?.applyingSymbolConfiguration(.init(weight: .thin)))
        let settingsNavigator = DefaultSettingsNavigator(services: networkUseCaseProvider, navigationController: settingsNavigationController, vcFactory: vcProvider)
        
        let tabBarController = UITabBarController()
        
        tabBarController.tabBar.barTintColor = UIColor(red: 0.03, green: 0.03, blue: 0.03, alpha: 1)
        let seperatorView = UIView()
        seperatorView.translatesAutoresizingMaskIntoConstraints = false
        seperatorView.backgroundColor = .systemGray4
        tabBarController.tabBar.addSubview(seperatorView)
        NSLayoutConstraint.activate([
            seperatorView.leadingAnchor.constraint(equalTo: tabBarController.tabBar.leadingAnchor),
            seperatorView.trailingAnchor.constraint(equalTo: tabBarController.tabBar.trailingAnchor),
            seperatorView.topAnchor.constraint(equalTo: tabBarController.tabBar.topAnchor),
            seperatorView.bottomAnchor.constraint(equalTo: tabBarController.tabBar.topAnchor, constant: 0.25)
        ])
        
        tabBarController.viewControllers = [
            homeNavigationController,
            settingsNavigationController
        ]
        window.rootViewController = tabBarController
        
        homeNavigator.toPosts(.Time, isMain: true, title: "홈")
        settingsNavigator.toSettings()
    }
}
