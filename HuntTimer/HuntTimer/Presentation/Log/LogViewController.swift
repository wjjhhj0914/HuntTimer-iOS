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

        // 타임라인 행 탭 → 해당 세션 상세 모달
        contentView.onRowTap = { [weak self] index in
            guard let self,
                  index < self.currentPlaySessions.count else { return }
            self.presentDetailModal(sessions: [self.currentPlaySessions[index]])
        }

        // 타임라인 행 스와이프 → 삭제 확인 얼럿
        contentView.onDeleteTap = { [weak self] index in
            guard let self,
                  index < self.currentPlaySessions.count else { return }
            self.showDeleteAlert(at: index)
        }

        reloadCalendar()

        // 오늘 날짜로 초기 선택
        let todayDay = Calendar.current.component(.day, from: Date())
        selectedDay = todayDay
        reloadSessions(for: Date())
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
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

    @objc private func profileTapped() {
        navigationController?.pushViewController(ProfileViewController(), animated: true)
    }

    // MARK: - Toggle Actions
    @objc private func calendarTapped() {
        contentView.setToggleState(isCalendar: true)
        UIView.animate(withDuration: 0.25) {
            self.contentView.calendarContainer.isHidden = false
            self.contentView.calendarContainer.alpha    = 1
        }
    }

    @objc private func listTapped() {
        contentView.setToggleState(isCalendar: false)
        UIView.animate(withDuration: 0.25) {
            self.contentView.calendarContainer.isHidden = true
            self.contentView.calendarContainer.alpha    = 0
        }
    }

    // MARK: - Month Navigation
    @objc private func prevMonth() {
        guard let prev = Calendar.current.date(byAdding: .month, value: -1, to: currentDate) else { return }
        currentDate = prev
        selectedDay = nil
        reloadCalendar()
        contentView.sessionTitleLabel.text  = "날짜를 선택하세요"
        contentView.reloadSessionRows([CatSessionGroup]())
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    @objc private func nextMonth() {
        guard let next = Calendar.current.date(byAdding: .month, value: 1, to: currentDate) else { return }
        currentDate = next
        selectedDay = nil
        reloadCalendar()
        contentView.sessionTitleLabel.text  = "날짜를 선택하세요"
        contentView.reloadSessionRows([CatSessionGroup]())
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

        // Realm에서 해당 월의 활동 일자·사진·통계 조회 (단일 쿼리)
        let monthly = loadMonthlyData(year: year, month: month)
        activityDays   = monthly.activityDays
        activityPhotos = monthly.activityPhotos

        contentView.updateCalendarHeight()
        contentView.calendarCollectionView.reloadData()
    }

    private func reloadSessions(for date: Date) {
        currentPlaySessions = loadAllPlaySessions(for: date)

        let cal   = Calendar.current
        let month = cal.component(.month, from: date)
        let day   = cal.component(.day,   from: date)
        contentView.sessionTitleLabel.text = "\(month)월 \(day)일 기록"

        contentView.reloadSessionRows(buildGroupedSessions(from: currentPlaySessions))
    }

    // MARK: - Session Builders

    /// PlaySession 목록을 고양이별로 그룹화해 반환
    private func buildGroupedSessions(from playSessions: [PlaySession]) -> [CatSessionGroup] {
        let formatter        = DateFormatter()
        formatter.locale     = Locale(identifier: "ko_KR")
        formatter.dateFormat = "a h:mm"

        // 삽입 순서를 유지하는 ordered 그룹 구축
        var groupOrder: [String] = []
        var groupMap: [String: [(session: HuntSession, playSessionIndex: Int)]] = [:]

        for (idx, session) in playSessions.enumerated() {
            let huntSession = makeHuntSession(from: session, index: idx, formatter: formatter)

            // 연결된 고양이가 없으면 "기타" 그룹
            let catNames: [String] = session.cats.isEmpty
                ? ["기타"]
                : session.cats.map { $0.name }

            for catName in catNames {
                if groupMap[catName] == nil {
                    groupOrder.append(catName)
                    groupMap[catName] = []
                }
                groupMap[catName]?.append((session: huntSession, playSessionIndex: idx))
            }
        }

        return groupOrder.compactMap { name in
            guard let items = groupMap[name] else { return nil }
            return CatSessionGroup(catName: name, items: items)
        }
    }

    private func makeHuntSession(from session: PlaySession, index: Int,
                                  formatter: DateFormatter) -> HuntSession {
        let mins     = session.duration / 60
        let toyName  = session.toys.first?.name
        let category = session.toys.first?.category ?? ""
        let title: String
        if let name = toyName {
            title = "\(name)\(Self.roPostposition(for: name)) 사냥했어요!"
        } else {
            title = "열정적으로 사냥했어요!"
        }
        return HuntSession(
            id:              index + 1,
            time:            formatter.string(from: session.startTime),
            title:           title,
            toy:             toyName ?? "장난감 없음",
            toySymbol:       Self.sfSymbol(for: category),
            durationText:    Self.formatDuration(session.duration),
            durationSeconds: session.duration,
            calories:        Int(Double(session.duration) / 60.0 * 2.8),
            imageURL:        ""
        )
    }

    // MARK: - Delete

    private func showDeleteAlert(at index: Int) {
        let alert = UIAlertController(
            title: "사냥 기록 삭제",
            message: "사냥 기록을 삭제하시겠습니까?\n삭제한 기록은 되돌릴 수 없어요!",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            self?.deleteSession(at: index)
        })
        present(alert, animated: true)
    }

    private func deleteSession(at index: Int) {
        guard index < currentPlaySessions.count,
              let realm = try? Realm() else { return }
        let session = currentPlaySessions[index]
        do {
            try realm.write {
                realm.delete(session.photos)   // PhotoLog (역참조) 삭제
                realm.delete(session.toys)     // Toy 목록 삭제
                realm.delete(session)          // PlaySession 본체 삭제
            }
        } catch {
            print("[Log] 세션 삭제 실패:", error)
            return
        }
        let cal   = Calendar.current
        var comps = cal.dateComponents([.year, .month], from: currentDate)
        comps.day = selectedDay ?? cal.component(.day, from: Date())
        if let date = cal.date(from: comps) {
            reloadSessions(for: date)
        }
        reloadCalendar()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    // MARK: - Realm Queries

    private func loadMonthlyData(year: Int, month: Int)
        -> (activityDays: Set<Int>, activityPhotos: [Int: String]) {
        guard let realm = try? Realm() else { return ([], [:]) }
        let cal        = Calendar.current
        let monthStart = cal.date(from: DateComponents(year: year, month: month, day: 1)) ?? Date()
        let monthEnd   = cal.date(byAdding: .month, value: 1, to: monthStart) ?? Date()

        let sessions = realm.objects(PlaySession.self)
            .filter("startTime >= %@ AND startTime < %@", monthStart, monthEnd)

        var days: Set<Int>        = []
        var photos: [Int: String] = [:]
        for session in sessions {
            let day = cal.component(.day, from: session.startTime)
            days.insert(day)

            if photos[day] == nil,
               let log = realm.objects(PhotoLog.self)
                   .filter("session == %@ AND imagePath != %@", session, "")
                   .first {
                photos[day] = log.imagePath
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

    // MARK: - Helpers

    /// 초 단위 duration → "SS초" 또는 "M분 SS초" 포맷
    private static func formatDuration(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds)초"
        } else {
            let m = seconds / 60
            let s = seconds % 60
            return s > 0 ? "\(m)분 \(s)초" : "\(m)분"
        }
    }

    private static func sfSymbol(for category: String) -> String {
        switch category {
        case "깃털":    return "leaf.fill"
        case "벌레":    return "ant.fill"
        case "레이저":  return "bolt.fill"
        case "카샤카샤": return "timelapse"
        case "오뎅꼬치": return "oar.2.crossed"
        default:       return "pawprint.fill"
        }
    }

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
