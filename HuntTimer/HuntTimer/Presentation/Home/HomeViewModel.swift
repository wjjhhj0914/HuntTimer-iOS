import Foundation
import RxSwift
import RxCocoa
import RealmSwift

// MARK: - HomeViewModel

final class HomeViewModel {

    // MARK: - Input / Output

    struct Input {
        let viewDidLoad: Observable<Void>
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

        // ── Realm에서 Cat 불러오기 ──────────────────────────────────────────
        let cat     = (try? Realm())?.objects(Cat.self).first
        let hasCat  = cat != nil

        // ── 헤더 타이틀 ────────────────────────────────────────────────────
        let catTitle: String
        let greeting: String
        if let cat = cat {
            let suffix = Self.callSuffix(for: cat.name)
            catTitle = "\(cat.name)\(suffix), 사냥하러 가자!"
            greeting = "안녕하세요 😸"
        } else {
            catTitle = "아직 등록된 냥이가 없어요!"
            greeting = "냥이를 등록해주세요 🐾"
        }

        // ── 진행 게이지 ─────────────────────────────────────────────────────
        let todayMinutes   = BehaviorRelay<Int>(value: 0)
        let goalMinutes    = BehaviorRelay<Int>(value: cat?.targetTime ?? 30)
        let completedCount = BehaviorRelay<Int>(value: 0)
        let streakDays     = BehaviorRelay<Int>(value: 0)

        let progressRatio: Driver<Float> = Driver
            .combineLatest(todayMinutes.asDriver(), goalMinutes.asDriver())
            .map { today, goal -> Float in
                guard goal > 0 else { return 0 }
                return min(1.0, Float(today) / Float(goal))
            }

        let streakText = streakDays.asDriver()
            .map { "\($0)일 연속 🔥" }

        // ── 시작 버튼 타이틀 ────────────────────────────────────────────────
        let startButtonTitle = hasCat
            ? "⭐ 새 사냥 시작하기! 🐾"
            : "냥이 프로필 등록하기 🐾"

        // ── Side effects ────────────────────────────────────────────────────
        input.startHuntingTapped
            .subscribe(onNext: { print("[HuntTimer] 새 사냥 시작 탭") })
            .disposed(by: disposeBag)

        input.seeAllTapped
            .subscribe(onNext: { print("[HuntTimer] 전체보기 탭") })
            .disposed(by: disposeBag)

        // ── 배너용 Cat 이름 ─────────────────────────────────────────────────
        let catName = cat.map { "\($0.name)의 오늘 🌿" } ?? ""

        // ── Output ──────────────────────────────────────────────────────────
        return Output(
            greeting:         .just(greeting),
            catTitle:         .just(catTitle),
            bannerImageURL:   .just("https://images.unsplash.com/photo-1766267167775-c93d3b6f6f56?w=800"),
            streakText:       streakText,
            heroCatName:      .just(catName),
            heroStatus:       .just(hasCat ? "사냥 준비 완료!" : ""),
            todayMinutes:     todayMinutes.asDriver(),
            goalMinutes:      goalMinutes.asDriver(),
            progressRatio:    progressRatio,
            completedCount:   completedCount.asDriver(),
            weeklyHours:      .just("0시간"),
            bestRecord:       .just("0분"),
            monthlyDays:      .just("0일"),
            recentSessions:   .just([]),
            hasCat:           .just(hasCat),
            startButtonTitle: .just(startButtonTitle)
        )
    }

    // MARK: - Korean postposition helper

    /// 이름 끝 글자의 받침 유무에 따라 '야' 또는 '아' 반환
    private static func callSuffix(for name: String) -> String {
        guard let lastChar  = name.last,
              let scalar    = lastChar.unicodeScalars.first else { return "야" }
        let code = scalar.value
        // 한글 음절 범위: 0xAC00 ~ 0xD7A3 / (code - 0xAC00) % 28 == 0 → 받침 없음 → "야"
        guard code >= 0xAC00, code <= 0xD7A3 else { return "야" }
        return (code - 0xAC00) % 28 == 0 ? "야" : "아"
    }
}
