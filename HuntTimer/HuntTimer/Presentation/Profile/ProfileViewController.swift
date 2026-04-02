import UIKit
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

    // MARK: - loadView
    override func loadView() {
        view = contentView
    }

    // MARK: - Lifecycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        // 네비게이션 바가 숨겨진 상태에서 push 된 경우 delegate가 초기화되어
        // 좌→우 스와이프 뒤로가기가 동작하지 않으므로 직접 delegate를 지정
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        navigationController?.interactivePopGestureRecognizer?.delegate  = self
        loadProfileImage()
        loadCatInfo()
        reloadBadges()
        reloadStats()
    }

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

    private func loadProfileImage() {
        guard let cat = (try? Realm())?.objects(Cat.self).first,
              let data = cat.profileImageData,
              let image = UIImage(data: data) else { return }
        contentView.avatarImageView.image = image
    }

    private func reloadBadges() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let badges = BadgeManager.evaluateBadges()
            DispatchQueue.main.async {
                self?.contentView.reloadBadges(badges)
            }
        }
    }

    private func reloadStats() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let realm = try? Realm() else { return }
            let sessions     = realm.objects(PlaySession.self)
            let huntCount    = sessions.count
            let totalSeconds = sessions.sum(ofProperty: "duration") as Int
            let earnedBadges = BadgeManager.evaluateBadges().filter { $0.unlocked }.count

            let hours = totalSeconds / 3600
            let mins  = (totalSeconds % 3600) / 60
            let timeText: String
            if hours > 0 {
                timeText = mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
            } else {
                timeText = "\(mins)m"
            }

            DispatchQueue.main.async { [weak self] in
                self?.contentView.huntCountLabel.text  = "\(huntCount)회"
                self?.contentView.totalTimeLabel.text  = timeText
                self?.contentView.statsBadgeLabel.text = "\(earnedBadges)개"
            }
        }
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
        backBtn.tintColor = AppTheme.Color.primary
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

        // 추모 모드 변경 시 UserDefaults 저장
        contentView.memorialToggle.rx.isOn
            .skip(1)
            .subscribe(onNext: { isOn in
                UserDefaults.standard.set(isOn, forKey: "isMemorialMode")
            })
            .disposed(by: disposeBag)

        // 추모 모드 ON 시 얼럿
        contentView.memorialToggle.rx.isOn
            .skip(1)
            .filter { $0 }
            .subscribe(onNext: { [weak self] _ in
                self?.showMemorialAlert()
            })
            .disposed(by: disposeBag)

        // 고양이 설정 행 탭 → 프로필 수정 화면
        let tap = UITapGestureRecognizer(target: self, action: #selector(catSettingsTapped))
        contentView.catSettingsCard.isUserInteractionEnabled = true
        contentView.catSettingsCard.addGestureRecognizer(tap)

        // 앱 설정 행 탭 → 앱 설정 화면
        let appSettingsTap = UITapGestureRecognizer(target: self, action: #selector(appSettingsTapped))
        contentView.appSettingsCard.isUserInteractionEnabled = true
        contentView.appSettingsCard.addGestureRecognizer(appSettingsTap)

        // 리뷰 남기기 행 탭 → 인앱 리뷰 요청
        let reviewTap = UITapGestureRecognizer(target: self, action: #selector(reviewTapped))
        contentView.reviewCard.isUserInteractionEnabled = true
        contentView.reviewCard.addGestureRecognizer(reviewTap)

        // 프로필 사진 편집 버튼
        contentView.photoEditButton.addTarget(self, action: #selector(photoTapped), for: .touchUpInside)
    }

    // MARK: - Actions
    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func photoTapped() {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else { return }
        let picker = UIImagePickerController()
        picker.sourceType    = .photoLibrary
        picker.allowsEditing = true
        picker.delegate      = self
        present(picker, animated: true)
    }

    @objc private func appSettingsTapped() {
        navigationController?.pushViewController(AppSettingsViewController(), animated: true)
    }

    @objc private func reviewTapped() {
        let urlString = "itms-apps://itunes.apple.com/app/id6761323921?action=write-review"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }

    @objc private func catSettingsTapped() {
        let vc = CatProfileViewController()
        vc.mode     = .edit
        vc.catToEdit = (try? Realm())?.objects(Cat.self).first
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Realm Save
    private func saveProfileImage(_ image: UIImage) {
        guard let realm = try? Realm(),
              let cat   = realm.objects(Cat.self).first else { return }
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        do {
            try realm.write { cat.profileImageData = data }
            contentView.avatarImageView.image = image
        } catch {
            print("[Profile] 이미지 저장 실패:", error)
        }
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
