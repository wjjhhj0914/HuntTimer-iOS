import UIKit
import RealmSwift

/// 고양이 목록 화면 — 등록된 고양이가 0마리면 Empty State, 1마리 이상이면 목록 표시
final class CatListViewController: BaseViewController {

    private let contentView = CatListView()
    private var cats: [Cat] = []

    // MARK: - loadView
    override func loadView() {
        view = contentView
    }

    // MARK: - Lifecycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        reloadCats()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    // MARK: - BaseViewController
    override func setupBind() {
        contentView.addButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
        contentView.startButton.addTarget(self, action: #selector(startTapped), for: .touchUpInside)

        contentView.tableView.dataSource = self
        contentView.tableView.delegate   = self
        contentView.tableView.register(CatListCell.self, forCellReuseIdentifier: CatListCell.id)
    }

    // MARK: - Data
    private func reloadCats() {
        do {
            let realm = try Realm()
            cats = Array(realm.objects(Cat.self))
        } catch {
            cats = []
        }
        contentView.tableView.reloadData()
        contentView.updateState(catCount: cats.count)
    }

    // MARK: - Actions
    @objc private func addTapped() {
        let vc = CatProfileViewController()
        vc.mode = .registration
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func startTapped() {
        guard let windowScene = view.window?.windowScene,
              let window      = windowScene.windows.first else { return }
        UIView.transition(with: window,
                          duration: 0.4,
                          options: .transitionCrossDissolve) {
            window.rootViewController = MainTabBarController()
        }
    }
}

// MARK: - UITableViewDataSource
extension CatListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        cats.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CatListCell.id, for: indexPath) as! CatListCell
        let cat  = cats[indexPath.row]
        cell.configure(cat: cat)
        cell.onEditTap = { [weak self] in
            guard let self else { return }
            let vc = CatProfileViewController()
            vc.mode      = .edit
            vc.catToEdit = cat
            self.navigationController?.pushViewController(vc, animated: true)
        }
        return cell
    }
}

// MARK: - UITableViewDelegate
extension CatListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        108
    }
}
