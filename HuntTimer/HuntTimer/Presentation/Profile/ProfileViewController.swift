import UIKit
import AVFoundation
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

    /// 현재 등록된 프로필 이미지 유무 — 액션 시트 메뉴 구성에 사용
    private var hasProfileImage: Bool = false

    // MARK: - loadView
    override func loadView() {
        view = contentView
    }

    // MARK: - Lifecycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        navigationController?.interactivePopGestureRecognizer?.delegate  = self
        loadProfileImage()
        loadCatInfo()
        reloadBadges()
        reloadStats()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
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
        backBtn.tintColor = AppTheme.Color.textDark
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

        contentView.memorialToggle.rx.isOn
            .skip(1)
            .subscribe(onNext: { isOn in
                UserDefaults.standard.set(isOn, forKey: "isMemorialMode")
            })
            .disposed(by: disposeBag)

        contentView.memorialToggle.rx.isOn
            .skip(1)
            .filter { $0 }
            .subscribe(onNext: { [weak self] _ in
                self?.showMemorialAlert()
            })
            .disposed(by: disposeBag)

        // 고양이 설정 행 탭
        let catTap = UITapGestureRecognizer(target: self, action: #selector(catSettingsTapped))
        contentView.catSettingsCard.isUserInteractionEnabled = true
        contentView.catSettingsCard.addGestureRecognizer(catTap)

        // 앱 설정 행 탭
        let appSettingsTap = UITapGestureRecognizer(target: self, action: #selector(appSettingsTapped))
        contentView.appSettingsCard.isUserInteractionEnabled = true
        contentView.appSettingsCard.addGestureRecognizer(appSettingsTap)

        // 리뷰 남기기 행 탭
        let reviewTap = UITapGestureRecognizer(target: self, action: #selector(reviewTapped))
        contentView.reviewCard.isUserInteractionEnabled = true
        contentView.reviewCard.addGestureRecognizer(reviewTap)

        // 아바타 이미지 탭 — 편집 버튼과 동일한 액션
        contentView.avatarImageView.isUserInteractionEnabled = true
        let avatarTap = UITapGestureRecognizer(target: self, action: #selector(photoEditTapped))
        contentView.avatarImageView.addGestureRecognizer(avatarTap)

        // 편집 아이콘 버튼
        contentView.photoEditButton.addTarget(self, action: #selector(photoEditTapped), for: .touchUpInside)
    }

    // MARK: - Profile Image Load

    private func loadProfileImage() {
        let cat = (try? Realm())?.objects(Cat.self).first
        if let data = cat?.profileImageData, let image = UIImage(data: data) {
            applyUserImage(image)
            hasProfileImage = true
        } else {
            applyDefaultImage()
            hasProfileImage = false
        }
    }

    /// 사용자가 선택한 이미지를 아바타에 표시
    private func applyUserImage(_ image: UIImage) {
        contentView.avatarImageView.contentMode  = .scaleAspectFill
        contentView.avatarImageView.backgroundColor = .clear
        contentView.avatarImageView.image        = image
    }

    /// 기본 이미지(SF Symbols person)를 아바타에 표시
    private func applyDefaultImage() {
        let symCfg = UIImage.SymbolConfiguration(pointSize: 44, weight: .light)
        let icon   = UIImage(systemName: "person", withConfiguration: symCfg)
        contentView.avatarImageView.contentMode  = .center
        contentView.avatarImageView.backgroundColor = AppTheme.Color.primaryLight
        contentView.avatarImageView.tintColor    = AppTheme.Color.primary
        contentView.avatarImageView.image        = icon
    }

    // MARK: - Bottom Sheet

    @objc private func photoEditTapped() {
        let sheet = ProfileImagePickerBottomSheet(hasCurrentImage: hasProfileImage)
        sheet.onAlbum        = { [weak self] in self?.presentImagePicker(source: .photoLibrary) }
        sheet.onCamera       = { [weak self] in self?.presentImagePicker(source: .camera) }
        sheet.onResetDefault = { [weak self] in self?.resetToDefaultImage() }
        present(sheet, animated: false)
    }

    // MARK: - Image Picker

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
            message: cameraPermissionMessage(),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "설정으로 이동", style: .default) { _ in
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url)
        })
        present(alert, animated: true)
    }

    private func cameraPermissionMessage() -> String {
        let cats  = (try? Realm()).map { Array($0.objects(Cat.self)) } ?? []
        let names = cats.map { $0.name.isEmpty ? "냥이" : $0.name }

        switch names.count {
        case 0:
            return "사진을 등록하기 위해 카메라 권한이 필요해요."
        case 1:
            return "\(names[0])의 사진을 등록하기 위해 카메라 권한이 필요해요."
        default:
            let front    = Array(names.dropLast())
            let last     = names.last!
            let particle = hasBatchim(front.last ?? "") ? "과" : "와"
            return "\(front.joined(separator: ", "))\(particle) \(last)의 사진을 등록하기 위해 카메라 권한이 필요해요."
        }
    }

    private func hasBatchim(_ text: String) -> Bool {
        guard let code = text.unicodeScalars.last?.value,
              code >= 0xAC00, code <= 0xD7A3 else { return false }
        return (code - 0xAC00) % 28 != 0
    }

    private func openPicker(source: UIImagePickerController.SourceType) {
        guard UIImagePickerController.isSourceTypeAvailable(source) else { return }
        let picker        = UIImagePickerController()
        picker.sourceType = source
        picker.allowsEditing = true
        picker.delegate   = self
        present(picker, animated: true)
    }

    // MARK: - Reset to Default

    private func resetToDefaultImage() {
        guard let realm = try? Realm(),
              let cat   = realm.objects(Cat.self).first else { return }
        do {
            try realm.write { cat.profileImageData = nil }
            hasProfileImage = false
            applyDefaultImage()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {
            print("[Profile] 기본 이미지 초기화 실패:", error)
        }
    }

    // MARK: - Save Image to Realm

    /// 선택 이미지를 리사이징·압축 후 Realm에 저장
    private func saveProfileImage(_ image: UIImage) {
        guard let realm = try? Realm(),
              let cat   = realm.objects(Cat.self).first else { return }
        guard let data = resized(image, maxDimension: 512)?.jpegData(compressionQuality: 0.75) else { return }
        do {
            try realm.write { cat.profileImageData = data }
            hasProfileImage = true
            // 저장한 data로 UIImage 재생성해 표시 (원본 image는 큰 사이즈일 수 있음)
            if let saved = UIImage(data: data) { applyUserImage(saved) }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {
            print("[Profile] 이미지 저장 실패:", error)
        }
    }

    // MARK: - Image Resize Helper

    /// 최대 변 기준으로 리사이징 (이미 작으면 원본 반환)
    private func resized(_ image: UIImage, maxDimension: CGFloat) -> UIImage? {
        let size  = image.size
        let ratio = max(size.width, size.height) / maxDimension
        guard ratio > 1 else { return image }
        let newSize = CGSize(width: size.width / ratio, height: size.height / ratio)
        return UIGraphicsImageRenderer(size: newSize).image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    // MARK: - Cat Info / Badges / Stats

    private func loadCatInfo() {
        guard let cat = (try? Realm())?.objects(Cat.self).first else { return }
        let breedName = CatBreed(rawValue: cat.breed)?.displayName ?? cat.breed
        let gender    = cat.isMale ? "수컷" : "암컷"
        let agePart: String = {
            guard let birthday = cat.birthday else { return "" }
            let years = Calendar.current.dateComponents([.year], from: birthday, to: Date()).year ?? 0
            return years > 0 ? " · \(years)살" : " · 1살 미만"
        }()
        contentView.updateCatInfo(name: cat.name, info: "\(breedName) · \(gender)\(agePart)")
    }

    private func reloadBadges() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let badges = BadgeManager.evaluateBadges()
            DispatchQueue.main.async { self?.contentView.reloadBadges(badges) }
        }
    }

    private func reloadStats() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let realm = try? Realm() else { return }
            let sessions     = realm.objects(PlaySession.self)
            let huntCount    = sessions.count
            let totalSeconds = sessions.sum(ofProperty: "duration") as Int
            let earnedBadges = BadgeManager.evaluateBadges().filter { $0.unlocked }.count

            let noData = "데이터가 없습니다"

            let hours = totalSeconds / 3600
            let mins  = (totalSeconds % 3600) / 60
            let timeText: String
            if totalSeconds == 0 {
                timeText = noData
            } else if hours > 0 {
                timeText = mins > 0 ? "\(hours)시간 \(mins)분" : "\(hours)시간"
            } else {
                timeText = "\(mins)분"
            }

            DispatchQueue.main.async { [weak self] in
                self?.contentView.huntCountLabel.text  = huntCount    == 0 ? noData : "\(huntCount)회"
                self?.contentView.totalTimeLabel.text  = timeText
                self?.contentView.statsBadgeLabel.text = earnedBadges == 0 ? noData : "\(earnedBadges)개"
            }
        }
    }

    // MARK: - Navigation Actions

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func appSettingsTapped() {
        navigationController?.pushViewController(AppSettingsViewController(), animated: true)
    }

    @objc private func reviewTapped() {
        let urlString = "itms-apps://itunes.apple.com/app/id6761323921?action=write-review"
        if let url = URL(string: urlString) { UIApplication.shared.open(url) }
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

// MARK: - UIGestureRecognizerDelegate (스와이프 뒤로가기)
extension ProfileViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        (navigationController?.viewControllers.count ?? 0) > 1
    }
}

// MARK: - UIImagePickerControllerDelegate + UINavigationControllerDelegate
extension ProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage
        guard let image else { return }
        saveProfileImage(image)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
