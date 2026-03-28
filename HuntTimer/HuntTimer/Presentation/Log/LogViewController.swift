import UIKit
import RealmSwift

/// 기록 화면 ViewController — 캘린더 상태 관리 및 델리게이트 처리 담당
final class LogViewController: BaseViewController {

    // MARK: - View
    private let contentView = LogView()

    // MARK: - State
    private var currentDate: Date = {
        var comps = Calendar.current.dateComponents([.year, .month], from: Date())
        comps.day = 1
        return Calendar.current.date(from: comps) ?? Date()
    }()
    private var activityDays: Set<Int> = []
    /// 날짜별 첫 번째 사진 경로 (사진이 없는 날짜는 포함하지 않음)
    private var activityPhotos: [Int: String] = [:]
    private var selectedDay: Int?
    /// 현재 선택된 날짜의 PlaySession 목록 — 행 탭 시 상세 모달에 전달
    private var currentPlaySessions: [PlaySession] = []

    // MARK: - loadView
    override func loadView() {
        view = contentView
    }

    // MARK: - BaseViewController
    override func setupBind() {
        contentView.calendarCollectionView.dataSource = self
        contentView.calendarCollectionView.delegate   = self
        contentView.calendarButton.addTarget(self,  action: #selector(calendarTapped), for: .touchUpInside)
        contentView.listButton.addTarget(self,      action: #selector(listTapped),     for: .touchUpInside)
        contentView.prevMonthButton.addTarget(self, action: #selector(prevMonth),      for: .touchUpInside)
        contentView.nextMonthButton.addTarget(self, action: #selector(nextMonth),      for: .touchUpInside)

        contentView.profileButton.addTarget(self, action: #selector(profileTapped), for: .touchUpInside)

        // 타임라인 행 탭 → 탭한 세션 하나만 상세 모달에 표시
        contentView.onSessionRowTap = { [weak self] index in
            guard let self,
                  index < self.currentPlaySessions.count else { return }
            self.presentDetailModal(sessions: [self.currentPlaySessions[index]])
        }

        reloadCalendar()

        // 오늘 날짜로 초기 선택
        let todayDay = Calendar.current.component(.day, from: Date())
        selectedDay = todayDay
        reloadSessions(for: Date())
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 타이머 저장 후 탭 전환 시 최신 데이터 반영
        reloadCalendar()
        if let day = selectedDay {
            let cal      = Calendar.current
            var comps    = cal.dateComponents([.year, .month], from: currentDate)
            comps.day    = day
            if let date  = cal.date(from: comps) {
                reloadSessions(for: date)
            }
        }
    }

    // MARK: - Navigation
    @objc private func profileTapped() {
        navigationController?.pushViewController(ProfileViewController(), animated: true)
    }

    // MARK: - Toggle Actions
    @objc private func calendarTapped() {
        contentView.setToggleState(isCalendar: true)
        UIView.animate(withDuration: 0.25) {
            self.contentView.calendarContainer.isHidden     = false
            self.contentView.calendarContainer.alpha        = 1
            self.contentView.summaryCardContainer.isHidden  = false
            self.contentView.summaryCardContainer.alpha     = 1
        }
    }

    @objc private func listTapped() {
        contentView.setToggleState(isCalendar: false)
        UIView.animate(withDuration: 0.25) {
            self.contentView.calendarContainer.isHidden     = true
            self.contentView.calendarContainer.alpha        = 0
            self.contentView.summaryCardContainer.isHidden  = true
            self.contentView.summaryCardContainer.alpha     = 0
        }
    }

    // MARK: - Month Navigation
    @objc private func prevMonth() {
        guard let prev = Calendar.current.date(byAdding: .month, value: -1, to: currentDate) else { return }
        currentDate = prev
        selectedDay = nil
        reloadCalendar()
        contentView.sessionTitleLabel.text  = "날짜를 선택하세요"
        contentView.sessionSummaryLabel.text = ""
        contentView.reloadSessionRows([])
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    @objc private func nextMonth() {
        guard let next = Calendar.current.date(byAdding: .month, value: 1, to: currentDate) else { return }
        currentDate = next
        selectedDay = nil
        reloadCalendar()
        contentView.sessionTitleLabel.text  = "날짜를 선택하세요"
        contentView.sessionSummaryLabel.text = ""
        contentView.reloadSessionRows([])
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    // MARK: - Reload helpers

    private func reloadCalendar() {
        let cal   = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: currentDate)
        let year  = comps.year  ?? 2026
        let month = comps.month ?? 3

        // 월 레이블 & 뷰 상태 업데이트
        contentView.monthLabel.text = "\(year)년 \(month)월"
        contentView.year  = year
        contentView.month = month - 1   // 0-indexed

        // Realm에서 해당 월의 활동 일자 및 사진 경로 조회
        (activityDays, activityPhotos) = loadActivityData(year: year, month: month)

        contentView.updateCalendarHeight()
        contentView.calendarCollectionView.reloadData()
    }

    private func reloadSessions(for date: Date) {
        // Realm 단일 쿼리 — currentPlaySessions와 HuntSession 목록을 동시에 갱신
        currentPlaySessions = loadAllPlaySessions(for: date)

        let cal   = Calendar.current
        let month = cal.component(.month, from: date)
        let day   = cal.component(.day,   from: date)
        contentView.sessionTitleLabel.text = "\(month)월 \(day)일 기록"

        if currentPlaySessions.isEmpty {
            contentView.sessionSummaryLabel.text = ""
        } else {
            let totalMins = currentPlaySessions.reduce(0) { $0 + $1.duration } / 60
            contentView.sessionSummaryLabel.text = "총 \(currentPlaySessions.count)회 · \(totalMins)분"
        }

        contentView.reloadSessionRows(buildHuntSessions(from: currentPlaySessions))
    }

    private func buildHuntSessions(from playSessions: [PlaySession]) -> [HuntSession] {
        let formatter        = DateFormatter()
        formatter.locale     = Locale(identifier: "ko_KR")
        formatter.dateFormat = "a h:mm"

        return playSessions.enumerated().map { idx, s in
            let mins    = s.duration / 60
            let toyName = s.toys.first?.name
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
                toy:             toyName ?? "장난감 없음",
                durationText:    mins > 0 ? "\(mins)분" : "1분 미만",
                durationSeconds: s.duration,
                calories:        Int(Double(s.duration) / 60.0 * 2.8),
                imageURL:        ""
            )
        }
    }

    // MARK: - Realm Queries

    private func loadActivityData(year: Int, month: Int) -> (Set<Int>, [Int: String]) {
        guard let realm = try? Realm() else { return ([], [:]) }
        let cal        = Calendar.current
        let monthStart = cal.date(from: DateComponents(year: year, month: month, day: 1)) ?? Date()
        let monthEnd   = cal.date(byAdding: .month, value: 1, to: monthStart) ?? Date()

        let sessions = realm.objects(PlaySession.self)
            .filter("startTime >= %@ AND startTime < %@", monthStart, monthEnd)

        var days: Set<Int>       = []
        var photos: [Int: String] = [:]
        for session in sessions {
            let day = cal.component(.day, from: session.startTime)
            days.insert(day)
            if photos[day] == nil, let path = session.photos.first?.imagePath, !path.isEmpty {
                photos[day] = path
            }
        }
        return (days, photos)
    }

    private func loadAllPlaySessions(for date: Date) -> [PlaySession] {
        guard let realm = try? Realm() else { return [] }
        let cal      = Calendar.current
        let dayStart = cal.startOfDay(for: date)
        let dayEnd   = cal.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
        return Array(
            realm.objects(PlaySession.self)
                .filter("startTime >= %@ AND startTime < %@", dayStart, dayEnd)
                .sorted(byKeyPath: "startTime", ascending: true)
        )
    }

    /// 캘린더 날짜 2번째 탭 — 해당 날의 모든 세션을 페이징으로 표시
    private func presentDetailModal(for date: Date) {
        let sessions = loadAllPlaySessions(for: date)
        presentDetailModal(sessions: sessions)
    }

    /// 공통 표시 — sessions 배열을 그대로 모달에 전달
    private func presentDetailModal(sessions: [PlaySession]) {
        guard !sessions.isEmpty else { return }
        let vc = HuntDetailViewController()
        vc.sessions               = sessions
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle   = .crossDissolve
        present(vc, animated: true)
    }

    // MARK: - Korean postposition helper
    private static func roPostposition(for name: String) -> String {
        guard let lastChar = name.last,
              let scalar   = lastChar.unicodeScalars.first else { return "으로" }
        let code = scalar.value
        guard code >= 0xAC00, code <= 0xD7A3 else { return "으로" }
        let jongseong = (code - 0xAC00) % 28
        return (jongseong == 0 || jongseong == 8) ? "로" : "으로"
    }

    // MARK: - Today helper
    private var todayDayInCurrentMonth: Int? {
        let cal        = Calendar.current
        let todayComps = cal.dateComponents([.year, .month, .day], from: Date())
        let curComps   = cal.dateComponents([.year, .month], from: currentDate)
        guard todayComps.year == curComps.year, todayComps.month == curComps.month else { return nil }
        return todayComps.day
    }
}

// MARK: - UICollectionViewDataSource / Delegate
extension LogViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ cv: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        contentView.buildCalendarCells().count
    }

    func collectionView(_ cv: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell  = cv.dequeueReusableCell(withReuseIdentifier: DayCell.id, for: indexPath) as! DayCell
        let cells = contentView.buildCalendarCells()
        let day   = cells[indexPath.item]
        let hasActivity = day.map { activityDays.contains($0) } ?? false
        let imagePath   = day.flatMap { activityPhotos[$0] }
        cell.configure(day: day,
                       isSelected: day == selectedDay,
                       isToday:    day == todayDayInCurrentMonth,
                       hasActivity: hasActivity,
                       imagePath:   imagePath)
        return cell
    }

    func collectionView(_ cv: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cells = contentView.buildCalendarCells()
        guard let day = cells[indexPath.item] else { return }

        let cal       = Calendar.current
        let curComps  = cal.dateComponents([.year, .month], from: currentDate)
        var dateComps = DateComponents()
        dateComps.year  = curComps.year
        dateComps.month = curComps.month
        dateComps.day   = day
        guard let date = cal.date(from: dateComps) else { return }

        // ── 이미 선택된 날짜를 다시 탭: 모달 표시 ─────────────────
        if day == selectedDay {
            if activityDays.contains(day) {
                presentDetailModal(for: date)
            }
            return
        }

        // ── 첫 번째 탭: 날짜 선택 + 세션 목록 갱신 ───────────────

        // 이전 선택 셀 해제
        if let prevDay = selectedDay,
           let prevIdx = cells.firstIndex(where: { $0 == prevDay }),
           let prevCell = cv.cellForItem(at: IndexPath(item: prevIdx, section: 0)) as? DayCell {
            prevCell.configure(day: prevDay, isSelected: false,
                               isToday: prevDay == todayDayInCurrentMonth,
                               hasActivity: activityDays.contains(prevDay),
                               imagePath: activityPhotos[prevDay])
        }

        selectedDay = day

        // 새 선택 셀 업데이트 + 튕김 애니메이션
        if let cell = cv.cellForItem(at: indexPath) as? DayCell {
            cell.configure(day: day, isSelected: true,
                           isToday: day == todayDayInCurrentMonth,
                           hasActivity: activityDays.contains(day),
                           imagePath: activityPhotos[day])
            cell.animateBounce()
        }

        reloadSessions(for: date)
    }
}
