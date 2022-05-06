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

class HomeTableViewCell: UITableViewCell {
    var viewModel: HomeTableViewCellViewModelType
    static let identifier = "HomeTableViewCell"
    
    var disposeBag = DisposeBag()
    
    var data = PublishRelay<ViewPost>()
    
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
                self.poll1.championLabel.text = currentPost.champion1
                self.poll2.championLabel.text = currentPost.champion2
                let attrString = NSMutableAttributedString(string: currentPost.text)
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineSpacing = 4
                attrString.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: NSMakeRange(0, attrString.length))
                self.postText.attributedText = attrString
                self.postText.appendReadmore(after: self.postText.text!, trailingContent: .readmore)
                
                
                if let user = Auth.auth().currentUser {
                    self.viewModel.fetchVoteDataOfCurrentUserForCurrentPost.onNext((userId: user.uid, docId: currentPost.docId, fromPollNumber: -1))
                }
                
                self.viewModel.fetchVoteCountOfCurrentPost.onNext(currentPost.docId)
            } )
            .disposed(by: disposeBag)
        
        postText.rx.tapGesture()
            .when(.ended)
            .withLatestFrom(data)
            .subscribe(onNext: { [weak self] (currentPost) in
                guard let self = self else { return }
                if self.postText.numberOfLines == 0 {
                    self.postText.appendReadmore(after: currentPost.text, trailingContent: .readmore)
                    Singleton.shared.renewCellHeight.accept(true)
                }
                else {
                    self.postText.appendReadLess(after: currentPost.text, trailingContent: .readless)
                    Singleton.shared.renewCellHeight.accept(true)
                }
            })
            .disposed(by: disposeBag)
        
        poll1.rx.tapGesture()
            .when(.ended)
            .withLatestFrom(data)
            .withLatestFrom(viewModel.activated) { ($0, $1) }
            .subscribe(onNext: { [weak self] (post,isActivating) in
                guard let user = Auth.auth().currentUser else { Singleton.shared.showLoginModal.accept(true); return }
                if isActivating == true { return }
                else {
                    self?.viewModel.setActivating.onNext(true)
                    self?.viewModel.fetchVoteDataOfCurrentUserForCurrentPost.onNext((userId: user.uid, docId: post.docId, fromPollNumber: 1))
                }
            })
            .disposed(by: disposeBag)
        
        poll2.rx.tapGesture()
            .when(.ended)
            .withLatestFrom(data)
            .withLatestFrom(viewModel.activated) { ($0, $1) }
            .subscribe(onNext: { [weak self] (post,isActivating) in
                guard let user = Auth.auth().currentUser else { Singleton.shared.showLoginModal.accept(true); return }
                if isActivating == true { return }
                else {
                    self?.viewModel.setActivating.onNext(true)
                    self?.viewModel.fetchVoteDataOfCurrentUserForCurrentPost.onNext((userId: user.uid, docId: post.docId, fromPollNumber: 2))
                }
                
            })
            .disposed(by: disposeBag)
        
        editBtn.rx.tapGesture()
            .when(.ended)
