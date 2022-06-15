//
//  LoginViewController.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/05/30.
//

import Foundation
import UIKit
import AuthenticationServices
import RxCocoa
import RxSwift
import RxGesture
import RxRelay

class LoginViewController: UIViewController {
    var viewModel: LoginViewModel!
    
    let appleSignInComplete = PublishSubject<ASAuthorization>()
    var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        connect()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        animateShowDimmedView()
        animatePresentContainer()
    }
    
    let maxDimmedAlpha: CGFloat = 0.6
    lazy var dimmedView: UIView = {
        let dimmedView = UIView()
        dimmedView.backgroundColor = .black
        dimmedView.alpha = maxDimmedAlpha
        dimmedView.translatesAutoresizingMaskIntoConstraints = false
        return dimmedView
    }()
    
    var containerViewBottomConstraint: NSLayoutConstraint?
    var containerViewHeight = 200.0
    let containerView: UIView = {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        containerView.layer.cornerRadius = 15
        containerView.clipsToBounds = true
        return containerView
    }()
    
    let loginLabel: UILabel = {
        let loginLabel = UILabel()
        loginLabel.text = "로그인을 해주세요!"
        loginLabel.font = .boldSystemFont(ofSize: 32)
        loginLabel.textColor = .white
        loginLabel.translatesAutoresizingMaskIntoConstraints = false
        return loginLabel
    }()
    
    let appleAuthButton: ASAuthorizationAppleIDButton = {
        let appleAuthButton = ASAuthorizationAppleIDButton()
        appleAuthButton.translatesAutoresizingMaskIntoConstraints = false
        return appleAuthButton
    }()
    
    let xbtn: UIButton = {
        let xbtn = UIButton()
        xbtn.setImage(UIImage(systemName: "xmark"), for: .normal)
        xbtn.tintColor = .white
        xbtn.translatesAutoresizingMaskIntoConstraints = false
        return xbtn
    }()
    
    func configureUI() {
        view.backgroundColor = .clear
        
        view.addSubview(dimmedView)
        view.addSubview(containerView)
        containerView.addSubview(loginLabel)
        containerView.addSubview(appleAuthButton)
        containerView.addSubview(xbtn)
        
        let safeArea = view.safeAreaLayoutGuide
        
        NSLayoutConstraint.activate([
            dimmedView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            dimmedView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            dimmedView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            dimmedView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor),
            
            containerView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            containerView.heightAnchor.constraint(equalToConstant: containerViewHeight),
            
            loginLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            loginLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            loginLabel.bottomAnchor.constraint(equalTo: appleAuthButton.topAnchor, constant: -24),
            
            appleAuthButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            appleAuthButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            appleAuthButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -24),
            appleAuthButton.heightAnchor.constraint(equalToConstant: 50),
            
            xbtn.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            xbtn.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            xbtn.widthAnchor.constraint(equalToConstant: 32),
            xbtn.heightAnchor.constraint(equalToConstant: 32)
        ])

        containerViewBottomConstraint = containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: containerViewHeight)
        containerViewBottomConstraint?.isActive = true
    }
    
    func animatePresentContainer() {
        // Update bottom constraint in animation block
        UIView.animate(withDuration: 0.3) { [unowned self] in
            self.containerViewBottomConstraint?.constant = 0
            // Call this to trigger refresh constraint
            self.view.layoutIfNeeded()
        }
    }
    
    func animateShowDimmedView() {
        dimmedView.alpha = 0
        UIView.animate(withDuration: 0.4) { [unowned self] in
            self.dimmedView.alpha = self.maxDimmedAlpha
        }
    }
    
    func animateDismissView() {
        // hide main container view by updating bottom constraint in animation block
        UIView.animate(withDuration: 0.2) { [unowned self] in
            self.containerViewBottomConstraint?.constant = self.containerViewHeight
            // call this to trigger refresh constraint
            self.view.layoutIfNeeded()
        }
        
        // hide blur view
        dimmedView.alpha = maxDimmedAlpha
        UIView.animate(withDuration: 0.2) { [unowned self] in
            self.dimmedView.alpha = 0
        }
    }
}

