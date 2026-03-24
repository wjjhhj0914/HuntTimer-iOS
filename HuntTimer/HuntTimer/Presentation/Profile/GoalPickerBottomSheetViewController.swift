import UIKit
import SnapKit

/// 하루 사냥 목표 시간 선택 바텀시트 (RifxN 디자인 기준)
final class GoalPickerBottomSheetViewController: BaseViewController {

    // MARK: - Callback
    var onGoalSelected: ((Int) -> Void)?

    // MARK: - State
    private let minValue = 5
    private let maxValue = 120
    private var selectedMinutes: Int

    init(initialMinutes: Int = 30) {
        self.selectedMinutes = max(5, min(120, initialMinutes))
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
        v.backgroundColor   = .white
        v.layer.cornerRadius = 28
        v.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return v
    }()

    private let pickerView = UIPickerView()
    private var sheetBottomConstraint: Constraint?
    private let sheetHeight: CGFloat = 380

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
        pickerView.delegate   = self
        pickerView.dataSource = self
        let initialRow = selectedMinutes - minValue
        pickerView.selectRow(initialRow, inComponent: 0, animated: false)

        dimView.onTap(self, action: #selector(dimTapped))
    }

    // MARK: - Build Sheet
    private func buildSheetContent() {
        let handle    = makeHandle()
        let headerRow = makeHeaderRow()
        let sep       = makeSeparator()
        let subWrap   = makeSubtitleWrap()
        let picker    = makePickerWrap()

        let stack = UIStackView.make(axis: .vertical, spacing: 0)
        [handle, headerRow, sep, subWrap, picker].forEach { stack.addArrangedSubview($0) }

        sheetView.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }
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
        let titleL  = UILabel.make(text: "하루 사냥 목표", size: 17, weight: .bold,
                                   color: UIColor(hex: "#2D1B1B"))
        let doneBtn = UIButton(type: .system)
        doneBtn.setTitle("완료", for: .normal)
        doneBtn.setTitleColor(.white, for: .normal)
        doneBtn.titleLabel?.font   = .appFont(size: 15, weight: .semibold)
        doneBtn.backgroundColor    = AppTheme.Color.primary
        doneBtn.layer.cornerRadius = 18
        doneBtn.contentEdgeInsets  = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        doneBtn.snp.makeConstraints { $0.height.equalTo(36) }
        doneBtn.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)

        let row = UIView()
        row.addSubview(titleL)
        row.addSubview(doneBtn)
        titleL.snp.makeConstraints { $0.leading.equalToSuperview().offset(20); $0.centerY.equalToSuperview() }
        doneBtn.snp.makeConstraints { $0.trailing.equalToSuperview().offset(-20); $0.centerY.equalToSuperview() }
        row.snp.makeConstraints { $0.height.equalTo(56) }
        return row
    }

    private func makeSeparator() -> UIView {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#F0E4E8")
        v.snp.makeConstraints { $0.height.equalTo(1) }
        return v
    }

    private func makeSubtitleWrap() -> UIView {
        let subL = UILabel.make(text: "매일 목표 사냥 시간을 설정하세요", size: 13,
                                color: UIColor(hex: "#bfa2a2"))
        let wrap = UIView()
        wrap.addSubview(subL)
        subL.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(12)
            make.leading.equalToSuperview().offset(20)
        }
        return wrap
    }

    private func makePickerWrap() -> UIView {
        let wrap = UIView()
        wrap.snp.makeConstraints { $0.height.equalTo(200) }

        // 선택된 행 하이라이트 배경
        let highlight = UIView()
        highlight.backgroundColor   = UIColor(hex: "#FFF0F4")
        highlight.layer.cornerRadius = 12

        // "분" 단위 레이블
        let unitL = UILabel.make(text: "분", size: 20, weight: .semibold, color: AppTheme.Color.primary)

        wrap.addSubview(highlight)
        wrap.addSubview(pickerView)
        wrap.addSubview(unitL)

        highlight.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(40)
        }
        pickerView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.centerX.equalToSuperview().offset(-20)
            make.top.bottom.equalToSuperview()
            make.width.equalTo(120)
        }
        unitL.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(pickerView.snp.trailing).offset(2)
        }
        return wrap
    }

    // MARK: - Actions
    @objc private func dimTapped()  { dismissSheet() }

    @objc private func doneTapped() {
        dismissSheet { [weak self] in
            guard let self else { return }
            self.onGoalSelected?(self.selectedMinutes)
        }
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

// MARK: - UIPickerViewDataSource & Delegate
extension GoalPickerBottomSheetViewController: UIPickerViewDataSource, UIPickerViewDelegate {

    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        maxValue - minValue + 1
    }

    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        40
    }

    func pickerView(_ pickerView: UIPickerView,
                    viewForRow row: Int,
                    forComponent component: Int,
                    reusing view: UIView?) -> UIView {

        let label = (view as? UILabel) ?? UILabel()
        label.text          = "\(row + minValue)"
        label.textAlignment = .center

        let selectedRow = pickerView.selectedRow(inComponent: 0)
        let distance    = abs(row - selectedRow)

        switch distance {
        case 0:
            label.font      = .appFont(size: 24, weight: .bold)
            label.textColor = AppTheme.Color.primary
            label.alpha     = 1.0
        case 1:
            label.font      = .appFont(size: 20)
            label.textColor = UIColor(hex: "#9B7B7B")
            label.alpha     = 0.7
        default:
            label.font      = .appFont(size: 18)
            label.textColor = UIColor(hex: "#bfa2a2")
            label.alpha     = 0.5
        }
        return label
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedMinutes = row + minValue
        pickerView.reloadComponent(0)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
