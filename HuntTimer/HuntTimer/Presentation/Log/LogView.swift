import UIKit
import SnapKit

/// 기록 화면 루트 뷰 — 모든 UI 선언과 SnapKit 레이아웃을 담당
final class LogView: BaseView {

    // MARK: - Calendar State (display-only)
    let year  = 2026
    let month = 2   // 0-indexed: March

    // MARK: - Scroll (private)
    private let scrollView: UIScrollView = {
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

    var calendarContainer = UIView()
    var summaryCardContainer = UIView()

    let calendarCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let itemW  = (UIScreen.main.bounds.width - 40 - 6 * 6) / 7
        // +10: label(top3+~14) + gap3 + image20 + gap2 + dot6 + selectionBg padding6 → compact
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
        // SF Symbol은 UIButton.system 기본값(center/center)으로 정중앙 배치됨
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

    // MARK: - BaseView
    override func setupUI() {
        backgroundColor = AppTheme.Color.background
        setupScrollView()
        buildContent()
    }

    // MARK: - Layout
    private func setupScrollView() {
        addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            // Safe Area 상단을 기준으로 잡아 Status Bar와 겹침 방지
            make.top.equalTo(safeAreaLayoutGuide.snp.top)
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
        let v = UIView()
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
        calendarContainer = UIView()

        let monthLabel = UILabel.make(text: "2026년 3월", size: 16, weight: .bold,
                                      color: AppTheme.Color.textDark, alignment: .center)

        let navRow = UIStackView.make(axis: .horizontal, alignment: .center)
        navRow.addArrangedSubview(prevMonthButton)
        navRow.addArrangedSubview(monthLabel)
        navRow.addArrangedSubview(nextMonthButton)

        // Calendar item width — 헤더와 그리드가 같은 itemW + 6pt 간격을 공유해야 열이 정렬됨
        let itemW = (UIScreen.main.bounds.width - 40 - 6 * 6) / 7

        // Day-of-week header: fillEqually 대신 itemW 고정 너비 + spacing 6으로 컬렉션뷰와 1:1 일치
        let daysKR = ["일", "월", "화", "수", "목", "금", "토"]
        let dayHeaderRow = UIStackView.make(axis: .horizontal, spacing: 6)
        daysKR.enumerated().forEach { i, d in
            let l = UILabel.make(
                text: d, size: 11, weight: .bold,
                color: i == 0 ? AppTheme.Color.primary : i == 6 ? UIColor(hex: "#7BA7FF") : AppTheme.Color.textMuted,
                alignment: .center)
            l.snp.makeConstraints { $0.width.equalTo(itemW) }
            dayHeaderRow.addArrangedSubview(l)
        }

        // Calendar height
        let cells  = buildCalendarCells()
        let rows   = ceil(Double(cells.count) / 7.0)
        // itemSize.height = itemW + 10 와 동일하게 유지
        let calH   = CGFloat(rows) * (itemW + 10) + CGFloat(rows - 1) * 2
        calendarCollectionView.snp.makeConstraints { $0.height.equalTo(calH) }

        let mainStack = UIStackView.make(axis: .vertical, spacing: 8)
        mainStack.addArrangedSubview(navRow)
        mainStack.addArrangedSubview(dayHeaderRow)
        mainStack.addArrangedSubview(calendarCollectionView)

        calendarContainer.addSubview(mainStack)
        mainStack.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }

        return calendarContainer
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
        let wrapper   = UIView()
        let headerRow = UIStackView.make(axis: .horizontal, alignment: .center)
        let titleL    = UILabel.make(text: "3월 19일 기록", size: 15, weight: .bold, color: AppTheme.Color.textDark)
        let subL      = UILabel.make(text: "총 5회 · 65분", size: 12, color: AppTheme.Color.textMuted)
        headerRow.addArrangedSubview(titleL)
        headerRow.addArrangedSubview(subL)

        let timelineContainer = UIView()
        let lineView = UIView()
        lineView.backgroundColor   = AppTheme.Color.primaryLight
        lineView.layer.cornerRadius = 1

        let rowsStack = UIStackView.make(axis: .vertical, spacing: 8)
        SampleData.sessions.forEach { session in
            rowsStack.addArrangedSubview(makeTimelineRow(session))
        }

        timelineContainer.addSubview(lineView)
        timelineContainer.addSubview(rowsStack)
        rowsStack.snp.makeConstraints { $0.edges.equalToSuperview() }
        lineView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(24)
            make.top.equalToSuperview().offset(24)
            make.bottom.equalToSuperview().offset(-24)
            make.width.equalTo(2)
        }

        let mainStack = UIStackView.make(axis: .vertical, spacing: 12)
        mainStack.addArrangedSubview(headerRow)
        mainStack.addArrangedSubview(timelineContainer)

        wrapper.addSubview(mainStack)
        mainStack.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }
        return wrapper
    }

    // MARK: - Timeline Row
    private func makeTimelineRow(_ session: HuntSession) -> UIView {
        let container = UIView()
        let imgView   = AsyncImageView(contentMode: .scaleAspectFill, cornerRadius: 14)
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
        container.addSubview(outerRow)
        outerRow.snp.makeConstraints { $0.edges.equalToSuperview() }
        return container
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
        let firstDay = Calendar(identifier: .gregorian)
            .component(.weekday, from: DateComponents(calendar: .current,
                                                      year: year, month: month + 1, day: 1).date ?? Date()) - 1
        let daysInMonth = Calendar(identifier: .gregorian)
            .range(of: .day, in: .month,
                   for: DateComponents(calendar: .current, year: year, month: month + 1).date ?? Date())!.count
        var cells: [Int?] = Array(repeating: nil, count: firstDay)
        (1...daysInMonth).forEach { cells.append($0) }
        while cells.count % 7 != 0 { cells.append(nil) }
        return cells
    }
}
