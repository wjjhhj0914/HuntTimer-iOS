import UIKit
import RealmSwift

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)

        // 등록된 고양이 프로필이 있으면 메인 탭으로, 없으면 온보딩으로
        let hasCat = (try? Realm())?.objects(Cat.self).isEmpty == false
        let rootVC: UIViewController
        if hasCat {
            rootVC = MainTabBarController()
        } else {
            let nav = UINavigationController(rootViewController: WelcomeViewController())
            nav.setNavigationBarHidden(true, animated: false)
            rootVC = nav
        }

        window.rootViewController = rootVC
        window.backgroundColor = AppTheme.Color.background
        window.makeKeyAndVisible()
        self.window = window
    }
}
