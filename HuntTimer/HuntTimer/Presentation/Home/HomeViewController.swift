import UIKit
import SnapKit
import RxSwift
import RxCocoa
import RealmSwift
import CropViewController   // TOCropViewController Swift 래퍼

/// 홈 화면 ViewController — RxSwift 바인딩만 담당
final class HomeViewController: BaseViewController {

    private let contentView           = HomeView()
    private let viewModel             = HomeViewModel()
    private let disposeBag            = DisposeBag()
    private let viewWillAppearSubject = PublishSubject<Void>()

    // MARK: - Cat Section State
    private var isEditingCats   = false
    private var selectedCatIds: Set<ObjectId> = []
    private var catItemViews:   [CatAvatarItemView] = []

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

        // Banner — 경로 있으면 로컬 파일 로딩, 없으면 primaryLight 플레이스홀더 + 안내 문구 표시
        output.bannerImagePath
            .drive(onNext: { [weak self] path in
                guard let self else { return }
                let iv          = self.contentView.bannerImageView
                let placeholder = self.contentView.bannerPlaceholderLabel
                if let path, let image = UIImage(contentsOfFile: path) {
                    UIView.transition(with: iv, duration: 0.25, options: .transitionCrossDissolve) {
                        iv.image           = image
                        iv.contentMode     = .scaleAspectFill
                        iv.backgroundColor = .clear
                    }
                    placeholder.isHidden = true
                } else {
                    iv.image             = nil
                    iv.contentMode       = .scaleAspectFill
                    iv.backgroundColor   = AppTheme.Color.primaryLight
                    placeholder.isHidden = false
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

        // Cat section
        output.cats
            .drive(onNext: { [weak self] cats in self?.reloadCatSection(cats) })
            .disposed(by: disposeBag)

        contentView.addCatButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                let vc = CatProfileViewController()
                vc.mode = .registration
                self.navigationController?.pushViewController(vc, animated: true)
            })
            .disposed(by: disposeBag)

        contentView.catEditDoneButton.rx.tap
            .subscribe(onNext: { [weak self] in self?.exitEditMode() })
            .disposed(by: disposeBag)

        // 고양이 섹션 빈 공간 탭 → 편집 모드 해제
        let sectionTap = UITapGestureRecognizer(target: self, action: #selector(catSectionBackgroundTapped))
        sectionTap.cancelsTouchesInView = false
        contentView.catSectionView?.addGestureRecognizer(sectionTap)

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

        // hasCat: 섹션 show/hide (recentSectionView는 populateRecentSessions에서 관리)
        output.hasCat
            .drive(onNext: { [weak self] hasCat in
                guard let self else { return }
                self.contentView.bannerSectionView?.isHidden     = !hasCat
                self.contentView.progressSectionView?.isHidden   = !hasCat
                self.contentView.quickStatsSectionView?.isHidden = !hasCat
            })
            .disposed(by: disposeBag)

        // startButton: 고양이 등록 시 → 타이머 탭
        contentView.startButton.rx.tap
            .withLatestFrom(output.hasCat)
            .filter { $0 }
            .subscribe(onNext: { [weak self] _ in
                self?.tabBarController?.selectedIndex = 1
            })
            .disposed(by: disposeBag)

        // 전체 보기 → 캘린더(Log) 탭
        contentView.seeAllButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.tabBarController?.selectedIndex = 2
            })
            .disposed(by: disposeBag)

        // startButton: 고양이 미등록 시 → 프로필 등록
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

    // MARK: - Cat Section

    private func reloadCatSection(_ cats: [Cat]) {
        catItemViews.removeAll()
        let stack = contentView.catAvatarsStack
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        cats.forEach { cat in
            let item = CatAvatarItemView(cat: cat)
            item.onTap       = { [weak self] in self?.handleCatTap(cat: cat) }
            item.onLongPress = { [weak self] in self?.enterEditMode() }
            // 선택 상태 복원
            item.setSelected(selectedCatIds.contains(cat.id), animated: false)
            // 편집 중이었다면 편집 상태 유지
            if isEditingCats { item.setEditing(true) }
            catItemViews.append(item)
            stack.addArrangedSubview(item)
        }

        // 추가 버튼
        let addLabel = UILabel.make(text: "추가", size: 12, weight: .semibold,
                                    color: UIColor(hex: "#C4956A"))
        addLabel.textAlignment = .center
        let addItem = UIStackView.make(axis: .vertical, spacing: 6, alignment: .center)
        addItem.addArrangedSubview(contentView.addCatButton)
        addItem.addArrangedSubview(addLabel)
        stack.addArrangedSubview(addItem)

        updateCatCountBadge(totalCount: cats.count)
    }

    // MARK: - Edit Mode

    private func enterEditMode() {
        guard !isEditingCats else { return }
        isEditingCats = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        catItemViews.forEach { $0.setEditing(true) }

        UIView.animate(withDuration: 0.2) {
            self.contentView.catBadgeContainer?.isHidden  = true
            self.contentView.catEditDoneButton.isHidden   = false
        }
    }

    private func exitEditMode() {
        guard isEditingCats else { return }
        isEditingCats = false

        catItemViews.forEach { item in
            item.setEditing(false)
            item.setSelected(selectedCatIds.contains(item.cat.id), animated: false)
        }

        UIView.animate(withDuration: 0.2) {
            self.contentView.catBadgeContainer?.isHidden  = false
            self.contentView.catEditDoneButton.isHidden   = true
        }
        updateCatCountBadge(totalCount: catItemViews.count)
    }

