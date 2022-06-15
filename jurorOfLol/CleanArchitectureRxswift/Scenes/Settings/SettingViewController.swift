//
//  SettingViewController.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/06/05.
//

import Foundation
import UIKit
import RxSwift
import RxDataSources
import RxRelay
import RxCocoa

final class SettingViewController: UIViewController {
    let disposeBag = DisposeBag()
    var viewModel: SettingViewModel!
 
    override func viewDidLoad() {
        super.viewDidLoad()
        connect()
        configureUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.isNavigationBarHidden = false
    }
    
    let settingsTableView: UITableView = {
        let settingsTableView = UITableView(frame: .zero, style: .grouped)
        settingsTableView.translatesAutoresizingMaskIntoConstraints = false
        settingsTableView.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        settingsTableView.register(SettingCell.self, forCellReuseIdentifier: SettingCell.identifier)
        return settingsTableView
    }()
    
    func configureUI() {
        view.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        
        view.addSubview(settingsTableView)
 
        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            settingsTableView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            settingsTableView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            settingsTableView.topAnchor.constraint(equalTo: guide.topAnchor),
            settingsTableView.bottomAnchor.constraint(equalTo: guide.bottomAnchor)
        ])
        
        let headerView: UIView = {
            let headerView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 80))
            headerView.backgroundColor = UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1)
            
            let label = UILabel(frame: .zero)
            label.text = "계정"
            label.textColor = .white
            label.font = .boldSystemFont(ofSize: 28)
            label.translatesAutoresizingMaskIntoConstraints = false
            
            headerView.addSubview(label)
            
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 18),
                label.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 18),
                label.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -18)
            ])
            return headerView
        }()
        
        let header = Driver.just(headerView)
        header.drive(settingsTableView.rx.tableHeaderView)
            .disposed(by: disposeBag)
    }

}
