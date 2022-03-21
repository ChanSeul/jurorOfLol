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
            .do(onNext: { [weak self] in
                self?.viewModel.clearPosts.onNext(())
            })
            .subscribe(onNext: { [weak self] in
                self?.viewModel.fetchInitial.onNext(())
            })
            .disposed(by: disposeBag)
        
        viewModel.activated
            .map { !$0 }
            .subscribe(onNext: { [weak self] finished in
               if finished {
                   DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(1), execute: {
                       self?.timeLineTableView.refreshControl?.endRefreshing()
                   })
               }
            })
            //.bind(to: activityIndicator.rx.isHidden)
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
    
    let header: UIView = {
        let header = UIView()
        header.translatesAutoresizingMaskIntoConstraints = false
        header.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.6)
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .boldSystemFont(ofSize: 24)
        label.textColor = .systemBlue
        label.text = "롤 재판소"
        header.addSubview(label)
        label.centerXAnchor.constraint(equalTo: header.centerXAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: header.centerYAnchor).isActive = true
        
        let searchButton = UIButton()
        searchButton.translatesAutoresizingMaskIntoConstraints = false
        searchButton.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        searchButton.setPreferredSymbolConfiguration(.init(pointSize: 30, weight: .thin, scale: .default), forImageIn: .normal)
        searchButton.tintColor = .white
        header.addSubview(searchButton)
        searchButton.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -10).isActive = true
        searchButton.centerYAnchor.constraint(equalTo: header.centerYAnchor).isActive = true
        searchButton.widthAnchor.constraint(equalTo: header.heightAnchor, multiplier: 0.65).isActive = true
        searchButton.heightAnchor.constraint(equalTo: header.heightAnchor, multiplier: 0.65).isActive = true
        
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
            let navVC = UINavigationController(rootViewController: uploadModal)
            navVC.modalPresentationStyle = .fullScreen
            self.present(navVC, animated: true, completion: nil)
        }
        else {
            LoginController.shared.modalPresentationStyle = .overCurrentContext
            self.present(LoginController.shared, animated: false, completion: nil)
        }
        
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
}

extension HomeViewController: RefreshDelegate {
    func refresh() {
        Observable<Void>.of(())
            .take(1)
            .do(onNext: { [weak self] in
                self?.viewModel.clearPosts.onNext(())
            })
            .subscribe(onNext: { [weak self] in
                self?.viewModel.fetchInitial.onNext(())
            })
            .disposed(by: disposeBag)
    }
}


