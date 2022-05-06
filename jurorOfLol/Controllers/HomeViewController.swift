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
    let fetchType: FirebaseFetchType
    var disposeBag = DisposeBag()
    
    init(viewModel: HomeViewModelType, fetchType: FirebaseFetchType) {
        self.viewModel = viewModel
        self.fetchType = fetchType
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        viewModel = HomeViewModel()
        fetchType = .ByTime
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        bind()
    }

    func bind() {
        //MARK: First loading
        
        rx.viewWillAppear
            .take(1)
            .subscribe(onNext: { [weak self] _ in
                if self?.fetchType == .ByTime {
                    self?.viewModel.fetchInitial.onNext(())
                } else {
                    self?.viewModel.fetchInitialMy.onNext(())
                }
            })
            .disposed(by: disposeBag)
        
        //MARK: Refresh loading
        
        timeLineTableView.refreshControl?.rx
            .controlEvent(.valueChanged)
            .subscribe(onNext: { [weak self] in
                if self?.fetchType == .ByTime {
                    self?.viewModel.fetchInitial.onNext(())
                } else {
                    self?.viewModel.fetchInitialMy.onNext(())
                }
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(1), execute: {
                    self?.timeLineTableView.refreshControl?.endRefreshing()
                })
            })
            .disposed(by: disposeBag)
        
        
         //MARK: From background into foreground
        
        Singleton.shared.becomeActive
            .subscribe(onNext: { [weak self] _ in
                if self?.fetchType == .ByTime {
                    if Date().timeIntervalSince1970 - Singleton.shared.timeStamp > 1200 {
                        self?.viewModel.fetchInitial.onNext(())
                        DispatchQueue.main.async {
                            let indexPath = IndexPath(row: 0, section: 0)
                            self?.timeLineTableView.scrollToRow(at: indexPath, at: .top, animated: true)
                        }
                    }
                }
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
        
        //MARK: TableView data handling
        
        viewModel.allPosts
            .bind(to: timeLineTableView.rx.items(cellIdentifier: HomeTableViewCell.identifier,
                                                 cellType: HomeTableViewCell.self)) {
                row, item, cell in
                cell.bind()
                cell.data.accept(item)
                cell.tag = row
            }
            .disposed(by: disposeBag)
        
        
        //MARK: Error handling
        
        viewModel.errorMessage
            .map { $0.domain }
            .subscribe(onNext: { [weak self] message in
                DispatchQueue.main.async {
                    self?.showAlert("Fetch error", message)
                }
            })
            .disposed(by: disposeBag)
        
        Singleton.shared.refreshHomeTableView
            .subscribe(onNext: { [weak self] _ in
                self?.viewModel.fetchInitial.onNext(())
            })
            .disposed(by: disposeBag)
        
        Singleton.shared.showLoginModal
            .subscribe(onNext: { [weak self] _ in
                LoginController.shared.modalPresentationStyle = .overCurrentContext
                self?.present(LoginController.shared, animated: false, completion: nil)
            })
            .disposed(by: disposeBag)
        
        Singleton.shared.showEditModal
            .subscribe(onNext: { [weak self] (docId, userId, prepost) in
                let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                actionSheet.addAction(UIAlertAction(title: "취소", style: .cancel))
                if let user = Auth.auth().currentUser {
                    if user.uid == userId {
                        actionSheet.addAction(UIAlertAction(title: "수정", style: .destructive) { _ in
                            let editModal = UploadViewController(uploadType: .edit, prepost: prepost)
                            let navVc = UINavigationController(rootViewController: editModal)
                            navVc.modalPresentationStyle = .fullScreen
                            self?.present(navVc, animated: true, completion: nil)
                        })
                        actionSheet.addAction(UIAlertAction(title: "삭제", style: .destructive) { _ in
                            self?.viewModel.deletePost.onNext(docId)
                        })
                    }
                }
                self?.present(actionSheet, animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
        
        Singleton.shared.renewCellHeight
            .subscribe(onNext: { [weak self] _ in
                UIView.performWithoutAnimation {
                    self?.timeLineTableView.performBatchUpdates(nil)
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
    
    lazy var header: UIView? = {
        if fetchType == .My {
            return nil
        }
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
    
    lazy var uploadButton: UIButton? = {
        if fetchType == .My {
            return nil
        }
        let uploadButton = UIButton()
        uploadButton.translatesAutoresizingMaskIntoConstraints = false
        uploadButton.setImage(UIImage(systemName: "plus.circle.fill")?.applyingSymbolConfiguration(.init(weight: .thin)), for: .normal)
        uploadButton.setPreferredSymbolConfiguration(.init(pointSize: 50, weight: .regular, scale: .default), forImageIn: .normal)
        uploadButton.addTarget(self, action: #selector(uploadAction(_:)), for: .touchUpInside)
        return uploadButton
    }()
    
    
    func configureUI() {
        timeLineTableView.refreshControl = UIRefreshControl()
        timeLineTableView.refreshControl?.tintColor = .white
        
        view.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        
        let guide = view.safeAreaLayoutGuide
        
        view.addSubview(timeLineTableView)
        
        NSLayoutConstraint.activate([
            timeLineTableView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            timeLineTableView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            timeLineTableView.bottomAnchor.constraint(equalTo: guide.bottomAnchor)
        ])
        
        if let header = header, let uploadButton = uploadButton {
            view.addSubview(header)
            view.addSubview(uploadButton)
            
            NSLayoutConstraint.activate([
                timeLineTableView.topAnchor.constraint(equalTo: guide.topAnchor, constant: view.frame.height / 15),
                
                header.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
                header.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
                header.topAnchor.constraint(equalTo: guide.topAnchor),
                header.bottomAnchor.constraint(equalTo: timeLineTableView.topAnchor),
                
                uploadButton.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                uploadButton.bottomAnchor.constraint(equalTo: timeLineTableView.bottomAnchor),
                uploadButton.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.2),
                uploadButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.2)
            ])
        } else {
            timeLineTableView.topAnchor.constraint(equalTo: guide.topAnchor).isActive = true
        }
    }
    // MARK: Button methods
    @objc
    func uploadAction(_ sender:UIButton!) {
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
