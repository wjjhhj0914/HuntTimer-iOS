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
        // Progress gauge — 초 단위로 보존하여 1분 미만 데이터 손실 방지
        let todaySeconds: Driver<Int>
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

        // ── 세션 Relay ──────────────────────────────────────────────────────
        let todaySecondsRelay   = BehaviorRelay<Int>(value: 0)
        let completedCountRelay = BehaviorRelay<Int>(value: 0)
        let streakDaysRelay     = BehaviorRelay<Int>(value: 0)
        let weeklyHoursRelay    = BehaviorRelay<String>(value: "0시간")
        let bestRecordRelay     = BehaviorRelay<String>(value: "0분")
        let monthlyDaysRelay    = BehaviorRelay<String>(value: "0일")
        let recentSessionsRelay = BehaviorRelay<[HuntSession]>(value: [])

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
                self.reloadSessions(
                    todaySeconds:   todaySecondsRelay,
                    completedCount: completedCountRelay,
                    streakDays:     streakDaysRelay,
                    weeklyHours:    weeklyHoursRelay,
                    bestRecord:     bestRecordRelay,
                    monthlyDays:    monthlyDaysRelay,
                    recentSessions: recentSessionsRelay
                )
            })
            .disposed(by: disposeBag)

        let progressRatio: Driver<Float> = Driver
            .combineLatest(todaySecondsRelay.asDriver(), goalMinutesRelay.asDriver())
            .map { todaySecs, goalMins -> Float in
                let goalSecs = goalMins * 60
                guard goalSecs > 0 else { return 0 }
                return min(1.0, Float(todaySecs) / Float(goalSecs))
            }

        let streakText = streakDaysRelay.asDriver().map { "\($0)일 연속 🔥" }

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
            todaySeconds:     todaySecondsRelay.asDriver(),
            goalMinutes:      goalMinutesRelay.asDriver(),
            progressRatio:    progressRatio,
            completedCount:   completedCountRelay.asDriver(),
            weeklyHours:      weeklyHoursRelay.asDriver(),
            bestRecord:       bestRecordRelay.asDriver(),
            monthlyDays:      monthlyDaysRelay.asDriver(),
            recentSessions:   recentSessionsRelay.asDriver(),
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

    // MARK: - Session Realm reload

    private func reloadSessions(
        todaySeconds:   BehaviorRelay<Int>,
        completedCount: BehaviorRelay<Int>,
        streakDays:     BehaviorRelay<Int>,
        weeklyHours:    BehaviorRelay<String>,
        bestRecord:     BehaviorRelay<String>,
        monthlyDays:    BehaviorRelay<String>,
        recentSessions: BehaviorRelay<[HuntSession]>
    ) {
        guard let realm = try? Realm() else { return }
        let all      = Array(realm.objects(PlaySession.self))
        let calendar = Calendar.current

        // ── 오늘 ────────────────────────────────────────────────────────────
        let todaySessions = all.filter { calendar.isDateInToday($0.startTime) }
        let todaySecs     = todaySessions.reduce(0) { $0 + $1.duration }
        todaySeconds.accept(todaySecs)
        completedCount.accept(todaySessions.count)

        // ── 연속 사냥일 (오늘 포함 역방향 탐색) ─────────────────────────────
        streakDays.accept(Self.computeStreak(from: all, calendar: calendar))

        // ── 이번 주 (7일) ───────────────────────────────────────────────────
        let weekAgo    = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let weeklySecs = all.filter { $0.startTime >= weekAgo }.reduce(0) { $0 + $1.duration }
        weeklyHours.accept(Self.formatDuration(seconds: weeklySecs, style: .hoursOnly))

        // ── 최고 기록 (단일 세션) ────────────────────────────────────────────
        let bestSecs = all.max(by: { $0.duration < $1.duration })?.duration ?? 0
        bestRecord.accept(bestSecs > 0 ? "\(bestSecs / 60)분" : "0분")

        // ── 이번 달 사냥일 수 ────────────────────────────────────────────────
        let monthStart  = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) ?? Date()
        let monthDays   = Set(all.filter { $0.startTime >= monthStart }
                                 .map { calendar.startOfDay(for: $0.startTime) }).count
        monthlyDays.accept("\(monthDays)일")

        // ── 최근 3회 세션 → HuntSession 변환 ────────────────────────────────
        let formatter        = DateFormatter()
        formatter.locale     = Locale(identifier: "ko_KR")
        formatter.dateFormat = "a h:mm"

        let recent = all.sorted { $0.startTime > $1.startTime }.prefix(3)
        let huntSessions: [HuntSession] = recent.enumerated().map { idx, s in
            let mins = s.duration / 60
            return HuntSession(
                id:              idx + 1,
                time:            formatter.string(from: s.startTime),
                toy:             s.toys.first?.name ?? "장난감 없음",
                durationText:    mins > 0 ? "\(mins)분" : "1분 미만",
                durationSeconds: s.duration,
                calories:        Int(Double(s.duration) / 60.0 * 2.8),
                imageURL:        ""
            )
        }
        recentSessions.accept(huntSessions)
    }

    // MARK: - Helpers

    private static func computeStreak(from sessions: [PlaySession], calendar: Calendar) -> Int {
        let activeDays = Set(sessions.map { calendar.startOfDay(for: $0.startTime) })
        var streak     = 0
        var date       = calendar.startOfDay(for: Date())
        while activeDays.contains(date) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: date) else { break }
            date = prev
        }
        return streak
    }

    private enum DurationStyle { case hoursOnly, full }

    private static func formatDuration(seconds: Int, style: DurationStyle) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        switch style {
        case .hoursOnly: return h > 0 ? "\(h)시간" : "\(m)분"
        case .full:      return h > 0 ? (m > 0 ? "\(h)시간 \(m)분" : "\(h)시간") : "\(m)분"
        }
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
