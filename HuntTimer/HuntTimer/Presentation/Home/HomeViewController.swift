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
        // 우측 상단 프로필 버튼 → 수정 모드로 push
        contentView.catProfileButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                let vc      = CatProfileViewController()
                vc.mode     = .edit
                vc.catToEdit = (try? Realm())?.objects(Cat.self).first
                self.navigationController?.pushViewController(vc, animated: true)
            })
            .disposed(by: disposeBag)

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

        // Banner
        output.bannerImageURL
            .drive(onNext: { [weak self] url in self?.contentView.bannerImageView.loadImage(from: url) })
            .disposed(by: disposeBag)
        output.streakText.drive(contentView.streakLabel.rx.text).disposed(by: disposeBag)
        output.heroCatName.drive(contentView.heroCatLabel.rx.text).disposed(by: disposeBag)
        output.heroStatus.drive(contentView.heroStatusLabel.rx.text).disposed(by: disposeBag)

        // Progress gauge
        Driver.combineLatest(output.todaySeconds, output.goalMinutes, output.progressRatio)
            .drive(onNext: { [weak self] todaySecs, goalMins, ratio in
                guard let self else { return }
                // 원형 중앙 — 압도적 퍼센트 레이블
                self.contentView.percentLabel.text = Self.formatPercent(todaySecs: todaySecs, goalMins: goalMins)
                // 게이지: 화면 등장 시 0 → 현재값으로 차오르는 애니메이션
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

    /// 초 단위 정밀 계산: (오늘 총 초 / 목표 초) * 100
    /// - 0초: "0%"  |  1분 미만: "< 1%"  |  이상: 반올림 정수%
    private static func formatPercent(todaySecs: Int, goalMins: Int) -> String {
        let goalSecs = goalMins * 60
        guard goalSecs > 0, todaySecs > 0 else { return "0%" }
        let ratio = Double(todaySecs) / Double(goalSecs)
        if ratio < 0.01 { return "< 1%" }
        return "\(min(Int((ratio * 100).rounded()), 100))%"
    }

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
}
