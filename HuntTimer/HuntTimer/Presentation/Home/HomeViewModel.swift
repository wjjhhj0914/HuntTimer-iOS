import Foundation
import RxSwift
import RxCocoa
import RealmSwift

// MARK: - HomeViewModel

final class HomeViewModel {

    // MARK: - Input / Output

    struct Input {
        let viewDidLoad: Observable<Void>
        let viewWillAppear: Observable<Void>
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
        // State
        let hasCat: Driver<Bool>
        let startButtonTitle: Driver<String>
    }

    // MARK: - Private

    private let disposeBag = DisposeBag()

    // MARK: - Transform

    func transform(input: Input) -> Output {

        // ── Cat 파생 값 (viewDidLoad + viewWillAppear 때마다 Realm 재쿼리) ──
        let greetingRelay      = BehaviorRelay<String>(value: "")
        let catTitleRelay      = BehaviorRelay<String>(value: "")
        let heroCatNameRelay   = BehaviorRelay<String>(value: "")
        let heroStatusRelay    = BehaviorRelay<String>(value: "")
        let goalMinutesRelay   = BehaviorRelay<Int>(value: 30)
        let hasCatRelay        = BehaviorRelay<Bool>(value: false)
        let startBtnTitleRelay = BehaviorRelay<String>(value: "")

        Observable.merge(input.viewDidLoad, input.viewWillAppear)
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                self.reloadCat(
                    greeting:      greetingRelay,
                    catTitle:      catTitleRelay,
                    heroCatName:   heroCatNameRelay,
                    heroStatus:    heroStatusRelay,
                    goalMinutes:   goalMinutesRelay,
                    hasCat:        hasCatRelay,
                    startBtnTitle: startBtnTitleRelay
                )
            })
            .disposed(by: disposeBag)

        // ── 세션 관련 (추후 Realm 연동) ────────────────────────────────────
        let todayMinutes   = BehaviorRelay<Int>(value: 0)
        let completedCount = BehaviorRelay<Int>(value: 0)
        let streakDays     = BehaviorRelay<Int>(value: 0)

        let progressRatio: Driver<Float> = Driver
            .combineLatest(todayMinutes.asDriver(), goalMinutesRelay.asDriver())
            .map { today, goal -> Float in
                guard goal > 0 else { return 0 }
                return min(1.0, Float(today) / Float(goal))
            }

        let streakText = streakDays.asDriver()
            .map { "\($0)일 연속 🔥" }

        // ── Side effects ────────────────────────────────────────────────────
        input.startHuntingTapped
            .subscribe(onNext: { print("[HuntTimer] 새 사냥 시작 탭") })
            .disposed(by: disposeBag)

        input.seeAllTapped
            .subscribe(onNext: { print("[HuntTimer] 전체보기 탭") })
            .disposed(by: disposeBag)

        // ── Output ──────────────────────────────────────────────────────────
        return Output(
            greeting:         greetingRelay.asDriver(),
            catTitle:         catTitleRelay.asDriver(),
            bannerImageURL:   .just("https://images.unsplash.com/photo-1766267167775-c93d3b6f6f56?w=800"),
            streakText:       streakText,
            heroCatName:      heroCatNameRelay.asDriver(),
            heroStatus:       heroStatusRelay.asDriver(),
            todayMinutes:     todayMinutes.asDriver(),
            goalMinutes:      goalMinutesRelay.asDriver(),
            progressRatio:    progressRatio,
            completedCount:   completedCount.asDriver(),
            weeklyHours:      .just("0시간"),
            bestRecord:       .just("0분"),
            monthlyDays:      .just("0일"),
            recentSessions:   .just([]),
            hasCat:           hasCatRelay.asDriver(),
            startButtonTitle: startBtnTitleRelay.asDriver()
        )
    }

    // MARK: - Realm reload

    private func reloadCat(
        greeting:      BehaviorRelay<String>,
        catTitle:      BehaviorRelay<String>,
        heroCatName:   BehaviorRelay<String>,
        heroStatus:    BehaviorRelay<String>,
        goalMinutes:   BehaviorRelay<Int>,
        hasCat:        BehaviorRelay<Bool>,
        startBtnTitle: BehaviorRelay<String>
    ) {
        let cat   = (try? Realm())?.objects(Cat.self).first
        let hasIt = cat != nil

        if let cat = cat {
            let suffix = Self.callSuffix(for: cat.name)
            catTitle.accept("\(cat.name)\(suffix), 사냥하러 가자!")
            greeting.accept("안녕하세요 😸")
            heroCatName.accept("\(cat.name)의 오늘 🌿")
            heroStatus.accept("사냥 준비 완료!")
            goalMinutes.accept(cat.targetTime)
            startBtnTitle.accept("⭐ 새 사냥 시작하기! 🐾")
        } else {
            catTitle.accept("아직 등록된 냥이가 없어요!")
            greeting.accept("냥이를 등록해주세요 🐾")
            heroCatName.accept("")
            heroStatus.accept("")
            goalMinutes.accept(30)
            startBtnTitle.accept("냥이 프로필 등록하기 🐾")
        }
        hasCat.accept(hasIt)
    }

    // MARK: - Korean postposition helper

    /// 이름 끝 글자의 받침 유무에 따라 '야' 또는 '아' 반환
    private static func callSuffix(for name: String) -> String {
        guard let lastChar = name.last,
              let scalar   = lastChar.unicodeScalars.first else { return "야" }
        let code = scalar.value
        // 한글 음절: 0xAC00~0xD7A3 / (code - 0xAC00) % 28 == 0 → 받침 없음 → "야"
        guard code >= 0xAC00, code <= 0xD7A3 else { return "야" }
        return (code - 0xAC00) % 28 == 0 ? "야" : "아"
    }
}
