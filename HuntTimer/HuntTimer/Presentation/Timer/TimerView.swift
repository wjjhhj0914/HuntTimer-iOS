import UIKit
import SnapKit

/// 타이머 화면 루트 뷰 — 카드 기반 레이아웃 (타이머 / 장난감 / 고양이 선택)
final class TimerView: BaseView {

    // MARK: - Constants
    let presets = [5, 10, 15, 20, 30]

    // MARK: - Scroll
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.alwaysBounceVertical         = true
        return sv
    }()
    private let contentStack = UIStackView.make(axis: .vertical, spacing: 0)

    // MARK: - Timer Card
    let statusLabel: UILabel = {
        let l = UILabel()
        l.text          = "R E A D Y"
        l.font          = .appFont(size: 10, weight: .semibold)
        l.textColor     = AppTheme.Color.textMuted
        l.textAlignment = .center
        return l
    }()

    let timerLabel: UILabel = {
        let l = UILabel()
        l.text          = "15:00"
        l.font          = .appFont(size: 64, weight: .black)
        l.textColor     = AppTheme.Color.textDark
        l.textAlignment = .center
        return l
    }()

    let presetStack = UIStackView.make(axis: .horizontal, spacing: 8, distribution: .fillEqually)
    var presetButtons: [UIButton] = []

    // MARK: - Toy Card
    private(set) var toyChipButtons:   [UIButton]    = []
    private(set) var toyChipIconViews: [UIImageView] = []
    private(set) var toyChipLabels:    [UILabel]     = []

    // MARK: - Cat Card
    let catCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let cv     = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.isScrollEnabled = false
        cv.showsVerticalScrollIndicator = false
        return cv
    }()

    private var catCollectionHeightConstraint: Constraint?

    let emptyLabel: UILabel = {
        let l = UILabel()
        l.text          = "등록된 고양이가 없어요.\n프로필에서 먼저 등록해 주세요 🐾"
        l.font          = .appFont(size: 14)
        l.textColor     = AppTheme.Color.textMuted
        l.textAlignment = .center
        l.numberOfLines = 0
        l.isHidden      = true
        return l
    }()

    // MARK: - Tip
    let tipLabel = UILabel.make(
        text: "하루 30분 이상 놀아주면 냥이의 스트레스가 줄어요!",
        size: 12, color: AppTheme.Color.textMuted, lines: 0
    )

    // MARK: - Bottom Controls
    let stopButton  = TimerView.makeControlButton(systemName: "stop.fill",  pointSize: 20,
                                                  bg: AppTheme.Color.primaryLight,  fg: AppTheme.Color.primary)
    let pauseButton = TimerView.makeControlButton(systemName: "pause.fill", pointSize: 20,
                                                  bg: AppTheme.Color.yellowLight,   fg: AppTheme.Color.yellowDark)

    /// stop + pause 버튼 컨테이너 (타이머 활성 시에만 표시)
    let controlRow: UIView = {
        let v = UIView()
        v.isHidden = true
        return v
    }()

    let startButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("사냥 시작!", for: .normal)
        btn.setTitleColor(AppTheme.Color.textDark, for: .normal)
        btn.titleLabel?.font   = .appFont(size: 18, weight: .heavy)
        btn.backgroundColor    = AppTheme.Color.primary
        btn.layer.cornerRadius = 29
        btn.clipsToBounds      = true
        btn.isEnabled          = false
        btn.alpha              = 0.5
        return btn
    }()

    // MARK: - BaseView
    override func setupUI() {
        backgroundColor = AppTheme.Color.background
        setupScrollView()
        buildContent()
        setupCatCollectionHeight()
        setupBottomArea()
    }

    // MARK: - Scroll
    private func setupScrollView() {
        addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide)   // 상태바 겹침 방지
            make.leading.trailing.bottom.equalToSuperview()
        }
        scrollView.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.top.leading.trailing.bottom.equalToSuperview()
            make.width.equalTo(scrollView)
        }
    }

    private func buildContent() {
        let header = makeHeaderSection()
        let timer  = makeTimerCard()
        let toy    = makeToyCard()
        let cat    = makeCatCard()
        let tip    = makeTipView()
        let spacer = makeBottomSpacer()

        [header, timer, toy, cat, tip, spacer].forEach { contentStack.addArrangedSubview($0) }
        contentStack.setCustomSpacing(12, after: header)
        contentStack.setCustomSpacing(12, after: timer)
        contentStack.setCustomSpacing(12, after: toy)
        contentStack.setCustomSpacing(16, after: cat)
    }

    // MARK: - Section Builders

    private func makeHeaderSection() -> UIView {
        let label = UILabel.make(text: "타이머 설정", size: 24, weight: .bold,
                                 color: AppTheme.Color.textDark)
        let wrap = UIView()
        wrap.addSubview(label)
        label.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().offset(-4)
            make.leading.equalToSuperview().offset(20)
        }
        return wrap
    }

    private func makeTimerCard() -> UIView {
        // Preset 칩 버튼 생성
        presets.forEach { min in
            let btn = UIButton(type: .system)
            btn.setTitle("\(min)분", for: .normal)
            btn.titleLabel?.font = .appFont(size: 13, weight: .semibold)
            btn.tag              = min
            btn.layer.cornerRadius = 16
            btn.clipsToBounds      = true
            btn.layer.borderWidth  = 1.5
            btn.layer.borderColor  = AppTheme.Color.yellowLight.cgColor
            btn.snp.makeConstraints { $0.height.equalTo(32) }
            presetButtons.append(btn)
            presetStack.addArrangedSubview(btn)
        }

        // 상태 + 시간 레이블 (중앙 정렬)
        let labelGroup = UIStackView.make(axis: .vertical, spacing: 4, alignment: .center)
        labelGroup.addArrangedSubview(statusLabel)
        labelGroup.addArrangedSubview(timerLabel)

        // 카드 내 전체 스택
        let cardStack = UIStackView.make(axis: .vertical, spacing: 12)
        cardStack.addArrangedSubview(labelGroup)
        cardStack.addArrangedSubview(presetStack)

        return wrapInCard(cardStack)
    }

    private func makeToyCard() -> UIView {
        let items: [(String, String, Bool)] = [
            ("leaf.fill",      "깃털",       false),
            ("ant.fill",       "벌레",       false),
            ("bolt.fill",      "레이저",     false),
            ("timelapse",      "카샤카샤",   false),
            ("oar.2.crossed",  "오뎅꼬치",   false),
            ("xmark",          "선택 안 함", true ),
        ]

        toyChipButtons.removeAll()
        toyChipIconViews.removeAll()
        toyChipLabels.removeAll()

        var all: [(UIButton, UIImageView, UILabel)] = []
        items.enumerated().forEach { idx, item in
            all.append(makeToyChip(iconName: item.0, labelText: item.1,
                                   tag: idx, muted: item.2))
        }
        all.forEach {
            toyChipButtons.append($0.0)
            toyChipIconViews.append($0.1)
            toyChipLabels.append($0.2)
        }

        let row1 = makeChipRow(Array(all[0..<3]))
        let row2 = makeChipRow(Array(all[3..<6]))

        let chipsGrid = UIStackView.make(axis: .vertical, spacing: 8)
        chipsGrid.addArrangedSubview(row1)
        chipsGrid.addArrangedSubview(row2)

        let titleL = UILabel.make(text: "장난감 선택", size: 15, weight: .bold,
                                  color: AppTheme.Color.textDark)
        let optL   = UILabel.make(text: "(선택 사항)", size: 11, color: AppTheme.Color.textMuted)
        let headerRow = UIStackView.make(axis: .horizontal, spacing: 6, alignment: .center)
        headerRow.addArrangedSubview(titleL)
        headerRow.addArrangedSubview(optL)
        headerRow.addArrangedSubview(UIView())   // spacer

        let cardStack = UIStackView.make(axis: .vertical, spacing: 12)
        cardStack.addArrangedSubview(headerRow)
        cardStack.addArrangedSubview(chipsGrid)

        return wrapInCard(cardStack)
    }

    private func makeChipRow(_ chips: [(UIButton, UIImageView, UILabel)]) -> UIStackView {
        let row = UIStackView.make(axis: .horizontal, spacing: 8, distribution: .fillEqually)
        chips.forEach { btn, _, _ in
            row.addArrangedSubview(btn)
            btn.snp.makeConstraints { $0.height.equalTo(36) }
        }
        return row
    }

    private func makeCatCard() -> UIView {
        catCollectionView.register(CatSelectionCell.self,
                                   forCellWithReuseIdentifier: CatSelectionCell.id)

        let titleL = UILabel.make(text: "오늘 사냥할 고양이는?", size: 16, weight: .bold,
                                  color: AppTheme.Color.textDark)

        let cardStack = UIStackView.make(axis: .vertical, spacing: 16)
        cardStack.addArrangedSubview(titleL)
        cardStack.setCustomSpacing(24, after: titleL)
        cardStack.addArrangedSubview(catCollectionView)
        cardStack.addArrangedSubview(emptyLabel)

        return wrapInCard(cardStack)
    }

    private func makeTipView() -> UIView {
        let v = UIView()
        v.backgroundColor    = UIColor(hex: "#EDF7F2")
        v.layer.cornerRadius = AppTheme.Radius.large

        let symCfg = UIImage.SymbolConfiguration(pointSize: 10, weight: .semibold)
        let bulb   = UIImageView(image: UIImage(systemName: "lightbulb.max",
                                                withConfiguration: symCfg))
        bulb.tintColor = AppTheme.Color.textMuted
        bulb.setContentHuggingPriority(.required, for: .horizontal)

        let row = UIStackView.make(axis: .horizontal, spacing: 8, alignment: .center)
        row.addArrangedSubview(bulb)
        row.addArrangedSubview(tipLabel)
        v.addSubview(row)
        row.snp.makeConstraints { $0.edges.equalToSuperview().inset(14) }

        let wrap = UIView()
        wrap.addSubview(v)
        v.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(20)
        }
        return wrap
    }

    private func makeBottomSpacer() -> UIView {
        let v = UIView()
        // startButton(58) + controlRow(52+12) + safeArea(≈34) + padding(32) ≈ 188
        v.snp.makeConstraints { $0.height.equalTo(148) }
        return v
    }

    // MARK: - Cat Collection Height

    private func setupCatCollectionHeight() {
        catCollectionView.snp.makeConstraints { make in
            catCollectionHeightConstraint = make.height.equalTo(101).constraint
        }
    }

    func updateCatCollectionHeight(_ height: CGFloat) {
        catCollectionHeightConstraint?.update(offset: max(height, 0))
    }

    // MARK: - Bottom Area

    private func setupBottomArea() {
        // stop + pause 버튼 행
        let btnRow = UIStackView.make(axis: .horizontal, spacing: 16, alignment: .center)
        btnRow.addArrangedSubview(stopButton)
        btnRow.addArrangedSubview(pauseButton)
        stopButton.snp.makeConstraints  { $0.width.height.equalTo(52) }
        pauseButton.snp.makeConstraints { $0.width.height.equalTo(52) }
        controlRow.addSubview(btnRow)
        btnRow.snp.makeConstraints { $0.center.equalToSuperview() }

        addSubview(startButton)
        addSubview(controlRow)

        startButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(safeAreaLayoutGuide).offset(-16)
            make.height.equalTo(58)
        }
        controlRow.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(startButton.snp.top).offset(-12)
            make.height.equalTo(52)
        }
    }

    // MARK: - Factories

    /// 카드 뷰로 감싸기: white bg, radius 24, shadow
    private func wrapInCard(_ content: UIView) -> UIView {
        let card = UIView()
        card.backgroundColor    = .white
        card.layer.cornerRadius = 24
        AppTheme.applyCardShadow(to: card, opacity: 0.08, radius: 20)
        card.addSubview(content)
        content.snp.makeConstraints { $0.edges.equalToSuperview().inset(20) }

        let wrap = UIView()
        wrap.addSubview(card)
        card.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(20)
        }
        return wrap
    }

    private func makeToyChip(iconName: String, labelText: String,
                              tag: Int, muted: Bool) -> (UIButton, UIImageView, UILabel) {
        let btn = UIButton(type: .custom)
        btn.tag = tag
        btn.layer.cornerRadius = 18
        btn.clipsToBounds      = true
        btn.layer.borderWidth  = 1.5

        if muted {
            btn.backgroundColor   = UIColor(hex: "#F5F0EE")
            btn.layer.borderColor = UIColor(hex: "#C4B5B5").cgColor
        } else {
            btn.backgroundColor   = .white
            btn.layer.borderColor = AppTheme.Color.yellowLight.cgColor
        }

        let fgColor: UIColor = muted ? AppTheme.Color.textMuted : AppTheme.Color.primary

        let cfg = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        let iv  = UIImageView(image: UIImage(systemName: iconName, withConfiguration: cfg)?
                                        .withRenderingMode(.alwaysTemplate))
        iv.tintColor   = fgColor
        iv.contentMode = .scaleAspectFit
        iv.isUserInteractionEnabled = false

        let lbl = UILabel()
        lbl.text          = labelText
        lbl.font          = .appFont(size: 13, weight: .semibold)
        lbl.textColor     = fgColor
        lbl.textAlignment = .center
        lbl.isUserInteractionEnabled = false

        let row = UIStackView.make(axis: .horizontal, spacing: 4, alignment: .center)
        row.addArrangedSubview(iv)
        row.addArrangedSubview(lbl)
        row.isUserInteractionEnabled = false

        btn.addSubview(row)
        iv.snp.makeConstraints  { $0.width.height.equalTo(14) }
        row.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().inset(8)
            make.trailing.lessThanOrEqualToSuperview().inset(8)
        }

        return (btn, iv, lbl)
    }

    private static func makeControlButton(systemName: String, pointSize: CGFloat,
                                          bg: UIColor, fg: UIColor) -> UIButton {
        let btn = UIButton(type: .system)
        let cfg = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .bold)
        btn.setImage(UIImage(systemName: systemName, withConfiguration: cfg), for: .normal)
        btn.tintColor          = fg
        btn.backgroundColor    = bg
        btn.layer.cornerRadius = 16
        btn.clipsToBounds      = true
        return btn
    }
}
