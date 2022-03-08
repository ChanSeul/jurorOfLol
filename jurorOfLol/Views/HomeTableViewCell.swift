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

protocol LoginModalDelegate {
    func presentLoginModal()
}

class HomeTableViewCell: UITableViewCell {
    let viewModel: HomeTableViewCellViewModelType
    static let identifier = "HomeTableViewCell"
    private let cellDisposeBag = DisposeBag()
    var delegate: LoginModalDelegate?
    
    var disposeBag = DisposeBag()
    
    let data = PublishRelay<ViewPost>()
    //let onData: AnyObserver<ViewPost>
    
    var isLoaded = false
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        //onData = data.asObserver()
        self.viewModel = HomeTableViewCellViewModel()
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        bind()
        configureUI()
    }
    func bind() {
        data.asDriver() { _ in .never() }
            .drive(onNext: { [weak self] post in
                guard let self = self,
                      let url = post.url,
                      let champion1 = post.chapion1,
                      let champion2 = post.champion2,
                      let champion1Votes = post.champion1Votes,
                      let champion2Votes =  post.champion2Votes,
                      let date = post.date,
                      let text = post.text
                else { return }
                
                if self.isLoaded == true {
                    self.videoContainerView.cueVideo(byId: url, startSeconds: 0, suggestedQuality: .default)
                }
                else {
                    self.videoContainerView.load(withVideoId: url)
                    self.isLoaded = true
                }
                self.postDate.text = date
                self.postText.text = text
                self.poll1.championLabel.text = champion1
                self.poll2.championLabel.text = champion2
                
                var percentage1: Double
                var percentage2: Double
            
                if champion1Votes == 0 {
                    percentage1 = 0
                } else {
                    percentage1 = round(champion1Votes / (champion1Votes + champion2Votes) * 100)
                }
                if champion2Votes == 0 {
                    percentage2 = 0
                } else {
                    percentage2 = round(champion2Votes / (champion1Votes + champion2Votes) * 100)
                }
                
                self.poll1.percentage.accept(percentage1)
                self.poll2.percentage.accept(percentage2)
                
//                self.poll1.percentageLabel.text = String(format: "%.f",percentage1) + "%"
//                self.poll2.percentageLabel.text = String(format: "%.f",percentage2) + "%"

//                NSLayoutConstraint.activate([
//                    self.poll1.percentageFillingView.widthAnchor.constraint(equalTo: self.containerView.widthAnchor, multiplier: percentage1 / 100),
//                    self.poll2.percentageFillingView.widthAnchor.constraint(equalTo: self.containerView.widthAnchor, multiplier: percentage2 / 100)
//                ])

            } )
            .disposed(by: cellDisposeBag)
        
        poll1.rx.tapGesture()
            .when(.recognized)
            //.asDriver() { _ in .never() }
            .withLatestFrom(data/*.asDriver() { _ in .never() }*/)
            .subscribe(onNext: { [weak self] post in
                if let user = Auth.auth().currentUser {
                    guard let docId = post.docId else { return }
                    
                    self?.viewModel.updateChampion1VotesUsers.onNext((userId: user.uid, docId: docId))
                    self?.viewModel.fetchUserInfoAboutVote.onNext((userId: user.uid, docId: docId, fromPollNumber: 1))
//                    DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 2) {
//                        self?.viewModel.updateUsersVoteInfo.onNext((userId: user.uid, docId: docId, fromPollNumber: 1))
//                    }
                    
                }
                else {
                    self?.delegate?.presentLoginModal()
                }
            })
            .disposed(by: cellDisposeBag)
        
        poll2.rx.tapGesture()
            .when(.recognized)
            //.asDriver() { _ in .never() }
            .withLatestFrom(data/*.asDriver() { _ in .never() }*/)
            .subscribe(onNext: { [weak self] post in
                if let user = Auth.auth().currentUser {
                    guard let docId = post.docId else { return }
                    
                    self?.viewModel.updateChampion2VotesUsers.onNext((userId: user.uid, docId: docId))
                    self?.viewModel.fetchUserInfoAboutVote.onNext((userId: user.uid, docId: docId, fromPollNumber: 2))
//                    DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 2) {
//                        self?.viewModel.updateUsersVoteInfo.onNext((userId: user.uid, docId: docId, fromPollNumber: 2))
//                    }
                    // Poll UI는 viewModel.voteInfoAboutPost 구독으로 처리
                }
                else {
                    self?.delegate?.presentLoginModal()
                }
            })
            .disposed(by: cellDisposeBag)
        
        viewModel.voteInfoAboutPost
            .withLatestFrom(data/*.asDriver() { _ in .never() }*/) {
                ($0, $1)
            }
            .subscribe(onNext: { [weak self] (info, post) in
                guard let champion1Votes = post.champion1Votes,
                      let champion2Votes = post.champion2Votes,
                      let docId = post.docId
                else { return }
                
                print(info.fromPollNumber)
                print(info.voteInfo)

                DispatchQueue.global().sync {
                    var percentage1: Double
                    var percentage2: Double
                    // poll1를 탭하였을 때 UI처리
                    if info.fromPollNumber == 1 {
                        if info.voteInfo == nil {
                            // case: 전에 아무것도 선택 안 한 경우
                            percentage1 = round((champion1Votes + 1) / ((champion1Votes + 1) + champion2Votes) * 100)
                            percentage2 = round(champion2Votes / ((champion1Votes + 1) + champion2Votes) * 100)
                            self?.poll1.percentage.accept(percentage1)
                            self?.poll2.percentage.accept(percentage2)
                        }

                        else if info.voteInfo == 2 {
                            // case: 전에 poll2을 선택하였으므로, poll2에서 1만큼 줄이고, poll1에서 1만큼 증가
                            percentage1 = round((champion1Votes + 1) / (champion1Votes + champion2Votes) * 100)
                            percentage2 = round((champion2Votes - 1) / (champion1Votes + champion2Votes) * 100)
                            self?.poll1.percentage.accept(percentage1)
                            self?.poll2.percentage.accept(percentage2)
                        }
                    }
                    else if info.fromPollNumber == 2 {
                        if info.voteInfo == nil {
                            // case: 전에 아무것도 선택 안 한 경우
                            percentage1 = round(champion1Votes / (champion1Votes + (champion2Votes + 1)) * 100)
                            percentage2 = round((champion2Votes + 1) / (champion1Votes + (champion2Votes + 1)) * 100)
                            self?.poll1.percentage.accept(percentage1)
                            self?.poll2.percentage.accept(percentage2)
                        }

                        else if info.voteInfo == 1 {
                            // case: 전에 poll1을 선택하였으므로, poll1에서 1만큼 줄이고, poll2에서 1만큼 증가
                            percentage1 = round((champion1Votes - 1) / (champion1Votes + champion2Votes) * 100)
                            percentage2 = round((champion2Votes + 1) / (champion1Votes + champion2Votes) * 100)
                            self?.poll1.percentage.accept(percentage1)
                            self?.poll2.percentage.accept(percentage2)
                        }
                    }
                }
                if let user = Auth.auth().currentUser {
                    self?.viewModel.updateUsersVoteInfo.onNext((userId: user.uid, docId: docId, fromPollNumber: info.fromPollNumber))
                }
            })
            .disposed(by: disposeBag)
    }
    
    
    required init?(coder aDecoder: NSCoder) {
//        data = PublishRelay<ViewPost>()
//        viewModel = HomeTableViewCellViewModel()
//        //onData = data.asObserver()
//
//
//        super.init(coder: aDecoder)
//
        fatalError("cell init error")
        
    }
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
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


