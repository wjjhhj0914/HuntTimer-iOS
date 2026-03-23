import UIKit

final class MainTabBarController: UITabBarController {

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        setupAppearance()
    }

    // MARK: - Setup

    private func setupTabs() {
        let tabs: [(UIViewController, String, String)] = [
            (HomeViewController(),  "홈",   "house.fill"),
            (LogViewController(),   "기록",  "calendar"),
            (TimerViewController(), "플레이", "pawprint.fill"),
            (ShopViewController(),  "쇼핑",  "cart.fill"),
            (AdoptViewController(), "입양",  "heart.fill"),
        ]

        viewControllers = tabs.map { vc, title, symbol in
            let nav = UINavigationController(rootViewController: vc)
            nav.setNavigationBarHidden(true, animated: false)
            nav.tabBarItem = UITabBarItem(
                title: title,
                image: UIImage(systemName: symbol),
                selectedImage: UIImage(systemName: symbol)
            )
            return nav
        }
    }

    private func setupAppearance() {
        tabBar.tintColor = AppTheme.Color.primary
        tabBar.unselectedItemTintColor = AppTheme.Color.textMuted

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.shadowColor = AppTheme.Color.primaryLight

        tabBar.standardAppearance   = appearance
        tabBar.scrollEdgeAppearance = appearance
    }
}
