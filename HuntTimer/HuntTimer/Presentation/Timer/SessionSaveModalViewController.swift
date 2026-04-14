import UIKit
import AVFoundation

/// 사냥 기록 저장 커스텀 모달 ViewController
final class SessionSaveModalViewController: UIViewController {

    // MARK: - Pending Session Draft (앱 종료 대비 UserDefaults 임시 저장)

    struct PendingSessionDraft: Codable {
        let duration:          Int
        let catIds:            [String]   // ObjectId.stringValue
        let toyName:           String?
        let targetDuration:    Int
        let sessionStartTime:  TimeInterval   // Date.timeIntervalSince1970
        let memo:              String?
        let photoData:         Data?
    }

    private static let draftKey = "pendingSessionDraft"

    /// 드래프트 불러오기 (HomeViewController에서 호출)
    static func loadDraft() -> PendingSessionDraft? {
        guard let data  = UserDefaults.standard.data(forKey: draftKey),
              let draft = try? JSONDecoder().decode(PendingSessionDraft.self, from: data)
        else { return nil }
        return draft
    }

    /// 드래프트 삭제 (복구 완료 또는 정상 저장 후 호출)
    static func clearSavedDraft() {
        UserDefaults.standard.removeObject(forKey: draftKey)
    }

    /// 현재 모달 상태를 UserDefaults에 임시 저장
    private func saveDraft() {
        let memo: String? = {
            guard !contentView.isShowingPlaceholder else { return nil }
            let t = contentView.memoTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
            return t.isEmpty ? nil : t
        }()
        let draft = PendingSessionDraft(
            duration:         duration,
            catIds:           catIds,
            toyName:          toyName,
            targetDuration:   targetDuration,
            sessionStartTime: sessionStartTime.timeIntervalSince1970,
            memo:             memo,
            photoData:        selectedPhoto?.jpegData(compressionQuality: 0.75)
        )
        if let data = try? JSONEncoder().encode(draft) {
            UserDefaults.standard.set(data, forKey: Self.draftKey)
        }
    }

    /// 모달이 살아있을 때 드래프트 삭제 (복구 불필요)
    private func clearDraft() {
        SessionSaveModalViewController.clearSavedDraft()
    }

    // MARK: - Configuration (호출 전 설정)
    var duration:        Int    = 0
    var onSave:          ((String?, UIImage?) -> Void)?
    var onCancel:        (() -> Void)?
    // 드래프트 저장용 세션 메타 데이터 (HuntInProgressVC에서 주입)
    var catIds:          [String] = []
    var toyName:         String?  = nil
    var targetDuration:  Int      = 0
    var sessionStartTime: Date    = Date()
    // 드래프트 복구 시 초기값 (HomeVC에서 주입)
    var initialMemo:     String?  = nil
    var initialPhoto:    UIImage? = nil

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
        registerKeyboardObservers()
        // 앱이 포그라운드로 돌아올 때 모달이 살아있으면 드래프트 삭제
        NotificationCenter.default.addObserver(
            self, selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 모달이 처음 나타날 때 이전 드래프트 정리 (설정 복귀 후 재노출 케이스도 포함)
        clearDraft()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func appWillEnterForeground() {
        // 모달이 화면에 있는 채로 포그라운드 복귀 → 드래프트 불필요
        clearDraft()
    }

    // MARK: - Configure
    private func configure() {
        contentView.durationLabel.text = formatDuration(duration)
        // 드래프트 복구 시 메모·사진 초기값 적용
        if let memo = initialMemo {
            contentView.memoTextView.text      = memo
            contentView.memoTextView.textColor = AppTheme.Color.textDark
            contentView.isShowingPlaceholder   = false
        }
        if let photo = initialPhoto {
            selectedPhoto = photo
            contentView.photoImageView.image           = photo
            contentView.photoImageView.isHidden        = false
            contentView.cameraPlaceholderStack.isHidden = true
        }
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
            self.clearDraft()
            dismiss(animated: true) { self.onSave?(nil, nil) }
        })

        // 기록 삭제 — 아무것도 저장하지 않고 파기
        alert.addAction(UIAlertAction(title: "기록 삭제", style: .destructive) { [weak self] _ in
            guard let self else { return }
            self.clearDraft()
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
        clearDraft()
        dismiss(animated: true) { [weak self] in
            self?.onSave?(memo, self?.selectedPhoto)
        }
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func photoSlotTapped() {
        let sheet = ProfileImagePickerBottomSheet(
            hasCurrentImage: selectedPhoto != nil,
            sheetTitle:      "사진 추가",
            resetOptionTitle: "사진 삭제"
        )
        sheet.onAlbum        = { [weak self] in self?.presentImagePicker(source: .photoLibrary) }
        sheet.onCamera       = { [weak self] in self?.presentImagePicker(source: .camera) }
        sheet.onResetDefault = { [weak self] in self?.removeSelectedPhoto() }
        present(sheet, animated: false)
    }

    private func presentImagePicker(source: UIImagePickerController.SourceType) {
        if source == .camera {
            openCameraWithPermission()
        } else {
            openPicker(source: .photoLibrary)
        }
    }

    // MARK: - Camera Permission

    private func openCameraWithPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            openPicker(source: .camera)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted { self?.openPicker(source: .camera) }
                }
            }
        case .denied, .restricted:
            showCameraPermissionAlert()
        @unknown default:
            break
        }
    }

    private func showCameraPermissionAlert() {
        let alert = UIAlertController(
            title: "카메라 권한이 필요해요",
            message: "사냥 놀이의 소중한 순간을 촬영하기 위해 카메라 접근 권한이 필요해요.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "설정으로 이동", style: .default) { [weak self] _ in
            self?.saveDraft()
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url)
        })
        present(alert, animated: true)
    }

    private func openPicker(source: UIImagePickerController.SourceType) {
        guard UIImagePickerController.isSourceTypeAvailable(source) else { return }
        let picker        = UIImagePickerController()
        picker.sourceType = source
        picker.allowsEditing = true
        picker.delegate   = self
        present(picker, animated: true)
    }

    private func removeSelectedPhoto() {
        selectedPhoto = nil
        contentView.photoImageView.image    = nil
        contentView.photoImageView.isHidden = true
        contentView.cameraPlaceholderStack.isHidden = false
    }

    // MARK: - Keyboard Avoidance

    private func registerKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let kbFrame  = userInfo[UIResponder.keyboardFrameEndUserInfoKey]          as? CGRect,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let curveRaw = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey]    as? UInt
        else { return }

        // 최신 레이아웃 반영 후 저장 버튼(카드 하단)이 키보드 바로 위에 오도록 이동량 계산
        view.layoutIfNeeded()
        let keyboardTop = view.bounds.height - kbFrame.height
        let cardBottom  = contentView.card.frame.maxY
        let shift       = max(0, cardBottom - keyboardTop + 8)

        let options = UIView.AnimationOptions(rawValue: curveRaw << 16)
        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.view.frame.origin.y = -shift
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let curveRaw = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey]    as? UInt
        else { return }

        let options = UIView.AnimationOptions(rawValue: curveRaw << 16)
        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.view.frame.origin.y = 0
        }
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
        textView.textColor = AppTheme.Color.textDark
        contentView.isShowingPlaceholder = false
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textView.text      = "즐거웠던 순간을 기록해 주세요..."
            textView.textColor = AppTheme.Color.textMuted
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
