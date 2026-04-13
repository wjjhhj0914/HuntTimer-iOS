import UIKit
import SnapKit

/// 프로필 이미지 변경 바텀 시트
/// - hasCurrentImage 가 true 일 때 "기본 이미지로 변경" 옵션이 추가됨
final class ProfileImagePickerBottomSheet: BaseViewController {

    // MARK: - Callbacks
    var onAlbum:        (() -> Void)?
    var onCamera:       (() -> Void)?
    var onResetDefault: (() -> Void)?

    // MARK: - State
    private let hasCurrentImage: Bool

    init(hasCurrentImage: Bool) {
        self.hasCurrentImage = hasCurrentImage
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle   = .crossDissolve
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - UI
    private let dimView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        v.alpha = 0
        return v
    }()

    private let sheetView: UIView = {
        let v = UIView()
        v.backgroundColor    = .white
        v.layer.cornerRadius = 28
        v.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return v
    }()

    private var sheetBottomConstraint: Constraint?

    // 옵션 수에 따른 동적 높이
    private var sheetHeight: CGFloat {
        let baseHeight: CGFloat = 24 + 64 + 1 + 16  // 핸들 + 헤더 + 구분선 + 하단 여백
        let rowHeight:  CGFloat = 72
        let rows: CGFloat       = hasCurrentImage ? 3 : 2
        let safeArea = (UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.bottom) ?? 0
        return baseHeight + rowHeight * rows + safeArea
    }

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

    // MARK: - Build Content

    private func buildSheetContent() {
        let stack = UIStackView.make(axis: .vertical, spacing: 0)
        stack.addArrangedSubview(makeHandle())
        stack.addArrangedSubview(makeHeader())
        stack.addArrangedSubview(makeSeparator())
        stack.addArrangedSubview(makeRows())

        sheetView.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }
    }

    private func makeHandle() -> UIView {
        let handle = UIView()
        handle.backgroundColor    = AppTheme.Color.primaryLight
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

    private func makeHeader() -> UIView {
        let titleL = UILabel.make(text: "프로필 사진 변경", size: 17, weight: .bold,
                                  color: AppTheme.Color.textDark)
        let row = UIView()
        row.addSubview(titleL)
        titleL.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.centerY.equalToSuperview()
        }
        row.snp.makeConstraints { $0.height.equalTo(56) }
        return row
    }

    private func makeSeparator() -> UIView {
        let v = UIView()
        v.backgroundColor = AppTheme.Color.separator
        v.snp.makeConstraints { $0.height.equalTo(1) }
        return v
    }

    private func makeRows() -> UIView {
        let container = UIView()
        let stack     = UIStackView.make(axis: .vertical, spacing: 0)
        container.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.trailing.equalToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }

        stack.addArrangedSubview(makeRow(
            symbol: "photo.fill",
            symbolBg: AppTheme.Color.primaryLight,
            symbolFg: AppTheme.Color.primary,
            title: "앨범에서 선택",
            action: #selector(albumTapped)
        ))
        stack.addArrangedSubview(makeRow(
            symbol: "camera.fill",
            symbolBg: AppTheme.Color.yellowLight,
            symbolFg: AppTheme.Color.yellowDark,
            title: "카메라로 촬영",
            action: #selector(cameraTapped)
        ))

        if hasCurrentImage {
            stack.addArrangedSubview(makeRow(
                symbol: "arrow.counterclockwise",
                symbolBg: UIColor(hex: "#FFF0F2"),
                symbolFg: UIColor.systemRed,
                title: "기본 이미지로 변경",
                titleColor: .systemRed,
                action: #selector(resetTapped)
            ))
        }

        return container
    }

    private func makeRow(symbol: String,
                         symbolBg: UIColor,
                         symbolFg: UIColor,
                         title: String,
                         titleColor: UIColor = AppTheme.Color.textDark,
                         action: Selector) -> UIView {
        let row = UIView()
        row.snp.makeConstraints { $0.height.equalTo(68) }

        let iconBG = UIView()
        iconBG.backgroundColor    = symbolBg
        iconBG.layer.cornerRadius = AppTheme.Radius.medium
        iconBG.snp.makeConstraints { $0.width.height.equalTo(44) }

        let cfg    = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        let iconIV = UIImageView(image: UIImage(systemName: symbol, withConfiguration: cfg))
        iconIV.tintColor    = symbolFg
        iconIV.contentMode  = .scaleAspectFit
        iconBG.addSubview(iconIV)
        iconIV.snp.makeConstraints { $0.center.equalToSuperview() }

        let titleL = UILabel.make(text: title, size: 15, weight: .semibold, color: titleColor)

        let chevronCfg = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        let chevronIV  = UIImageView(image: UIImage(systemName: "chevron.forward",
                                                    withConfiguration: chevronCfg))
        chevronIV.tintColor   = AppTheme.Color.textMuted
        chevronIV.contentMode = .scaleAspectFit

        row.addSubview(iconBG)
        row.addSubview(titleL)
        row.addSubview(chevronIV)

        iconBG.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.centerY.equalToSuperview()
        }
        titleL.snp.makeConstraints { make in
            make.leading.equalTo(iconBG.snp.trailing).offset(14)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(chevronIV.snp.leading).offset(-8)
        }
        chevronIV.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
        }

        // 탭 영역 전체에 인식기 부착
        let tap = UITapGestureRecognizer(target: self, action: action)
        row.isUserInteractionEnabled = true
        row.addGestureRecognizer(tap)

        return row
    }

    // MARK: - Row Actions

    @objc private func albumTapped() {
        dismissSheet { [weak self] in self?.onAlbum?() }
    }

    @objc private func cameraTapped() {
        dismissSheet { [weak self] in self?.onCamera?() }
    }

    @objc private func resetTapped() {
        dismissSheet { [weak self] in self?.onResetDefault?() }
    }

    @objc private func dimTapped() {
        dismissSheet()
    }

    // MARK: - Animation

    private func animateIn() {
        sheetBottomConstraint?.update(offset: 0)
        UIView.animate(withDuration: 0.35, delay: 0,
                       usingSpringWithDamping: 0.85, initialSpringVelocity: 0.2) {
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
