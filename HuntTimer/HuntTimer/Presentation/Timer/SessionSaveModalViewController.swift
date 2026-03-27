import UIKit
import PhotosUI

/// 사냥 기록 저장 커스텀 모달 ViewController
final class SessionSaveModalViewController: UIViewController {

    // MARK: - Configuration (호출 전 설정)
    var duration: Int = 0
    var onSave:   ((String?, UIImage?) -> Void)?
    var onCancel: (() -> Void)?

    // MARK: - View / State
    private let contentView = SessionSaveModalView()
    private var selectedPhoto: UIImage?

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
        contentView.durationLabel.text = formatDuration(duration)
    }

    // MARK: - Bind
    private func bind() {
        contentView.closeButton.addTarget(self, action: #selector(closeTapped),    for: .touchUpInside)
        contentView.saveButton.addTarget(self,  action: #selector(saveTapped),     for: .touchUpInside)

        let photoTap = UITapGestureRecognizer(target: self, action: #selector(photoSlotTapped))
        contentView.photoSlotView.isUserInteractionEnabled = true
        contentView.photoSlotView.addGestureRecognizer(photoTap)

        // 카드 밖 백드롭 탭 → 취소
        let backdropTap = UITapGestureRecognizer(target: self, action: #selector(closeTapped))
        contentView.backdropView.addGestureRecognizer(backdropTap)

        contentView.memoTextView.delegate = self
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        view.endEditing(true)
        dismiss(animated: true) { [weak self] in
            self?.onCancel?()
        }
    }

    @objc private func saveTapped() {
        view.endEditing(true)
        let memo: String? = {
            guard !contentView.isShowingPlaceholder else { return nil }
            let trimmed = contentView.memoTextView.text
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }()
        dismiss(animated: true) { [weak self] in
            self?.onSave?(memo, self?.selectedPhoto)
        }
    }

    @objc private func photoSlotTapped() {
        var config = PHPickerConfiguration()
        config.filter         = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    // MARK: - Duration Formatting

    private func formatDuration(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        if mins > 0 { return secs > 0 ? "\(mins)분 \(secs)초" : "\(mins)분" }
        return "\(secs)초"
    }
}

// MARK: - UITextViewDelegate (메모 플레이스홀더)

extension SessionSaveModalViewController: UITextViewDelegate {

    func textViewDidBeginEditing(_ textView: UITextView) {
        guard contentView.isShowingPlaceholder else { return }
        textView.text      = ""
        textView.textColor = UIColor(hex: "#3D2B2B")
        contentView.isShowingPlaceholder = false
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textView.text      = "냥이의 반응이나 특이사항을 적어주세요..."
            textView.textColor = UIColor(hex: "#C8B4BC")
            contentView.isShowingPlaceholder = true
        }
    }
}

// MARK: - PHPickerViewControllerDelegate (사진 선택)

extension SessionSaveModalViewController: PHPickerViewControllerDelegate {

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let result = results.first else { return }
        result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let image = object as? UIImage else { return }
            DispatchQueue.main.async {
                self?.selectedPhoto = image
                self?.contentView.photoImageView.image    = image
                self?.contentView.photoImageView.isHidden = false
                self?.contentView.cameraPlaceholderStack.isHidden = true
            }
        }
    }
}
