//
//  TabBarController.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/03/01.
//

import UIKit

class TabBarController : UITabBarController {
    
    let unselectedImages = ["house"/*, "flame"*/,"person"]
    var itemIdx = 0

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
 
        let timeLine = HomeViewController()
        //let rank = HomeViewController()
        let myOptions = SettingsController()
        myOptions.delegate = timeLine
        
        timeLine.title = "홈"
        //rank.title = "탐색"
        myOptions.title = "계정"
        
        setViewControllers([timeLine,myOptions], animated: false)
        
        guard let items = self.tabBar.items else { return }
 
        items[0].image = UIImage(systemName: "house.fill")
        items[1].image = UIImage(systemName: unselectedImages[1])
        //items[2].image = UIImage(systemName: unselectedImages[2])
        
        tabBar.unselectedItemTintColor = .white
        tabBar.barTintColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        tabBar.tintColor = .white
        
        tabBar.addSubview(seperatorView)
//        NSLayoutConstraint.activate([
//            seperatorView.leadingAnchor.constraint(equalTo: tabBar.leadingAnchor),
//            seperatorView.trailingAnchor.constraint(equalTo: tabBar.trailingAnchor),
//            seperatorView.topAnchor.constraint(equalTo: tabBar.topAnchor),
//            seperatorView.heightAnchor.constraint(equalToConstant: 0.25)
//        ])
        
    }
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        guard let items = self.tabBar.items else { return }
        
        for i in 0..<items.count {
            if item == items[i] {
                items[itemIdx].image = UIImage(systemName: unselectedImages[itemIdx])
                item.image = UIImage(systemName: unselectedImages[i] + ".fill")
                itemIdx = i
            }
        }
    }
  
}

