//
//  UploadCell.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/03/01.
//

import Foundation
import UIKit
import KMPlaceholderTextView


class UploadCell: UITableViewCell{
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("upload cell error")
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
            seperatorView.heightAnchor.constraint(equalToConstant: 0.25)
        ])
        
    }
}

