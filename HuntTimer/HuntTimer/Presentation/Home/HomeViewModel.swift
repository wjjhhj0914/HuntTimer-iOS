import Foundation
import RxSwift
import RxCocoa

// MARK: - HomeViewModel

final class HomeViewModel {

    // MARK: - Input / Output

    struct Input {
        let viewDidLoad: Observable<Void>
        let bellButtonTapped: Observable<Void>
        let startHuntingTapped: Observable<Void>
        let seeAllTapped: Observable<Void>
    }

    struct Output {
        // Header
        let greeting: Driver<String>
        let catTitle: Driver<String>
        // Banner
        let bannerImageURL: Driver<String>
        let streakText: Driver<String>
        let heroCatName: Driver<String>
        let heroStatus: Driver<String>
        // Progress gauge
        let todayMinutes: Driver<Int>
        let goalMinutes: Driver<Int>
        let progressRatio: Driver<Float>
        let completedCount: Driver<Int>
        // Quick stats
        let weeklyHours: Driver<String>
        let bestRecord: Driver<String>
        let monthlyDays: Driver<String>
        // Recent sessions
        let recentSessions: Driver<[HuntSession]>
    }

    // MARK: - Private

    private let disposeBag = DisposeBag()

    // MARK: - Transform

    func transform(input: Input) -> Output {

        // ── Mock 데이터 ────────────────────────────────────────────────────
        // TODO: Realm 연동 시 아래 BehaviorRelay 값을 Repository에서 주입
        let todayMinutes   = BehaviorRelay<Int>(value: 35)
        let goalMinutes    = BehaviorRelay<Int>(value: 60)
        let completedCount = BehaviorRelay<Int>(value: 3)
        let streakDays     = BehaviorRelay<Int>(value: 3)

        let progressRatio: Driver<Float> = Driver
            .combineLatest(todayMinutes.asDriver(), goalMinutes.asDriver())
            .map { today, goal -> Float in
                guard goal > 0 else { return 0 }
                return min(1.0, Float(today) / Float(goal))
            }

        let streakText = streakDays.asDriver()
            .map { "\($0)일 연속 🔥" }

        // ── Side effects ───────────────────────────────────────────────────
        input.bellButtonTapped
            .subscribe(onNext: { print("[HuntTimer] 벨 버튼 탭") })
            .disposed(by: disposeBag)

        input.startHuntingTapped
            .subscribe(onNext: { print("[HuntTimer] 새 사냥 시작 탭") })
            .disposed(by: disposeBag)

        input.seeAllTapped
            .subscribe(onNext: { print("[HuntTimer] 전체보기 탭") })
            .disposed(by: disposeBag)

        // ── Output ─────────────────────────────────────────────────────────
        return Output(
            greeting:       .just("안녕하세요 😸"),
            catTitle:       .just("민지야, 사냥하러 가자!"),
            bannerImageURL: .just("https://images.unsplash.com/photo-1766267167775-c93d3b6f6f56?w=800"),
            streakText:     streakText,
            heroCatName:    .just("뮤기의 오늘 🌿"),
            heroStatus:     .just("사냥 준비 완료!"),
            todayMinutes:   todayMinutes.asDriver(),
            goalMinutes:    goalMinutes.asDriver(),
            progressRatio:  progressRatio,
            completedCount: completedCount.asDriver(),
            weeklyHours:    .just("4.2시간"),
            bestRecord:     .just("25분"),
            monthlyDays:    .just("18일"),
            recentSessions: .just(Array(SampleData.sessions.prefix(3)))
        )
    }
}
