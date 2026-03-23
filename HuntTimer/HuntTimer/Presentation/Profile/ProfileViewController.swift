import UIKit
import RxSwift
import RxCocoa

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

    // MARK: - BaseViewController
    override func setupBind() {
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
    }
}
