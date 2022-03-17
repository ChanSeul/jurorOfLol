//
//  HomeTableViewCell.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/03/01.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import RxRelay
import RxGesture
import YoutubePlayer_in_WKWebView
import Firebase

protocol HomeTableViewCellDelegate {
    func presentLoginModal()
    func showEditModal()
}

class HomeTableViewCell: UITableViewCell {
    var viewModel: HomeTableViewCellViewModelType
    static let identifier = "HomeTableViewCell"
    var cellDisposeBag = DisposeBag()
    var delegate: HomeTableViewCellDelegate?
    
    var disposeBag = DisposeBag()
    
    var data = PublishRelay<ViewPost>()
    var voteData = PublishRelay<ViewPost>()
    
    var isLoaded = false
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) { // 순서 1번
        self.viewModel = HomeTableViewCellViewModel()
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("cell init error")
    }

    func bind() {
        data.asDriver() { _ in .never() }
            .drive(onNext: { [weak self] currentPost in
                guard let self = self else { return }
                
                if self.isLoaded == true {
                    self.videoContainerView.cueVideo(byId: currentPost.url, startSeconds: 0, suggestedQuality: .default)
                }
                else {
                    self.videoContainerView.load(withVideoId: currentPost.url)
                    self.isLoaded = true
                }
                self.postDate.text = currentPost.date
                self.postText.text = currentPost.text
                self.poll1.championLabel.text = currentPost.champion1
                self.poll2.championLabel.text = currentPost.champion2
                
                if let user = Auth.auth().currentUser {
                    self.viewModel.fetchVoteDataOfCurrentUserForCurrentPost.onNext((userId: user.uid, docId: currentPost.docId, fromPollNumber: -1))
                }
                self.viewModel.fetchVoteCountOfCurrentPost.onNext(currentPost.docId)

            } )
            .disposed(by: cellDisposeBag)
        
        poll1.rx.tapGesture()
            .when(.ended)
            .withLatestFrom(data)
            .withLatestFrom(viewModel.activated) { ($0, $1) }
            .subscribe(onNext: { [weak self] (post,isActivating) in
                guard let user = Auth.auth().currentUser else { self?.delegate?.presentLoginModal(); return }
                if isActivating == true { return }
                else {
                    self?.viewModel.setActivating.onNext(true)
                    self?.viewModel.fetchVoteDataOfCurrentUserForCurrentPost.onNext((userId: user.uid, docId: post.docId, fromPollNumber: 1))
                }
            })
            .disposed(by: cellDisposeBag)
        
        poll2.rx.tapGesture()
            .when(.ended)
            .withLatestFrom(data)
            .withLatestFrom(viewModel.activated) { ($0, $1) }
            .subscribe(onNext: { [weak self] (post,isActivating) in
                guard let user = Auth.auth().currentUser else { self?.delegate?.presentLoginModal(); return }
                if isActivating == true { return }
                else {
                    self?.viewModel.setActivating.onNext(true)
                    self?.viewModel.fetchVoteDataOfCurrentUserForCurrentPost.onNext((userId: user.uid, docId: post.docId, fromPollNumber: 2))
                }
                
            })
            .disposed(by: cellDisposeBag)
        
        editBtn.rx.tapGesture()
            .when(.ended)
            .asDriver{ _ in .never() }
            .drive(onNext: { [weak self] _ in
                self?.delegate?.showEditModal()
            })
            .disposed(by: disposeBag)

        viewModel.voteDataOfCurrentUserForCurrentPost
            .withLatestFrom(data) { ($0, $1) }
            .subscribe(onNext: { [weak self] (preVoteData, currentPostData) in
                guard let self = self else { return }
                
                if preVoteData.fromPollNumber == -1 {
                    if preVoteData.voteData == nil {
                        DispatchQueue.main.async { [weak self] in
                            self?.poll1.setGray()
                            self?.poll2.setGray()
                        }
                    }
                    else if preVoteData.voteData == 1 {
                        DispatchQueue.main.async { [weak self] in
                            self?.poll1.setBlue()
                            self?.poll2.setGray()
                        }
                    }
                    else if preVoteData.voteData == 2 {
                        DispatchQueue.main.async { [weak self] in
                            self?.poll1.setGray()
                            self?.poll2.setBlue()
                        }
                    }
                }

                else if preVoteData.fromPollNumber == 1 {
                    if preVoteData.voteData == nil {
                        // case: 전에 아무것도 선택 안 한 경우
                        let oldData = self.viewModel.VoteCountOfCurrentPost.value
                        let newData = (oldData.0 + 1, oldData.1)
                        self.viewModel.VoteCountOfCurrentPost.accept(newData)
                        
                        DispatchQueue.main.async { [weak self] in
                            self?.poll1.setBlue()
                            self?.poll2.setGray()
                        }
                        
                        if let user = Auth.auth().currentUser {
                            self.viewModel.updateData.onNext((userId: user.uid, docId: currentPostData.docId, fromPollNumber: 1, updateType: .onlyAddFirst))
                        }
                        
                    }
                    
                    else if preVoteData.voteData == 1 {
                        let oldData = self.viewModel.VoteCountOfCurrentPost.value
                        let newData = (oldData.0 - 1, oldData.1)
                        self.viewModel.VoteCountOfCurrentPost.accept(newData)
                        
                        DispatchQueue.main.async { [weak self] in
                            self?.poll1.setGray()
                        }
                        
                        if let user = Auth.auth().currentUser {
                            self.viewModel.updateData.onNext((userId: user.uid, docId: currentPostData.docId, fromPollNumber: 1, updateType: .onlyDecreaseFirst))
                        }
                        
                    }
                    
                    else if preVoteData.voteData == 2 {
                        // case: 전에 poll2을 선택하였으므로, poll2에서 1만큼 줄이고, poll1에서 1만큼 증가
                        let oldData = self.viewModel.VoteCountOfCurrentPost.value
                        let newData = (oldData.0 + 1, oldData.1 - 1)
                        self.viewModel.VoteCountOfCurrentPost.accept(newData)
                        
                        DispatchQueue.main.async { [weak self] in
                            self?.poll1.setBlue()
                            self?.poll2.setGray()
                        }
                        
                        if let user = Auth.auth().currentUser {
                            self.viewModel.updateData.onNext((userId: user.uid, docId: currentPostData.docId, fromPollNumber: 1, updateType: .addFirstDecreaseSecond))
                        }
                    }
                    
                }
                else if preVoteData.fromPollNumber == 2 {
                    if preVoteData.voteData == nil {
                        // case: 전에 아무것도 선택 안 한 경우
                        let oldData = self.viewModel.VoteCountOfCurrentPost.value
                        let newData = (oldData.0, oldData.1 + 1)
                        self.viewModel.VoteCountOfCurrentPost.accept(newData)
                        
                        DispatchQueue.main.async { [weak self] in
                            self?.poll1.setGray()
                            self?.poll2.setBlue()
                        }
                        
                        if let user = Auth.auth().currentUser {
                            self.viewModel.updateData.onNext((userId: user.uid, docId: currentPostData.docId, fromPollNumber: 2, updateType: .onlyAddSecond))
                        }
                    }

                    else if preVoteData.voteData == 1 {
                        // case: 전에 poll1을 선택하였으므로, poll1에서 1만큼 줄이고, poll2에서 1만큼 증가
                        let oldData = self.viewModel.VoteCountOfCurrentPost.value
                        let newData = (oldData.0 - 1, oldData.1 + 1)
                        self.viewModel.VoteCountOfCurrentPost.accept(newData)
                        
                        DispatchQueue.main.async { [weak self] in
                            self?.poll1.setGray()
                            self?.poll2.setBlue()
                        }
                        
                        if let user = Auth.auth().currentUser {
                            self.viewModel.updateData.onNext((userId: user.uid, docId: currentPostData.docId, fromPollNumber: 2, updateType: .decreaseFirstAddSecond))
                        }
                    }
                    
                    else if preVoteData.voteData == 2 {
                        let oldData = self.viewModel.VoteCountOfCurrentPost.value
                        let newData = (oldData.0, oldData.1 - 1)
                        self.viewModel.VoteCountOfCurrentPost.accept(newData)
                        
                        DispatchQueue.main.async { [weak self] in
                            self?.poll2.setGray()
                        }
                        
                        if let user = Auth.auth().currentUser {
                            self.viewModel.updateData.onNext((userId: user.uid, docId: currentPostData.docId, fromPollNumber: 2, updateType: .onlyDecreaseSecond))
                        }
                    }
                }
            })
            .disposed(by: disposeBag)
        
        viewModel.VoteCountOfCurrentPost
            .asDriver()
            .drive(onNext: { (count1, count2) in
                var percentage1: Double
                var percentage2: Double

                if count1 + count2 == 0 {
                    percentage1 = 0
                    percentage2 = 0
                }
                else {
                    percentage1 = round(count1 / (count1 + count2))
                    percentage2 = round(count2 / (count1 + count2))
                }
                
                self.poll1.setPercentage(percentageNumber: percentage1)
                self.poll2.setPercentage(percentageNumber: percentage2)
            })
            .disposed(by: disposeBag)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        viewModel = HomeTableViewCellViewModel()
        data = PublishRelay<ViewPost>()
        disposeBag = DisposeBag()
        cellDisposeBag = DisposeBag()
        poll1.setGray()
        poll2.setGray()
        poll1.deactiveWidthConstraint()
        poll2.deactiveWidthConstraint()
    }
    
    //MARK: UI
    
    let containerView: UIView = {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        return containerView
    }()
    
    let postDate: UILabel = {
        let date = UILabel()
        date.translatesAutoresizingMaskIntoConstraints = false
        date.font = UIFont.systemFont(ofSize: 14)
        date.textColor = .lightGray
        return date
    }()
    
    let postText: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .white
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 50
        return label
    }()
    
    let videoContainerView: WKYTPlayerView = {
        let videoContainerView = WKYTPlayerView()
        videoContainerView.translatesAutoresizingMaskIntoConstraints = false
        videoContainerView.clipsToBounds = true
        videoContainerView.layer.cornerRadius = 15
        return videoContainerView
    }()
    
    let seperatorView: UIView = {
        let seperatorView = UIView()
        seperatorView.translatesAutoresizingMaskIntoConstraints = false
        seperatorView.backgroundColor = .systemGray4
        return seperatorView
    }()
    
    var poll1 = PollView()
    var poll2 = PollView()
    
    let editBtn: UIButton = {
        let editBtn = UIButton()
        editBtn.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        editBtn.tintColor = .white
        editBtn.translatesAutoresizingMaskIntoConstraints = false
        return editBtn
    }()
    
    func configureUI() {
        backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        selectionStyle = .none
        
        contentView.addSubview(containerView)
        containerView.addSubview(postDate)
        containerView.addSubview(postText)
        containerView.addSubview(videoContainerView)
        containerView.addSubview(poll1)
        containerView.addSubview(poll2)
        containerView.addSubview(editBtn)
        containerView.addSubview(seperatorView)
        
        let margin: CGFloat = 18
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            postDate.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: margin),
            postDate.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -margin),
            postDate.topAnchor.constraint(equalTo: containerView.topAnchor, constant: margin),
            
            postText.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: margin),
            postText.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -margin),
            postText.topAnchor.constraint(equalTo: postDate.bottomAnchor),
            postText.heightAnchor.constraint(greaterThanOrEqualToConstant: 1),
            
            videoContainerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: margin),
            videoContainerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -margin),
            videoContainerView.topAnchor.constraint(equalTo: postText.bottomAnchor, constant: margin),
            videoContainerView.heightAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 9 / 16),
            
            poll1.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: margin),
            poll1.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -margin),
            poll1.topAnchor.constraint(equalTo: videoContainerView.bottomAnchor, constant: margin),
            
            poll2.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: margin),
            poll2.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -margin),
            poll2.topAnchor.constraint(equalTo: poll1.bottomAnchor, constant: margin / 2),
            
            editBtn.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -margin),
            editBtn.topAnchor.constraint(equalTo: containerView.topAnchor, constant: margin / 2),
            
            seperatorView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            seperatorView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            seperatorView.topAnchor.constraint(equalTo: poll2.bottomAnchor, constant: margin),
            seperatorView.heightAnchor.constraint(equalToConstant: 0.25),
            seperatorView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
    
}


