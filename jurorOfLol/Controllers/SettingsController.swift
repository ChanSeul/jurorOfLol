//
//  MyController.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/03/02.
//

import UIKit
import Differentiator
import RxDataSources
import RxRelay
import RxSwift
import Firebase


class SettingsController: UIViewController {
    let disposeBag = DisposeBag()
    
    lazy var dataSource = RxTableViewSectionedReloadDataSource<Section> { _, _, _, _ in
        return UITableViewCell()
    }
    
    let currentSections = BehaviorRelay<[Section]>(value: [])
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var settingsTableView: UITableView = {
        let settingsTableView = UITableView(frame: .zero, style: .grouped)
        settingsTableView.translatesAutoresizingMaskIntoConstraints = false
        settingsTableView.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        settingsTableView.register(StaticSettingTableViewCell.self, forCellReuseIdentifier: StaticSettingTableViewCell.identifier)
        settingsTableView.register(SwitchSettingTableViewCell.self, forCellReuseIdentifier: SwitchSettingTableViewCell.identifier)
        settingsTableView.rx.setDelegate(self)
            .disposed(by: disposeBag)
        return settingsTableView
    }()
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableViewDataSource()
        bind()
        configureUI()
    }
    
    func bind() {
        LoginViewModel.shared.isLogin.asDriver()
            .drive(onNext: { [weak self] isLogin in
                if isLogin == true {
                    self?.currentSections.accept([
                        Section(title: "계정", items: [
                            .staticCell(model: SettingsStaticOption(title: "로그아웃") { [weak self] in
                                self?.showLogoutAlert("알림", "정말 로그아웃 하시겠습니까?")
                            })
                        ]),
                        Section(title: "", items: [
                            .staticCell(model: SettingsStaticOption(title: "내가 올린 글") {

                            })
                        ])])
                }
                else {
                    self?.currentSections.accept([
                        Section(title: "계정", items: [
                            .staticCell(model: SettingsStaticOption(title: "로그인") { [weak self] in
                                LoginController.shared.modalPresentationStyle = .overCurrentContext
                                self?.present(LoginController.shared, animated: false, completion: nil)
                            })
                        ])
                    ])
                }
            })
            .disposed(by: disposeBag)
        
        currentSections.asDriver()
            .drive(settingsTableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
    }
    
    func setupTableViewDataSource() {
        dataSource = RxTableViewSectionedReloadDataSource<Section> { dataSource,
            tableView, indexPath, item in
            switch item.self {
            case .staticCell(let model):
                guard let cell = tableView.dequeueReusableCell(
                    withIdentifier: StaticSettingTableViewCell.identifier,
                    for: indexPath) as? StaticSettingTableViewCell else {
                        return UITableViewCell()
                    }
                cell.configure(with: model)
                return cell
            case .switchCell(let model):
                guard let cell = tableView.dequeueReusableCell(
                    withIdentifier: SwitchSettingTableViewCell.identifier,
                    for: indexPath) as? SwitchSettingTableViewCell else {
                        return UITableViewCell()
                    }
                cell.configure(with: model)
                return cell
            }
        }
        
        dataSource.titleForHeaderInSection = { ds, index in
            return ds.sectionModels[index].title
        }

        
    }
    
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
        

    }
    
    func showLogoutAlert(_ title: String, _ message: String) {
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "취소", style: .cancel))
        alertVC.addAction(UIAlertAction(title: "확인", style: .default) { _ in
            let firebaseAuth = Auth.auth()
            do {
                try firebaseAuth.signOut()
            } catch let signOutError as NSError {
              print("Error signing out: %@", signOutError)
            }
            LoginViewModel.shared.isLogin.accept(false)
        })
        present(alertVC, animated: true, completion: nil)
    }
}


extension SettingsController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let view = view as? UITableViewHeaderFooterView {
            view.textLabel?.textColor = UIColor.white
            view.textLabel?.font = .boldSystemFont(ofSize: 36)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1 {
            return 30
        }
        return 120
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = dataSource[indexPath.section].items[indexPath.row]
        switch model.self {
        case .staticCell(let model):
            model.handler()
        case .switchCell(let model):
            model.handler()
        }
    }
}

