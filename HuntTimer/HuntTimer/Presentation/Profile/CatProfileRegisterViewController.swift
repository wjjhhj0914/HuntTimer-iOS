import UIKit
import AVFoundation
import RealmSwift

// MARK: - ProfileMode
enum ProfileMode {
    case registration   // 최초 등록
    case edit           // 수정
}

/// 냥이 프로필 등록 / 수정 화면 ViewController
final class CatProfileViewController: BaseViewController {

    // MARK: - Registration Draft (등록 화면에서 뒤로가기 시 작성 내역 보존)
    private struct RegistrationDraft {
        var name:           String    = ""
        var birthdate:      Date?     = nil
        var unknownBirthday: Bool     = false
        var isMale:         Bool      = false
        var goalMinutes:    Int       = 30
        var breed:          CatBreed? = nil
        var photoData:      Data?     = nil

        var isEmpty: Bool {
            name.isEmpty && birthdate == nil && !unknownBirthday
                && goalMinutes == 30 && breed == nil && photoData == nil
        }
    }
    private static var draft = RegistrationDraft()

    // MARK: - Mode
    var mode: ProfileMode = .registration
    var catToEdit: Cat?

    // MARK: - Temp State (Realm에 즉시 반영하지 않고 임시 보관)
    private var tempBirthdate:    Date?      = nil
    private var tempIsMale:       Bool       = false
    private var tempGoalMinutes:  Int        = 30
    private var tempBreed:        CatBreed?  = nil
    /// 실제 선택된 사진 데이터 (nil = 기본 이미지)
    private var tempPhotoData:    Data?      = nil
    private var hasProfileImage:  Bool       = false

