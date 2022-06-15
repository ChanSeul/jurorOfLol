//
//  UplodaCell.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/06/02.
//

import UIKit
import KMPlaceholderTextView
import RxSwift
import RxRelay
import RxCocoa

final class UploadCell: UITableViewCell {
    static let identifier = "CreateCell"
    var disposeBag = DisposeBag()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("upload cell error")
    }
    
    func connect(inputType: String, viewHeight: CGFloat) -> EventOutput {
        switch inputType {
        case "url":
            textView.placeholder = "유튜브 URL('일부 공개'로 업로드시, 유튜브에 노출되지 않습니다.)"
            textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 48).isActive = true
        case "champion1":
            textView.placeholder = "본인의 주장."
        case "champion2":
            textView.placeholder = "상대방의 주장."
        case "detail":
            textView.placeholder = "당시 상황에 대해 자세히 적어주세요."
            blankView.heightAnchor.constraint(equalToConstant: viewHeight * 0.6).isActive = true
        default:
            break
        }
        
        let textChange = textView.rx.text.orEmpty.asDriver()
        let textEditBegin = textView.rx.didBeginEditing.asDriver()
        
        return EventOutput(textChange: textChange, textEditBegin: textEditBegin)
    }
    //MARK: UI
    
    let containerView: UIView = {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        return containerView
    }()
    
    let textView: KMPlaceholderTextView = {
        let textView = KMPlaceholderTextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isScrollEnabled = false
        textView.font = .systemFont(ofSize: 16)
        textView.textColor = .white
        textView.placeholderColor = .white
        textView.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        textView.autocapitalizationType = .none
        textView.autocorrectionType = .no
        return textView
    }()
    
    let blankView: UIView = {
        let blankView = UIView()
        blankView.translatesAutoresizingMaskIntoConstraints = false
        return blankView
    }()
    
    let seperatorView: UIView = {
        let seperatorView = UIView()
        seperatorView.translatesAutoresizingMaskIntoConstraints = false
        seperatorView.backgroundColor = .systemGray4
        return seperatorView
    }()
    
    func configureUI() {
        backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        
        contentView.addSubview(containerView)
        containerView.addSubview(textView)
        containerView.addSubview(blankView)
        containerView.addSubview(seperatorView)
        
        let margin: CGFloat = 18
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            textView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: margin),
            textView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -margin),
            textView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: margin),
            
            blankView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            blankView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            blankView.topAnchor.constraint(equalTo: textView.bottomAnchor),
            blankView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -margin),
            
            seperatorView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            seperatorView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            seperatorView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            seperatorView.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
}

extension UploadCell {
    struct EventOutput {
        let textChange: Driver<String>
        let textEditBegin: Driver<Void>
    }
}
