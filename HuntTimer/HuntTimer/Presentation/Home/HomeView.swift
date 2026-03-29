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
        btn.setImage(UIImage(systemName: "square.and.pencil"), for: .normal)
        btn.tintColor = AppTheme.Color.textMuted
        btn.backgroundColor = AppTheme.Color.cardBG
        btn.layer.cornerRadius = 20
        btn.clipsToBounds = true
        return btn
    }()
    let streakLabel     = UILabel.make(text: "", size: 12, weight: .bold, color: AppTheme.Color.primary)
    let heroCatLabel    = UILabel.make(text: "", size: 18, weight: .black, color: AppTheme.Color.textDark)
    let heroStatusLabel = UILabel.make(text: "", size: 13, color: AppTheme.Color.textMuted)

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
        container.applyCardStyle(cornerRadius: AppTheme.Radius.xxLarge)

        // ── 원형 아바타 (좌상단) ──────────────────────────────────────────
        bannerImageView.layer.cornerRadius = 32
        bannerImageView.clipsToBounds = true
        container.addSubview(bannerImageView)
        bannerImageView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(16)
            make.width.height.equalTo(64)
        }

        // ── 고양이 이름 ──────────────────────────────────────────────────
        container.addSubview(heroCatLabel)
        heroCatLabel.snp.makeConstraints { make in
            make.top.equalTo(bannerImageView.snp.bottom).offset(10)
            make.leading.equalToSuperview().inset(16)
            make.trailing.lessThanOrEqualTo(editBannerButton.snp.leading).offset(-8)
        }

        // ── 품종 / 상태 텍스트 ───────────────────────────────────────────
        container.addSubview(heroStatusLabel)
        heroStatusLabel.snp.makeConstraints { make in
            make.top.equalTo(heroCatLabel.snp.bottom).offset(3)
            make.leading.equalToSuperview().inset(16)
        }

        // ── 스트릭 뱃지 (좌하단) ─────────────────────────────────────────
        let streakBG = UIView()
        streakBG.backgroundColor    = AppTheme.Color.primaryLight
        streakBG.layer.cornerRadius = 14
        streakBG.clipsToBounds      = true
        streakBG.addSubview(streakLabel)
        streakLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12))
        }
        container.addSubview(streakBG)
        streakBG.snp.makeConstraints { make in
            make.top.equalTo(heroStatusLabel.snp.bottom).offset(12)
            make.leading.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(16)  // 컨테이너 높이 결정
        }

        // ── 편집 버튼 (우하단) ───────────────────────────────────────────
        container.addSubview(editBannerButton)
        editBannerButton.snp.makeConstraints { make in
            make.bottom.trailing.equalToSuperview().inset(16)
            make.width.height.equalTo(40)
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
            ("🎯", "이번 주",  weeklyValueLabel),
            ("🏆", "최고 기록", bestValueLabel),
            ("📅", "이번 달",  monthlyValueLabel),
        ]
        let row = UIStackView.make(axis: .horizontal, spacing: 8, distribution: .fillEqually)
        stats.forEach { emoji, label, valueLabel in
            let card = UIView()
            card.applyCardStyle(cornerRadius: AppTheme.Radius.large)
            let emojiL = UILabel.make(text: emoji, size: 20, alignment: .center)
            let labelL = UILabel.make(text: label, size: 10, color: AppTheme.Color.textMuted, alignment: .center)
            let stack  = UIStackView.make(axis: .vertical, spacing: 2, alignment: .center)
            [emojiL, labelL, valueLabel].forEach { stack.addArrangedSubview($0) }
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

        let imgView = AsyncImageView(contentMode: .scaleAspectFill, cornerRadius: 14)
        imgView.loadImage(from: session.imageURL)

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
