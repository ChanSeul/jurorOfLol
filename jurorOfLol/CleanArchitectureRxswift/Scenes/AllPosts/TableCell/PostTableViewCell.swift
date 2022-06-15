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


final class PostTableViewCell: UITableViewCell {
    static let identifier = "PostTableViewCell"
    
    private var isLoaded = false
    private var url = ""
    
    weak var delegate: PostTableCellDelegate?
    
    var disposeBag = DisposeBag()
       
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("cell init error")
    }
    
    func connect(postItem: Driver<PostItemViewModel>, voteData: Driver<[String: Int]>) -> EventOutput {
        Driver.combineLatest(postItem, voteData) { ($0, $1) }
            .drive(onNext: { [unowned self] (post, voteDict) in
                postDate.text = post.date.toDateFormat()
                if isLoaded {
                    if url != post.url {
                        videoContainerView.cueVideo(byId: post.url.youTubeId!, startSeconds: 0, suggestedQuality: .default)
                        url = post.url
                        self.postText.appendReadmore(after: post.text, trailingContent: .readmore)
                    }
                } else {
                    videoContainerView.load(withVideoId: post.url.youTubeId!)
                    url = post.url
                    isLoaded = true
                    self.postText.appendReadmore(after: post.text, trailingContent: .readmore)
                }
        
                self.poll1.championLabel.text = post.champion1
                self.poll2.championLabel.text = post.champion2
        
                self.poll1.setPercentage(percentageNumber: post.totalVotes > 0 ? (Double(post.vote1) / (Double(post.totalVotes))) : 0)
        
                self.poll2.setPercentage(percentageNumber: post.totalVotes > 0 ? (Double(post.vote2) / (Double(post.totalVotes))) : 0)
        
                self.numberOfVotesLabel.text = String(post.totalVotes) + "명 투표"
                    
                if let voteValue = voteDict[post.docID] {
                    switch voteValue {
                    case 1:
                        self.poll1.setBlue()
                        self.poll2.setGray()
                    case 2:
                        self.poll1.setGray()
                        self.poll2.setBlue()
                    default:
                        break
                    }
                } else {
                    self.poll1.setGray()
                    self.poll2.setGray()
                }
            }).disposed(by: disposeBag)
        
        Driver.merge(
            poll1.rx.tapGesture().when(.ended).asDriverOnErrorJustComplete().map { _ in 1 },
            poll2.rx.tapGesture().when(.ended).asDriverOnErrorJustComplete().map { _ in 2 }
        )
        .withLatestFrom(postItem) { ($1.id, $0) }
        .drive(onNext: { (id, from) in
            NotificationCenter.default.post(name: .pollTapped, object: (id, from))
        })
        .disposed(by: disposeBag)
        
        
        let detailTapped =
        postText.rx.tapGesture()
            .when(.ended)
            .asDriverOnErrorJustComplete()
            .withLatestFrom(postItem)
            .map { $0.text }
        
        let editBtnTapped = editBtn.rx.tap
            .asDriver()
            .withLatestFrom(postItem)
            .flatMap { [unowned self] post in
                self.delegate!.showAlert(post.userID)
            }.withLatestFrom(postItem) { ($1.id, $0) }
        
        return EventOutput(detailTapped: detailTapped, editBtnTapped: editBtnTapped)
        
    }
    
    func appendMoreOrLess(detail: String) {
        if postText.numberOfLines == 0 {
            postText.appendReadmore(after: detail, trailingContent: .readmore)
        } else {
            postText.appendReadLess(after: detail, trailingContent: .readless)
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
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
        postText.numberOfLines = 0
        return postText
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

extension PostTableViewCell {
    struct EventOutput {
        let detailTapped: Driver<String>
        let editBtnTapped: Driver<(PostItemViewModel.ID, Int)>
    }
}
