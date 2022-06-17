//
//  SettingsViewControllerConnection.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/06/15.
//

import Foundation
import UIKit
import RxSwift
import RxDataSources
import RxRelay
import RxCocoa

extension SettingViewController {
    func connect() {
        assert(viewModel != nil)
        
        let isLogin = UserDefaults.standard.rx.observe(Bool.self, "isLoggedIn").map { $0 ?? false }
        
        let signInTrigger = PublishSubject<Void>()
        let signOutTrigger = PublishSubject<Void>()
        let withdrawalTrigger = PublishSubject<Void>()
        let viewMyPostTrigger = PublishSubject<Void>()
        
        let input = SettingViewModel.Input(isLogin: isLogin, signInTrigger: signInTrigger, signOutTrigger: signOutTrigger, withdrawalTrigger: withdrawalTrigger, viewMyPostTrigger: viewMyPostTrigger)
        let output = viewModel.transform(input: input)
        
        output.signIn.subscribe().disposed(by: disposeBag)
        output.signOut.subscribe().disposed(by: disposeBag)
        output.withdrawal.subscribe().disposed(by: disposeBag)
        output.viewMyPost.subscribe().disposed(by: disposeBag)
        output.error.asDriverOnErrorJustComplete().drive(onNext: { error in
            print(error.localizedDescription)
        }).disposed(by: disposeBag)
        
        let dataSource = RxTableViewSectionedReloadDataSource<SettingSection>(
        configureCell: { [unowned self] dataSource, tableView, indexPath, model in
            let cell = tableView.dequeueReusableCell(withIdentifier: SettingCell.identifier, for: indexPath) as! SettingCell
            
            let cellEvent = cell.connect(model: model)
            
            switch model {
            case "로그인":
                cellEvent.cellTapped
                    .bind(to: signInTrigger)
                    .disposed(by: cell.disposeBag)
            case "로그아웃":
                cellEvent.cellTapped
                    .observe(on: MainScheduler.instance)
                    .flatMap {
                        self.showAlert(title: "알림", message: "정말 로그아웃 하시겠습니까?", style: .alert, actions: [AlertAction(title: "취소", style: .cancel), AlertAction(title: "확인", style: .default)])
                            .asDriverOnErrorJustComplete()
                    }
                    .filter { $0 == 1 }
                    .mapToVoid()
                    .bind(to: signOutTrigger)
                    .disposed(by: cell.disposeBag)
            case "내가 올린 글":
                cellEvent.cellTapped
                    .bind(to: viewMyPostTrigger)
                    .disposed(by: cell.disposeBag)
            case "회원 탈퇴":
                cellEvent.cellTapped
                    .observe(on: MainScheduler.instance)
                    .flatMap {
                        self.showAlert(title: "알림", message: "정말 회원 탈퇴 하시겠습니까?\n" + "작성된 게시물은 삭제되지 않습니다.", style: .alert, actions: [AlertAction(title: "취소", style: .cancel), AlertAction(title: "확인", style: .default)])
                            .asDriverOnErrorJustComplete()
                    }
                    .filter { $0 == 1 }
                    .mapToVoid()
                    .bind(to: withdrawalTrigger)
                    .disposed(by: cell.disposeBag)
            default:
                break
            }
            return cell
        })
        
        settingsTableView.delegate = nil
        settingsTableView.dataSource = nil
        
        output.sections
            .asDriverOnErrorJustComplete()
            .drive(settingsTableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
    }
}
