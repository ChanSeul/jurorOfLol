//
//  CreatePostNavigator.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/05/18.
//

import Foundation
import UIKit

protocol CreatePostNavigator {
    func toPosts()
}

final class DefaultCreatePostNavigator: CreatePostNavigator {
    private let navigationController: UINavigationController
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func toPosts() {
        navigationController.dismiss(animated: true)
    }
}
