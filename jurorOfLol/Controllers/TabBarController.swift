//
//  TabBarController.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/03/01.
//

import UIKit

class TabBarController : UITabBarController {
    let timeLine = HomeViewController(viewModel: HomeViewModel(timeLineType: .Home), timeLineType: .Home)
    let myOptions = SettingsController()
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
        timeLine.title = "홈"
        myOptions.title = "계정"
        
        let myOptionsNav = UINavigationController(rootViewController: myOptions)
        myOptionsNav.navigationBar.tintColor = .white
        setViewControllers([timeLine,myOptionsNav], animated: false)
        
        guard let items = self.tabBar.items else { return }
 
//        if let img1 = UIImage(systemName: "house.fill").applyingSymbolConfiguration(.init(weight: .thin)) {
//            items[0].image = img1
//        }
        items[0].image = UIImage(systemName: "house.fill")?.applyingSymbolConfiguration(.init(weight: .thin))
        items[1].image = UIImage(systemName: unselectedImages[1])?.applyingSymbolConfiguration(.init(weight: .thin))
        //items[2].image = UIImage(systemName: unselectedImages[2])
        
        tabBar.unselectedItemTintColor = .white
        tabBar.barTintColor = UIColor(red: 0.03, green: 0.03, blue: 0.03, alpha: 1)
//        tabBar.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)

        tabBar.tintColor = .white
        
        tabBar.addSubview(seperatorView)

        
    }
 
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        guard let items = self.tabBar.items else { return }
        
        for i in 0..<items.count {
            if item == items[i] {
                if itemIdx == 0 && i == 0 {
                    let indexPath = IndexPath(row: 0, section: 0)
                    timeLine.timeLineTableView.scrollToRow(at: indexPath, at: .top, animated: true)
                }
                items[itemIdx].image = UIImage(systemName: unselectedImages[itemIdx])?.applyingSymbolConfiguration(.init(weight: .thin))
                item.image = UIImage(systemName: unselectedImages[i] + ".fill")?.applyingSymbolConfiguration(.init(weight: .thin))
                itemIdx = i
                return
            }
        }
    }
  
}

