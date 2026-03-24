import UIKit
import SnapKit

/// 생년월일 선택 바텀시트 (ehxo2 디자인 기준)
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
        v.backgroundColor   = UIColor(hex: "#fff5f8")
        v.layer.cornerRadius = 28
        v.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return v
    }()

    private let monthLabel = UILabel.make(text: "", size: 16, weight: .bold,
                                          color: UIColor(hex: "#2D1B1B"), alignment: .center)

    private var sheetBottomConstraint: Constraint?
    private let sheetHeight: CGFloat = 480

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
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

    // MARK: - Build Sheet
    private func buildSheetContent() {
        // Handle
        let handle     = makeHandle()
        let headerRow  = makeHeaderRow()
        let sep1       = makeSeparator(color: "#F0E4E8")
        let monthNav   = makeMonthNav()
        let dowHeader  = makeDayOfWeekHeader()
        let sep2       = makeSeparator(color: "#F5EEF0")
        let grid       = buildCalendarGrid()

        let stack = UIStackView.make(axis: .vertical, spacing: 0)
        [handle, headerRow, sep1, monthNav, dowHeader, sep2, grid].forEach { stack.addArrangedSubview($0) }

        sheetView.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }

        updateCalendar()
    }

    private func makeHandle() -> UIView {
        let handle = UIView()
        handle.backgroundColor   = UIColor(hex: "#D0C0C8")
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
        btn.titleLabel?.font = .appFont(size: 15, weight: .semibold)
        btn.backgroundColor   = AppTheme.Color.primary
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

        let nav = UIView()
        nav.addSubview(prevBtn)
        nav.addSubview(monthLabel)
        nav.addSubview(nextBtn)
        prevBtn.snp.makeConstraints { $0.leading.equalToSuperview().offset(16); $0.centerY.equalToSuperview() }
        monthLabel.snp.makeConstraints { $0.center.equalToSuperview() }
        nextBtn.snp.makeConstraints { $0.trailing.equalToSuperview().offset(-16); $0.centerY.equalToSuperview() }
        nav.snp.makeConstraints { $0.height.equalTo(52) }
        return nav
    }

    private func makeNavCircleButton(systemName: String) -> UIButton {
        let btn    = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        btn.setImage(UIImage(systemName: systemName, withConfiguration: config), for: .normal)
        btn.tintColor       = UIColor(hex: "#E8507A")
        btn.backgroundColor = UIColor(hex: "#FFF0F4")
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
        zip(days, colors).forEach { (day, color) in
            let l = UILabel.make(text: day, size: 13, weight: .semibold, color: color, alignment: .center)
            stack.addArrangedSubview(l)
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
                btn.titleLabel?.font    = .appFont(size: 15)
                btn.layer.cornerRadius  = 18
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

        let offset = calendar.component(.weekday, from: firstDay) - 1  // 0=일, 6=토
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

        let dates = calendarDates(for: currentMonth)
        for (i, btn) in dayButtons.enumerated() {
            guard i < dates.count, let date = dates[i] else {
                btn.setTitle("", for: .normal)
                btn.backgroundColor           = .clear
                btn.isUserInteractionEnabled  = false
                continue
            }

            let day      = calendar.component(.day, from: date)
            let col      = i % 7   // 0=일, 6=토
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

    // MARK: - Actions
    @objc private func dimTapped()   { dismissSheet() }

    @objc private func doneTapped() {
        dismissSheet { [weak self] in
            guard let self else { return }
            self.onDateSelected?(self.selectedDate)
        }
    }

    @objc private func prevMonth() {
        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
        updateCalendar()
    }

    @objc private func nextMonth() {
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
