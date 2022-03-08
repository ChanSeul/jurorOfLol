//
//  SwitchSettingTableViewCell.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/03/02.
//

import UIKit

class SwitchSettingTableViewCell: UITableViewCell {
    static let identifier = "SwitchSettingTableViewCell"
    
    lazy var label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var someSwitch: UISwitch = {
        let someSwitch = UISwitch()
        someSwitch.onTintColor = .systemBlue
        return someSwitch
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
        contentView.addSubview(someSwitch)
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 18),
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 18),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -18),
            
            someSwitch.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -18),
            someSwitch.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 18),
            someSwitch.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -18)
        ])
        
        accessoryType = .none
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        label.text = nil
        someSwitch.isOn = false
    }
    
    func configure(with model: SettingsSwitchOption) {
        label.text = model.title
        someSwitch.isOn = model.isOn
    }
}
