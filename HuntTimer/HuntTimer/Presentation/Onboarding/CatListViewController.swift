import UIKit
import RealmSwift

/// 고양이 목록 화면 — 등록된 고양이가 0마리면 Empty State, 1마리 이상이면 목록 표시(추후 확장)
final class CatListViewController: BaseViewController {

    private let contentView = CatListView()

    // MARK: - loadView
    override func loadView() {
        view = contentView
    }

    // MARK: - Lifecycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 다음 화면(CatProfileViewController)도 nav bar를 숨기므로 그대로 유지
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    // MARK: - BaseViewController
    override func setupBind() {
        contentView.addButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
    }

    // MARK: - Actions
    @objc private func addTapped() {
        let vc = CatProfileViewController()
        vc.mode = .registration
        navigationController?.pushViewController(vc, animated: true)
    }
}
