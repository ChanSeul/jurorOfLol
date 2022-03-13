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
    let percentage = PublishRelay<Double>()
    
    init() {
        super.init(frame: CGRect.zero)
        bind()
        configureUI()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func bind() {
        percentage.asDriver() { _ in .never() }
            .drive(onNext: { [weak self] percentageNumber in
                guard let self = self else { return }
                //print("ssibal \(percentageNumber)")
                var n = percentageNumber
                if n == 1.0 { n = 0.9825 }
                else if n == 0 { n = 0.00001 }
                
                self.percentageFillingView.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: n).isActive = true
                
                self.percentageLabel.text = String(format: "%.f",percentageNumber * 100) + "%"
            })
            .disposed(by: disposeBag)
    }
    let percentageFillingView: UIView = {
        let percentageFillingView = UIView()
        percentageFillingView.translatesAutoresizingMaskIntoConstraints = false
        percentageFillingView.backgroundColor = .systemGray4
        percentageFillingView.layer.cornerRadius = 5
        return percentageFillingView
    }()
    
    let championLabel: UILabel = {
        let championLabel = UILabel()
        championLabel.translatesAutoresizingMaskIntoConstraints = false
        championLabel.textColor = .systemBlue
        //championLabel.text = "그레이브즈"
        return championLabel
    }()

    let percentageLabel: UILabel = {
        let percentageLabel = UILabel()
        percentageLabel.translatesAutoresizingMaskIntoConstraints = false
        percentageLabel.textColor = .systemBlue
        //percentageLabel.text = "36%"
        return percentageLabel
    }()
    
    func configureUI() {
        layer.borderWidth = 1
        let borderColor: UIColor = .systemGray4
        layer.borderColor = borderColor.cgColor
        clipsToBounds = true
        layer.cornerRadius = 7
        
        translatesAutoresizingMaskIntoConstraints = false
    
        addSubview(percentageFillingView)
        addSubview(championLabel)
        //championLabel.addSubview(percentageLabel)
        addSubview(percentageLabel)
        
        let margin:CGFloat = 9
        NSLayoutConstraint.activate([
            percentageFillingView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 3),
            percentageFillingView.topAnchor.constraint(equalTo: self.topAnchor, constant: 3),
            percentageFillingView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -3),
            //percentageFillingView.widthAnchor.constraint(lessThanOrEqualTo: self.widthAnchor, multiplier: 1.0),
            
            championLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: margin),
            championLabel.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.8),
            championLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: margin),
            championLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -margin),
            
            //percentageLabel.leadingAnchor.constraint(equalTo: championLabel.trailingAnchor),
            percentageLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -margin),
            percentageLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: margin),
            percentageLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -margin)
        ])
 
    }
}

