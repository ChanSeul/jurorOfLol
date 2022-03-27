//
//  HomeViewController.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/03/01.
//

import UIKit
import Firebase
import RxSwift
import RxRelay
import RxCocoa
import RxViewController

class HomeViewController: UIViewController {
    let viewModel: HomeViewModelType
    var disposeBag = DisposeBag()
    
    
    init(viewModel: HomeViewModelType = HomeViewModel()) {
        self.viewModel = viewModel
        //LoginController.shared.delegate = self
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        viewModel = HomeViewModel()
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
                cell.delegate = self
                cell.bind()
                cell.data.accept(item)
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
        
        // MARK: From background into foreground
        ThreadViewModel.shared.isBackground
            .subscribe(onNext: { [weak self] isBackground in
                if isBackground == true {
                    self?.viewModel.fetchInitial.onNext(())
                }
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
    
    lazy var header: UIView = {
        let header = UIView()
        header.translatesAutoresizingMaskIntoConstraints = false
        header.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.6)
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .boldSystemFont(ofSize: 20)
        label.textColor = .white
        label.text = "홈"
        header.addSubview(label)
        label.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 18).isActive = true
        //label.centerXAnchor.constraint(equalTo: header.centerXAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: header.centerYAnchor).isActive = true
        
        let sortMethodButton = UIButton()
        sortMethodButton.translatesAutoresizingMaskIntoConstraints = false
        sortMethodButton.setImage(UIImage(systemName: "slider.horizontal.3"), for: .normal)
        sortMethodButton.setPreferredSymbolConfiguration(.init(pointSize: 30, weight: .thin, scale: .default), forImageIn: .normal)
        sortMethodButton.tintColor = .white
        header.addSubview(sortMethodButton)
        sortMethodButton.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -10).isActive = true
        sortMethodButton.centerYAnchor.constraint(equalTo: header.centerYAnchor).isActive = true
        sortMethodButton.widthAnchor.constraint(equalTo: header.heightAnchor, multiplier: 0.65).isActive = true
        sortMethodButton.heightAnchor.constraint(equalTo: header.heightAnchor, multiplier: 0.5).isActive = true
        sortMethodButton.addTarget(self, action: #selector(showSortingMethod(_:)), for: .touchUpInside)
        
        let seperatorView = UIView()
        seperatorView.translatesAutoresizingMaskIntoConstraints = false
        seperatorView.backgroundColor = .systemGray4
        header.addSubview(seperatorView)
        seperatorView.leadingAnchor.constraint(equalTo: header.leadingAnchor).isActive = true
        seperatorView.trailingAnchor.constraint(equalTo: header.trailingAnchor).isActive = true
        seperatorView.topAnchor.constraint(equalTo: header.bottomAnchor, constant: -0.25).isActive = true
        seperatorView.bottomAnchor.constraint(equalTo: header.bottomAnchor).isActive = true
        return header
    }()
    
    let btn: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "plus.circle.fill")?.applyingSymbolConfiguration(.init(weight: .thin)), for: .normal)
        button.setPreferredSymbolConfiguration(.init(pointSize: 50, weight: .regular, scale: .default), forImageIn: .normal)
        return button
    }()
    
    
    func configureUI() {
        view.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        let guide = view.safeAreaLayoutGuide
        
        view.addSubview(timeLineTableView)
        view.addSubview(header)
        view.addSubview(btn)
        
        NSLayoutConstraint.activate([
            timeLineTableView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            timeLineTableView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            timeLineTableView.topAnchor.constraint(equalTo: guide.topAnchor, constant: view.frame.height / 15),
            timeLineTableView.bottomAnchor.constraint(equalTo: guide.bottomAnchor),
            
            header.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            header.topAnchor.constraint(equalTo: guide.topAnchor),
            header.bottomAnchor.constraint(equalTo: timeLineTableView.topAnchor),
            
            btn.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            btn.bottomAnchor.constraint(equalTo: timeLineTableView.bottomAnchor),
            btn.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.2),
            btn.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.2)
        ])
    
        btn.addTarget(self, action: #selector(buttonAction(_:)), for: .touchUpInside)
    }
    
    @objc
    func buttonAction(_ sender:UIButton!) {
        if let _ = Auth.auth().currentUser {
            let uploadModal = UploadViewController(uploadType: .new)
            uploadModal.delegate = self
            let navVC = UINavigationController(rootViewController: uploadModal)
            navVC.modalPresentationStyle = .fullScreen
            self.present(navVC, animated: true, completion: nil)
        }
        else {
            LoginController.shared.modalPresentationStyle = .overCurrentContext
            self.present(LoginController.shared, animated: false, completion: nil)
        }
    }
    @objc
    func showSortingMethod(_ sender:UIButton!) {
        let actionSheet = UIAlertController(title: "정렬 기준", message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "취소", style: .cancel))
        actionSheet.addAction(UIAlertAction(title: "업로드 날짜", style: .default) { [weak self] _ in
            self?.viewModel.fetchInitial.onNext(())
        })
        actionSheet.addAction(UIAlertAction(title: "투표수", style: .default) { [weak self] _ in
            self?.viewModel.fetchInitialByVotes.onNext(())
        })
        present(actionSheet, animated: true, completion: nil)
    }
}

extension HomeViewController: HomeTableViewCellDelegate {
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

extension HomeViewController: RefreshDelegate {
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


