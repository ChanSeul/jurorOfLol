import UIKit
import SwiftUI
import Firebase

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window : UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
//        UserDefaults.standard.setIsLoggedIn(value: false, userId: "")
        let window = UIWindow(frame: UIScreen.main.bounds)
        
        Application.shared.configureMainInterface(in: window)
        
        self.window = window
        self.window?.makeKeyAndVisible()
        return true
    }
    
}

