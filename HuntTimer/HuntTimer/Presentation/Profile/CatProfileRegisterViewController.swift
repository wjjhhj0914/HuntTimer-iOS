import UIKit
import PhotosUI
import RealmSwift

// MARK: - ProfileMode
enum ProfileMode {
    case registration   // 최초 등록
    case edit           // 수정
}

/// 냥이 프로필 등록 / 수정 화면 ViewController
final class CatProfileViewController: BaseViewController {

    // MARK: - Mode
    var mode: ProfileMode = .registration
    var catToEdit: Cat?

    // MARK: - Temp State (Realm에 즉시 반영하지 않고 임시 보관)
    private var tempBirthdate:    Date?      = nil
    private var tempIsMale:       Bool       = false
    private var tempGoalMinutes:  Int        = 30
    private var tempBreed:        CatBreed?  = nil

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
        if mode == .edit { loadEditData() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    // MARK: - BaseViewController
    override func setupBind() {
        // Header
        contentView.backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        contentView.saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        contentView.registerButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)

        // Gender
        contentView.femaleButton.addTarget(self, action: #selector(femaleTapped), for: .touchUpInside)
        contentView.maleButton.addTarget(self, action: #selector(maleTapped), for: .touchUpInside)

        // Photo
        contentView.photoContainerView.onTap(self, action: #selector(photoTapped))

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
        switch mode {
        case .registration:
            contentView.headerTitleLabel.text   = "냥이 프로필 등록"
            contentView.registerButton.isHidden = false
            contentView.saveButton.isHidden     = true
        case .edit:
            contentView.headerTitleLabel.text   = "프로필 수정"
            contentView.registerButton.isHidden = true
            contentView.saveButton.isHidden     = false
        }
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
        }

        // 성별 (tempIsMale도 함께 업데이트됨)
        if cat.isMale { maleTapped() } else { femaleTapped() }

        // 목표 시간
        contentView.goalMinuteLabel.text = "\(cat.targetTime)"

        // 품종
        if let breed = CatBreed.from(rawValue: cat.breed) {
            contentView.breedDisplayLabel.text      = breed.displayName
            contentView.breedDisplayLabel.textColor = AppTheme.Color.textMuted
        }

        // 프로필 사진
        if let data = cat.profileImageData, let image = UIImage(data: data) {
            contentView.photoImageView.image    = image
            contentView.photoImageView.isHidden = false
        }
    }

    // MARK: - Navigation
    @objc private func backTapped() {
        // temp 변수는 VC 소멸과 함께 자동 파기 — Realm 원본 데이터 보존
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Save
    @objc private func saveTapped() {
        let name = contentView.nameTextField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        guard !name.isEmpty else {
            showAlert(title: "이름을 입력해주세요", message: "냥이의 이름을 입력해야 합니다.")
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

        if let image = contentView.photoImageView.image {
            cat.profileImageData = image.jpegData(compressionQuality: 0.8)
        }

        do {
            let realm = try Realm()
            try realm.write { realm.add(cat) }
        } catch {
            showAlert(title: "저장 실패", message: "프로필 저장 중 오류가 발생했습니다.\n\(error.localizedDescription)")
            return
        }

        let alert = UIAlertController(title: "등록 완료!", message: "\(name) 냥이의 프로필이 등록됐어요 🐾", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "시작하기", style: .default) { [weak self] _ in
            guard let windowScene = self?.view.window?.windowScene,
                  let window      = windowScene.windows.first else { return }
            UIView.transition(with: window,
                              duration: 0.4,
                              options: .transitionCrossDissolve) {
                window.rootViewController = MainTabBarController()
            }
        })
        present(alert, animated: true)
    }

    private func updateExisting(name: String) {
        guard let cat = catToEdit else { return }

        do {
            let realm = try Realm()
            try realm.write {
                cat.name       = name
                cat.isMale     = tempIsMale
                cat.birthday   = contentView.unknownBirthdayToggle.isOn ? nil : tempBirthdate
                cat.breed      = tempBreed?.rawValue ?? cat.breed
                cat.targetTime = tempGoalMinutes
                if let image = contentView.photoImageView.image {
                    cat.profileImageData = image.jpegData(compressionQuality: 0.8)
                }
            }
        } catch {
            showAlert(title: "저장 실패", message: "프로필 저장 중 오류가 발생했습니다.\n\(error.localizedDescription)")
            return
        }

        navigationController?.popViewController(animated: true)
    }

    // MARK: - Helpers
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Gender
    @objc private func femaleTapped() {
        tempIsMale = false
        contentView.femaleButton.backgroundColor = AppTheme.Color.primary
        contentView.femaleButton.setTitleColor(.white, for: .normal)
        contentView.maleButton.backgroundColor = .clear
        contentView.maleButton.setTitleColor(AppTheme.Color.textMuted, for: .normal)
    }

    @objc private func maleTapped() {
        tempIsMale = true
        contentView.maleButton.backgroundColor = AppTheme.Color.primary
        contentView.maleButton.setTitleColor(.white, for: .normal)
        contentView.femaleButton.backgroundColor = .clear
        contentView.femaleButton.setTitleColor(AppTheme.Color.textMuted, for: .normal)
    }

    // MARK: - Photo
    @objc private func photoTapped() {
        var config = PHPickerConfiguration()
        config.filter         = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    // MARK: - Birthdate
    @objc private func dateTapped() {
        guard !contentView.unknownBirthdayToggle.isOn else { return }

        let sheet = DatePickerBottomSheetViewController(
            initialDate: tempBirthdate ?? Calendar.current.date(byAdding: .year, value: -2, to: Date()) ?? Date()
        )
        sheet.onDateSelected = { [weak self] date in
            guard let self else { return }
            self.tempBirthdate = date
            self.contentView.birthdateLabel.text      = self.dateFormatter.string(from: date)
            self.contentView.birthdateLabel.textColor = AppTheme.Color.textMuted
        }
        present(sheet, animated: false)
    }

    @objc private func toggleChanged(_ sender: UISwitch) {
        UIView.animate(withDuration: 0.2) {
            if sender.isOn {
                self.contentView.birthdateLabel.text                 = "생년월일 미정"
                self.contentView.birthdateLabel.textColor            = AppTheme.Color.textMuted
                self.contentView.dateFieldView.alpha                 = 0.5
                self.contentView.dateFieldView.isUserInteractionEnabled = false
            } else {
                let text = self.tempBirthdate.map { self.dateFormatter.string(from: $0) }
                              ?? "생년월일을 선택하세요"
                self.contentView.birthdateLabel.text                 = text
                self.contentView.birthdateLabel.textColor            = AppTheme.Color.textMuted
                self.contentView.dateFieldView.alpha                 = 1.0
                self.contentView.dateFieldView.isUserInteractionEnabled = true
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
            self.contentView.breedDisplayLabel.textColor = AppTheme.Color.textMuted
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

// MARK: - PHPickerViewControllerDelegate
extension CatProfileViewController: PHPickerViewControllerDelegate {

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let result = results.first else { return }

        result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let self, let image = object as? UIImage else { return }
            DispatchQueue.main.async {
                self.contentView.photoImageView.image    = image
                self.contentView.photoImageView.isHidden = false
            }
        }
    }
}
