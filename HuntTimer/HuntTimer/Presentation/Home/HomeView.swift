import UIKit
import SnapKit

/// 홈 화면 루트 뷰 — 모든 UI 선언과 SnapKit 레이아웃을 담당
final class HomeView: BaseView {

    // MARK: - Scroll Container (private)
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.alwaysBounceVertical = true
        sv.backgroundColor = AppTheme.Color.background
        return sv
    }()
    private let contentStack = UIStackView.make(axis: .vertical, spacing: 16)

    // MARK: - Header
    let greetLabel  = UILabel.make(text: "", size: 13, color: AppTheme.Color.textMuted)
    let titleLabel  = UILabel.make(text: "", size: 22, weight: .black, color: AppTheme.Color.textDark)

    // MARK: - Banner
    let bannerImageView: AsyncImageView = {
        let iv = AsyncImageView(contentMode: .scaleAspectFill)
        iv.backgroundColor = AppTheme.Color.cardBG   // 이미지 없을 때 위젯 플레이스홀더
        return iv
    }()
    let editBannerButton: UIButton = {
        let btn = UIButton(type: .system)
        let symCfg = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        btn.setImage(UIImage(systemName: "photo", withConfiguration: symCfg), for: .normal)
        btn.tintColor = .white
        btn.backgroundColor = UIColor(white: 0, alpha: 0.28)
        btn.layer.cornerRadius = 16
        btn.clipsToBounds = true
        return btn
    }()
    let streakLabel     = UILabel.make(text: "", size: 12, weight: .bold, color: .white)
    let heroCatLabel    = UILabel.make(text: "", size: 18, weight: .black, color: .white)
    let heroStatusLabel = UILabel.make(text: "", size: 13, color: UIColor(white: 1, alpha: 0.85))
    let bannerPlaceholderLabel: UILabel = {
        let l = UILabel()
        l.text          = "우리 아이의 가장 멋진 사냥 순간을 채워주세요!"
        l.font          = .systemFont(ofSize: 14, weight: .medium)
        l.textColor     = UIColor(white: 1, alpha: 0.75)
        l.textAlignment = .center
        l.numberOfLines = 2
        return l
    }()

    // MARK: - Progress
    let gaugeView          = CircularProgressView(size: 130)
    let centerLabel           = UILabel.make(text: "", size: 22, weight: .black, color: AppTheme.Color.textDark, alignment: .center)
    let unitLabel             = UILabel.make(text: "", size: 11, color: AppTheme.Color.textMuted, alignment: .center)
    let progressPercentLabel  = UILabel.make(text: "", size: 10, weight: .semibold, color: AppTheme.Color.primary, alignment: .center)
    let progressValueLabel = UILabel.make(text: "", size: 17, weight: .black, color: AppTheme.Color.textDark)
    let goalBadgeLabel     = UILabel.make(text: "", size: 11, weight: .semibold, color: AppTheme.Color.primary)
    let timeBadgeLabel     = UILabel.make(text: "", size: 11, weight: .semibold, color: AppTheme.Color.yellowDark)
    let sessionCountLabel  = UILabel.make(text: "", size: 11, color: AppTheme.Color.textMuted)

    // MARK: - Quick Stats
    let weeklyValueLabel  = UILabel.make(text: "", size: 13, weight: .bold, color: AppTheme.Color.textDark, alignment: .center)
    let bestValueLabel    = UILabel.make(text: "", size: 13, weight: .bold, color: AppTheme.Color.textDark, alignment: .center)
    let monthlyValueLabel = UILabel.make(text: "", size: 13, weight: .bold, color: AppTheme.Color.textDark, alignment: .center)

    // MARK: - Recent Sessions
    let recentStack  = UIStackView.make(axis: .vertical, spacing: 8)
    let seeAllButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("전체보기 →", for: .normal)
        btn.titleLabel?.font = .appFont(size: 12, weight: .semibold)
        btn.tintColor = AppTheme.Color.primary
        return btn
    }()

    // MARK: - CTA
    let startButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("사냥 시작하기!", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = .appFont(size: 17, weight: .black)
        btn.layer.cornerRadius = AppTheme.Radius.xxLarge
        btn.clipsToBounds = true
        AppTheme.applyButtonShadow(to: btn)
        return btn
    }()
    var startGradientLayer: CAGradientLayer?

    // MARK: - BaseView
    override func setupUI() {
        backgroundColor = AppTheme.Color.background
        setupScrollView()
        buildSections()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        startGradientLayer?.frame = startButton.bounds
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
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(-24)
            make.width.equalTo(scrollView)
        }
    }

    // hasCat에 따라 show/hide 할 섹션 참조
    private(set) var bannerSectionView: UIView?
    private(set) var progressSectionView: UIView?
    private(set) var quickStatsSectionView: UIView?
    private(set) var recentSectionView: UIView?

    private func buildSections() {
        contentStack.addArrangedSubview(makeHeaderSection())

        let banner = makeBannerSection()
        bannerSectionView = banner
        contentStack.addArrangedSubview(banner)

        let progress = makeProgressSection()
        progressSectionView = progress
        contentStack.addArrangedSubview(progress)

        let quickStats = makeQuickStatsSection()
        quickStatsSectionView = quickStats
        contentStack.addArrangedSubview(quickStats)

        let recent = makeRecentSection()
        recentSectionView = recent
        contentStack.addArrangedSubview(recent)

        contentStack.addArrangedSubview(makeCTAButton())
        let spacer = UIView()
        spacer.snp.makeConstraints { $0.height.equalTo(12) }
        contentStack.addArrangedSubview(spacer)
    }

    // MARK: - Section Builders
    private func makeHeaderSection() -> UIView {
        let textStack = UIStackView.make(axis: .vertical, spacing: 2)
        textStack.addArrangedSubview(greetLabel)
        textStack.addArrangedSubview(titleLabel)
        return textStack.wrapped(insets: UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20))
    }

    private func makeBannerSection() -> UIView {
        let container = UIView()
        container.snp.makeConstraints { $0.height.equalTo(180) }
        container.layer.cornerRadius = AppTheme.Radius.xxLarge
        container.clipsToBounds      = true

        // ── 1단계: 모든 서브뷰 addSubview (제약 참조 전 동일 계층 보장) ──
        container.addSubview(bannerImageView)

        let gradView = UIView()
        gradView.isUserInteractionEnabled = false
        container.addSubview(gradView)

        container.addSubview(bannerPlaceholderLabel)

        let streakBG = UIView()
        streakBG.backgroundColor    = UIColor(white: 1, alpha: 0.20)
        streakBG.layer.cornerRadius = 14
        streakBG.clipsToBounds      = true
        streakBG.addSubview(streakLabel)
        container.addSubview(streakBG)

        container.addSubview(editBannerButton)

        // ── 2단계: 제약 설정 ──────────────────────────────────────────────
        bannerImageView.snp.makeConstraints { $0.edges.equalToSuperview() }
        gradView.snp.makeConstraints { $0.edges.equalToSuperview() }

        bannerPlaceholderLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(24)
        }

        // 그라디언트는 레이아웃 후 프레임 확정 시점에 추가
        DispatchQueue.main.async {
            let grad         = CAGradientLayer()
            grad.colors      = [UIColor.clear.cgColor, UIColor(white: 0, alpha: 0.50).cgColor]
            grad.startPoint  = CGPoint(x: 0.5, y: 0.25)
            grad.endPoint    = CGPoint(x: 0.5, y: 1.0)
            grad.frame       = gradView.bounds.isEmpty
                ? CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - 40, height: 180)
                : gradView.bounds
            gradView.layer.addSublayer(grad)
        }

        streakLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10))
        }
        // 스트릭 배지: 좌하단으로 이동
        streakBG.snp.makeConstraints { make in
            make.bottom.leading.equalToSuperview().inset(16)
        }
        editBannerButton.snp.makeConstraints { make in
            make.bottom.trailing.equalToSuperview().inset(12)
            make.width.height.equalTo(32)
        }

        return container.wrapped(insets: UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20))
    }

    private func makeProgressSection() -> UIView {
        let card = UIView()
        card.applyCardStyle(cornerRadius: AppTheme.Radius.xxLarge)

        let innerStack = UIStackView.make(axis: .vertical, spacing: 0, alignment: .center)
        innerStack.addArrangedSubview(centerLabel)
        innerStack.addArrangedSubview(unitLabel)
        innerStack.addArrangedSubview(progressPercentLabel)
        gaugeView.addSubview(innerStack)
        innerStack.snp.makeConstraints { $0.center.equalToSuperview() }
        gaugeView.snp.makeConstraints { $0.width.height.equalTo(130) }

        let headerLabel = UILabel.make(text: "오늘의 사냥 목표", size: 12, color: AppTheme.Color.textMedium)
        let goalBadge   = makePill(label: goalBadgeLabel, bg: AppTheme.Color.primaryLight)
        let timeBadge   = makePill(label: timeBadgeLabel, bg: AppTheme.Color.yellowLight)
        let badgeRow    = UIStackView.make(axis: .vertical, spacing: 6, alignment: .leading)
        badgeRow.addArrangedSubview(goalBadge)
        badgeRow.addArrangedSubview(timeBadge)

        let infoStack = UIStackView.make(axis: .vertical, spacing: 6)
        infoStack.addArrangedSubview(headerLabel)
        infoStack.addArrangedSubview(progressValueLabel)
        infoStack.addArrangedSubview(badgeRow)
        infoStack.addArrangedSubview(sessionCountLabel)

        let row = UIStackView.make(axis: .horizontal, spacing: 16, alignment: .center)
        row.addArrangedSubview(gaugeView)
        row.addArrangedSubview(infoStack)
        card.addSubview(row)
        row.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }

        return card.wrapped(insets: UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20))
    }

    private func makeQuickStatsSection() -> UIView {
        let stats: [(String, String, UILabel)] = [
            ("target",   "이번 주",  weeklyValueLabel),
            ("trophy",   "최고 기록", bestValueLabel),
            ("calendar", "이번 달",  monthlyValueLabel),
        ]
        let row = UIStackView.make(axis: .horizontal, spacing: 8, distribution: .fillEqually)
        stats.forEach { symbolName, label, valueLabel in
            let card = UIView()
            card.applyCardStyle(cornerRadius: AppTheme.Radius.large)
            let config    = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
            let iconImage = UIImage(systemName: symbolName, withConfiguration: config)
            let iconView  = UIImageView(image: iconImage)
            iconView.tintColor = AppTheme.Color.primary
            iconView.contentMode = .scaleAspectFit
            let labelL = UILabel.make(text: label, size: 10, color: AppTheme.Color.textMuted, alignment: .center)
            let stack  = UIStackView.make(axis: .vertical, spacing: 2, alignment: .center)
            [iconView, labelL, valueLabel].forEach { stack.addArrangedSubview($0) }
            card.addSubview(stack)
            stack.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview().inset(12)
                make.leading.trailing.equalToSuperview().inset(4)
            }
            row.addArrangedSubview(card)
        }
        return row.wrapped(insets: UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20))
    }

    private func makeRecentSection() -> UIView {
        let sectionTitle = UILabel.make(text: "최근 사냥 기록", size: 16, weight: .bold, color: AppTheme.Color.textDark)
        sectionTitle.setContentHuggingPriority(.defaultLow, for: .horizontal)
        seeAllButton.setContentHuggingPriority(.required, for: .horizontal)

        let headerRow = UIStackView.make(axis: .horizontal, alignment: .center)
        headerRow.addArrangedSubview(sectionTitle)
        headerRow.addArrangedSubview(seeAllButton)

        let mainStack = UIStackView.make(axis: .vertical, spacing: 12)
        mainStack.addArrangedSubview(headerRow)
        mainStack.addArrangedSubview(recentStack)
        return mainStack.wrapped(insets: UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20))
    }

    private func makeCTAButton() -> UIView {
        let gradLayer = AppTheme.primaryGradient()
        startButton.layer.insertSublayer(gradLayer, at: 0)
        startGradientLayer = gradLayer
        startButton.snp.makeConstraints { $0.height.equalTo(56) }
        return startButton.wrapped(insets: UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20))
    }

    // MARK: - Helpers
    func makePill(label: UILabel, bg: UIColor) -> UIView {
        let pill = UIView()
        pill.backgroundColor   = bg
        pill.layer.cornerRadius = 10
        pill.addSubview(label)
        label.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(4)
            make.leading.trailing.equalToSuperview().inset(8)
        }
        return pill
    }

    func makeSessionRow(_ session: HuntSession) -> UIView {
        let card = UIView()
        card.applyCardStyle(cornerRadius: AppTheme.Radius.large)

        // 장난감 SF Symbol 아이콘 뷰
        let symCfg  = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        let imgView = UIImageView(image: UIImage(systemName: session.toySymbol,
                                                 withConfiguration: symCfg))
        imgView.contentMode      = .center
        imgView.tintColor        = AppTheme.Color.primary
        imgView.backgroundColor  = AppTheme.Color.primaryLight
        imgView.layer.cornerRadius = 14
        imgView.clipsToBounds    = true

        let toyLabel  = UILabel.make(text: session.title, size: 13, weight: .bold, color: AppTheme.Color.textDark)
        let timeLabel = UILabel.make(text: session.time,  size: 11, color: AppTheme.Color.textMuted)
        let textStack = UIStackView.make(axis: .vertical, spacing: 2)
        textStack.addArrangedSubview(toyLabel)
        textStack.addArrangedSubview(timeLabel)

        let durationLabel = UILabel.make(text: "\(session.durationText)", size: 11,
                                         weight: .semibold, color: AppTheme.Color.yellowDark)
        durationLabel.setContentHuggingPriority(.required, for: .horizontal)
        durationLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        let durationBadge = makePill(label: durationLabel, bg: AppTheme.Color.yellowLight)

        card.addSubview(imgView)
        card.addSubview(textStack)
        card.addSubview(durationBadge)

        imgView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(48)
            make.top.greaterThanOrEqualToSuperview().offset(12)
            make.bottom.lessThanOrEqualToSuperview().offset(-12)
        }
        durationBadge.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
            make.top.greaterThanOrEqualToSuperview().offset(12)
            make.bottom.lessThanOrEqualToSuperview().offset(-12)
        }
        textStack.snp.makeConstraints { make in
            make.leading.equalTo(imgView.snp.trailing).offset(12)
            make.trailing.lessThanOrEqualTo(durationBadge.snp.leading).offset(-12)
            make.top.bottom.equalToSuperview().inset(14)
        }
        return card
    }
}
