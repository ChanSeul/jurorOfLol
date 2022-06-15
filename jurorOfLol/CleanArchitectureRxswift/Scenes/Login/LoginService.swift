//
//  LoginService.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/06/01.
//

import Foundation
import AuthenticationServices
import RxSwift
import CryptoKit
import FirebaseAuth

fileprivate var currentNonce: String?

enum LoginService {
    static func makeCredential(didCompleteWithAuthorization authorization: ASAuthorization) -> Observable<(credential: OAuthCredential, appleUserId: String)> {
        Observable.create { observer in
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                guard let nonce = currentNonce else {
                    print("Invalid state: A login callback was recieved, but no login request was sent.")
                    observer.onError(RxError.unknown)
                    return Disposables.create()
                }
                guard let appleIDToken = appleIDCredential.identityToken else {
                    print("Unable to fetch identity token")
                    observer.onError(RxError.unknown)
                    return Disposables.create()
                }
                guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                    print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                    observer.onError(RxError.unknown)
                    return Disposables.create()
                }
                
                let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: idTokenString, rawNonce: nonce)
                
                observer.onNext((credential: credential, appleUserId: appleIDCredential.user))
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
    @available(iOS 13, *)
    static func startSignInWithAppleFlow() -> Observable<[ASAuthorizationAppleIDRequest]> {
        let nonce = randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        return Observable.just([request])
    }
    
    @available(iOS 13, *)
    static func startSignInWithFirebaseFlow(credential: OAuthCredential) -> Observable<Void> {
        Observable.create { observer in
            Auth.auth().signIn(with: credential) { (authDataResult, error) in
                if let error = error {
                    observer.onError(error)
                }
                if let user = authDataResult?.user {
                    UserDefaults.standard.setIsLoggedIn(value: true, userId: user.uid)
                    observer.onNext(())
                }
                observer.onCompleted()
            }
            return Disposables.create()
        }
        
    }
    @available(iOS 13, *)
    static func signOut() -> Observable<Void> {
        Observable<Void>.create { observer -> Disposable in
            do {
                try Auth.auth().signOut()
                UserDefaults.standard.setIsLoggedIn(value: false, userId: nil)
                observer.onNext(())
            } catch {
                observer.onError(error)
            }
            observer.onCompleted()
            return Disposables.create()
        }
    }
    static private func randomNonceString(length: Int = 32) -> String {
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
    static private func sha256(_ input: String) -> String {
      let inputData = Data(input.utf8)
      let hashedData = SHA256.hash(data: inputData)
      let hashString = hashedData.compactMap {
        String(format: "%02x", $0)
      }.joined()

      return hashString
    }
}
