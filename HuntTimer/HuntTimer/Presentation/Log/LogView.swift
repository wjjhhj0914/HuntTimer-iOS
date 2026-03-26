import UIKit
import SnapKit

/// 기록 화면 루트 뷰 — 모든 UI 선언과 SnapKit 레이아웃을 담당
final class LogView: BaseView {

    // MARK: - Calendar State (mutable — VC가 월 이동 시 갱신)
    var year: Int  = Calendar.current.component(.year,  from: Date())
    var month: Int = Calendar.current.component(.month, from: Date()) - 1  // 0-indexed

    // MARK: - Scroll (VC가 delegate 할당을 위해 접근)
    let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.alwaysBounceVertical = true
        sv.backgroundColor = AppTheme.Color.background
        return sv
    }()
    private let contentStack: UIStackView = {
        let sv = UIStackView.make(axis: .vertical, spacing: 16)
        sv.layoutMargins = UIEdgeInsets(top: 12, left: 0, bottom: 24, right: 0)
        sv.isLayoutMarginsRelativeArrangement = true
        return sv
    }()

    // MARK: - Sticky Nav (scrollView 바깥 — 항상 상단에 고정)
    /// 월 타이틀 행. scrollView 위에 배치되어 캘린더가 완전히 접혀도 보임
    let stickyNavView = UIView()

    // MARK: - Public UI
    let calendarButton: UIButton = {
        var cfg = UIButton.Configuration.filled()
        cfg.title = "캘린더"
        cfg.image = UIImage(systemName: "calendar",
                            withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold))
        cfg.imagePadding = 4
        cfg.imagePlacement = .leading
        cfg.baseBackgroundColor = AppTheme.Color.primary
        cfg.baseForegroundColor = .white
        cfg.cornerStyle = .capsule
        cfg.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        cfg.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attr in
            var a = attr; a.font = .systemFont(ofSize: 13, weight: .semibold); return a
        }
        return UIButton(configuration: cfg)
    }()

    let listButton: UIButton = {
        var cfg = UIButton.Configuration.filled()
        cfg.title = "목록"
        cfg.image = UIImage(systemName: "list.bullet",
                            withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold))
        cfg.imagePadding = 4
        cfg.imagePlacement = .leading
        cfg.baseBackgroundColor = AppTheme.Color.primaryLight
        cfg.baseForegroundColor = AppTheme.Color.textMedium
        cfg.cornerStyle = .capsule
        cfg.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        cfg.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attr in
            var a = attr; a.font = .systemFont(ofSize: 13, weight: .semibold); return a
        }
        return UIButton(configuration: cfg)
    }()

    var calendarContainer    = UIView()
    var summaryCardContainer = UIView()

    let calendarCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let itemW  = (UIScreen.main.bounds.width - 40 - 6 * 6) / 7
        layout.itemSize                = CGSize(width: itemW, height: itemW + 10)
        layout.minimumInteritemSpacing = 6
        layout.minimumLineSpacing      = 2
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.isScrollEnabled = false
        cv.register(DayCell.self, forCellWithReuseIdentifier: DayCell.id)
        return cv
    }()

    let prevMonthButton: UIButton = {
        let btn = UIButton(type: .system)
        let cfg = UIImage.SymbolConfiguration(pointSize: 10, weight: .semibold)
        btn.setImage(UIImage(systemName: "chevron.left", withConfiguration: cfg), for: .normal)
        btn.tintColor = AppTheme.Color.primary
        btn.backgroundColor = AppTheme.Color.primaryLight
        btn.layer.cornerRadius = 16
        btn.snp.makeConstraints { $0.width.height.equalTo(32) }
        return btn
    }()

    let nextMonthButton: UIButton = {
        let btn = UIButton(type: .system)
        let cfg = UIImage.SymbolConfiguration(pointSize: 10, weight: .semibold)
        btn.setImage(UIImage(systemName: "chevron.right", withConfiguration: cfg), for: .normal)
        btn.tintColor = AppTheme.Color.primary
        btn.backgroundColor = AppTheme.Color.primaryLight
        btn.layer.cornerRadius = 16
        btn.snp.makeConstraints { $0.width.height.equalTo(32) }
        return btn
    }()

    let monthLabel = UILabel.make(text: "", size: 16, weight: .bold,
                                  color: AppTheme.Color.textDark, alignment: .center)

    // MARK: - Session list stored properties
    let sessionTitleLabel   = UILabel.make(text: "날짜를 선택하세요", size: 15,
                                           weight: .bold, color: AppTheme.Color.textDark)
    let sessionSummaryLabel = UILabel.make(text: "", size: 12, color: AppTheme.Color.textMuted)
    let rowsStack           = UIStackView.make(axis: .vertical, spacing: 8)
    let emptyStateView      = UIView()

    // MARK: - Collapse state
    /// 캘린더 그리드의 전체 높이 — VC가 스크롤 진행도 계산에 사용
    private(set) var calendarGridFullHeight: CGFloat = 0
    private var calendarGridConstraint:  Constraint?
    private var calendarHeightConstraint: Constraint?

    // MARK: - BaseView
    override func setupUI() {
        backgroundColor = AppTheme.Color.background
        setupStickyNav()    // 1) 고정 헤더 (scrollView 밖)
        setupScrollView()   // 2) scrollView = stickyNavView 아래부터
        buildContent()
    }

    // MARK: - Sticky Nav
    private func setupStickyNav() {
        stickyNavView.backgroundColor = AppTheme.Color.background

        let navRow = UIStackView.make(axis: .horizontal, alignment: .center)
        navRow.addArrangedSubview(prevMonthButton)
        navRow.addArrangedSubview(monthLabel)
        navRow.addArrangedSubview(nextMonthButton)

        stickyNavView.addSubview(navRow)
        navRow.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(8)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }

        addSubview(stickyNavView)
        stickyNavView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
        }
    }

    // MARK: - Layout
    private func setupScrollView() {
        addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            // stickyNavView 바로 아래에서 시작
            make.top.equalTo(stickyNavView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        scrollView.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.top.leading.trailing.bottom.equalToSuperview()
            make.width.equalTo(scrollView)
        }
    }

    private func buildContent() {
        contentStack.addArrangedSubview(makeHeader())
        contentStack.addArrangedSubview(makeToggle())
        contentStack.addArrangedSubview(makeCalendarSection())
        summaryCardContainer = makeSummaryCard()
        contentStack.addArrangedSubview(summaryCardContainer)
        contentStack.addArrangedSubview(makeSessionList())
    }

    // MARK: - Sections
    private func makeHeader() -> UIView {
        let v     = UIView()
        let title = UILabel.make(text: "활동 기록", size: 22, weight: .black, color: AppTheme.Color.textDark)
        let sub   = UILabel.make(text: "뮤기의 사냥 히스토리", size: 13, color: AppTheme.Color.textMuted)
        let stack = UIStackView.make(axis: .vertical, spacing: 2)
        stack.addArrangedSubview(title)
        stack.addArrangedSubview(sub)
        v.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }
        return v
    }

    private func makeToggle() -> UIView {
        let v     = UIView()
        let stack = UIStackView.make(axis: .horizontal, spacing: 8, distribution: .fillEqually)
        stack.addArrangedSubview(calendarButton)
        stack.addArrangedSubview(listButton)
        v.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.height.equalTo(44)
        }
        return v
    }

    func setToggleState(isCalendar: Bool) {
        var calCfg = calendarButton.configuration!
        calCfg.baseBackgroundColor = isCalendar ? AppTheme.Color.primary : AppTheme.Color.primaryLight
        calCfg.baseForegroundColor = isCalendar ? .white : AppTheme.Color.textMedium
        calendarButton.configuration = calCfg

        var listCfg = listButton.configuration!
        listCfg.baseBackgroundColor = isCalendar ? AppTheme.Color.primaryLight : AppTheme.Color.primary
        listCfg.baseForegroundColor = isCalendar ? AppTheme.Color.textMedium : .white
        listButton.configuration = listCfg
    }

    private func makeCalendarSection() -> UIView {
        // calendarContainer = 접히는 그리드 영역 (navRow는 stickyNavView로 이동)
        calendarContainer = UIView()
        calendarContainer.clipsToBounds = true  // 높이 축소 시 내용 클리핑

        let itemW = (UIScreen.main.bounds.width - 40 - 6 * 6) / 7

        // 요일 헤더
        let daysKR = ["일", "월", "화", "수", "목", "금", "토"]
        let dayHeaderRow = UIStackView.make(axis: .horizontal, spacing: 6)
        dayHeaderRow.snp.makeConstraints { $0.height.equalTo(16) }
        daysKR.enumerated().forEach { i, d in
            let l = UILabel.make(
                text: d, size: 11, weight: .bold,
                color: i == 0 ? AppTheme.Color.primary : i == 6 ? UIColor(hex: "#7BA7FF") : AppTheme.Color.textMuted,
                alignment: .center)
            l.snp.makeConstraints { $0.width.equalTo(itemW) }
            dayHeaderRow.addArrangedSubview(l)
        }

        // 컬렉션뷰 높이
        let cells = buildCalendarCells()
        let rows  = ceil(Double(cells.count) / 7.0)
        let calH  = CGFloat(rows) * (itemW + 10) + CGFloat(rows - 1) * 2
        calendarCollectionView.snp.makeConstraints { make in
            calendarHeightConstraint = make.height.equalTo(calH).constraint
        }

        // 그리드 스택 (dayHeader + collectionView) — calendarContainer 상단에 고정
        let gridStack = UIStackView.make(axis: .vertical, spacing: 8)
        gridStack.addArrangedSubview(dayHeaderRow)
        gridStack.addArrangedSubview(calendarCollectionView)
        calendarContainer.addSubview(gridStack)
        gridStack.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            // bottom은 잡지 않음 — height constraint가 calendarContainer 크기를 결정
        }

        // calendarContainer 전체 높이 (= 접힌/펼쳐진 기준)
        let gridFullH: CGFloat = 16 + 8 + calH   // dayHeaderH + spacing + calH
        calendarGridFullHeight = gridFullH
        calendarContainer.snp.makeConstraints { make in
            calendarGridConstraint = make.height.equalTo(gridFullH).constraint
        }

        // 좌우 패딩 wrapper
        let wrapper = UIView()
        wrapper.addSubview(calendarContainer)
        calendarContainer.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }
        return wrapper
    }

    // MARK: - Collapse API
    /// 스크롤 진행도(0=펼침, 1=완전 접힘)에 따라 캘린더 그리드 높이·투명도 조정
    func collapseCalendar(progress: CGFloat) {
        let p = min(1, max(0, progress))
        calendarGridConstraint?.update(offset: calendarGridFullHeight * (1 - p))
        calendarContainer.alpha = 1 - p
    }

    /// 월 변경 후 캘린더 높이 재계산 및 완전 펼침 복원
    func updateCalendarHeight() {
        let itemW = (UIScreen.main.bounds.width - 40 - 6 * 6) / 7
        let cells = buildCalendarCells()
        let rows  = ceil(Double(cells.count) / 7.0)
        let calH  = CGFloat(rows) * (itemW + 10) + CGFloat(rows - 1) * 2

        calendarHeightConstraint?.update(offset: calH)

        let gridFullH: CGFloat = 16 + 8 + calH
        calendarGridFullHeight = gridFullH
        calendarGridConstraint?.update(offset: gridFullH)  // 완전 펼침으로 복원
        calendarContainer.alpha = 1
        layoutIfNeeded()
    }

    private func makeSummaryCard() -> UIView {
        let card = UIView()
        card.backgroundColor   = AppTheme.Color.yellowLight
        card.layer.cornerRadius = AppTheme.Radius.large

        let stats: [(String, String, String)] = [
            ("🎯", "42회",    "총 사냥 횟수"),
            ("⏱️", "8.5시간", "총 시간"),
            ("📅", "18일",    "활동 일수"),
        ]
        let row = UIStackView.make(axis: .horizontal, distribution: .fillEqually)
        stats.forEach { emoji, value, label in
            let col = UIStackView.make(axis: .vertical, spacing: 2, alignment: .center)
            col.addArrangedSubview(UILabel.make(text: emoji, size: 18, alignment: .center))
            col.addArrangedSubview(UILabel.make(text: value, size: 14, weight: .bold,
                                                color: AppTheme.Color.textDark, alignment: .center))
            col.addArrangedSubview(UILabel.make(text: label, size: 10, color: UIColor(hex: "#9B7A00"), alignment: .center))
            row.addArrangedSubview(col)
        }
        card.addSubview(row)
        row.snp.makeConstraints { $0.edges.equalToSuperview().inset(12) }

        let wrapper = UIView()
        wrapper.addSubview(card)
        card.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }
        return wrapper
    }

    private func makeSessionList() -> UIView {
        let emptyStack = UIStackView.make(axis: .vertical, spacing: 8, alignment: .center)
        emptyStack.addArrangedSubview(UILabel.make(text: "🐾", size: 36, alignment: .center))
        emptyStack.addArrangedSubview(UILabel.make(text: "기록이 없습니다", size: 14,
                                                   color: AppTheme.Color.textMuted, alignment: .center))
        emptyStateView.addSubview(emptyStack)
        emptyStack.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(20)
            make.centerX.equalToSuperview()
        }
        emptyStateView.isHidden = true

        let headerRow = UIStackView.make(axis: .horizontal, alignment: .center)
        sessionSummaryLabel.setContentHuggingPriority(.required, for: .horizontal)
        headerRow.addArrangedSubview(sessionTitleLabel)
        headerRow.addArrangedSubview(sessionSummaryLabel)

        let contentSwitch = UIStackView.make(axis: .vertical, spacing: 0)
        contentSwitch.addArrangedSubview(rowsStack)
        contentSwitch.addArrangedSubview(emptyStateView)

        let lineView = UIView()
        lineView.backgroundColor   = AppTheme.Color.primaryLight
        lineView.layer.cornerRadius = 1

        let timelineContainer = UIView()
        timelineContainer.addSubview(lineView)
        timelineContainer.addSubview(contentSwitch)
        contentSwitch.snp.makeConstraints { $0.edges.equalToSuperview() }
        lineView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(24)
            make.top.equalToSuperview().offset(24)
            make.bottom.equalToSuperview().offset(-24)
            make.width.equalTo(2)
        }

        let mainStack = UIStackView.make(axis: .vertical, spacing: 12)
        mainStack.addArrangedSubview(headerRow)
        mainStack.addArrangedSubview(timelineContainer)

        let wrapper = UIView()
        wrapper.addSubview(mainStack)
        mainStack.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }
        return wrapper
    }

    /// 세션 목록 갱신 — 빈 배열이면 empty state 표시
    func reloadSessionRows(_ sessions: [HuntSession]) {
        rowsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if sessions.isEmpty {
            rowsStack.isHidden      = true
            emptyStateView.isHidden = false
            sessionSummaryLabel.text = ""
        } else {
            rowsStack.isHidden      = false
            emptyStateView.isHidden = true
            sessions.forEach { rowsStack.addArrangedSubview(makeTimelineRow($0)) }
        }
    }

    // MARK: - Timeline Row
    private func makeTimelineRow(_ session: HuntSession) -> UIView {
        let imgView = AsyncImageView(contentMode: .scaleAspectFill, cornerRadius: 14)
        imgView.loadImage(from: session.imageURL)
        imgView.layer.borderWidth = 2
        imgView.layer.borderColor = UIColor.white.cgColor
        imgView.snp.makeConstraints { $0.width.height.equalTo(48) }

        let card = UIView()
        card.applyCardStyle(cornerRadius: AppTheme.Radius.medium)

        let toyL  = UILabel.make(text: session.toy,  size: 13, weight: .bold, color: AppTheme.Color.textDark)
        let timeL = UILabel.make(text: session.time, size: 11, color: AppTheme.Color.textMuted)
        let textS = UIStackView.make(axis: .vertical, spacing: 2)
        textS.addArrangedSubview(toyL)
        textS.addArrangedSubview(timeL)

        let durationPill = makePillLabel("⏱ \(session.durationText)", bg: AppTheme.Color.primaryLight, fg: AppTheme.Color.primary)
        let calPill      = makePillLabel("🔥 \(session.calories)kcal", bg: AppTheme.Color.yellowLight, fg: AppTheme.Color.yellowDark)
        let pillStack    = UIStackView.make(axis: .vertical, spacing: 3, alignment: .trailing)
        pillStack.addArrangedSubview(durationPill)
        pillStack.addArrangedSubview(calPill)

        let innerRow = UIStackView.make(axis: .horizontal, spacing: 8, alignment: .center)
        innerRow.addArrangedSubview(textS)
        innerRow.addArrangedSubview(pillStack)
        card.addSubview(innerRow)
        innerRow.snp.makeConstraints { $0.edges.equalToSuperview().inset(12) }

        let outerRow = UIStackView.make(axis: .horizontal, spacing: 8, alignment: .center)
        outerRow.addArrangedSubview(imgView)
        outerRow.addArrangedSubview(card)
        return outerRow
    }

    private func makePillLabel(_ text: String, bg: UIColor, fg: UIColor) -> UIView {
        let pill  = UIView()
        pill.backgroundColor   = bg
        pill.layer.cornerRadius = 8
        let label = UILabel.make(text: text, size: 10, weight: .semibold, color: fg)
        pill.addSubview(label)
        label.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(3)
            make.leading.trailing.equalToSuperview().inset(6)
        }
        return pill
    }

    // MARK: - Calendar Data
    func buildCalendarCells() -> [Int?] {
        let cal      = Calendar(identifier: .gregorian)
        let comps    = DateComponents(calendar: .current, year: year, month: month + 1, day: 1)
        let firstDay = cal.component(.weekday, from: comps.date ?? Date()) - 1
        let daysInMonth = cal.range(of: .day, in: .month,
                                    for: DateComponents(calendar: .current, year: year, month: month + 1).date ?? Date())!.count
        var cells: [Int?] = Array(repeating: nil, count: firstDay)
        (1...daysInMonth).forEach { cells.append($0) }
        while cells.count % 7 != 0 { cells.append(nil) }
        return cells
    }
}
