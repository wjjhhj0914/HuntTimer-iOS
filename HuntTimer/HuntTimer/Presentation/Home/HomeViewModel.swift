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
        let bannerImagePath: Driver<String?>
        let streakText: Driver<String>
        let heroCatName: Driver<String>
        let heroStatus: Driver<String>
        // Progress pager
        let catProgressPages: Driver<[CatProgressPage]>
        // Quick stats
        let weeklyHours: Driver<String>
        let bestRecord: Driver<String>
        let monthlyDays: Driver<String>
        // Recent sessions
        let recentSessions: Driver<[HuntSession]>
        // Cats section
        let cats: Driver<[Cat]>
        // State
        let hasCat: Driver<Bool>
        let startButtonTitle: Driver<String>
    }

    // MARK: - Private

    private let disposeBag = DisposeBag()

    // MARK: - Transform

    func transform(input: Input) -> Output {

        // ── Cat 파생 값 (viewDidLoad + viewWillAppear 때마다 Realm 재쿼리) ──
        let greetingRelay        = BehaviorRelay<String>(value: "")
        let catTitleRelay        = BehaviorRelay<String>(value: "")
        let heroCatNameRelay     = BehaviorRelay<String>(value: "")
        let heroStatusRelay      = BehaviorRelay<String>(value: "")
        let goalMinutesRelay     = BehaviorRelay<Int>(value: 30)
        let hasCatRelay          = BehaviorRelay<Bool>(value: false)
        let startBtnTitleRelay   = BehaviorRelay<String>(value: "")
        let bannerImagePathRelay = BehaviorRelay<String?>(value: nil)

        // ── 세션 Relay ──────────────────────────────────────────────────────
        let streakDaysRelay      = BehaviorRelay<Int>(value: 0)
        let weeklyHoursRelay     = BehaviorRelay<String>(value: "0시간")
        let bestRecordRelay      = BehaviorRelay<String>(value: "0분")
        let monthlyDaysRelay     = BehaviorRelay<String>(value: "0일")
        let recentSessionsRelay  = BehaviorRelay<[HuntSession]>(value: [])
        let catsRelay            = BehaviorRelay<[Cat]>(value: [])
        let catProgressPagesRelay = BehaviorRelay<[CatProgressPage]>(value: [])

        Observable.merge(input.viewDidLoad, input.viewWillAppear)
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                self.reloadCat(
                    greeting:        greetingRelay,
                    catTitle:        catTitleRelay,
                    heroCatName:     heroCatNameRelay,
                    heroStatus:      heroStatusRelay,
                    goalMinutes:     goalMinutesRelay,
                    hasCat:          hasCatRelay,
                    startBtnTitle:   startBtnTitleRelay,
                    bannerImagePath: bannerImagePathRelay
                )
                self.reloadSessions(
                    streakDays:       streakDaysRelay,
                    weeklyHours:      weeklyHoursRelay,
                    bestRecord:       bestRecordRelay,
                    monthlyDays:      monthlyDaysRelay,
                    recentSessions:   recentSessionsRelay,
                    catProgressPages: catProgressPagesRelay
                )
                if let realm = try? Realm() {
                    catsRelay.accept(Array(realm.objects(Cat.self)))
                }
            })
            .disposed(by: disposeBag)

        let streakText = streakDaysRelay.asDriver().map { "\($0)일 연속" }

        // ── Side effects ────────────────────────────────────────────────────
        input.startHuntingTapped
            .subscribe(onNext: { print("[HuntTimer] 새 사냥 시작 탭") })
            .disposed(by: disposeBag)

        // ── Output ──────────────────────────────────────────────────────────
        return Output(
            greeting:          greetingRelay.asDriver(),
            catTitle:          catTitleRelay.asDriver(),
            bannerImagePath:   bannerImagePathRelay.asDriver(),
            streakText:        streakText,
            heroCatName:       heroCatNameRelay.asDriver(),
            heroStatus:        heroStatusRelay.asDriver(),
            catProgressPages:  catProgressPagesRelay.asDriver(),
            weeklyHours:       weeklyHoursRelay.asDriver(),
            bestRecord:        bestRecordRelay.asDriver(),
            monthlyDays:       monthlyDaysRelay.asDriver(),
            recentSessions:    recentSessionsRelay.asDriver(),
            cats:              catsRelay.asDriver(),
            hasCat:            hasCatRelay.asDriver(),
            startButtonTitle:  startBtnTitleRelay.asDriver()
        )
    }

    // MARK: - Realm reload

    private func reloadCat(
        greeting:        BehaviorRelay<String>,
        catTitle:        BehaviorRelay<String>,
        heroCatName:     BehaviorRelay<String>,
        heroStatus:      BehaviorRelay<String>,
        goalMinutes:     BehaviorRelay<Int>,
        hasCat:          BehaviorRelay<Bool>,
        startBtnTitle:   BehaviorRelay<String>,
        bannerImagePath: BehaviorRelay<String?>
    ) {
        let cat   = (try? Realm())?.objects(Cat.self).first
        let hasIt = cat != nil

        let todayString = Self.todayDateString()
        if let cat = cat {
            let suffix = Self.callSuffix(for: cat.name)
            catTitle.accept("오늘의 목표를 향해 힘차게 출발!")
            greeting.accept(todayString)
            heroCatName.accept(cat.name)
            let breedDisplay = CatBreed(rawValue: cat.breed)?.displayName ?? cat.breed
            heroStatus.accept(breedDisplay.isEmpty ? "사냥 준비 완료! 🐾" : breedDisplay)
            goalMinutes.accept(cat.targetTime)
            startBtnTitle.accept("사냥 시작하기!")
            // 파일명만 저장돼 있으므로 현재 Documents 경로와 조합 → 빌드/재설치 후에도 유효
            // 구버전 호환: 절대 경로가 저장된 경우 마지막 경로 컴포넌트(파일명)만 추출
            if cat.bannerImagePath.isEmpty {
                bannerImagePath.accept(nil)
            } else {
                let fileName = (cat.bannerImagePath as NSString).lastPathComponent
                let dir      = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let fullPath = dir.appendingPathComponent(fileName).path
                bannerImagePath.accept(fullPath)
            }
        } else {
            catTitle.accept("아직 등록된 냥이가 없어요!")
            greeting.accept(todayString)
            heroCatName.accept("")
            heroStatus.accept("")
            goalMinutes.accept(30)
            startBtnTitle.accept("냥이 프로필 등록하기 🐾")
            bannerImagePath.accept(nil)
        }
        hasCat.accept(hasIt)
    }

    // MARK: - Session Realm reload

    private func reloadSessions(
        streakDays:       BehaviorRelay<Int>,
        weeklyHours:      BehaviorRelay<String>,
        bestRecord:       BehaviorRelay<String>,
        monthlyDays:      BehaviorRelay<String>,
        recentSessions:   BehaviorRelay<[HuntSession]>,
        catProgressPages: BehaviorRelay<[CatProgressPage]>
    ) {
        guard let realm = try? Realm() else { return }
        let all      = Array(realm.objects(PlaySession.self))
        let allCats  = Array(realm.objects(Cat.self))
        let calendar = Calendar.current

        // ── 오늘 세션 ────────────────────────────────────────────────────────
        let todaySessions = all.filter { calendar.isDateInToday($0.startTime) }
        let todaySecs     = todaySessions.reduce(0) { $0 + $1.duration }

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
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) ?? Date()
        let monthDays  = Set(all.filter { $0.startTime >= monthStart }
                                .map { calendar.startOfDay(for: $0.startTime) }).count
        monthlyDays.accept("\(monthDays)일")

        // ── 최근 3회 세션 → HuntSession 변환 ────────────────────────────────
        let formatter        = DateFormatter()
        formatter.locale     = Locale(identifier: "ko_KR")
        formatter.dateFormat = "a h:mm"

        let recent = todaySessions
            .sorted { $0.startTime > $1.startTime }
            .prefix(3)
        let huntSessions: [HuntSession] = recent.enumerated().map { idx, s in
            let mins     = s.duration / 60
            let toyName  = s.toys.first?.name
            let category = s.toys.first?.category ?? ""
            let title: String
            if let name = toyName {
                title = "\(name)\(Self.roPostposition(for: name)) 사냥했어요!"
            } else {
                title = "열정적으로 사냥했어요!"
            }
            return HuntSession(
                id:              idx + 1,
                time:            formatter.string(from: s.startTime),
                title:           title,
                toy:             toyName ?? "",
                toySymbol:       Self.sfSymbol(for: category),
                durationText:    mins > 0 ? "\(mins)분" : "1분 미만",
                durationSeconds: s.duration,
                calories:        Int(Double(s.duration) / 60.0 * 2.8),
                imageURL:        ""
            )
        }
        recentSessions.accept(huntSessions)

        // ── 목표 대시보드 페이지 계산 ────────────────────────────────────────
        var pages: [CatProgressPage] = []

        // 전체 overview 페이지 (첫 번째 고양이의 목표 기준)
        let overviewGoal = allCats.first?.targetTime ?? 30
        pages.append(CatProgressPage(
            catId:            nil,
            catName:          "전체",
            profileImageData: nil,
            todaySeconds:     todaySecs,
            goalMinutes:      overviewGoal,
            completedCount:   todaySessions.count
        ))

        // 개별 고양이 페이지
        for cat in allCats {
            let catSessions = todaySessions.filter { s in
                s.cats.contains(where: { $0.id == cat.id })
            }
            let catSecs = catSessions.reduce(0) { $0 + $1.duration }
            pages.append(CatProgressPage(
                catId:            cat.id,
                catName:          cat.name,
                profileImageData: cat.profileImageData,
                todaySeconds:     catSecs,
                goalMinutes:      cat.targetTime,
                completedCount:   catSessions.count
            ))
        }
        catProgressPages.accept(pages)
    }

    // MARK: - Helpers

    private static func todayDateString() -> String {
        let formatter        = DateFormatter()
        formatter.locale     = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 MM월 dd일"
        return formatter.string(from: Date())
    }

    /// 장난감 카테고리(= 장난감 이름) → SF Symbol 이름 매핑
    /// TimerView.makeToySection() 의 items 배열과 1:1 대응
    private static func sfSymbol(for category: String) -> String {
        switch category {
        case "깃털":    return "leaf.fill"
        case "벌레":    return "ant.fill"
        case "레이저":  return "bolt.fill"
        case "카샤카샤": return "timelapse"
        case "오뎅꼬치": return "oar.2.crossed"
        default:       return "pawprint.fill"   // 장난감 미선택 or 알 수 없는 카테고리
        }
    }

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

    // MARK: - Korean postposition helpers

    /// 끝 글자 받침 유무에 따라 '로' 또는 '으로' 반환 (ㄹ 받침도 '로')
    private static func roPostposition(for name: String) -> String {
        guard let lastChar = name.last,
              let scalar   = lastChar.unicodeScalars.first else { return "으로" }
        let code = scalar.value
        guard code >= 0xAC00, code <= 0xD7A3 else { return "으로" }
        let jongseong = (code - 0xAC00) % 28
        return (jongseong == 0 || jongseong == 8) ? "로" : "으로"  // 0: 받침 없음, 8: ㄹ
    }

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
