import UIKit
import SnapKit

// MARK: - YearPickerCell

private final class YearPickerCell: UITableViewCell {
    static let id = "YearPickerCell"

    private let pillView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 12
        return v
    }()

    private let yearLabel: UILabel = {
        let l = UILabel()
        l.textAlignment = .center
        return l
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle  = .none
        contentView.addSubview(pillView)
        pillView.addSubview(yearLabel)
        pillView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(4)
            make.height.equalTo(40)
        }
        yearLabel.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(year: Int, isSelected: Bool, distanceFromSelected: Int) {
        yearLabel.text = "\(year)"
        if isSelected {
            pillView.backgroundColor = UIColor(hex: "#FF8FAB")
            yearLabel.textColor      = .white
            yearLabel.font           = .appFont(size: 16, weight: .bold)
            yearLabel.alpha          = 1
        } else {
            pillView.backgroundColor = .clear
            yearLabel.textColor      = UIColor(hex: "#3D2B2B")
            switch distanceFromSelected {
            case 1:
                yearLabel.font  = .appFont(size: 15)
                yearLabel.alpha = 0.75
            case 2:
                yearLabel.font  = .appFont(size: 15)
                yearLabel.alpha = 0.55
            default:
                yearLabel.font  = .appFont(size: 14)
                yearLabel.alpha = 1
            }
        }
    }
}

// MARK: - MonthPickerCell

private final class MonthPickerCell: UITableViewCell {
    static let id = "MonthPickerCell"

    private let pillView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 12
        return v
    }()

    private let monthLabel: UILabel = {
        let l = UILabel()
        l.textAlignment = .center
        return l
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle  = .none
        contentView.addSubview(pillView)
        pillView.addSubview(monthLabel)
        pillView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(4)
            make.height.equalTo(40)
        }
        monthLabel.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(month: String, isSelected: Bool, distanceFromSelected: Int) {
        monthLabel.text = month
        if isSelected {
            pillView.backgroundColor = UIColor(hex: "#FF8FAB")
            monthLabel.textColor     = .white
            monthLabel.font          = .appFont(size: 16, weight: .bold)
            monthLabel.alpha         = 1
        } else {
            pillView.backgroundColor = .clear
            monthLabel.textColor     = UIColor(hex: "#3D2B2B")
            switch distanceFromSelected {
            case 1:  monthLabel.font = .appFont(size: 15); monthLabel.alpha = 0.75
            case 2:  monthLabel.font = .appFont(size: 15); monthLabel.alpha = 0.55
            default: monthLabel.font = .appFont(size: 14); monthLabel.alpha = 1
            }
        }
    }
}

// MARK: - DatePickerBottomSheetViewController

/// 생년월일 선택 바텀시트 (ehxo2 디자인 기준)
/// 월 레이블 탭 → 년도 퀵점프 피커 오버레이 표시
final class DatePickerBottomSheetViewController: BaseViewController {

    // MARK: - Callback
    var onDateSelected: ((Date) -> Void)?

    // MARK: - State
    private var selectedDate: Date
    private var currentMonth: Date
    private var dayButtons: [UIButton] = []

