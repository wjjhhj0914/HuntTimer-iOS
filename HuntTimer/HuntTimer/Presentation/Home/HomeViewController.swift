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
    private var isEditingCats:        Bool      = false
    private var focusedCatId:         ObjectId? = nil   // 페이저와 동기화된 포커스 고양이
    private var catItemViews:         [CatAvatarItemView] = []
    private var currentProgressPages: [CatProgressPage] = []

    // "전체" 아바타 참조 (포커스 상태 업데이트용)
    private var allCatCircleView:    UIView?
    private var allCatContainerView: UIView?

    // MARK: - loadView
    override func loadView() {
        view = contentView
    }

    // MARK: - Draft Recovery Flag
    private static var hasCheckedDraftThisLaunch = false

    // MARK: - Lifecycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewWillAppearSubject.onNext(())
        if !HomeViewController.hasCheckedDraftThisLaunch {
            HomeViewController.hasCheckedDraftThisLaunch = true
            checkForPendingSessionDraft()
        }
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

        output.heroCatName.drive(contentView.heroCatLabel.rx.text).disposed(by: disposeBag)
        output.heroStatus.drive(contentView.heroStatusLabel.rx.text).disposed(by: disposeBag)

        // Progress pager
        output.catProgressPages
            .drive(onNext: { [weak self] pages in
                guard let self else { return }
                self.currentProgressPages = pages
                self.contentView.progressPagerView.configure(pages: pages)
            })
            .disposed(by: disposeBag)

        // 페이지 변경 → 고양이 아바타 하이라이트 동기화
        contentView.progressPagerView.onPageChanged = { [weak self] pageIndex in
            self?.syncCatHighlight(forPagerPage: pageIndex)
        }

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
                self.contentView.bannerSectionView?.isHidden   = !hasCat
                self.contentView.progressSectionView?.isHidden = !hasCat
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

    // MARK: - Cat Section

    private func reloadCatSection(_ cats: [Cat]) {
        catItemViews.removeAll()
        allCatCircleView    = nil
        allCatContainerView = nil
        let stack = contentView.catAvatarsStack
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // "전체" 버튼 (고양이가 1마리 이상일 때만 표시)
        if !cats.isEmpty {
            let allItem = makeAllCatAvatarItem()
            stack.addArrangedSubview(allItem)
            // 현재 페이지가 overview(0)면 포커스됨, 아니면 반투명
            setAllCatFocused(focusedCatId == nil, animated: false)
        }

        cats.forEach { cat in
            let item = CatAvatarItemView(cat: cat)
            item.onTap       = { [weak self] in self?.handleCatTap(cat: cat) }
            item.onLongPress = { [weak self] in self?.enterEditMode() }
            // 포커스 상태 복원
            item.setFocused(focusState(for: cat), animated: false)
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

    // MARK: - All Cat Avatar

    private func makeAllCatAvatarItem() -> UIView {
        let circleView = UIView()
        circleView.backgroundColor    = UIColor(hex: "#FFF3E0")
        circleView.layer.cornerRadius = 32
        circleView.layer.borderWidth  = 0
        circleView.layer.borderColor  = AppTheme.Color.primary.cgColor
        circleView.clipsToBounds      = true

        let cfg  = UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold)
        let icon = UIImageView(image: UIImage(systemName: "pawprint.fill", withConfiguration: cfg))
        icon.tintColor   = AppTheme.Color.primary
        icon.contentMode = .scaleAspectFit
        circleView.addSubview(icon)
        icon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(28)
        }

        let nameLabel = UILabel.make(text: "전체", size: 12, weight: .semibold,
                                     color: AppTheme.Color.textDark)
        nameLabel.textAlignment = .center

        let container = UIView()
        container.isUserInteractionEnabled = true
        container.addSubview(circleView)
        container.addSubview(nameLabel)
        container.snp.makeConstraints { $0.width.equalTo(64) }
        circleView.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.width.height.equalTo(64)
        }
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(circleView.snp.bottom).offset(6)
            make.leading.trailing.equalTo(circleView)
            make.bottom.equalToSuperview()
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(allCatAvatarTapped))
        container.addGestureRecognizer(tap)

        allCatCircleView    = circleView
        allCatContainerView = container
        return container
    }

    @objc private func allCatAvatarTapped() {
        contentView.progressPagerView.setPage(0, animated: true)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func setAllCatFocused(_ focused: Bool, animated: Bool = true) {
        guard let circleView    = allCatCircleView,
              let containerView = allCatContainerView else { return }
        let apply = {
            if focused {
                circleView.layer.borderWidth = 3
                containerView.alpha          = 1.0
            } else {
                circleView.layer.borderWidth = 0
                containerView.alpha          = 0.5
            }
        }
        animated ? UIView.animate(withDuration: 0.2, animations: apply) : apply()
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
            item.setFocused(focusState(for: item.cat), animated: false)
        }
        setAllCatFocused(focusedCatId == nil, animated: false)

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
            // 해당 고양이의 페이저 페이지로 스크롤
            if let pageIdx = currentProgressPages.firstIndex(where: { $0.catId == cat.id }) {
                contentView.progressPagerView.setPage(pageIdx, animated: true)
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    /// 페이저 페이지 변경에 따라 고양이 아바타 포커스 동기화
    private func syncCatHighlight(forPagerPage pageIndex: Int) {
        if pageIndex == 0 || pageIndex >= currentProgressPages.count {
            // 전체 페이지 — 포커스 없음 (모두 기본 상태)
            focusedCatId = nil
            setAllCatFocused(true, animated: true)
        } else {
            focusedCatId = currentProgressPages[pageIndex].catId
            setAllCatFocused(false, animated: true)
        }
        catItemViews.forEach { $0.setFocused(focusState(for: $0.cat), animated: true) }
        updateCatCountBadge(totalCount: catItemViews.count)
    }

    /// 포커스 상태 계산 — nil: 기본, true: 포커스됨, false: 포커스 해제됨
    private func focusState(for cat: Cat) -> Bool? {
        guard let id = focusedCatId else { return nil }
        return cat.id == id
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
        // ⚠️ 삭제 전에 ID를 값으로 복사 — write 이후 Realm 관리 객체는 invalidated 됨
        let catId = cat.id

        guard let realm = try? Realm(),
              let managed = realm.object(ofType: Cat.self, forPrimaryKey: catId) else { return }
        do {
            try realm.write { realm.delete(managed) }
            // cat / managed 모두 무효화됨 → catId(값 타입)만 사용
            if focusedCatId == catId { focusedCatId = nil }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {
            print("[HuntTimer] 고양이 삭제 실패:", error)
            return
        }

        // 섹션 갱신 — 새 Realm 인스턴스로 재조회
        let remaining: [Cat]
        if let realm = try? Realm() {
            remaining = Array(realm.objects(Cat.self))
        } else {
            remaining = []
        }
        reloadCatSection(remaining)

        // 남은 고양이가 없으면 편집 모드 자동 종료
        if remaining.isEmpty { exitEditMode() }
    }

    // MARK: - Badge Label

    private func updateCatCountBadge(totalCount: Int) {
        contentView.catCountBadgeLabel.text = "\(totalCount)마리"
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

    // MARK: - Draft Recovery

    private func checkForPendingSessionDraft() {
        guard let draft = SessionSaveModalViewController.loadDraft() else { return }
        let alert = UIAlertController(
            title: "이전 기록을 이어 작성할까요?",
            message: "설정을 다녀오는 사이 저장 중이던 사냥 기록이 있어요.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "이어 작성", style: .default) { [weak self] _ in
            self?.restorePendingSession(from: draft)
        })
        alert.addAction(UIAlertAction(title: "기록 삭제", style: .destructive) { _ in
            SessionSaveModalViewController.clearSavedDraft()
        })
        present(alert, animated: true)
    }

    private func restorePendingSession(from draft: SessionSaveModalViewController.PendingSessionDraft) {
        SessionSaveModalViewController.clearSavedDraft()

        let modal              = SessionSaveModalViewController()
        modal.duration         = draft.duration
        modal.catIds           = draft.catIds
        modal.toyName          = draft.toyName
        modal.targetDuration   = draft.targetDuration
        modal.sessionStartTime = Date(timeIntervalSince1970: draft.sessionStartTime)
        modal.initialMemo      = draft.memo
        modal.initialPhoto     = draft.photoData.flatMap { UIImage(data: $0) }

        modal.onSave = { [weak self] memo, photo in
            guard let realm = try? Realm() else { return }
            let cats = draft.catIds.compactMap { idStr -> Cat? in
                guard let oid = try? ObjectId(string: idStr) else { return nil }
                return realm.object(ofType: Cat.self, forPrimaryKey: oid)
            }
            TimerViewModel().saveSession(
                startTime:      Date(timeIntervalSince1970: draft.sessionStartTime),
                endTime:        Date(),
                duration:       draft.duration,
                targetDuration: draft.targetDuration,
                cats:           cats,
                toyName:        draft.toyName,
                memo:           memo,
                photo:          photo
            )
            self?.viewWillAppearSubject.onNext(())
        }
        modal.onCancel = { }

        modal.modalPresentationStyle = .overFullScreen
        modal.modalTransitionStyle   = .crossDissolve
        present(modal, animated: true)
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
