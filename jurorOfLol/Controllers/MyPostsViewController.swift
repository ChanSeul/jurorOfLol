//
//  MyPostViewController.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/03/23.
//

import UIKit
import Firebase
import RxSwift
import RxRelay
import RxCocoa
import RxViewController

class MyPostsViewController: UIViewController {
    let viewModel: MyPostsViewModelType
    var disposeBag = DisposeBag()
    
    init(viewModel: MyPostsViewModelType = MyPostsViewModel()) {
        self.viewModel = viewModel
        //LoginController.shared.delegate = self
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        viewModel = MyPostsViewModel()
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        timeLineTableView.refreshControl = UIRefreshControl()
        timeLineTableView.refreshControl?.tintColor = .white
        bind()
    }

    func bind() {
        
        //MARK: First loading
        
        rx.viewWillAppear
            .take(1)
            .subscribe(onNext: { [weak self] _ in
                self?.viewModel.fetchInitial.onNext(())
            })
            .disposed(by: disposeBag)
        
        //MARK: Refresh loading
        
        timeLineTableView.refreshControl?.rx
            .controlEvent(.valueChanged)
            .map { _ in () }
            .subscribe(onNext: { [weak self] in
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(1), execute: {
                    self?.viewModel.fetchInitial.onNext(())
                    self?.timeLineTableView.refreshControl?.endRefreshing()
                })
            })
            .disposed(by: disposeBag)
        
        //MARK: Pagination
        
        timeLineTableView.rx.didScroll
            .withLatestFrom(viewModel.activated)
            .subscribe(onNext: { [weak self] isActivated in
                if !isActivated {
                    guard let self = self else { return }
                    let position = self.timeLineTableView.contentOffset.y
                    if position > self.timeLineTableView.contentSize.height - 100 - self.timeLineTableView.frame.size.height {
                        self.viewModel.fetchNext.onNext(())
                    }
                }
            })
            .disposed(by: disposeBag)
        
        //MARK: tableView data handling
        
        viewModel.allPosts
            .bind(to: timeLineTableView.rx.items(cellIdentifier: HomeTableViewCell.identifier,
                                                 cellType: HomeTableViewCell.self)) { [weak self]
                row, item, cell in
                guard let self = self else { return }
                cell.bind()
                cell.data.accept(item)
                cell.delegate = self
                cell.tag = row

            }
            .disposed(by: disposeBag)
        
        
        //MARK: Error handling
        
        viewModel.errorMessage
            .map { $0.domain }
            .subscribe(onNext: { [weak self] message in
                self?.showAlert("Fetch error", message)
            })
            .disposed(by: disposeBag)
        
    }
    
    //MARK: UI
    
    lazy var timeLineTableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        tableView.register(HomeTableViewCell.self, forCellReuseIdentifier: HomeTableViewCell.identifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = view.frame.height / 2
        return tableView
    }()
    
    func configureUI() {
        view.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        let guide = view.safeAreaLayoutGuide
        
        view.addSubview(timeLineTableView)
        
        NSLayoutConstraint.activate([
            timeLineTableView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            timeLineTableView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            timeLineTableView.topAnchor.constraint(equalTo: guide.topAnchor),
            timeLineTableView.bottomAnchor.constraint(equalTo: guide.bottomAnchor)
        ])
    }

}

extension MyPostsViewController: HomeTableViewCellDelegate {
    func presentLoginModal() {
        LoginController.shared.modalPresentationStyle = .overCurrentContext
        self.present(LoginController.shared, animated: false, completion: nil)
    }
    
    func showEditModal(docId: String, userId: String, prepost: ViewPost) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "취소", style: .cancel))
        if let user = Auth.auth().currentUser {
            if user.uid == userId {
                actionSheet.addAction(UIAlertAction(title: "수정", style: .destructive) { [weak self] _ in
                    let editModal = UploadViewController(uploadType: .edit, prepost: prepost)
                    editModal.delegate = self
                    let navVc = UINavigationController(rootViewController: editModal)
                    navVc.modalPresentationStyle = .fullScreen
                    self?.present(navVc, animated: true, completion: nil)
                })
                actionSheet.addAction(UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
                    self?.viewModel.deletePost.onNext(docId)
                })
            }
        }
        present(actionSheet, animated: true, completion: nil)
    }
    func renewCellHeight() {
        UIView.performWithoutAnimation {
            timeLineTableView.performBatchUpdates(nil)
        }
    }
}

extension MyPostsViewController: RefreshDelegate {
    func refresh() {
        Observable<Void>.of(())
            .take(1)
//            .do(onNext: { [weak self] in
//                self?.viewModel.clearPosts.onNext(())
//            })
            .subscribe(onNext: { [weak self] in
                self?.viewModel.fetchInitial.onNext(())
            })
            .disposed(by: disposeBag)
    }
}