    private var calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.firstWeekday = 1  // 일요일 시작
        return c
    }()

    init(initialDate: Date = Date()) {
        self.selectedDate = initialDate
        self.currentMonth = initialDate
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle   = .crossDissolve
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - UI
    private let dimView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.48)
        v.alpha = 0
        return v
    }()

    private let sheetView: UIView = {
        let v = UIView()
        v.backgroundColor    = UIColor(hex: "#fff5f8")
        v.layer.cornerRadius = 28
        v.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return v
    }()

    private let monthLabel = UILabel.make(text: "", size: 16, weight: .bold,
                                          color: UIColor(hex: "#2D1B1B"), alignment: .center)

    private var sheetBottomConstraint: Constraint?
    private let sheetHeight: CGFloat = 480

    // MARK: - Year / Month Picker State
    private var years: [Int] = []
    private var selectedYearIndex: Int = 0
    private let months: [String] = (1...12).map { "\($0)월" }
    private var selectedMonthIndex: Int = 0
    private var isYearPickerVisible = false

    // MARK: - Year Picker Views
    private let yearChevron: UIImageView = {
        let cfg = UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
        let iv  = UIImageView(image: UIImage(systemName: "chevron.down", withConfiguration: cfg))
        iv.tintColor   = UIColor(hex: "#E8507A")
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    /// 캘린더 영역을 반투명 흰색으로 덮는 오버레이 (피커 뒤 배경)
    private let calendarFrostView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        v.alpha = 0
        return v
    }()

    /// 그림자를 담당하는 컨테이너 (clipsToBounds OFF → 그림자 표시)
    private let yearPickerShadow: UIView = {
        let v = UIView()
        v.backgroundColor     = .white
        v.layer.cornerRadius  = 16
        v.layer.shadowColor   = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.09
        v.layer.shadowRadius  = 20
        v.layer.shadowOffset  = CGSize(width: 0, height: 4)
        v.alpha = 0
        return v
    }()

    private lazy var yearTableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor              = .white
        tv.separatorStyle               = .none
        tv.showsVerticalScrollIndicator = false
        tv.dataSource                   = self
        tv.delegate                     = self
        tv.register(YearPickerCell.self, forCellReuseIdentifier: YearPickerCell.id)
        return tv
    }()

    private lazy var monthTableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor              = .white
        tv.separatorStyle               = .none
        tv.showsVerticalScrollIndicator = false
        tv.dataSource                   = self
        tv.delegate                     = self
        tv.register(MonthPickerCell.self, forCellReuseIdentifier: MonthPickerCell.id)
        return tv
    }()

    private let yearRowHeight: CGFloat = 44
    private let visibleYearRows: Int   = 7

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        setupYearData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateIn()
    }

    // MARK: - BaseViewController
    override func setupHierarchy() {
        view.addSubview(dimView)
        view.addSubview(sheetView)
        buildSheetContent()
    }

    override func setupConstraints() {
        dimView.snp.makeConstraints { $0.edges.equalToSuperview() }
        sheetView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(sheetHeight)
            sheetBottomConstraint = make.bottom.equalToSuperview().offset(sheetHeight).constraint
        }
    }

    override func setupBind() {
        dimView.onTap(self, action: #selector(dimTapped))
    }

    // MARK: - Year Data
    private func setupYearData() {
        let currentYear = Calendar.current.component(.year, from: Date())
        years = Array((currentYear - 25)...currentYear)
        let selectedYear  = calendar.component(.year,  from: currentMonth)
        let selectedMonth = calendar.component(.month, from: currentMonth)
        selectedYearIndex  = years.firstIndex(of: selectedYear) ?? max(0, years.count - 1)
        selectedMonthIndex = selectedMonth - 1
    }

    // MARK: - Build Sheet
    private func buildSheetContent() {
        let handle    = makeHandle()
        let headerRow = makeHeaderRow()
        let sep1      = makeSeparator(color: "#F0E4E8")
        let monthNav  = makeMonthNav()
        let dowHeader = makeDayOfWeekHeader()
        let sep2      = makeSeparator(color: "#F5EEF0")
        let grid      = buildCalendarGrid()

        let stack = UIStackView.make(axis: .vertical, spacing: 0)
        [handle, headerRow, sep1, monthNav, dowHeader, sep2, grid].forEach { stack.addArrangedSubview($0) }

        sheetView.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }

        // ── Year Picker Overlay ──────────────────────────────────────
        // monthNav 아래부터 시작: handle(24) + header(56) + sep(1) + monthNav(52) = 133
        let pickerTopOffset: CGFloat = 133

        sheetView.addSubview(calendarFrostView)
        calendarFrostView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(pickerTopOffset)
            make.leading.trailing.bottom.equalToSuperview()
        }

        let pickerHeight = yearRowHeight * CGFloat(visibleYearRows)
        sheetView.addSubview(yearPickerShadow)
        yearPickerShadow.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(pickerTopOffset + 4)
            make.width.equalTo(260)
            make.height.equalTo(pickerHeight)
        }

        // 두 테이블뷰를 나란히 — clipWrapper가 cornerRadius 클리핑 담당
        let clipWrapper = UIView()
        clipWrapper.layer.cornerRadius = 16
        clipWrapper.clipsToBounds      = true
        clipWrapper.backgroundColor    = .white
        yearPickerShadow.addSubview(clipWrapper)
        clipWrapper.snp.makeConstraints { $0.edges.equalToSuperview() }

        let pickerDivider = UIView()
        pickerDivider.backgroundColor = UIColor(hex: "#F0E4E8")

        clipWrapper.addSubview(yearTableView)
        clipWrapper.addSubview(pickerDivider)
        clipWrapper.addSubview(monthTableView)

        pickerDivider.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.bottom.equalToSuperview()
            make.width.equalTo(1)
        }
        yearTableView.snp.makeConstraints { make in
            make.top.bottom.leading.equalToSuperview()
            make.trailing.equalTo(pickerDivider.snp.leading)
        }
        monthTableView.snp.makeConstraints { make in
            make.top.bottom.trailing.equalToSuperview()
            make.leading.equalTo(pickerDivider.snp.trailing)
        }

        // 오버레이 탭 → 피커 닫기
        calendarFrostView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(overlayTapped))
        )

        updateCalendar()
    }

    private func makeHandle() -> UIView {
        let handle = UIView()
        handle.backgroundColor    = UIColor(hex: "#D0C0C8")
        handle.layer.cornerRadius = 2.5

        let area = UIView()
        area.addSubview(handle)
        handle.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(40)
            make.height.equalTo(5)
        }
        area.snp.makeConstraints { $0.height.equalTo(24) }
        return area
    }

    private func makeHeaderRow() -> UIView {
        let titleL  = UILabel.make(text: "생년월일 선택", size: 17, weight: .bold,
                                   color: UIColor(hex: "#2D1B1B"))
        let doneBtn = makeDoneButton()
        doneBtn.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)

        let row = UIView()
        row.addSubview(titleL)
        row.addSubview(doneBtn)
        titleL.snp.makeConstraints { $0.leading.equalToSuperview().offset(20); $0.centerY.equalToSuperview() }
        doneBtn.snp.makeConstraints { $0.trailing.equalToSuperview().offset(-20); $0.centerY.equalToSuperview() }
        row.snp.makeConstraints { $0.height.equalTo(56) }
        return row
    }

    private func makeDoneButton() -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle("완료", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font   = .appFont(size: 15, weight: .semibold)
        btn.backgroundColor    = AppTheme.Color.primary
        btn.layer.cornerRadius = 18
        btn.contentEdgeInsets  = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        btn.snp.makeConstraints { $0.height.equalTo(36) }
        return btn
    }

    private func makeSeparator(color: String) -> UIView {
        let v = UIView()
        v.backgroundColor = UIColor(hex: color)
        v.snp.makeConstraints { $0.height.equalTo(1) }
        return v
    }

    private func makeMonthNav() -> UIView {
        let prevBtn = makeNavCircleButton(systemName: "chevron.left")
        let nextBtn = makeNavCircleButton(systemName: "chevron.right")
        prevBtn.addTarget(self, action: #selector(prevMonth), for: .touchUpInside)
        nextBtn.addTarget(self, action: #selector(nextMonth), for: .touchUpInside)

        // 월 레이블 + 다운 쉐브론 → 탭 시 년도 피커 표시
        yearChevron.snp.makeConstraints { $0.width.height.equalTo(14) }

        let labelStack = UIStackView.make(axis: .horizontal, spacing: 4, alignment: .center)
        labelStack.addArrangedSubview(monthLabel)
        labelStack.addArrangedSubview(yearChevron)
        labelStack.isUserInteractionEnabled = true
        labelStack.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(monthLabelTapped))
        )

        let nav = UIView()
        nav.addSubview(prevBtn)
        nav.addSubview(labelStack)
        nav.addSubview(nextBtn)
        prevBtn.snp.makeConstraints { $0.leading.equalToSuperview().offset(16); $0.centerY.equalToSuperview() }
        labelStack.snp.makeConstraints { $0.center.equalToSuperview() }
        nextBtn.snp.makeConstraints { $0.trailing.equalToSuperview().offset(-16); $0.centerY.equalToSuperview() }
        nav.snp.makeConstraints { $0.height.equalTo(52) }
        return nav
    }

    private func makeNavCircleButton(systemName: String) -> UIButton {
        let btn    = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        btn.setImage(UIImage(systemName: systemName, withConfiguration: config), for: .normal)
        btn.tintColor          = UIColor(hex: "#E8507A")
        btn.backgroundColor    = UIColor(hex: "#FFF0F4")
        btn.layer.cornerRadius = 18
        btn.snp.makeConstraints { $0.width.height.equalTo(36) }
        return btn
    }

    private func makeDayOfWeekHeader() -> UIView {
        let days   = ["일", "월", "화", "수", "목", "금", "토"]
        let colors: [UIColor] = [
            UIColor(hex: "#E8507A"),
            AppTheme.Color.textMedium,
            AppTheme.Color.textMedium,
            AppTheme.Color.textMedium,
            AppTheme.Color.textMedium,
            AppTheme.Color.textMedium,
            UIColor(hex: "#5B8FE8")
        ]
        let stack = UIStackView.make(axis: .horizontal, alignment: .center, distribution: .fillEqually)
        stack.snp.makeConstraints { $0.height.equalTo(36) }
        zip(days, colors).forEach { day, color in
            stack.addArrangedSubview(UILabel.make(text: day, size: 13, weight: .semibold,
                                                  color: color, alignment: .center))
        }
        return stack
    }

    private func buildCalendarGrid() -> UIView {
        let outer = UIStackView.make(axis: .vertical, distribution: .fillEqually)

        for row in 0..<6 {
            let rowStack = UIStackView.make(axis: .horizontal, alignment: .center, distribution: .fillEqually)
            rowStack.snp.makeConstraints { $0.height.equalTo(48) }

            for col in 0..<7 {
                let btn = UIButton(type: .system)
                btn.titleLabel?.font   = .appFont(size: 15)
                btn.layer.cornerRadius = 18
                btn.tag = row * 7 + col
                btn.addTarget(self, action: #selector(dayTapped(_:)), for: .touchUpInside)
                btn.snp.makeConstraints { $0.width.height.equalTo(36) }
                rowStack.addArrangedSubview(btn)
                dayButtons.append(btn)
            }
            outer.addArrangedSubview(rowStack)
        }

        let container = UIView()
        container.addSubview(outer)
        outer.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8))
        }
        return container
    }

    // MARK: - Calendar Logic
    private func calendarDates(for monthDate: Date) -> [Date?] {
        var comps = calendar.dateComponents([.year, .month], from: monthDate)
        comps.day = 1
        guard let firstDay = calendar.date(from: comps) else { return [] }

        let offset      = calendar.component(.weekday, from: firstDay) - 1  // 0=일, 6=토
        let daysInMonth = calendar.range(of: .day, in: .month, for: firstDay)!.count

        var dates: [Date?] = Array(repeating: nil, count: offset)
        for day in 1...daysInMonth {
            var dc = comps; dc.day = day
            dates.append(calendar.date(from: dc))
        }
        while dates.count < 42 { dates.append(nil) }
        return dates
    }

    private func updateCalendar() {
        let df = DateFormatter()
        df.locale     = Locale(identifier: "ko_KR")
        df.dateFormat = "yyyy년 M월"
        monthLabel.text = df.string(from: currentMonth)

        // selectedYearIndex / selectedMonthIndex 동기화
        let currentYear  = calendar.component(.year,  from: currentMonth)
        let currentMonth2 = calendar.component(.month, from: currentMonth)
        if let idx = years.firstIndex(of: currentYear) { selectedYearIndex = idx }
        selectedMonthIndex = currentMonth2 - 1

        let dates = calendarDates(for: currentMonth)
        for (i, btn) in dayButtons.enumerated() {
            guard i < dates.count, let date = dates[i] else {
                btn.setTitle("", for: .normal)
                btn.backgroundColor          = .clear
                btn.isUserInteractionEnabled = false
                continue
            }

            let day        = calendar.component(.day, from: date)
            let col        = i % 7
            let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)

            btn.setTitle("\(day)", for: .normal)
            btn.isUserInteractionEnabled = true

            if isSelected {
                btn.backgroundColor = AppTheme.Color.primary
                btn.setTitleColor(.white, for: .normal)
            } else {
                btn.backgroundColor = .clear
                switch col {
                case 0:  btn.setTitleColor(UIColor(hex: "#E8507A"), for: .normal)
                case 6:  btn.setTitleColor(UIColor(hex: "#5B8FE8"), for: .normal)
                default: btn.setTitleColor(UIColor(hex: "#3D2B2B"), for: .normal)
                }
            }
        }
    }

    // MARK: - Year Picker Show / Hide
    @objc private func monthLabelTapped() {
        isYearPickerVisible ? hideYearPicker() : showYearPicker()
    }

    @objc private func overlayTapped() {
        hideYearPicker()
    }

    private func showYearPicker() {
        isYearPickerVisible = true
        yearTableView.reloadData()
        monthTableView.reloadData()

        // 선택된 연도/월이 피커 중앙(3번째 위치)에 오도록 스크롤
        let topRow = max(0, selectedYearIndex - 3)
        yearTableView.scrollToRow(at: IndexPath(row: topRow, section: 0),
                                   at: .top, animated: false)
        let monthTopRow = max(0, selectedMonthIndex - 3)
        monthTableView.scrollToRow(at: IndexPath(row: monthTopRow, section: 0),
                                    at: .top, animated: false)

        UIView.animate(withDuration: 0.22, delay: 0, options: .curveEaseOut) {
            self.calendarFrostView.alpha = 1
            self.yearPickerShadow.alpha  = 1
            self.yearChevron.transform   = CGAffineTransform(rotationAngle: .pi)
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func hideYearPicker(animated: Bool = true) {
        isYearPickerVisible = false
        if animated {
            UIView.animate(withDuration: 0.18, delay: 0, options: .curveEaseIn) {
                self.calendarFrostView.alpha = 0
                self.yearPickerShadow.alpha  = 0
                self.yearChevron.transform   = .identity
            } completion: { _ in }
        } else {
            calendarFrostView.alpha = 0
            yearPickerShadow.alpha  = 0
            yearChevron.transform   = .identity
        }
    }

    // MARK: - Actions
    @objc private func dimTapped() { dismissSheet() }

    @objc private func doneTapped() {
        dismissSheet { [weak self] in
            guard let self else { return }
            self.onDateSelected?(self.selectedDate)
        }
    }

    @objc private func prevMonth() {
        guard !isYearPickerVisible else { return }
        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
        updateCalendar()
    }

    @objc private func nextMonth() {
        guard !isYearPickerVisible else { return }
        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        updateCalendar()
    }

    @objc private func dayTapped(_ sender: UIButton) {
        let dates = calendarDates(for: currentMonth)
        guard sender.tag < dates.count, let date = dates[sender.tag] else { return }
        selectedDate = date
        updateCalendar()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    // MARK: - Animation
    private func animateIn() {
        sheetBottomConstraint?.update(offset: 0)
        UIView.animate(withDuration: 0.35, delay: 0,
                       usingSpringWithDamping: 0.85, initialSpringVelocity: 0.2,
                       options: []) {
            self.dimView.alpha = 1
            self.view.layoutIfNeeded()
        }
    }

    func dismissSheet(completion: (() -> Void)? = nil) {
        sheetBottomConstraint?.update(offset: sheetHeight)
        UIView.animate(withDuration: 0.28, delay: 0, options: .curveEaseIn) {
            self.dimView.alpha = 0
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.dismiss(animated: false, completion: completion)
        }
    }
}

// MARK: - UITableViewDataSource / Delegate

extension DatePickerBottomSheetViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableView === yearTableView ? years.count : months.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView === yearTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: YearPickerCell.id,
                                                      for: indexPath) as! YearPickerCell
            cell.configure(year: years[indexPath.row],
                            isSelected: indexPath.row == selectedYearIndex,
                            distanceFromSelected: abs(indexPath.row - selectedYearIndex))
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: MonthPickerCell.id,
                                                      for: indexPath) as! MonthPickerCell
            cell.configure(month: months[indexPath.row],
                            isSelected: indexPath.row == selectedMonthIndex,
                            distanceFromSelected: abs(indexPath.row - selectedMonthIndex))
            return cell
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        yearRowHeight
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var comps = calendar.dateComponents([.year, .month], from: currentMonth)

        if tableView === yearTableView {
            // 년도 선택: 피커 유지, 달 선택을 기다림
            selectedYearIndex = indexPath.row
            comps.year = years[indexPath.row]
            if let newDate = calendar.date(from: comps) { currentMonth = newDate }
            yearTableView.reloadData()
            updateCalendar()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } else {
            // 달 선택: 피커 닫기
            selectedMonthIndex = indexPath.row
            comps.month = indexPath.row + 1
            if let newDate = calendar.date(from: comps) { currentMonth = newDate }
            monthTableView.reloadData()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                self?.hideYearPicker()
                self?.updateCalendar()
            }
        }
    }
}
