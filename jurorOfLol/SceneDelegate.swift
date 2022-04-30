
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = (scene as? UIWindowScene) else { return }
         
        self.window = UIWindow(windowScene: windowScene)
        
        let mainTC = TabBarController()
        
        self.window?.rootViewController = mainTC
        
        self.window?.makeKeyAndVisible()
        
    }
//
//    func sceneDidEnterBackground(_ scene: UIScene) {
//        print("background")
//    }
//    func sceneWillEnterForeground(_ scene: UIScene) {
//        print("foreground")
//    }
    func sceneDidBecomeActive(_ scene: UIScene) {
        print("becomActive")
        Singleton.shared.becomeActive.accept(true)
    }
//    func sceneWillResignActive(_ scene: UIScene) {
////        ThreadViewModel.shared.isBackground.accept(true)
//        print("resign")
//    }
}

