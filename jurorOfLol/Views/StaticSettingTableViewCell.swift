//
//  SettingTableViewCell.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/03/02.
//

import Foundation
import UIKit

class StaticSettingTableViewCell: UITableViewCell {
    static let identifier = "SettingTableViewCell"
    
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
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init error")
    }
    func configureUI() {
        backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
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
    }
    
    func configure(with model: SettingsStaticOption) {
        label.text = model.title
    }
    
}
