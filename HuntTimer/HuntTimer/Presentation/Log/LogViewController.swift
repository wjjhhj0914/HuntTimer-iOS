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
    private var selectedDay: Int?

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

        reloadCalendar()

        // 오늘 날짜로 초기 선택
        let todayDay = Calendar.current.component(.day, from: Date())
        selectedDay = todayDay
        reloadSessions(for: Date())
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

        // Realm에서 해당 월의 활동 일자 조회
        activityDays = loadActivityDays(year: year, month: month)

        contentView.updateCalendarHeight()
        contentView.calendarCollectionView.reloadData()
    }

    private func reloadSessions(for date: Date) {
        let sessions = loadSessions(for: date)
        let cal      = Calendar.current
        let month    = cal.component(.month, from: date)
        let day      = cal.component(.day,   from: date)

        contentView.sessionTitleLabel.text = "\(month)월 \(day)일 기록"

        if sessions.isEmpty {
            contentView.sessionSummaryLabel.text = ""
        } else {
            let totalSecs = sessions.reduce(0) { $0 + $1.durationSeconds }
            let totalMins = totalSecs / 60
            contentView.sessionSummaryLabel.text = "총 \(sessions.count)회 · \(totalMins)분"
        }

        contentView.reloadSessionRows(sessions)
    }

    // MARK: - Realm Queries

    private func loadActivityDays(year: Int, month: Int) -> Set<Int> {
        guard let realm = try? Realm() else { return [] }
        let cal        = Calendar.current
        let monthStart = cal.date(from: DateComponents(year: year, month: month, day: 1)) ?? Date()
        let monthEnd   = cal.date(byAdding: .month, value: 1, to: monthStart) ?? Date()

        let sessions = realm.objects(PlaySession.self)
            .filter("startTime >= %@ AND startTime < %@", monthStart, monthEnd)
        return Set(sessions.map { cal.component(.day, from: $0.startTime) })
    }

    private func loadSessions(for date: Date) -> [HuntSession] {
        guard let realm = try? Realm() else { return [] }
        let cal      = Calendar.current
        let dayStart = cal.startOfDay(for: date)
        let dayEnd   = cal.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart

        let formatter        = DateFormatter()
        formatter.locale     = Locale(identifier: "ko_KR")
        formatter.dateFormat = "a h:mm"

        let playSessions = Array(
            realm.objects(PlaySession.self)
                .filter("startTime >= %@ AND startTime < %@", dayStart, dayEnd)
                .sorted(byKeyPath: "startTime", ascending: true)
        )

        return playSessions.enumerated().map { idx, s in
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
        cell.configure(day: day,
                       isSelected: day == selectedDay,
                       isToday:    day == todayDayInCurrentMonth,
                       hasActivity: hasActivity,
                       imageURL:   nil)
        return cell
    }

    func collectionView(_ cv: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cells = contentView.buildCalendarCells()
        guard let day = cells[indexPath.item] else { return }

        // 이전 선택 셀 해제
        if let prevDay = selectedDay,
           let prevIdx = cells.firstIndex(where: { $0 == prevDay }),
           let prevCell = cv.cellForItem(at: IndexPath(item: prevIdx, section: 0)) as? DayCell {
            prevCell.configure(day: prevDay, isSelected: false,
                               isToday: prevDay == todayDayInCurrentMonth,
                               hasActivity: activityDays.contains(prevDay), imageURL: nil)
        }

        selectedDay = day

        // 새 선택 셀 업데이트 + 튕김 애니메이션
        if let cell = cv.cellForItem(at: indexPath) as? DayCell {
            cell.configure(day: day, isSelected: true,
                           isToday: day == todayDayInCurrentMonth,
                           hasActivity: activityDays.contains(day), imageURL: nil)
            cell.animateBounce()
        }

        // 선택 날짜의 세션 불러오기
        let cal       = Calendar.current
        let curComps  = cal.dateComponents([.year, .month], from: currentDate)
        var dateComps = DateComponents()
        dateComps.year  = curComps.year
        dateComps.month = curComps.month
        dateComps.day   = day
        if let date = cal.date(from: dateComps) {
            reloadSessions(for: date)
        }
    }
}