//            .asDriver{ _ in .never() }
            .withLatestFrom(data)
            .subscribe(onNext: { currentPost in
                Singleton.shared.showEditModal.accept((docId: currentPost.docId, userId: currentPost.userId, prepost: currentPost))
            })
            .disposed(by: disposeBag)

        viewModel.voteDataOfCurrentUserForCurrentPost
            .withLatestFrom(data) { ($0, $1) }
            .subscribe(onNext: { [weak self] (preVoteData, currentPostData) in
                guard let self = self else { return }
                
                //fromPollNumber == -1 => Initial Setting
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
                            self?.numberOfVotesLabel.text = String(Int(oldData.0 + oldData.1 + 1)) + "명 투표"
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
                            self?.numberOfVotesLabel.text = String(Int(oldData.0 + oldData.1 - 1)) + "명 투표"
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
                            self?.numberOfVotesLabel.text = String(Int(oldData.0 + oldData.1 + 1)) + "명 투표"
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
                            self?.numberOfVotesLabel.text = String(Int(oldData.0 + oldData.1 - 1)) + "명 투표"
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
                    percentage1 = round(count1 / (count1 + count2) * 100) / 100
                    percentage2 = round(count2 / (count1 + count2) * 100) / 100
                }
                
                self.poll1.setPercentage(percentageNumber: percentage1)
                self.poll2.setPercentage(percentageNumber: percentage2)
                self.numberOfVotesLabel.text = String(Int(count1 + count2)) + "명 투표"
            })
            .disposed(by: disposeBag)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        viewModel = HomeTableViewCellViewModel()
        data = PublishRelay<ViewPost>()
        disposeBag = DisposeBag()
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
    
    let editBtn: UIButton = {
        let editBtn = UIButton()
        editBtn.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        editBtn.tintColor = .white
        editBtn.translatesAutoresizingMaskIntoConstraints = false
        return editBtn
    }()
    
    let postDate: UILabel = {
        let date = UILabel()
        date.translatesAutoresizingMaskIntoConstraints = false
        date.font = UIFont.systemFont(ofSize: 14)
        date.textColor = .lightGray
        return date
    }()
    
    let postText: UILabel = {
        // width 설정 안하면 첫 로딩화면에서 UILabel의 width가 0이돼서 UILabel.appendReadmore()가 제대로 작동 안하게됨.
        let postText = UILabel(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - 36, height: 0))
        postText.translatesAutoresizingMaskIntoConstraints = false
        postText.font = UIFont.systemFont(ofSize: 15)
        postText.textColor = .white
        return postText
    }()
    
    var videoContainerView: WKYTPlayerView = {
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
    
    let numberOfVotesLabel: UILabel = {
        let numberOfVotesLabel = UILabel()
        numberOfVotesLabel.translatesAutoresizingMaskIntoConstraints = false
        numberOfVotesLabel.font = UIFont.systemFont(ofSize: 14)
        numberOfVotesLabel.textColor = .lightGray
        numberOfVotesLabel.text = "test"
        return numberOfVotesLabel
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
        containerView.addSubview(numberOfVotesLabel)
        containerView.addSubview(seperatorView)
        
        let margin: CGFloat = 18
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
//            containerView.widthAnchor.constraint(equalTo: contentView.widthAnchor),
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            editBtn.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -margin),
            editBtn.topAnchor.constraint(equalTo: containerView.topAnchor, constant: margin / 2),
            
            postDate.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: margin),
            postDate.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -margin),
            postDate.topAnchor.constraint(equalTo: containerView.topAnchor, constant: margin),
            
            postText.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: margin),
            postText.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -margin),
//            postText.widthAnchor.constraint(equalTo: self.widthAnchor, constant: -margin * 2),
            postText.topAnchor.constraint(equalTo: postDate.bottomAnchor, constant: margin / 2),
            postText.heightAnchor.constraint(greaterThanOrEqualToConstant: 1),
            
            videoContainerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: margin),
            videoContainerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -margin),
            videoContainerView.topAnchor.constraint(equalTo: postText.bottomAnchor, constant: margin),
            videoContainerView.heightAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 9 / 16),
            
            poll1.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: margin),
            poll1.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -margin),
            poll1.topAnchor.constraint(equalTo: videoContainerView.bottomAnchor, constant: margin),
            poll1.heightAnchor.constraint(greaterThanOrEqualToConstant: 1),
            
            poll2.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: margin),
            poll2.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -margin),
            poll2.topAnchor.constraint(equalTo: poll1.bottomAnchor, constant: margin / 2),
            poll2.heightAnchor.constraint(greaterThanOrEqualToConstant: 1),
            
            numberOfVotesLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: margin * 1.5),
            numberOfVotesLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -margin),
            numberOfVotesLabel.topAnchor.constraint(equalTo: poll2.bottomAnchor, constant: margin / 4),
            
            seperatorView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            seperatorView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            seperatorView.topAnchor.constraint(equalTo: numberOfVotesLabel.bottomAnchor, constant: margin),
            seperatorView.heightAnchor.constraint(equalToConstant: 1),
            seperatorView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
}

