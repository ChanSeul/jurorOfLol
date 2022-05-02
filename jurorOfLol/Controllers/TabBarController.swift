//
//  TabBarController.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/03/01.
//

import UIKit
import RxSwift

class TabBarController : UITabBarController {
    let timeLine = HomeViewController(viewModel: HomeViewModel(), fetchType: .All)
    let myOptions = SettingsController()
    var selectedItem: UITabBarItem?
    var imageDic = [UITabBarItem:[UIImage?]]()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    
    let seperatorView: UIView = {
        let seperatorView = UIView()
        seperatorView.translatesAutoresizingMaskIntoConstraints = false
        seperatorView.backgroundColor = .systemGray4
        return seperatorView
    }()

    func configureUI() {
        timeLine.title = "홈"
        myOptions.title = "계정"
        
        let myOptionsNav = UINavigationController(rootViewController: myOptions)
        myOptionsNav.navigationBar.tintColor = .white
        setViewControllers([timeLine,myOptionsNav], animated: false)
        
        guard let items = self.tabBar.items else { return }
 
        imageDic[items[0]] = [UIImage(systemName: "house")?.applyingSymbolConfiguration(.init(weight: .thin)), UIImage(systemName: "house.fill")?.applyingSymbolConfiguration(.init(weight: .thin))]
        imageDic[items[1]] = [UIImage(systemName: "person")?.applyingSymbolConfiguration(.init(weight: .thin)), UIImage(systemName: "person.fill")?.applyingSymbolConfiguration(.init(weight: .thin))]
        selectedItem = items[0]
        items[0].image = UIImage(systemName: "house.fill")?.applyingSymbolConfiguration(.init(weight: .thin))
        items[1].image = UIImage(systemName: "person")?.applyingSymbolConfiguration(.init(weight: .thin))
        
        tabBar.unselectedItemTintColor = .white
        tabBar.barTintColor = UIColor(red: 0.03, green: 0.03, blue: 0.03, alpha: 1)
        tabBar.tintColor = .white
        
        tabBar.addSubview(seperatorView)
        NSLayoutConstraint.activate([
            seperatorView.leadingAnchor.constraint(equalTo: tabBar.leadingAnchor),
            seperatorView.trailingAnchor.constraint(equalTo: tabBar.trailingAnchor),
            seperatorView.topAnchor.constraint(equalTo: tabBar.topAnchor),
            seperatorView.bottomAnchor.constraint(equalTo: tabBar.topAnchor, constant: 0.25)
        ])
    }
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if self.selectedItem != nil {
            if item == self.selectedItem && item.title == "홈" {
                let indexPath = IndexPath(row: 0, section: 0)
                timeLine.timeLineTableView.scrollToRow(at: indexPath, at: .top, animated: true)
            }
            self.selectedItem!.image = self.imageDic[self.selectedItem!]![0]
            item.image = self.imageDic[item]![1]
            self.selectedItem = item

        }
    }
}

