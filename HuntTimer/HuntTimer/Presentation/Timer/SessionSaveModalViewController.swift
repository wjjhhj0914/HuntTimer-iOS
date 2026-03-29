import UIKit

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

        contentView.memoTextView.delegate = self

        // 모달 배경 탭 → 키보드 내리기
        let bgTap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        bgTap.cancelsTouchesInView = false
        contentView.addGestureRecognizer(bgTap)
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        view.endEditing(true)

        let alert = UIAlertController(
            title: "기록을 어떻게 할까요?",
            message: "작성 중인 사진과 메모는 사라집니다.",
            preferredStyle: .alert
        )

        // 시간만 저장 — 메모·사진 없이 사냥 시간만 Realm에 기록
        alert.addAction(UIAlertAction(title: "시간만 저장", style: .default) { [weak self] _ in
            guard let self else { return }
            dismiss(animated: true) { self.onSave?(nil, nil) }
        })

        // 기록 삭제 — 아무것도 저장하지 않고 파기
        alert.addAction(UIAlertAction(title: "기록 삭제", style: .destructive) { [weak self] _ in
            guard let self else { return }
            dismiss(animated: true) { self.onCancel?() }
        })

        // 취소 — 알림창만 닫고 기록 화면으로 복귀
        // .alert 스타일은 바깥 탭으로 dismiss 되지 않으므로 별도 처리 불필요
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))

        present(alert, animated: true)
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

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func photoSlotTapped() {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else { return }
        let picker = UIImagePickerController()
        picker.sourceType    = .photoLibrary
        picker.allowsEditing = true
        picker.delegate      = self
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

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        guard contentView.isShowingPlaceholder else { return }
        textView.text      = ""
        textView.textColor = UIColor(hex: "#3D2B2B")
        contentView.isShowingPlaceholder = false
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textView.text      = "즐거웠던 순간을 기록해 주세요..."
            textView.textColor = UIColor(hex: "#C8B4BC")
            contentView.isShowingPlaceholder = true
        }
    }
}

// MARK: - UIImagePickerControllerDelegate (사진 선택 + 크롭)

extension SessionSaveModalViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage
        guard let image else { return }
        selectedPhoto = image
        contentView.photoImageView.image    = image
        contentView.photoImageView.isHidden = false
        contentView.cameraPlaceholderStack.isHidden = true
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
