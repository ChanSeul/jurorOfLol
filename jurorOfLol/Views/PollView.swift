//
//  PollView.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/03/01.
//

import Foundation
import UIKit
import RxCocoa
import RxRelay
import RxSwift

class PollView: UIView {
    private let disposeBag = DisposeBag()
    var percentageFillingWidthViewConstraint: NSLayoutConstraint?
    
    init() {
        super.init(frame: CGRect.zero)
        configureUI()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setPercentage(percentageNumber: Double) {
        var margin:CGFloat = 0
        if percentageNumber >= 0.99 { margin = -4.0 }

        deactiveWidthConstraint()
        
        percentageFillingWidthViewConstraint = percentageFillingView.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: percentageNumber, constant: margin)
        if let width = percentageFillingWidthViewConstraint {
            NSLayoutConstraint.activate([width])
        }
        
        percentageLabel.text = String(format: "%.f",percentageNumber * 100) + "%"
    }
    func setBlue() {
        championLabel.textColor = .systemBlue
        percentageLabel.textColor = .systemBlue
        layer.borderColor = UIColor.systemBlue.cgColor
        percentageFillingView.backgroundColor = UIColor(red: 90/255, green: 150/255, blue: 255/255, alpha: 0.2)
    }
    func setGray() {
        championLabel.textColor = .systemGray
        percentageLabel.textColor = .systemGray
        layer.borderColor = UIColor.systemGray4.cgColor
        percentageFillingView.backgroundColor = .systemGray4
    }
    func deactiveWidthConstraint() {
        if let width = percentageFillingWidthViewConstraint {
            NSLayoutConstraint.deactivate([width])
        }
        percentageFillingWidthViewConstraint = nil
    }
    let percentageFillingView: UIView = {
        let percentageFillingView = UIView()
        percentageFillingView.translatesAutoresizingMaskIntoConstraints = false
        percentageFillingView.backgroundColor = .systemGray4
        percentageFillingView.layer.cornerRadius = 3
        return percentageFillingView
    }()
    
    let championLabel: UILabel = {
        let championLabel = UILabel()
        championLabel.font = UIFont.systemFont(ofSize: 14)
        championLabel.translatesAutoresizingMaskIntoConstraints = false
        championLabel.textColor = .systemGray
        championLabel.numberOfLines = 2
        return championLabel
    }()

    let percentageLabel: UILabel = {
        let percentageLabel = UILabel()
        percentageLabel.font = UIFont.systemFont(ofSize: 14)
        percentageLabel.translatesAutoresizingMaskIntoConstraints = false
        percentageLabel.textColor = .systemGray
        return percentageLabel
    }()
    
//    let containerView: UIView = {
//        let containerView = UIView()
//        containerView.translatesAutoresizingMaskIntoConstraints = false
//        return containerView
//    }()
    
    func configureUI() {
        layer.borderWidth = 1
        let borderColor: UIColor = .systemGray4
        layer.borderColor = borderColor.cgColor
        clipsToBounds = true
        layer.cornerRadius = 3
        
        translatesAutoresizingMaskIntoConstraints = false
    
        addSubview(percentageFillingView)
        addSubview(championLabel)
        //championLabel.addSubview(percentageLabel)
        addSubview(percentageLabel)
        
        let margin:CGFloat = 9
        NSLayoutConstraint.activate([
            percentageFillingView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 2),
            percentageFillingView.topAnchor.constraint(equalTo: self.topAnchor, constant: 2),
            percentageFillingView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -2),
            
            championLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: margin),
            championLabel.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.8),
            championLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: margin),
            championLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -margin),
            
            percentageLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -margin),
            percentageLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: margin),
            percentageLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -margin)
        ])
        
        
    }
}


