

import UIKit
import SwiftUI
import CoreData
import UserNotifications


class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var window: UIWindow?
    lazy var appSession = AppSession(context: context)

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let url = URLContexts.first?.url{
            let urlStr = url.absoluteString
            appSession.addUserFromQrScan(urlStr)
        }
    }
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        migrateIfNecessary()
        
        let contentView = SetupView()
            .environment(\.managedObjectContext, context)
            .environmentObject(appSession)
        
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: contentView)
            self.window = window
            window.makeKeyAndVisible()
        }
    }

   
    func sceneDidEnterBackground(_ scene: UIScene) {
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }
    
    
    private func migrateIfNecessary() {
        
        guard let username = UserDefaults.standard.string(forKey: "Username") else {
            print("-- NO NEED TO MIGRATE USER --")
            return
        }
        
        let components = username.components(separatedBy: "#")
        
        guard components.count == 3 else {
            print("-- COULD NOT MIGRATE USER --")
            return
        }
        
        UserDefaults.standard.set(components[0], forKey: UserDefaultsKey.username.rawValue)
        UserDefaults.standard.set(components[2], forKey: UserDefaultsKey.userId.rawValue)
        UserDefaults.standard.removeObject(forKey: "Username")
    }
}

