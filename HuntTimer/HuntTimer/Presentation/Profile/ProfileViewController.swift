import UIKit
import RxSwift
import RxCocoa
import RealmSwift

/// 프로필 화면 ViewController — 추모 모드 토글 바인딩만 담당
final class ProfileViewController: BaseViewController {

    // MARK: - View
    private let contentView = ProfileView()

    // MARK: - ViewModel
    private let viewModel   = ProfileViewModel()
    private let disposeBag  = DisposeBag()

    // MARK: - loadView
    override func loadView() {
        view = contentView
    }

    // MARK: - Lifecycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    // MARK: - BaseViewController
    override func setupBind() {
        // 뒤로가기 버튼
        let backBtn = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
        backBtn.tintColor = AppTheme.Color.primary
        navigationItem.leftBarButtonItem = backBtn

        let input = ProfileViewModel.Input(
            memorialToggled: contentView.memorialToggle.rx.isOn.asObservable()
        )
        let output = viewModel.transform(input: input)

        output.backgroundTint
            .drive(onNext: { [weak self] color in
                UIView.animate(withDuration: 0.2) {
                    self?.contentView.backgroundColor = color
                }
            })
            .disposed(by: disposeBag)

        // 추모 모드 ON 시 얼럿
        contentView.memorialToggle.rx.isOn
            .skip(1)
            .filter { $0 }
            .subscribe(onNext: { [weak self] _ in
                self?.showMemorialAlert()
            })
            .disposed(by: disposeBag)

        // 고양이 설정 행 탭 → 프로필 수정 화면
        let tap = UITapGestureRecognizer(target: self, action: #selector(catSettingsTapped))
        contentView.catSettingsCard.isUserInteractionEnabled = true
        contentView.catSettingsCard.addGestureRecognizer(tap)
    }

    // MARK: - Actions
    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func catSettingsTapped() {
        let vc = CatProfileViewController()
        vc.mode     = .edit
        vc.catToEdit = (try? Realm())?.objects(Cat.self).first
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Alerts
    private func showMemorialAlert() {
        let alert = UIAlertController(
            title: "소중한 기억을 간직하며",
            message: "무지개 다리를 건넌 우리 아이가 푹 쉬기를 바랍니다. 추모 모드에서는 아이의 기록을 보호하기 위해 사냥 타이머 기능이 제한됩니다.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}
