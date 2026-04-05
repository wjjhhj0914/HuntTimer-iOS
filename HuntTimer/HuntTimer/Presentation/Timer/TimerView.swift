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
//    let bgImageView: AsyncImageView = {
//        let iv = AsyncImageView(contentMode: .scaleAspectFill)
//        iv.loadImage(from: "https://images.unsplash.com/photo-1744710835733-936ab49ee0b4?w=800")
//        return iv
//    }()
//    let bgGradientView = UIView()

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
    /// 게이지 내부 상단 — 경과 시간 (20pt, pink)
    let elapsedLabel   = UILabel.make(text: "00:00", size: 20, weight: .black,
                                      color: AppTheme.Color.primary, alignment: .center)
    /// 게이지 내부 하단 — 남은 시간 (42pt, pink)
    let remainingLabel = UILabel.make(text: "15:00", size: 42, weight: .black,
                                      color: AppTheme.Color.primary, alignment: .center)

    // MARK: - Toy Chips
    private(set) var toyChipButtons:   [UIButton]    = []
    private(set) var toyChipIconViews: [UIImageView] = []
    private(set) var toyChipLabels:    [UILabel]     = []

    // MARK: - Tip
    let tipLabel = UILabel.make(text: "하루 30분 이상 놀아주면 냥이의 스트레스가 줄어요!",
                                size: 12, color: AppTheme.Color.textMuted, lines: 0)

    // MARK: - Preset & Controls
    let presetStack = UIStackView.make(axis: .horizontal, spacing: 8, distribution: .fillEqually)
    var presetButtons: [UIButton] = []

    let stopButton:  UIButton = makeControlButton(systemName: "stop.fill",  pointSize: 22, bg: AppTheme.Color.primaryLight, fg: AppTheme.Color.primary)
    let moreButton:  UIButton = makeControlButton(systemName: "pause.fill", pointSize: 22, bg: AppTheme.Color.yellowLight,  fg: AppTheme.Color.yellowDark)

    // CAGradientLayer를 버튼 레이어에 직접 삽입하면 imageView 렌더링과 충돌 → 이미지로 미리 렌더링
    let startButton: UIButton = {
        let btn = UIButton(type: .custom)

        // 그라디언트를 72×72 이미지로 렌더링 → backgroundImage로 설정
        let size = CGSize(width: 72, height: 72)
        let gradLayer = AppTheme.primaryGradient()
        gradLayer.frame = CGRect(origin: .zero, size: size)
        let renderer = UIGraphicsImageRenderer(size: size)
        let gradImage = renderer.image { ctx in gradLayer.render(in: ctx.cgContext) }
        btn.setBackgroundImage(gradImage, for: .normal)

        // play 아이콘 — .alwaysOriginal로 흰색 고정 (tintColor 상속 무관)
        let symConfig = UIImage.SymbolConfiguration(pointSize: 30, weight: .bold)
        let icon = UIImage(systemName: "play.fill", withConfiguration: symConfig)?
            .withTintColor(.white, renderingMode: .alwaysOriginal)
        btn.setImage(icon, for: .normal)

        btn.layer.cornerRadius = 20
        btn.clipsToBounds = true
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

        // Status badge (이미지 제거, 배지만 유지)
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
            make.bottom.equalToSuperview().offset(-14)
            make.leading.equalToSuperview().offset(16)
        }

        return container
    }

    private func makeBodySection() -> UIView {
        let bodyStack = UIStackView.make(axis: .vertical, spacing: 20)
        bodyStack.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 24, right: 20)
        bodyStack.isLayoutMarginsRelativeArrangement = true

        // Gauge — gaugeWrapper 위에 레이블 오버레이 (gaugeView의 sublayer 제거 사이클에 영향받지 않도록)
        let gaugeWrapper = UIView()
        gaugeWrapper.addSubview(gaugeView)
        gaugeView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(220)
        }

        let timerLabels = UIStackView.make(axis: .vertical, spacing: 4, alignment: .center)
        timerLabels.addArrangedSubview(elapsedLabel)
        timerLabels.addArrangedSubview(remainingLabel)
        timerLabels.isUserInteractionEnabled = false
        gaugeWrapper.addSubview(timerLabels)
        timerLabels.snp.makeConstraints { $0.center.equalToSuperview() }

        gaugeWrapper.snp.makeConstraints { $0.height.equalTo(220) }

        // "시간 설정" 헤더 — 좌측 정렬, bold 13pt
        let presetHeader = UILabel.make(text: "시간 설정", size: 13, weight: .bold, color: AppTheme.Color.textDark)

        // Preset buttons
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

        [gaugeWrapper, presetHeader, presetStack, makeToySection(), controlWrapper, makeTipView()]
            .forEach { bodyStack.addArrangedSubview($0) }

        return bodyStack
    }

    private func makeToySection() -> UIView {
        let sectionStack = UIStackView.make(axis: .vertical, spacing: 8)

        // 헤더
        let headerRow = UIStackView.make(axis: .horizontal, spacing: 4, alignment: .center)
        let titleL = UILabel.make(text: "장난감 선택 영역", size: 13, weight: .bold, color: AppTheme.Color.textDark)
        let optL   = UILabel.make(text: "(선택 사항)", size: 11, color: AppTheme.Color.textMuted)
        titleL.setContentHuggingPriority(.required, for: .horizontal)
        optL.setContentHuggingPriority(.required, for: .horizontal)
        let headerSpacer = UIView()
        headerRow.addArrangedSubview(titleL)
        headerRow.addArrangedSubview(optL)
        headerRow.addArrangedSubview(headerSpacer)

        // 칩 행
        let chipsRow = UIStackView.make(axis: .horizontal, spacing: 5, distribution: .fillEqually)
        let items: [(icon: String, label: String, muted: Bool)] = [
            ("leaf.fill",   "깃털", false),
            ("ant.fill",    "벌레", false),
            ("bolt.fill",   "레이저",      false),
            ("timelapse", "카샤카샤",     false),
            ("oar.2.crossed",   "오뎅꼬치",        false),
            ("xmark",       "선택 안 함",  true),
        ]
        toyChipButtons.removeAll()
        toyChipIconViews.removeAll()
        toyChipLabels.removeAll()
        items.enumerated().forEach { idx, item in
            let (btn, iconView, lbl) = makeToyChip(iconName: item.icon, labelText: item.label,
                                                    tag: idx, muted: item.muted)
            toyChipButtons.append(btn)
            toyChipIconViews.append(iconView)
            toyChipLabels.append(lbl)
            chipsRow.addArrangedSubview(btn)
        }

        sectionStack.addArrangedSubview(headerRow)
        sectionStack.addArrangedSubview(chipsRow)
        return sectionStack
    }

    private func makeToyChip(iconName: String, labelText: String,
                              tag: Int, muted: Bool) -> (UIButton, UIImageView, UILabel) {
        let btn = UIButton(type: .custom)
        btn.tag = tag
        btn.backgroundColor = AppTheme.Color.primaryLight
        btn.layer.cornerRadius = 12
        btn.clipsToBounds = true
        btn.alpha = 0.6

        let fgColor: UIColor = muted ? AppTheme.Color.textMuted : AppTheme.Color.primary

        let symCfg   = UIImage.SymbolConfiguration(pointSize: 10, weight: .semibold)
        let iconView = UIImageView(image: UIImage(systemName: iconName, withConfiguration: symCfg)?
                                    .withRenderingMode(.alwaysTemplate))
        iconView.tintColor            = fgColor
        iconView.contentMode          = .scaleAspectFit
        iconView.isUserInteractionEnabled = false

        let lbl = UILabel()
        lbl.text          = labelText
        lbl.font          = .appFont(size: 8, weight: .semibold)
        lbl.textColor     = fgColor
        lbl.textAlignment = .center
        lbl.numberOfLines = 2
        lbl.isUserInteractionEnabled = false

        let chipStack = UIStackView.make(axis: .vertical, spacing: 2, alignment: .center)
        chipStack.addArrangedSubview(iconView)
        chipStack.addArrangedSubview(lbl)
        chipStack.isUserInteractionEnabled = false

        // 뷰 계층 완성 후 제약 설치 (iconView → chipStack → btn 순서 완료 후)
        btn.addSubview(chipStack)
        iconView.snp.makeConstraints  { $0.width.height.equalTo(12) }
        chipStack.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(4)
            make.leading.trailing.equalToSuperview().inset(4)
        }

        return (btn, iconView, lbl)
    }

    // MARK: - Factories
    private static func makeControlButton(systemName: String, pointSize: CGFloat, bg: UIColor, fg: UIColor) -> UIButton {
        let btn = UIButton(type: .system)
        let symConfig = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .bold)
        btn.setImage(UIImage(systemName: systemName, withConfiguration: symConfig), for: .normal)
        btn.tintColor = fg
        btn.backgroundColor = bg
        btn.layer.cornerRadius = 16
        btn.clipsToBounds = true
        return btn
    }

    private func makeTipView() -> UIView {
        let v = UIView()
        v.backgroundColor = AppTheme.Color.yellowLight
        v.layer.cornerRadius = AppTheme.Radius.large
        let stack = UIStackView.make(axis: .horizontal, spacing: 8, alignment: .center)
        let symCfg  = UIImage.SymbolConfiguration(pointSize: 10, weight: .semibold)
        let bulbIcon = UIImageView(image: UIImage(systemName: "lightbulb.max", withConfiguration: symCfg))
        bulbIcon.tintColor = AppTheme.Color.textMuted
        bulbIcon.setContentHuggingPriority(.required, for: .horizontal)
        stack.addArrangedSubview(bulbIcon)
        stack.addArrangedSubview(tipLabel)
        v.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(14) }
        return v
    }
}
