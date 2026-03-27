import UIKit

/// 사냥 기록 상세 모달 ViewController — 디자인 Node ID: v2cvH 기반
final class HuntDetailViewController: UIViewController {

    // MARK: - Configuration (호출 전 설정)
    var durationSeconds: Int = 0
    var toyName:   String?   = nil
    var imagePath: String?   = nil
    var memo:      String?   = nil

    // MARK: - View
    private let contentView = HuntDetailView()

    // MARK: - loadView
    override func loadView() {
        view = contentView
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
        bind()
    }

    // MARK: - Configure
    private func configure() {
        let image: UIImage?
        if let path = imagePath {
            image = UIImage(contentsOfFile: path)
        } else {
            image = nil
        }
        contentView.configure(
            durationSeconds: durationSeconds,
            toyName:         toyName,
            image:           image,
            memo:            memo
        )
    }

    // MARK: - Bind
    private func bind() {
        contentView.closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        let backdropTap = UITapGestureRecognizer(target: self, action: #selector(closeTapped))
        contentView.backdropView.addGestureRecognizer(backdropTap)
    }

    // MARK: - Actions
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}
