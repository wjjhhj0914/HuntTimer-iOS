import UIKit
import RealmSwift

/// 사냥 기록 상세 모달 ViewController — 하루치 모든 세션을 좌우 스와이프로 탐색
final class HuntDetailViewController: UIViewController {

    // MARK: - Configuration (호출 전 설정)
    var sessions: [PlaySession] = []

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
        let data = sessions.map { s -> (durationSeconds: Int, toyName: String?, image: UIImage?, memo: String?) in
            let image: UIImage? = s.photos.first.flatMap { UIImage(contentsOfFile: $0.imagePath) }
            return (s.duration, s.toys.first?.name, image, s.memo)
        }
        contentView.configure(sessions: data)
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
