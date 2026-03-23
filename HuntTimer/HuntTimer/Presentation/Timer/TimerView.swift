import UIKit
import SnapKit

/// 타이머 화면 루트 뷰 — 모든 UI 선언과 SnapKit 레이아웃을 담당
final class TimerView: BaseView {

    // MARK: - Constants
    let presets = [5, 10, 15, 20, 30]

    // MARK: - Scroll (private)
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.alwaysBounceVertical = true
        sv.backgroundColor = AppTheme.Color.background
        return sv
    }()
    private let contentStack = UIStackView.make(axis: .vertical, spacing: 0)

    // MARK: - Background
    let bgImageView: AsyncImageView = {
        let iv = AsyncImageView(contentMode: .scaleAspectFill)
        iv.loadImage(from: "https://images.unsplash.com/photo-1744710835733-936ab49ee0b4?w=800")
        return iv
    }()
    let bgGradientView = UIView()

    // MARK: - Status Badge
    let statusDot: UIView = {
        let v = UIView()
        v.backgroundColor = AppTheme.Color.textMuted
        v.layer.cornerRadius = 5
        v.snp.makeConstraints { $0.width.height.equalTo(10) }
        return v
    }()
    let statusLabel = UILabel.make(text: "사냥 준비", size: 13, weight: .bold, color: AppTheme.Color.textDark)

    // MARK: - Gauge & Labels
    let gaugeView      = CircularTimerView()
    let elapsedLabel   = UILabel.make(text: "00:00", size: 28, weight: .black,
                                      color: AppTheme.Color.textDark, alignment: .center)
    let remainingLabel = UILabel.make(text: "15:00", size: 28, weight: .black,
                                      color: AppTheme.Color.textDark, alignment: .center)

    // MARK: - Preset & Controls
    let presetStack = UIStackView.make(axis: .horizontal, spacing: 8, distribution: .fillEqually)
    var presetButtons: [UIButton] = []

    let stopButton:  UIButton = makeControlButton(emoji: "⏹", bg: AppTheme.Color.primaryLight, fg: AppTheme.Color.primary)
    let moreButton:  UIButton = makeControlButton(emoji: "⬇", bg: AppTheme.Color.yellowLight, fg: AppTheme.Color.yellowDark)
    let startButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("▶", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 28)
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 22
        btn.clipsToBounds = true
        AppTheme.applyButtonShadow(to: btn)
        let grad = AppTheme.primaryGradient()
        btn.layer.insertSublayer(grad, at: 0)
        DispatchQueue.main.async {
            grad.frame = CGRect(x: 0, y: 0, width: 72, height: 72)
        }
        return btn
    }()

    // MARK: - BaseView
    override func setupUI() {
        backgroundColor = AppTheme.Color.background
        setupScrollView()
        buildContent()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if let gl = bgGradientView.layer.sublayers?.first as? CAGradientLayer {
            gl.frame = bgGradientView.bounds
        }
    }

    // MARK: - Layout
    private func setupScrollView() {
        addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        scrollView.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.top.leading.trailing.bottom.equalToSuperview()
            make.width.equalTo(scrollView)
        }
    }

    private func buildContent() {
        contentStack.addArrangedSubview(makeBgSection())
        contentStack.addArrangedSubview(makeBodySection())
    }

    private func makeBgSection() -> UIView {
        let container = UIView()
        container.snp.makeConstraints { $0.height.equalTo(220) }
        container.clipsToBounds = true
        container.addSubview(bgImageView)
        bgImageView.snp.makeConstraints { $0.edges.equalToSuperview() }

        let gradLayer = CAGradientLayer()
        gradLayer.colors     = [UIColor.clear.cgColor, AppTheme.Color.background.cgColor]
        gradLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradLayer.endPoint   = CGPoint(x: 0.5, y: 1.0)
        bgGradientView.isUserInteractionEnabled = false
        container.addSubview(bgGradientView)
        bgGradientView.snp.makeConstraints { $0.edges.equalToSuperview() }
        bgGradientView.layer.addSublayer(gradLayer)

        // Status badge
        let statusBadge = UIView()
        statusBadge.backgroundColor = UIColor(white: 1, alpha: 0.75)
        statusBadge.layer.cornerRadius = 16

        let statusRow = UIStackView.make(axis: .horizontal, spacing: 6, alignment: .center)
        statusRow.addArrangedSubview(statusDot)
        statusRow.addArrangedSubview(statusLabel)
        statusBadge.addSubview(statusRow)
        statusRow.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(8)
            make.leading.trailing.equalToSuperview().inset(12)
        }
        container.addSubview(statusBadge)
        statusBadge.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.leading.equalToSuperview().offset(16)
        }

        return container
    }

    private func makeBodySection() -> UIView {
        let bodyStack = UIStackView.make(axis: .vertical, spacing: 20)
        bodyStack.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 24, right: 20)
        bodyStack.isLayoutMarginsRelativeArrangement = true

        // Gauge wrapper
        let gaugeWrapper = UIView()
        gaugeWrapper.addSubview(gaugeView)
        gaugeView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(300)
        }
        gaugeWrapper.snp.makeConstraints { $0.height.equalTo(300) }

        // Clock row
        let elapsedHeader = UILabel.make(text: "🌸 경과", size: 12, weight: .semibold,
                                         color: AppTheme.Color.primary, alignment: .center)
        let dividerView   = UIView()
        dividerView.backgroundColor = AppTheme.Color.primaryLight
        dividerView.snp.makeConstraints { $0.width.equalTo(1).priority(.high) }
        let remainHeader  = UILabel.make(text: "⏳ 남은", size: 12, weight: .semibold,
                                         color: AppTheme.Color.yellowDark, alignment: .center)

        let leftCol  = UIStackView.make(axis: .vertical, spacing: 4, alignment: .center)
        leftCol.addArrangedSubview(elapsedHeader)
        leftCol.addArrangedSubview(elapsedLabel)

        let rightCol = UIStackView.make(axis: .vertical, spacing: 4, alignment: .center)
        rightCol.addArrangedSubview(remainHeader)
        rightCol.addArrangedSubview(remainingLabel)

        let clockRow = UIStackView.make(axis: .horizontal, spacing: 20, alignment: .center, distribution: .fillEqually)
        clockRow.addArrangedSubview(leftCol)
        clockRow.addArrangedSubview(dividerView)
        clockRow.addArrangedSubview(rightCol)
        dividerView.snp.makeConstraints { $0.height.equalTo(44) }

        // Presets
        let presetHeader = UILabel.make(text: "시간 설정", size: 12, color: AppTheme.Color.textMuted, alignment: .center)
        presets.forEach { min in
            let btn = UIButton(type: .system)
            btn.setTitle("\(min)분", for: .normal)
            btn.titleLabel?.font = .appFont(size: 13, weight: .bold)
            btn.tag = min
            btn.layer.cornerRadius = 14
            btn.clipsToBounds = true
            btn.snp.makeConstraints { $0.height.equalTo(32) }
            presetButtons.append(btn)
            presetStack.addArrangedSubview(btn)
        }

        // Control row
        let controlRow = UIStackView.make(axis: .horizontal, spacing: 16, alignment: .center, distribution: .fill)
        controlRow.addArrangedSubview(stopButton)
        controlRow.addArrangedSubview(startButton)
        controlRow.addArrangedSubview(moreButton)
        stopButton.snp.makeConstraints { $0.width.height.equalTo(56) }
        startButton.snp.makeConstraints { $0.width.height.equalTo(72) }
        moreButton.snp.makeConstraints { $0.width.height.equalTo(56) }

        let controlWrapper = UIView()
        controlWrapper.addSubview(controlRow)
        controlRow.snp.makeConstraints { $0.center.equalToSuperview() }
        controlWrapper.snp.makeConstraints { $0.height.equalTo(80) }

        [gaugeWrapper, clockRow, presetHeader, presetStack, controlWrapper, makeTipView()]
            .forEach { bodyStack.addArrangedSubview($0) }

        return bodyStack
    }

    // MARK: - Factories
    private static func makeControlButton(emoji: String, bg: UIColor, fg: UIColor) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(emoji, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 22)
        btn.backgroundColor = bg
        btn.setTitleColor(fg, for: .normal)
        btn.layer.cornerRadius = 16
        btn.clipsToBounds = true
        return btn
    }

    private func makeTipView() -> UIView {
        let v = UIView()
        v.backgroundColor = AppTheme.Color.yellowLight
        v.layer.cornerRadius = AppTheme.Radius.large
        let stack = UIStackView.make(axis: .horizontal, spacing: 8, alignment: .center)
        let emoji = UILabel.make(text: "💡", size: 20)
        let tip   = UILabel.make(text: "하루 30분 이상 놀아주면 뮤기의 스트레스가 줄어요!",
                                 size: 12, color: UIColor(hex: "#9B7A00"), lines: 0)
        stack.addArrangedSubview(emoji)
        stack.addArrangedSubview(tip)
        v.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(12) }
        return v
    }
}
