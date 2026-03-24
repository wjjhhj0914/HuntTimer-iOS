import UIKit
import RealmSwift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        configureRealm()
        return true
    }

    // MARK: - Realm
    private func configureRealm() {
        #if DEBUG
        let config = Realm.Configuration(deleteRealmIfMigrationNeeded: true)
        #else
        let config = Realm.Configuration(deleteRealmIfMigrationNeeded: false)
        #endif
        Realm.Configuration.defaultConfiguration = config
        if let url = config.fileURL {
            print("📦 Realm file path:\n\(url.path)")
        }
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}
