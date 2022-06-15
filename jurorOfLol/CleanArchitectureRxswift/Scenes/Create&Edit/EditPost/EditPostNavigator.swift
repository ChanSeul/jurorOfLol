//
//  EditPostNavigator.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/06/04.
//

import Foundation
import UIKit

protocol EditPostNavigator {
    func toPosts()
}

final class DefaultEditPostNavigator: EditPostNavigator {
    private let navigationController: UINavigationController
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func toPosts() {
        navigationController.dismiss(animated: true)
    }
}
