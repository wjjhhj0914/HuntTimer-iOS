import UIKit
import RxSwift
import RxCocoa
import RealmSwift

/// 홈 화면 ViewController — RxSwift 바인딩만 담당
final class HomeViewController: BaseViewController {

    private let contentView = HomeView()
    private let viewModel   = HomeViewModel()
    private let disposeBag  = DisposeBag()

    // MARK: - loadView
    override func loadView() {
        view = contentView
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
            bellButtonTapped:   contentView.bellButton.rx.tap.asObservable(),
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
        Driver.combineLatest(output.todayMinutes, output.goalMinutes, output.progressRatio)
            .drive(onNext: { [weak self] today, goal, ratio in
                guard let self else { return }
                self.contentView.centerLabel.text        = "\(today)"
                self.contentView.unitLabel.text          = "/ \(goal)분"
                self.contentView.progressValueLabel.text = "\(today) / \(goal)분"
                self.contentView.goalBadgeLabel.text     = "🎯 목표 \(Int(ratio * 100))%"
                self.contentView.timeBadgeLabel.text     = "⭐ \(goal - today)분 남음"
                self.contentView.gaugeView.updateProgress(ratio)
            })
            .disposed(by: disposeBag)

        output.completedCount
            .drive(onNext: { [weak self] count in
                self?.contentView.sessionCountLabel.text = "⏱ 오늘 \(count)회 사냥 완료"
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
    }

    // MARK: - Helpers
    private func populateRecentSessions(_ sessions: [HuntSession]) {
        contentView.recentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        sessions.forEach { contentView.recentStack.addArrangedSubview(contentView.makeSessionRow($0)) }
    }
}
