//
//  SettingCell.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/06/05.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

final class SettingCell: UITableViewCell {
    static let identifier = "SettingCell"
    
    var disposeBag = DisposeBag()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init error")
    }
    
    func connect(model: String) -> EventOutput {
        label.text = model
        
        let cellTapped =
        rx.tapGesture()
            .when(.ended)
            .mapToVoid()
        
        return EventOutput(cellTapped: cellTapped)
    }
    
    let label: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let seperatorView: UIView = {
        let seperatorView = UIView()
        seperatorView.translatesAutoresizingMaskIntoConstraints = false
        seperatorView.backgroundColor = .systemGray4
        return seperatorView
    }()
    
    
    
    func configureUI() {
        backgroundColor = UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1)
        contentView.addSubview(label)
        contentView.addSubview(seperatorView)
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 18),
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 18),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -18),
            
            seperatorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            seperatorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            seperatorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            seperatorView.heightAnchor.constraint(equalToConstant: 0.5)
        ])
        
        accessoryType = .disclosureIndicator
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        label.text = nil
        disposeBag = DisposeBag()
    }
}

extension SettingCell {
    struct EventOutput {
        let cellTapped: Observable<Void>
    }
}