    // MARK: - View
    private let contentView = CatProfileRegisterView()

    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale     = Locale(identifier: "ko_KR")
        df.dateFormat = "yyyy년 M월 d일"
        return df
    }()

    // MARK: - loadView
    override func loadView() {
        view = contentView
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()          // setupHierarchy → setupConstraints → setupBind
        configureForMode()
        if mode == .edit {
            loadEditData()
        } else {
            // 초기 비활성화
            contentView.registerButton.isEnabled = false
            contentView.registerButton.alpha     = 0.5
            restoreDraft()
            updateRegisterButton()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        navigationController?.interactivePopGestureRecognizer?.delegate  = self
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
        if mode == .registration { saveDraft() }
    }

    // MARK: - BaseViewController
    override func setupBind() {
        contentView.registerButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)

        // Gender
        contentView.femaleButton.addTarget(self, action: #selector(femaleTapped), for: .touchUpInside)
        contentView.maleButton.addTarget(self, action: #selector(maleTapped), for: .touchUpInside)

        // Photo — 이미지 영역 탭 또는 카메라 버튼 탭 모두 동일 동작
        contentView.photoImageView.isUserInteractionEnabled = true
        let photoTap = UITapGestureRecognizer(target: self, action: #selector(photoEditTapped))
        contentView.photoImageView.addGestureRecognizer(photoTap)
        contentView.photoEditButton.addTarget(self, action: #selector(photoEditTapped), for: .touchUpInside)

        // Date field
        contentView.dateFieldView.onTap(self, action: #selector(dateTapped))

        // Goal field
        contentView.goalFieldView.onTap(self, action: #selector(goalTapped))

        // Breed field
        contentView.breedFieldView.onTap(self, action: #selector(breedTapped))

        // Toggle
        contentView.unknownBirthdayToggle.addTarget(self, action: #selector(toggleChanged(_:)),
                                                    for: .valueChanged)

        // TextField
        contentView.nameTextField.delegate = self
        contentView.nameTextField.addTarget(self, action: #selector(nameChanged), for: .editingChanged)

        // 키보드 외 영역 탭 → 키보드 내림
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        contentView.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        contentView.endEditing(true)
    }

    // MARK: - Mode Configuration
    private func configureForMode() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = AppTheme.Color.background
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [
            .foregroundColor: AppTheme.Color.textDark,
            .font: UIFont.appFont(size: 17, weight: .bold)
        ]
        let buttonAppearance = UIBarButtonItemAppearance(style: .plain)
        buttonAppearance.normal.titleTextAttributes = [.foregroundColor: AppTheme.Color.textDark]
        appearance.buttonAppearance     = buttonAppearance
        appearance.backButtonAppearance = buttonAppearance
        navigationController?.navigationBar.standardAppearance   = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = AppTheme.Color.textDark

        // 커스텀 뒤로가기 버튼 (chevron 색상 명시적 설정)
        let backBtn = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
        backBtn.tintColor = AppTheme.Color.textDark
        navigationItem.leftBarButtonItem = backBtn

        switch mode {
        case .registration:
            navigationItem.title = "냥이 프로필 등록"
            contentView.registerButton.isHidden = false
        case .edit:
            navigationItem.title = "프로필 수정"
            contentView.registerButton.isHidden = true
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: "저장",
                style: .plain,
                target: self,
                action: #selector(saveTapped)
            )
            contentView.hideCTAForEditMode()
        }
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Load Edit Data
    private func loadEditData() {
        guard let cat = catToEdit else { return }

        // temp 변수에 현재 값 세팅
        tempBirthdate   = cat.birthday
        tempGoalMinutes = cat.targetTime
        tempBreed       = CatBreed.from(rawValue: cat.breed)

        // 이름
        contentView.nameTextField.text = cat.name

        // 생년월일
        if let bd = cat.birthday {
            contentView.birthdateLabel.text      = dateFormatter.string(from: bd)
            contentView.birthdateLabel.textColor = AppTheme.Color.textMuted
        } else {
            contentView.unknownBirthdayToggle.isOn          = true
            contentView.birthdateLabel.text                 = "생년월일 미정"
            contentView.birthdateLabel.textColor            = AppTheme.Color.textMuted
            contentView.dateFieldView.alpha                 = 0.5
            contentView.dateFieldView.isUserInteractionEnabled = false
            contentView.unknownBirthdayLabel.textColor      = AppTheme.Color.textDark
            contentView.unknownBirthdayLabel.font           = .appFont(size: 13, weight: .bold)
        }

        // 성별 (tempIsMale도 함께 업데이트됨)
        if cat.isMale { maleTapped() } else { femaleTapped() }

        // 목표 시간
        contentView.goalMinuteLabel.text = "\(cat.targetTime)"

        // 품종
        if let breed = CatBreed.from(rawValue: cat.breed) {
            contentView.breedDisplayLabel.text      = breed.displayName
            contentView.breedDisplayLabel.textColor = AppTheme.Color.textDark
        }

        // 프로필 사진
        if let data = cat.profileImageData {
            tempPhotoData = data
            applyUserPhoto(UIImage(data: data))
        }

        // 생년월일이 이미 설정돼 있으면 textDark 색상으로 표시
        if cat.birthday != nil {
            contentView.birthdateLabel.textColor = AppTheme.Color.textDark
        }
    }

    // MARK: - Save
    @objc private func saveTapped() {
        let name = contentView.nameTextField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        guard !name.isEmpty else {
            showAlert(title: "이름을 입력해 주세요", message: "고양이의 이름을 입력해야 합니다.")
            return
        }

        switch mode {
        case .registration: saveAsNew(name: name)
        case .edit:         updateExisting(name: name)
        }
    }

    private func saveAsNew(name: String) {
        let cat         = Cat()
        cat.name        = name
        cat.isMale      = tempIsMale
        cat.birthday    = contentView.unknownBirthdayToggle.isOn ? nil : tempBirthdate
        cat.breed       = tempBreed?.rawValue ?? ""
        cat.targetTime  = tempGoalMinutes

        cat.profileImageData = tempPhotoData

        do {
            let realm = try Realm()
            try realm.write { realm.add(cat) }
        } catch {
            showAlert(title: "저장 실패", message: "프로필 저장 중 오류가 발생했습니다.\n\(error.localizedDescription)")
            return
        }

        CatProfileViewController.draft = RegistrationDraft()   // 드래프트 초기화
        navigationController?.popViewController(animated: true)
    }

    private func updateExisting(name: String) {
        guard let cat = catToEdit else { return }

        do {
            let realm = try Realm()
            try realm.write {
                cat.name             = name
                cat.isMale           = tempIsMale
                cat.birthday         = contentView.unknownBirthdayToggle.isOn ? nil : tempBirthdate
                cat.breed            = tempBreed?.rawValue ?? cat.breed
                cat.targetTime       = tempGoalMinutes
                cat.profileImageData = tempPhotoData
            }
        } catch {
            showAlert(title: "저장 실패", message: "프로필 저장 중 오류가 발생했습니다.\n\(error.localizedDescription)")
            return
        }

        navigationController?.popViewController(animated: true)
    }

    // MARK: - Draft Save / Restore

    private func saveDraft() {
        CatProfileViewController.draft = RegistrationDraft(
            name:            contentView.nameTextField.text ?? "",
            birthdate:       tempBirthdate,
            unknownBirthday: contentView.unknownBirthdayToggle.isOn,
            isMale:          tempIsMale,
            goalMinutes:     tempGoalMinutes,
            breed:           tempBreed,
            photoData:       tempPhotoData
        )
    }

    private func restoreDraft() {
        let d = CatProfileViewController.draft
        guard !d.isEmpty else { return }

        // 이름
        contentView.nameTextField.text = d.name

        // 생년월일
        tempBirthdate = d.birthdate
        if d.unknownBirthday {
            contentView.unknownBirthdayToggle.isOn = true
            toggleChanged(contentView.unknownBirthdayToggle)
        } else if let date = d.birthdate {
            contentView.birthdateLabel.text      = dateFormatter.string(from: date)
            contentView.birthdateLabel.textColor = AppTheme.Color.textDark
        }

        // 성별
        tempIsMale = d.isMale
        if d.isMale { maleTapped() } else { femaleTapped() }

        // 목표 시간
        tempGoalMinutes = d.goalMinutes
        contentView.goalMinuteLabel.text = "\(d.goalMinutes)"

        // 품종
        tempBreed = d.breed
        if let breed = d.breed {
            contentView.breedDisplayLabel.text      = breed.displayName
            contentView.breedDisplayLabel.textColor = AppTheme.Color.textDark
        }

        // 사진
        if let data = d.photoData {
            tempPhotoData = data
            applyUserPhoto(UIImage(data: data))
        }
    }

    // MARK: - Helpers
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    @objc private func nameChanged() {
        updateRegisterButton()
    }

    private func updateRegisterButton() {
        guard mode == .registration else { return }
        let hasName      = !(contentView.nameTextField.text?.trimmingCharacters(in: .whitespaces).isEmpty ?? true)
        let hasBirthdate = tempBirthdate != nil || contentView.unknownBirthdayToggle.isOn
        let hasBreed     = tempBreed != nil
        let isValid      = hasName && hasBirthdate && hasBreed
        contentView.registerButton.isEnabled = isValid
        UIView.animate(withDuration: 0.2) {
            self.contentView.registerButton.alpha = isValid ? 1.0 : 0.5
        }
    }

    // MARK: - Gender
    @objc private func femaleTapped() {
        tempIsMale = false
        contentView.femaleButton.backgroundColor = AppTheme.Color.primary
        contentView.femaleButton.setTitleColor(AppTheme.Color.textDark, for: .normal)
        contentView.maleButton.backgroundColor = .clear
        contentView.maleButton.setTitleColor(AppTheme.Color.textMuted, for: .normal)
    }

    @objc private func maleTapped() {
        tempIsMale = true
        contentView.maleButton.backgroundColor = AppTheme.Color.primary
        contentView.maleButton.setTitleColor(AppTheme.Color.textDark, for: .normal)
        contentView.femaleButton.backgroundColor = .clear
        contentView.femaleButton.setTitleColor(AppTheme.Color.textMuted, for: .normal)
    }

    // MARK: - Photo
    @objc private func photoEditTapped() {
        let sheet = ProfileImagePickerBottomSheet(hasCurrentImage: hasProfileImage)
        sheet.onAlbum        = { [weak self] in self?.presentImagePicker(source: .photoLibrary) }
        sheet.onCamera       = { [weak self] in self?.presentImagePicker(source: .camera) }
        sheet.onResetDefault = { [weak self] in self?.resetToDefaultPhoto() }
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

    /// 카메라 권한 상태를 확인하고, 허용 시 카메라를 열고 거부 시 설정 유도 알림을 표시한다.
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

    /// 카메라 권한 거부 시 표시하는 설정 유도 알림
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

    /// 등록된 고양이 이름을 기반으로 권한 안내 문구를 동적으로 생성한다.
    private func cameraPermissionMessage() -> String {
        let cats  = (try? Realm()).map { Array($0.objects(Cat.self)) } ?? []
        let names = cats.map { $0.name.isEmpty ? "냥이" : $0.name }

        switch names.count {
        case 0:
            return "사진을 등록하기 위해 카메라 권한이 필요해요."
        case 1:
            return "\(names[0])의 사진을 등록하기 위해 카메라 권한이 필요해요."
        default:
            let front     = Array(names.dropLast())
            let last      = names.last!
            let particle  = hasBatchim(front.last ?? "") ? "과" : "와"
            return "\(front.joined(separator: ", "))\(particle) \(last)의 사진을 등록하기 위해 카메라 권한이 필요해요."
        }
    }

    /// 마지막 글자의 받침 유무로 조사(와/과)를 결정한다.
    private func hasBatchim(_ text: String) -> Bool {
        guard let code = text.unicodeScalars.last?.value,
              code >= 0xAC00, code <= 0xD7A3 else { return false }
        return (code - 0xAC00) % 28 != 0
    }

    private func openPicker(source: UIImagePickerController.SourceType) {
        guard UIImagePickerController.isSourceTypeAvailable(source) else { return }
        let picker           = UIImagePickerController()
        picker.sourceType    = source
        picker.allowsEditing = true
        picker.delegate      = self
        present(picker, animated: true)
    }

    private func applyUserPhoto(_ image: UIImage?) {
        guard let image else { applyDefaultPhoto(); return }
        hasProfileImage = true
        contentView.photoImageView.image       = image
        contentView.photoImageView.contentMode = .scaleAspectFill
        contentView.photoImageView.backgroundColor = .clear
        contentView.photoImageView.tintColor   = .clear
    }

    private func applyDefaultPhoto() {
        hasProfileImage = false
        tempPhotoData   = nil
        let symCfg = UIImage.SymbolConfiguration(pointSize: 44, weight: .light)
        contentView.photoImageView.image           = UIImage(systemName: "person", withConfiguration: symCfg)
        contentView.photoImageView.contentMode     = .center
        contentView.photoImageView.backgroundColor = AppTheme.Color.primaryLight
        contentView.photoImageView.tintColor       = AppTheme.Color.primary
    }

    private func resetToDefaultPhoto() {
        applyDefaultPhoto()
    }

    private func resized(_ image: UIImage, maxDimension: CGFloat) -> UIImage? {
        let size  = image.size
        let ratio = max(size.width, size.height) / maxDimension
        guard ratio > 1 else { return image }
        let newSize = CGSize(width: size.width / ratio, height: size.height / ratio)
        return UIGraphicsImageRenderer(size: newSize).image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    // MARK: - Birthdate
    @objc private func dateTapped() {
        guard !contentView.unknownBirthdayToggle.isOn else { return }

        let sheet = DatePickerBottomSheetViewController(
            initialDate: tempBirthdate ?? Date()
        )
        sheet.onDateSelected = { [weak self] date in
            guard let self else { return }
            self.tempBirthdate = date
            self.contentView.birthdateLabel.text      = self.dateFormatter.string(from: date)
            self.contentView.birthdateLabel.textColor = AppTheme.Color.textDark
            self.updateRegisterButton()
        }
        present(sheet, animated: false)
    }

    @objc private func toggleChanged(_ sender: UISwitch) {
        updateRegisterButton()
        UIView.animate(withDuration: 0.2) {
            if sender.isOn {
                self.contentView.birthdateLabel.text                 = "생년월일 미정"
                self.contentView.birthdateLabel.textColor            = AppTheme.Color.textMuted
                self.contentView.dateFieldView.alpha                 = 0.5
                self.contentView.dateFieldView.isUserInteractionEnabled = false
                self.contentView.unknownBirthdayLabel.textColor      = AppTheme.Color.textDark
                self.contentView.unknownBirthdayLabel.font           = .appFont(size: 13, weight: .bold)
            } else {
                let text = self.tempBirthdate.map { self.dateFormatter.string(from: $0) }
                              ?? "생년월일을 선택하세요"
                self.contentView.birthdateLabel.text      = text
                self.contentView.birthdateLabel.textColor = self.tempBirthdate != nil
                    ? AppTheme.Color.textDark
                    : AppTheme.Color.textMuted
                self.contentView.dateFieldView.alpha                 = 1.0
                self.contentView.dateFieldView.isUserInteractionEnabled = true
                self.contentView.unknownBirthdayLabel.textColor      = AppTheme.Color.textMuted
                self.contentView.unknownBirthdayLabel.font           = .appFont(size: 13)
            }
        }
    }

    // MARK: - Breed
    @objc private func breedTapped() {
        let sheet = BreedPickerBottomSheetViewController(selectedBreed: tempBreed)
        sheet.onBreedSelected = { [weak self] breed in
            guard let self else { return }
            self.tempBreed = breed
            self.contentView.breedDisplayLabel.text      = breed.displayName
            self.contentView.breedDisplayLabel.textColor = AppTheme.Color.textDark
            self.updateRegisterButton()
        }
        present(sheet, animated: false)
    }

    // MARK: - Goal
    @objc private func goalTapped() {
        let sheet = GoalPickerBottomSheetViewController(initialMinutes: tempGoalMinutes)
        sheet.onGoalSelected = { [weak self] minutes in
            guard let self else { return }
            self.tempGoalMinutes = minutes
            self.contentView.goalMinuteLabel.text = "\(minutes)"
        }
        present(sheet, animated: false)
    }
}

// MARK: - UITextFieldDelegate
extension CatProfileViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - UIImagePickerControllerDelegate + UINavigationControllerDelegate
extension CatProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage
        guard let image else { return }
        let compressed = resized(image, maxDimension: 512)?.jpegData(compressionQuality: 0.75)
        tempPhotoData = compressed
        applyUserPhoto(compressed.flatMap { UIImage(data: $0) } ?? image)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - UIGestureRecognizerDelegate (스와이프 뒤로가기)
extension CatProfileViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        (navigationController?.viewControllers.count ?? 0) > 1
    }
}