    @objc private func catSectionBackgroundTapped() {
        guard isEditingCats else { return }
        exitEditMode()
    }

    // MARK: - Cat Tap Handling

    private func handleCatTap(cat: Cat) {
        if isEditingCats {
            showDeleteConfirmation(for: cat)
        } else {
            toggleCatSelection(cat)
        }
    }

    private func toggleCatSelection(_ cat: Cat) {
        if selectedCatIds.contains(cat.id) {
            selectedCatIds.remove(cat.id)
        } else {
            selectedCatIds.insert(cat.id)
        }
        catItemViews.first { $0.cat.id == cat.id }?
            .setSelected(selectedCatIds.contains(cat.id))
        updateCatCountBadge(totalCount: catItemViews.count)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    // MARK: - Delete

    private func showDeleteConfirmation(for cat: Cat) {
        let suffix = cat.name.last.map { _ in "" } ?? ""
        let alert = UIAlertController(
            title: "\(cat.name)을(를) 삭제할까요?",
            message: "삭제된 고양이는 복구할 수 없어요.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            self?.deleteCat(cat)
        })
        present(alert, animated: true)
    }

    private func deleteCat(_ cat: Cat) {
        guard let realm = try? Realm(),
              let managed = realm.object(ofType: Cat.self, forPrimaryKey: cat.id) else { return }
        do {
            try realm.write { realm.delete(managed) }
            selectedCatIds.remove(cat.id)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {
            print("[HuntTimer] 고양이 삭제 실패:", error)
            return
        }
        // 섹션 직접 갱신 (ViewModel 우회 – viewWillAppear에서도 동기화됨)
        let remaining = (try? Realm())?.objects(Cat.self).map { $0 } ?? []
        reloadCatSection(Array(remaining))
    }

    // MARK: - Badge Label

    private func updateCatCountBadge(totalCount: Int) {
        let selCount = selectedCatIds.count
        contentView.catCountBadgeLabel.text = selCount > 0
            ? "\(selCount)마리 선택"
            : "\(totalCount)마리"
    }

    private func populateRecentSessions(_ sessions: [HuntSession]) {
        contentView.recentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        sessions.forEach { contentView.recentStack.addArrangedSubview(contentView.makeSessionRow($0)) }
        // 오늘 기록이 없으면 섹션 자체를 숨김
        contentView.recentSectionView?.isHidden = sessions.isEmpty
    }

    // MARK: - Banner Image Picker

    private func presentBannerImagePicker() {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else { return }
        let picker           = UIImagePickerController()
        picker.sourceType    = .photoLibrary
        picker.allowsEditing = false   // 원본 그대로 → TOCropViewController 에서 정확한 비율로 크롭
        picker.delegate      = self
        present(picker, animated: true)
    }

    /// 선택된 원본 이미지를 배너 비율(35:18)로 크롭할 수 있는 화면 표시
    private func presentBannerCrop(with image: UIImage) {
        let cropVC = CropViewController(image: image)
        cropVC.delegate = self

        // 배너 실제 비율: (screenWidth - 40) × 180 을 CGSize로 직접 지정
        cropVC.aspectRatioPreset        = CGSize(width: UIScreen.main.bounds.width - 40, height: 180)
        cropVC.aspectRatioLockEnabled   = true    // 비율 고정
        cropVC.resetAspectRatioEnabled  = false   // 리셋 버튼으로 비율 변경 불가
        cropVC.aspectRatioPickerButtonHidden = true // 비율 선택 UI 숨김

        present(cropVC, animated: true)
    }

    // MARK: - Save

    private func applyBannerImage(_ image: UIImage) {
        let iv = contentView.bannerImageView
        UIView.transition(with: iv, duration: 0.25, options: .transitionCrossDissolve) {
            iv.image           = image
            iv.contentMode     = .scaleAspectFill
            iv.backgroundColor = .clear
        }
        contentView.bannerPlaceholderLabel.isHidden = true
        saveBannerImage(image)
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
            // 절대 경로 대신 파일명만 저장 → 빌드/재설치 시 컨테이너 경로 변경에 무관
        try realm.write { cat.bannerImagePath = fileName }
            print("[HuntTimer] 배너 이미지 경로 저장 완료:", url.path)
        } catch {
            print("[HuntTimer] 배너 이미지 경로 Realm 저장 실패:", error)
        }
    }
}

// MARK: - UIImagePickerControllerDelegate

extension HomeViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true) { [weak self] in
            guard let self,
                  let image = info[.originalImage] as? UIImage else { return }
            self.presentBannerCrop(with: image)
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - CropViewControllerDelegate (TOCropViewController)

extension HomeViewController: CropViewControllerDelegate {

    /// 크롭 완료 — 잘린 이미지를 배너에 적용하고 저장
    func cropViewController(_ cropViewController: CropViewController,
                            didCropToImage image: UIImage,
                            withRect cropRect: CGRect,
                            angle: Int) {
        cropViewController.dismiss(animated: true) { [weak self] in
            self?.applyBannerImage(image)
        }
    }

    /// 크롭 취소 — 아무것도 변경하지 않고 닫기
    func cropViewController(_ cropViewController: CropViewController,
                            didFinishCancelled cancelled: Bool) {
        cropViewController.dismiss(animated: true)
    }
}
