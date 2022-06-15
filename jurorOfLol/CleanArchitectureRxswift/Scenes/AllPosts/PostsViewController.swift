//
//  HomeViewController.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/03/01.
//

import UIKit
import RxSwift
import RxRelay
import RxCocoa
import RxViewController

final class PostsViewController: UIViewController {
    let disposeBag = DisposeBag()
    
    var viewModel: PostsViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        connect()
    }
    
    //MARK: UI
    
    lazy var timeLineTableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        tableView.register(PostTableViewCell.self, forCellReuseIdentifier: PostTableViewCell.identifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = view.frame.height / 2
        return tableView
    }()
    
    let uploadButton: UIButton = {
        let uploadButton = UIButton()
        uploadButton.translatesAutoresizingMaskIntoConstraints = false
        uploadButton.setImage(UIImage(systemName: "plus.circle.fill")?.applyingSymbolConfiguration(.init(weight: .thin)), for: .normal)
        uploadButton.setPreferredSymbolConfiguration(.init(pointSize: 50, weight: .regular, scale: .default), forImageIn: .normal)
        return uploadButton
    }()
    
    
    func configureUI() {
        timeLineTableView.refreshControl = UIRefreshControl()
        timeLineTableView.refreshControl?.tintColor = .white
        
        view.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        
        let guide = view.safeAreaLayoutGuide
        
        view.addSubview(timeLineTableView)
        view.addSubview(uploadButton)
        
        NSLayoutConstraint.activate([
            timeLineTableView.topAnchor.constraint(equalTo: guide.topAnchor),
            timeLineTableView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            timeLineTableView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            timeLineTableView.bottomAnchor.constraint(equalTo: guide.bottomAnchor),
            uploadButton.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            uploadButton.bottomAnchor.constraint(equalTo: timeLineTableView.bottomAnchor),
            uploadButton.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.2),
            uploadButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.2)
        ])
        // 네비게이션바 우측 게시물 정렬 버튼
        let sortMethodButton = UIButton()
        sortMethodButton.setImage(UIImage(systemName: "slider.horizontal.3"), for: .normal)
        sortMethodButton.setPreferredSymbolConfiguration(.init(pointSize: 25, weight: .thin, scale: .default), forImageIn: .normal)
        sortMethodButton.tintColor = .white
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: sortMethodButton)
    }
    
}

extension PostsViewController: PostTableCellDelegate {
    // 셀 우측 상단의 수정&삭제 버튼누를 시, 액션시트 생성
    func showAlert(_ userId: String) -> Driver<Int> {
        if userId == UserDefaults.standard.getUserId() {
            return showAlert(title: nil, message: nil, style: .actionSheet, actions: [AlertAction(title: "취소", style: .cancel), AlertAction(title: "수정", style: .destructive), AlertAction(title: "삭제", style: .destructive)])
                .asDriverOnErrorJustComplete()
        }
        return showAlert(title: nil, message: nil, style: .actionSheet, actions: [AlertAction(title: "취소", style: .cancel)])
            .asDriverOnErrorJustComplete()
    }
}


