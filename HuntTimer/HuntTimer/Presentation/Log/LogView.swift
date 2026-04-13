import UIKit
import SnapKit

/// 기록 화면 루트 뷰 — 모든 UI 선언과 SnapKit 레이아웃을 담당
final class LogView: BaseView {

    // MARK: - Calendar State (mutable — VC가 월 이동 시 갱신)
    var year: Int  = Calendar.current.component(.year,  from: Date())
    var month: Int = Calendar.current.component(.month, from: Date()) - 1  // 0-indexed

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
        cfg.baseForegroundColor = AppTheme.Color.textDark
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


    // MARK: - Profile Button (makeHeader 에서 구성)
    let profileButton = UIButton(type: .system)

    // MARK: - Calendar month label (VC가 월 이동 시 갱신)
    let monthLabel = UILabel.make(text: "", size: 16, weight: .bold,
                                  color: AppTheme.Color.textDark, alignment: .center)

    // MARK: - Session list stored properties (VC가 직접 갱신)
    let sessionTitleLabel = UILabel.make(text: "날짜를 선택하세요", size: 18,
                                         weight: .black, color: AppTheme.Color.textDark)
    let rowsStack           = UIStackView.make(axis: .vertical, spacing: 8)
    let emptyStateView      = UIView()

    private var calendarHeightConstraint: Constraint?

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
        contentStack.addArrangedSubview(makeSessionList())
    }

    private func makeHeader() -> UIView {
        let wrapper = UIView()

        let titleLabel = UILabel.make(text: "활동 기록", size: 22, weight: .black,
                                       color: AppTheme.Color.textDark)

        let cfg = UIImage.SymbolConfiguration(pointSize: 22, weight: .regular)
        profileButton.setImage(UIImage(systemName: "person.circle", withConfiguration: cfg),
                               for: .normal)
        profileButton.tintColor = AppTheme.Color.primary

        let row = UIStackView.make(axis: .horizontal, alignment: .center)
        row.addArrangedSubview(titleLabel)
        row.addArrangedSubview(UIView())        // spacer
        row.addArrangedSubview(profileButton)

        wrapper.addSubview(row)
        row.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.bottom.equalToSuperview().offset(-4)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        return wrapper
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
        calCfg.baseForegroundColor = isCalendar ? AppTheme.Color.textDark : AppTheme.Color.textMedium
        calendarButton.configuration = calCfg

        var listCfg = listButton.configuration!
        listCfg.baseBackgroundColor = isCalendar ? AppTheme.Color.primaryLight : AppTheme.Color.primary
        listCfg.baseForegroundColor = isCalendar ? AppTheme.Color.textMedium : AppTheme.Color.textDark
        listButton.configuration = listCfg
    }

    private func makeCalendarSection() -> UIView {
        calendarContainer = UIView()

        let navRow = UIStackView.make(axis: .horizontal, alignment: .center)
        navRow.addArrangedSubview(prevMonthButton)
        navRow.addArrangedSubview(monthLabel)
        navRow.addArrangedSubview(nextMonthButton)

        let itemW = (UIScreen.main.bounds.width - 40 - 6 * 6) / 7

        let daysKR = ["일", "월", "화", "수", "목", "금", "토"]
        let dayHeaderRow = UIStackView.make(axis: .horizontal, spacing: 6)
        daysKR.enumerated().forEach { i, d in
            let l = UILabel.make(
                text: d, size: 11, weight: .bold,
                color: i == 0 ? AppTheme.Color.primary : i == 6 ? AppTheme.Color.purpleDeep : AppTheme.Color.textMuted,
                alignment: .center)
            l.snp.makeConstraints { $0.width.equalTo(itemW) }
            dayHeaderRow.addArrangedSubview(l)
        }

        let cells = buildCalendarCells()
        let rows  = ceil(Double(cells.count) / 7.0)
        let calH  = CGFloat(rows) * (itemW + 10) + CGFloat(rows - 1) * 2
        calendarCollectionView.snp.makeConstraints { make in
            calendarHeightConstraint = make.height.equalTo(calH).constraint
        }

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

    /// 월이 변경되었을 때 컬렉션뷰 높이를 재계산
    func updateCalendarHeight() {
        let itemW = (UIScreen.main.bounds.width - 40 - 6 * 6) / 7
        let cells = buildCalendarCells()
        let rows  = ceil(Double(cells.count) / 7.0)
        let calH  = CGFloat(rows) * (itemW + 10) + CGFloat(rows - 1) * 2
        calendarHeightConstraint?.update(offset: calH)
        layoutIfNeeded()
    }

    private func makeSessionList() -> UIView {
        // emptyStateView: content drives height (top/bottom inset → no height conflict)
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
        headerRow.addArrangedSubview(sessionTitleLabel)

        // contentSwitch: UIStackView이므로 isHidden인 뷰를 자동 collapse
        // → rowsStack/emptyStateView 양쪽을 edges로 쓰는 충돌을 방지
        let contentSwitch = UIStackView.make(axis: .vertical, spacing: 0)
        contentSwitch.addArrangedSubview(rowsStack)
        contentSwitch.addArrangedSubview(emptyStateView)

        // ⚠️ 글로벌 lineView 제거 — 각 고양이 섹션별 독립 라인은 makeCatSessionsBlock에서 생성
        let mainStack = UIStackView.make(axis: .vertical, spacing: 12)
        mainStack.addArrangedSubview(headerRow)
        mainStack.addArrangedSubview(contentSwitch)

        let wrapper = UIView()
        wrapper.addSubview(mainStack)
        mainStack.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }
        return wrapper
    }

    /// 삭제 버튼 탭 콜백 — LogViewController에서 주입 (index: 탭된 세션의 순서)
    var onDeleteTap: ((Int) -> Void)?

    /// 현재 스와이프로 열린 행의 콘텐츠 뷰 (weak — 행 제거 시 자동 nil)
    private weak var currentSwipeContent: UIView?

    private let swipeRevealWidth: CGFloat = 60

    /// 고양이별 그룹 세션 목록을 갱신 — 빈 배열이면 empty state 표시
    func reloadSessionRows(_ groups: [CatSessionGroup]) {
        currentSwipeContent = nil
        rowsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let hasAny = groups.contains { !$0.items.isEmpty }
        if !hasAny {
            rowsStack.isHidden      = true
            emptyStateView.isHidden = false
        } else {
            rowsStack.isHidden      = false
            emptyStateView.isHidden = true

            groups.enumerated().forEach { groupIdx, group in
                // H2 헤더
                rowsStack.addArrangedSubview(makeCatSectionHeader(group.catName))

                // 세션 블록 (2개 이상일 때만 연결선 표시)
                let block = makeCatSessionsBlock(group.items)
                rowsStack.addArrangedSubview(block)

                // 마지막 그룹 이외엔 다음 그룹과의 간격을 넓힘
                if groupIdx < groups.count - 1 {
                    rowsStack.setCustomSpacing(20, after: block)
                }
            }
        }
    }

    // MARK: - Cat Section Timeline Block

    /// 세션 행들을 타임라인 선과 함께 감싸는 컨테이너 — 2개 이상일 때만 연결선 표시
    private func makeCatSessionsBlock(_ items: [(session: HuntSession, playSessionIndex: Int)]) -> UIView {
        let innerStack = UIStackView.make(axis: .vertical, spacing: 8)
        items.forEach { item in
            innerStack.addArrangedSubview(makeTimelineRow(item.session, index: item.playSessionIndex))
        }

        let lineView = UIView()
        lineView.backgroundColor    = AppTheme.Color.primaryLight
        lineView.layer.cornerRadius = 1
        lineView.isHidden           = items.count < 2   // 1개면 선 숨김

        let container = UIView()
        container.addSubview(lineView)
        container.addSubview(innerStack)

        innerStack.snp.makeConstraints { $0.edges.equalToSuperview() }
        lineView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(24)   // 아이콘 중심(48/2)
            make.top.equalToSuperview().offset(24)       // 첫 아이콘 중심
            make.bottom.equalToSuperview().offset(-24)   // 마지막 아이콘 중심
            make.width.equalTo(2)
        }
        return container
    }

    // MARK: - Cat Section H2 Header

    private func makeCatSectionHeader(_ catName: String) -> UIView {
        let cfg  = UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
        let icon = UIImageView(image: UIImage(systemName: "pawprint.fill", withConfiguration: cfg))
        icon.tintColor   = AppTheme.Color.primary
        icon.contentMode = .scaleAspectFit
        icon.snp.makeConstraints { $0.width.height.equalTo(13) }

        let label = UILabel.make(text: "\(catName)의 사냥 기록", size: 13, weight: .bold,
                                  color: AppTheme.Color.textDark)

        let row = UIStackView.make(axis: .horizontal, spacing: 6, alignment: .center)
        row.addArrangedSubview(icon)
        row.addArrangedSubview(label)

        let container = UIView()
        container.addSubview(row)
        row.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(4)
            make.bottom.equalToSuperview().offset(-4)
            make.leading.trailing.equalToSuperview()
        }
        return container
    }

    // MARK: - Timeline Row
    private func makeTimelineRow(_ session: HuntSession, index: Int) -> UIView {
        let symCfg  = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        let imgView = UIImageView(image: UIImage(systemName: session.toySymbol,
                                                  withConfiguration: symCfg))
        imgView.contentMode       = .center
        imgView.tintColor         = AppTheme.Color.primary
        imgView.backgroundColor   = AppTheme.Color.primaryLight
        imgView.layer.cornerRadius = 14
        imgView.clipsToBounds     = true
        imgView.layer.borderWidth = 2
        imgView.layer.borderColor = UIColor.white.cgColor
        imgView.snp.makeConstraints { $0.width.height.equalTo(48) }

        let card = UIView()
        card.applyCardStyle(cornerRadius: AppTheme.Radius.medium)

        let toyL  = UILabel.make(text: session.title, size: 13, weight: .bold, color: AppTheme.Color.textDark)
        let timeL = UILabel.make(text: session.time, size: 11, color: AppTheme.Color.textMuted)
        let textS = UIStackView.make(axis: .vertical, spacing: 2)
        textS.addArrangedSubview(toyL)
        textS.addArrangedSubview(timeL)

        let durationPill = makePillWithSymbol("clock.fill",  text: session.durationText,       bg: AppTheme.Color.yellowLight, fg: AppTheme.Color.yellowDark)
        let calPill      = makePillWithSymbol("flame.fill",  text: "\(session.calories)kcal",  bg: AppTheme.Color.yellowLight,  fg: AppTheme.Color.yellowDark)
        let pillStack    = UIStackView.make(axis: .vertical, spacing: 3, alignment: .trailing)
        pillStack.addArrangedSubview(durationPill)
        pillStack.addArrangedSubview(calPill)

        let innerRow = UIStackView.make(axis: .horizontal, spacing: 8, alignment: .center)
        innerRow.addArrangedSubview(textS)
        innerRow.addArrangedSubview(pillStack)
        card.addSubview(innerRow)
        innerRow.snp.makeConstraints { $0.edges.equalToSuperview().inset(12) }

        // 콘텐츠 (스와이프로 왼쪽으로 밀리는 부분)
        let outerRow = UIStackView.make(axis: .horizontal, spacing: 8, alignment: .center)
        outerRow.addArrangedSubview(imgView)
        outerRow.addArrangedSubview(card)
        outerRow.tag = 100   // handleRowPan에서 viewWithTag(100)으로 탐색

        // 삭제 버튼 (outerRow 뒤에 숨어 있다가 스와이프 시 노출)
        let delCfg    = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        let deleteBtn = UIButton(type: .system)
        deleteBtn.setImage(UIImage(systemName: "minus.circle.fill", withConfiguration: delCfg), for: .normal)
        deleteBtn.tintColor = .systemRed
        deleteBtn.tag = index
        deleteBtn.addTarget(self, action: #selector(deleteRowTapped(_:)), for: .touchUpInside)

        let deleteWrapper = UIView()
        deleteWrapper.addSubview(deleteBtn)
        deleteBtn.snp.makeConstraints { $0.center.equalToSuperview() }

        // 컨테이너: outerRow가 왼쪽으로 밀리면 오른쪽 deleteWrapper가 드러남
        let container = UIView()
        container.clipsToBounds = true
        container.addSubview(deleteWrapper)   // z-order 하단 (outerRow 뒤)
        container.addSubview(outerRow)        // z-order 상단 (초기에 deleteWrapper 덮음)

        outerRow.snp.makeConstraints { $0.edges.equalToSuperview() }
        deleteWrapper.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.trailing.equalToSuperview()
            make.width.equalTo(swipeRevealWidth)
        }

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleRowPan(_:)))
        pan.delegate = self
        container.addGestureRecognizer(pan)

        return container
    }

    @objc private func handleRowPan(_ sender: UIPanGestureRecognizer) {
        guard let container = sender.view,
              let content   = container.viewWithTag(100) else { return }

        let dx = sender.translation(in: container).x
        sender.setTranslation(.zero, in: container)

        switch sender.state {
        case .began:
            // 다른 열린 행이 있으면 닫기
            if let prev = currentSwipeContent, prev !== content {
                UIView.animate(withDuration: 0.2) { prev.transform = .identity }
            }
        case .changed:
            let newTx = max(-swipeRevealWidth, min(0, content.transform.tx + dx))
            content.transform = CGAffineTransform(translationX: newTx, y: 0)
        case .ended, .cancelled:
            let vel        = sender.velocity(in: container)
            let shouldOpen = content.transform.tx < -(swipeRevealWidth / 2) || vel.x < -400
            UIView.animate(withDuration: 0.3, delay: 0,
                           usingSpringWithDamping: 0.8, initialSpringVelocity: 0.3,
                           options: .allowUserInteraction) {
                content.transform = shouldOpen
                    ? CGAffineTransform(translationX: -self.swipeRevealWidth, y: 0)
                    : .identity
            }
            currentSwipeContent = shouldOpen ? content : nil
        default:
            break
        }
    }

    @objc private func deleteRowTapped(_ sender: UIButton) {
        UIView.animate(withDuration: 0.2) {
            self.currentSwipeContent?.transform = .identity
        }
        currentSwipeContent = nil
        onDeleteTap?(sender.tag)
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

    private func makePillWithSymbol(_ symbolName: String, text: String, bg: UIColor, fg: UIColor) -> UIView {
        let pill = UIView()
        pill.backgroundColor    = bg
        pill.layer.cornerRadius = 8

        let cfg  = UIImage.SymbolConfiguration(pointSize: 9, weight: .semibold)
        let icon = UIImageView(image: UIImage(systemName: symbolName, withConfiguration: cfg))
        icon.tintColor   = fg
        icon.contentMode = .scaleAspectFit

        let label = UILabel.make(text: text, size: 10, weight: .semibold, color: fg)

        let row = UIStackView.make(axis: .horizontal, spacing: 3, alignment: .center)
        row.addArrangedSubview(icon)
        row.addArrangedSubview(label)
        icon.snp.makeConstraints { $0.width.height.equalTo(10) }

        pill.addSubview(row)
        row.snp.makeConstraints { make in
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

// MARK: - UIGestureRecognizerDelegate (수직 스크롤과 충돌 방지)
extension LogView: UIGestureRecognizerDelegate {
    override func gestureRecognizerShouldBegin(_ gr: UIGestureRecognizer) -> Bool {
        guard let pan = gr as? UIPanGestureRecognizer else { return true }
        let vel = pan.velocity(in: gr.view)
        return abs(vel.x) > abs(vel.y)   // 수평 스와이프일 때만 활성화
    }
}
