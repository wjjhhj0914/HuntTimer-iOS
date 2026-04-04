import UIKit

/// 온보딩 Welcome 화면 ViewController
final class WelcomeViewController: BaseViewController {

    private let contentView = WelcomeView()

    // MARK: - loadView
    override func loadView() {
        view = contentView
    }

    // MARK: - Lifecycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    // MARK: - BaseViewController
    override func setupBind() {
        contentView.ctaButton.addTarget(self, action: #selector(ctaTapped), for: .touchUpInside)
    }

    // MARK: - Actions
    @objc private func ctaTapped() {
        navigationController?.pushViewController(CatListViewController(), animated: true)
    }
}
