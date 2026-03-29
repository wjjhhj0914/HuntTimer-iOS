import UIKit
import RxSwift
import RxCocoa
import RealmSwift

/// 홈 화면 ViewController — RxSwift 바인딩만 담당
final class HomeViewController: BaseViewController {

    private let contentView          = HomeView()
    private let viewModel            = HomeViewModel()
    private let disposeBag           = DisposeBag()
    private let viewWillAppearSubject = PublishSubject<Void>()

    // MARK: - loadView
    override func loadView() {
        view = contentView
    }

    // MARK: - Lifecycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewWillAppearSubject.onNext(())
    }

    // MARK: - BaseViewController
    override func setupBind() {
        let input = HomeViewModel.Input(
            viewDidLoad:        Observable.just(()),
            viewWillAppear:     viewWillAppearSubject.asObservable(),
            startHuntingTapped: contentView.startButton.rx.tap.asObservable(),
            seeAllTapped:       contentView.seeAllButton.rx.tap.asObservable()
        )
        let output = viewModel.transform(input: input)

        // Header
        output.greeting.drive(contentView.greetLabel.rx.text).disposed(by: disposeBag)
        output.catTitle.drive(contentView.titleLabel.rx.text).disposed(by: disposeBag)

        // Banner — 전체 배경 이미지: 경로 있으면 로컬 파일 로딩, 없으면 primaryLight 플레이스홀더
        output.bannerImagePath
            .drive(onNext: { [weak self] path in
                guard let self else { return }
                let iv = self.contentView.bannerImageView
                if let path, let image = UIImage(contentsOfFile: path) {
                    UIView.transition(with: iv, duration: 0.25, options: .transitionCrossDissolve) {
                        iv.image           = image
                        iv.contentMode     = .scaleAspectFill
                        iv.backgroundColor = .clear
                    }
                } else {
                    iv.image           = nil
                    iv.contentMode     = .scaleAspectFill
                    iv.backgroundColor = AppTheme.Color.primaryLight
                }
            })
            .disposed(by: disposeBag)

        // 편집 버튼 → 사진 피커
        contentView.editBannerButton.rx.tap
            .subscribe(onNext: { [weak self] in self?.presentBannerImagePicker() })
            .disposed(by: disposeBag)
        output.streakText.drive(contentView.streakLabel.rx.text).disposed(by: disposeBag)
        output.heroCatName.drive(contentView.heroCatLabel.rx.text).disposed(by: disposeBag)
        output.heroStatus.drive(contentView.heroStatusLabel.rx.text).disposed(by: disposeBag)

        // Progress gauge
        Driver.combineLatest(output.todaySeconds, output.goalMinutes, output.progressRatio)
            .drive(onNext: { [weak self] todaySecs, goalMins, ratio in
                guard let self else { return }
                let elapsedText  = Self.formatElapsed(seconds: todaySecs)
                let remainSecs   = max(0, goalMins * 60 - todaySecs)
                let pct          = Int(ratio * 100)
                self.contentView.centerLabel.text           = elapsedText
                self.contentView.unitLabel.text             = "/ \(goalMins)분"
                self.contentView.progressPercentLabel.text  = "\(pct)%"
                self.contentView.progressValueLabel.text    = "\(elapsedText) | \(goalMins)분"
                self.contentView.goalBadgeLabel.text        = "목표 \(pct)%"
                self.contentView.timeBadgeLabel.text        = Self.formatRemaining(seconds: remainSecs)
                // 화면 등장 시 0 → 현재값으로 부드럽게 차오르는 애니메이션
                self.contentView.gaugeView.animateProgress(ratio)
            })
            .disposed(by: disposeBag)

        output.completedCount
            .drive(onNext: { [weak self] count in
                self?.contentView.sessionCountLabel.text = "오늘 \(count)회 사냥 완료"
            })
            .disposed(by: disposeBag)

        // Quick stats
        output.weeklyHours.drive(contentView.weeklyValueLabel.rx.text).disposed(by: disposeBag)
        output.bestRecord.drive(contentView.bestValueLabel.rx.text).disposed(by: disposeBag)
        output.monthlyDays.drive(contentView.monthlyValueLabel.rx.text).disposed(by: disposeBag)

        // Recent sessions
        output.recentSessions
            .drive(onNext: { [weak self] sessions in self?.populateRecentSessions(sessions) })
            .disposed(by: disposeBag)

        // 시작 버튼 타이틀
        output.startButtonTitle
            .drive(onNext: { [weak self] title in
                self?.contentView.startButton.setTitle(title, for: .normal)
            })
            .disposed(by: disposeBag)

        // hasCat: 섹션 show/hide
        output.hasCat
            .drive(onNext: { [weak self] hasCat in
                guard let self else { return }
                self.contentView.bannerSectionView?.isHidden   = !hasCat
                self.contentView.progressSectionView?.isHidden  = !hasCat
                self.contentView.quickStatsSectionView?.isHidden = !hasCat
                self.contentView.recentSectionView?.isHidden   = !hasCat
            })
            .disposed(by: disposeBag)

        // startButton: 고양이 등록 시 → 타이머 탭으로 전환
        contentView.startButton.rx.tap
            .withLatestFrom(output.hasCat)
            .filter { $0 }
            .subscribe(onNext: { [weak self] _ in
                self?.tabBarController?.selectedIndex = 1
            })
            .disposed(by: disposeBag)

        // 전체 보기 → 캘린더(Log) 탭으로 전환
        contentView.seeAllButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.tabBarController?.selectedIndex = 2
            })
            .disposed(by: disposeBag)

        // startButton: 고양이 미등록 시 → 프로필 등록 화면으로
        contentView.startButton.rx.tap
            .withLatestFrom(output.hasCat)
            .filter { !$0 }
            .subscribe(onNext: { [weak self] _ in
                guard let self else { return }
                let vc = CatProfileViewController()
                vc.mode = .registration
                self.navigationController?.pushViewController(vc, animated: true)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Helpers
    private static func formatElapsed(seconds: Int) -> String {
        if seconds < 60 { return "\(seconds)초" }
        let m = seconds / 60, s = seconds % 60
        return s > 0 ? "\(m)분 \(s)초" : "\(m)분"
    }

    private static func formatRemaining(seconds: Int) -> String {
        if seconds == 0 { return "목표 달성!" }
        if seconds < 60 { return "\(seconds)초 남음" }
        let m = seconds / 60, s = seconds % 60
        return s > 0 ? "\(m)분 \(s)초 남음" : "\(m)분 남음"
    }

    private func populateRecentSessions(_ sessions: [HuntSession]) {
        contentView.recentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        sessions.forEach { contentView.recentStack.addArrangedSubview(contentView.makeSessionRow($0)) }
    }

    private func presentBannerImagePicker() {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else { return }
        let picker              = UIImagePickerController()
        picker.sourceType       = .photoLibrary
        picker.allowsEditing    = true   // 크롭 영역 지정 활성화
        picker.delegate         = self
        present(picker, animated: true)
    }
}

// MARK: - UIImagePickerControllerDelegate

extension HomeViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        // allowsEditing = true 이므로 editedImage 우선, 없으면 originalImage 사용
        guard let image = info[.editedImage] as? UIImage
                       ?? info[.originalImage] as? UIImage else { return }

        let iv = contentView.bannerImageView
        UIView.transition(with: iv, duration: 0.25, options: .transitionCrossDissolve) {
            iv.image           = image
            iv.contentMode     = .scaleAspectFill
            iv.backgroundColor = .clear
        }
        saveBannerImage(image)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    private func saveBannerImage(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        let fileName = "cat_banner.jpg"
        let dir      = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url      = dir.appendingPathComponent(fileName)
        do {
            try data.write(to: url)
        } catch {
            print("[HuntTimer] 배너 이미지 저장 실패:", error)
            return
        }
        guard let realm = try? Realm(),
              let cat   = realm.objects(Cat.self).first else { return }
        do {
            try realm.write { cat.bannerImagePath = url.path }
            print("[HuntTimer] 배너 이미지 경로 저장 완료:", url.path)
        } catch {
            print("[HuntTimer] 배너 이미지 경로 Realm 저장 실패:", error)
        }
    }
}
