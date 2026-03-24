import UIKit
import PhotosUI
import RealmSwift

/// 냥이 프로필 등록 화면 ViewController
final class CatProfileRegisterViewController: BaseViewController {

    // MARK: - Properties
    private let contentView      = CatProfileRegisterView()
    private var selectedBirthdate: Date?
    private var isMale           = false
    private var goalMinutes      = 30
    /// Realm 저장 시 selectedBreed.rawValue(String)를 Cat.breed에 기록
    private var selectedBreed: CatBreed?

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

    // MARK: - Navigation
    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func saveTapped() {
        // 이름 유효성 검사
        let name = contentView.nameTextField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        guard !name.isEmpty else {
            showAlert(title: "이름을 입력해주세요", message: "냥이의 이름을 입력해야 합니다.")
            return
        }

        // Cat 객체 생성
        let cat         = Cat()
        cat.name        = name
        cat.isMale      = isMale
        cat.birthday    = contentView.unknownBirthdayToggle.isOn ? nil : selectedBirthdate
        cat.breed       = selectedBreed?.rawValue ?? ""
        cat.targetTime  = goalMinutes

        // 프로필 이미지 압축 저장
        if let image = contentView.photoImageView.image {
            cat.profileImageData = image.jpegData(compressionQuality: 0.8)
        }

        // Realm 저장
        do {
            let realm = try Realm()
            try realm.write { realm.add(cat) }
        } catch {
            showAlert(title: "저장 실패", message: "프로필 저장 중 오류가 발생했습니다.\n\(error.localizedDescription)")
            return
        }

        // 등록 완료 알럿 → 메인 탭으로 전환
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

    // MARK: - Helpers
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Gender
    @objc private func femaleTapped() {
        isMale = false
        contentView.femaleButton.backgroundColor = AppTheme.Color.primary
        contentView.femaleButton.setTitleColor(.white, for: .normal)
        contentView.maleButton.backgroundColor = .clear
        contentView.maleButton.setTitleColor(AppTheme.Color.textMuted, for: .normal)
    }

    @objc private func maleTapped() {
        isMale = true
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
            initialDate: selectedBirthdate ?? Calendar.current.date(byAdding: .year, value: -2, to: Date()) ?? Date()
        )
        sheet.onDateSelected = { [weak self] date in
            guard let self else { return }
            self.selectedBirthdate = date
            self.contentView.birthdateLabel.text      = self.dateFormatter.string(from: date)
            self.contentView.birthdateLabel.textColor = AppTheme.Color.textMuted
        }
        present(sheet, animated: false)
    }

    @objc private func toggleChanged(_ sender: UISwitch) {
        UIView.animate(withDuration: 0.2) {
            if sender.isOn {
                self.contentView.birthdateLabel.text      = "생년월일 미정"
                self.contentView.birthdateLabel.textColor = AppTheme.Color.textMuted
                self.contentView.dateFieldView.alpha                 = 0.5
                self.contentView.dateFieldView.isUserInteractionEnabled = false
            } else {
                let text = self.selectedBirthdate.map { self.dateFormatter.string(from: $0) }
                              ?? "생년월일을 선택하세요"
                self.contentView.birthdateLabel.text      = text
                self.contentView.birthdateLabel.textColor = AppTheme.Color.textMuted
                self.contentView.dateFieldView.alpha                 = 1.0
                self.contentView.dateFieldView.isUserInteractionEnabled = true
            }
        }
    }

    // MARK: - Breed
    @objc private func breedTapped() {
        let sheet = BreedPickerBottomSheetViewController(selectedBreed: selectedBreed)
        sheet.onBreedSelected = { [weak self] breed in
            guard let self else { return }
            self.selectedBreed = breed
            self.contentView.breedDisplayLabel.text      = breed.displayName
            self.contentView.breedDisplayLabel.textColor = AppTheme.Color.textMuted
        }
        present(sheet, animated: false)
    }

    // MARK: - Goal
    @objc private func goalTapped() {
        let sheet = GoalPickerBottomSheetViewController(initialMinutes: goalMinutes)
        sheet.onGoalSelected = { [weak self] minutes in
            guard let self else { return }
            self.goalMinutes = minutes
            self.contentView.goalMinuteLabel.text = "\(minutes)"
        }
        present(sheet, animated: false)
    }
}

// MARK: - UITextFieldDelegate
extension CatProfileRegisterViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - PHPickerViewControllerDelegate
extension CatProfileRegisterViewController: PHPickerViewControllerDelegate {

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
