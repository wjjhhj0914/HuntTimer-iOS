import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)

        // TODO: 고양이 프로필이 등록된 경우 MainTabBarController로 바로 진입
        let root = UINavigationController(rootViewController: WelcomeViewController())
        root.setNavigationBarHidden(true, animated: false)

        window.rootViewController = root
        window.backgroundColor = AppTheme.Color.background
        window.makeKeyAndVisible()
        self.window = window
    }
}
