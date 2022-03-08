//
//  LoginController.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/03/01.
//

import Foundation
import UIKit
import AuthenticationServices
import CryptoKit
import FirebaseAuth
import Firebase
import FirebaseFirestore
import RxCocoa
import RxSwift
import RxGesture
import RxRelay
import simd

// Unhashed nonce.
fileprivate var currentNonce: String?

class LoginController: UIViewController {
    var disposeBag = DisposeBag()
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        bind()
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
    lazy var containerViewHeight = 200.0
    lazy var containerView: UIView = {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        containerView.layer.cornerRadius = 15
        containerView.clipsToBounds = true
        return containerView
    }()
    
    lazy var loginLabel: UILabel = {
        let loginLabel = UILabel()
        loginLabel.text = "로그인을 해주세요!"
        loginLabel.font = .boldSystemFont(ofSize: 32)
        loginLabel.textColor = .white
        loginLabel.translatesAutoresizingMaskIntoConstraints = false
        return loginLabel
    }()
    
    lazy var appleAuthButton: ASAuthorizationAppleIDButton = {
        let appleAuthButton = ASAuthorizationAppleIDButton()
        appleAuthButton.addTarget(self, action: #selector(handleSignInWithAppleTapped), for: .touchUpInside)
        appleAuthButton.translatesAutoresizingMaskIntoConstraints = false
        return appleAuthButton
    }()
    
    lazy var xbtn: UIButton = {
        let xbtn = UIButton()
        xbtn.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)
        xbtn.setImage(UIImage(systemName: "xmark"), for: .normal)
        xbtn.tintColor = .white
        xbtn.translatesAutoresizingMaskIntoConstraints = false
        return xbtn
    }()
    
    func configureUI() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(dismissSelf))
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
            //containerView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: view.frame.height),
            containerView.heightAnchor.constraint(equalToConstant: containerViewHeight),
            
            loginLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            loginLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            //loginLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 24),
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
    
    func bind() {
        dimmedView.rx.tapGesture()
            .when(.recognized)
            .asDriver() { _ in .never() }
            .drive(onNext: { _ in
                self.animateDismissView()
            })
            .disposed(by: disposeBag)
    }
    
    func animatePresentContainer() {
        // Update bottom constraint in animation block
        UIView.animate(withDuration: 0.3) {
            self.containerViewBottomConstraint?.constant = 0
            // Call this to trigger refresh constraint
            self.view.layoutIfNeeded()
        }
    }
    
    func animateShowDimmedView() {
        dimmedView.alpha = 0
        UIView.animate(withDuration: 0.4) {
            self.dimmedView.alpha = self.maxDimmedAlpha
        }
    }
    
    func animateDismissView() {
        // hide main container view by updating bottom constraint in animation block
        UIView.animate(withDuration: 0.3) {
            self.containerViewBottomConstraint?.constant = self.containerViewHeight
            // call this to trigger refresh constraint
            self.view.layoutIfNeeded()
        }
        
        // hide blur view
        dimmedView.alpha = maxDimmedAlpha
        UIView.animate(withDuration: 0.4) {
            self.dimmedView.alpha = 0
        } completion: { _ in
            // once done, dismiss without animation
            self.dismiss(animated: false)
        }
    }
    
    @objc private func dismissSelf() {
        animateDismissView()
    }
    
    @objc func handleSignInWithAppleTapped() {
        startSignInWithAppleFlow()
    }
    

    
    @available(iOS 13, *)
    func startSignInWithAppleFlow() {
      let nonce = randomNonceString()
      currentNonce = nonce
      let appleIDProvider = ASAuthorizationAppleIDProvider()
      let request = appleIDProvider.createRequest()
      request.requestedScopes = [.fullName, .email]
      request.nonce = sha256(nonce)

      let authorizationController = ASAuthorizationController(authorizationRequests: [request])
      authorizationController.delegate = self
      authorizationController.presentationContextProvider = self
      authorizationController.performRequests()
    }
    
}
@available(iOS 13.0, *)
extension LoginController: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                fatalError("Invalid state: A login callback was recieved, but no login request was sent.")
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }
            
            let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: idTokenString, rawNonce: nonce)
            
            Auth.auth().signIn(with: credential) { (authDataResult, error) in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                if let user = authDataResult?.user {
                    print("Nice! You're now signed in as \(user.uid), email: \(user.email ?? "unknwon")")
                    let db = Firestore.firestore()
                    let docRef = db.collection("users").document(user.uid)
                    docRef.getDocument { document, error in
                        if let document = document, document.exists == false {
                            docRef.setData(["userId": user.uid]) { err in
                                if let err = err {
                                    print("User Id Setting error occured")
                                }
                            }
                        }
                        if let error = error {
                            print("Getting document error occured")
                        }
                    }
//                    db.collection("users").document(user.uid).updateData(["userId": user.uid]) { err in
//                        if let err = err {
//                            print("User Id Setting error occured")
//                        }
//                    }
                    LoginViewModel.shared.isLogin.accept(true)
                    self.animateDismissView()
                }
            }
        }
    }
    
}
@available(iOS 13.0, *)
extension LoginController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}
// Adapted from https://auth0.com/docs/api-auth/tutorials/nonce#generate-a-cryptographically-random-nonce
private func randomNonceString(length: Int = 32) -> String {
  precondition(length > 0)
  let charset: [Character] =
    Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
  var result = ""
  var remainingLength = length

  while remainingLength > 0 {
    let randoms: [UInt8] = (0 ..< 16).map { _ in
      var random: UInt8 = 0
      let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
      if errorCode != errSecSuccess {
        fatalError(
          "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
        )
      }
      return random
    }

    randoms.forEach { random in
      if remainingLength == 0 {
        return
      }

      if random < charset.count {
        result.append(charset[Int(random)])
        remainingLength -= 1
      }
    }
  }

  return result
}

@available(iOS 13, *)
private func sha256(_ input: String) -> String {
  let inputData = Data(input.utf8)
  let hashedData = SHA256.hash(data: inputData)
  let hashString = hashedData.compactMap {
    String(format: "%02x", $0)
  }.joined()

  return hashString
}

