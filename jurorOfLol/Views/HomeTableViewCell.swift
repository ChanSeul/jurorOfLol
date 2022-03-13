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
    func changeVotes(row: Int, updateType: voteUpdateType)
}

class HomeTableViewCell: UITableViewCell {
    var viewModel: HomeTableViewCellViewModelType
    static let identifier = "HomeTableViewCell"
    var cellDisposeBag = DisposeBag()
    var delegate: HomeTableViewCellDelegate?
    
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
            .drive(onNext: { [weak self] post in
                guard let self = self else { return }
                
                if self.isLoaded == true {
                    self.videoContainerView.cueVideo(byId: post.url, startSeconds: 0, suggestedQuality: .default)
                }
                else {
                    self.videoContainerView.load(withVideoId: post.url)
                    self.isLoaded = true
                }
                self.postDate.text = post.date
                self.postText.text = post.text
                self.poll1.championLabel.text = post.champion1
                self.poll2.championLabel.text = post.champion2
                
                var percentage1: Double
                var percentage2: Double
            
                if post.champion1Votes == 0 {
                    percentage1 = 0
                } else {
                    percentage1 = round(post.champion1Votes / (post.champion1Votes + post.champion2Votes))
                }
                if post.champion2Votes == 0 {
                    percentage2 = 0
                } else {
                    percentage2 = round(post.champion2Votes / (post.champion1Votes + post.champion2Votes))
                }
                print("bind: \(percentage1), \(percentage2)")
                self.poll1.percentage.accept(percentage1)
                self.poll2.percentage.accept(percentage2)
                

            } )
            .disposed(by: cellDisposeBag)
        
        poll1.rx.tapGesture()
            .when(.recognized)
            .withLatestFrom(data)
            .withLatestFrom(viewModel.activated) { ($0, $1) }
            .subscribe(onNext: { [weak self] (post,isActivating) in
                if isActivating == true { print("activatin"); return }
                else {
                    print("\(isActivating) ssibal")
                    self?.viewModel.setActivating.onNext(true)
                    if let user = Auth.auth().currentUser {
                        self?.viewModel.updateChampionVotesUsers.onNext((userId: user.uid, docId: post.docId, fromPollNumber: 1))
                        self?.viewModel.fetchUserInfoAboutVote.onNext((userId: user.uid, docId: post.docId, fromPollNumber: 1))
                    }
                    else {
                        self?.delegate?.presentLoginModal()
                    }
                
                }
            })
            .disposed(by: cellDisposeBag)
        
        poll2.rx.tapGesture()
            .when(.recognized)
            .withLatestFrom(data)
            .withLatestFrom(viewModel.activated) { ($0, $1) }
            .subscribe(onNext: { [weak self] (post,isActivating) in
                if isActivating == true { print("activatin"); return }
                else {
                    self?.viewModel.setActivating.onNext(true)
                    if let user = Auth.auth().currentUser {
                        self?.viewModel.updateChampionVotesUsers.onNext((userId: user.uid, docId: post.docId, fromPollNumber: 2))
                        self?.viewModel.fetchUserInfoAboutVote.onNext((userId: user.uid, docId: post.docId, fromPollNumber: 2))
                    }
                    else {
                        self?.delegate?.presentLoginModal()
                    }
                }
                
            })
            .disposed(by: cellDisposeBag)

        viewModel.voteInfoAboutPost
            .withLatestFrom(data) { ($0, $1) }
            .subscribe(onNext: { [weak self] (info, post) in
                guard let self = self else { return }

                if info.fromPollNumber == 1 {
                    if info.voteInfo == nil {
                        // case: 전에 아무것도 선택 안 한 경우
                        self.delegate?.changeVotes(row: self.tag, updateType: .onlyAddFirst)
                        if let user = Auth.auth().currentUser {
                            self.viewModel.updateUsersVoteInfo.onNext((userId: user.uid, docId: post.docId, fromPollNumber: 1))
                        }
                    }
                    
                    else if info.voteInfo == 1 {
                        self.viewModel.setActivating.onNext(false)
                    }
                    
                    else if info.voteInfo == 2 {
                        // case: 전에 poll2을 선택하였으므로, poll2에서 1만큼 줄이고, poll1에서 1만큼 증가
                        self.delegate?.changeVotes(row: self.tag, updateType: .addFirstDecreaseSecond)
                        if let user = Auth.auth().currentUser {
                            self.viewModel.updateUsersVoteInfo.onNext((userId: user.uid, docId: post.docId, fromPollNumber: 1))
                        }
                    }
                    
                    
                    
                }
                else if info.fromPollNumber == 2 {
                    if info.voteInfo == nil {
                        // case: 전에 아무것도 선택 안 한 경우
                        self.delegate?.changeVotes(row: self.tag, updateType: .onlyAddSecond)
                        if let user = Auth.auth().currentUser {
                            self.viewModel.updateUsersVoteInfo.onNext((userId: user.uid, docId: post.docId, fromPollNumber: info.fromPollNumber))
                        }
                    }

                    else if info.voteInfo == 1 {
                        // case: 전에 poll1을 선택하였으므로, poll1에서 1만큼 줄이고, poll2에서 1만큼 증가
                        self.delegate?.changeVotes(row: self.tag, updateType: .decreaseFirstAddSecond)
                        if let user = Auth.auth().currentUser {
                            self.viewModel.updateUsersVoteInfo.onNext((userId: user.uid, docId: post.docId, fromPollNumber: info.fromPollNumber))
                        }
                    }
                    
                    else if info.voteInfo == 2 {
                        self.viewModel.setActivating.onNext(false)
                    }
                }
            })
            .disposed(by: disposeBag)
    }
    
    
    
    
    override func prepareForReuse() {
        super.prepareForReuse()
        viewModel = HomeTableViewCellViewModel()
        data = PublishRelay<ViewPost>()
        disposeBag = DisposeBag()
        cellDisposeBag = DisposeBag()
        
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
    
    let poll1 = PollView()
    let poll2 = PollView()
    
    func configureUI() {
        backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        selectionStyle = .none
        
        contentView.addSubview(containerView)
        containerView.addSubview(postDate)
        containerView.addSubview(postText)
        containerView.addSubview(videoContainerView)
        containerView.addSubview(poll1)
        containerView.addSubview(poll2)
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
            
            seperatorView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            seperatorView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            seperatorView.topAnchor.constraint(equalTo: poll2.bottomAnchor, constant: margin),
            seperatorView.heightAnchor.constraint(equalToConstant: 0.25),
            seperatorView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
    
}


