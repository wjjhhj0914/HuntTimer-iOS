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
    let greetLabel  = UILabel.make(text: "", size: 13, weight: .bold, color: AppTheme.Color.textMuted)
    let titleLabel  = UILabel.make(text: "", size: 22, weight: .black, color: AppTheme.Color.textDark)

    // MARK: - Banner
    let bannerImageView: AsyncImageView = {
        let iv = AsyncImageView(contentMode: .scaleAspectFill)
        iv.backgroundColor = AppTheme.Color.primary   // 이미지 없을 때 위젯 플레이스홀더
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

    // MARK: - Progress Pager
    let progressPagerView = ProgressPagerView()

    // MARK: - Recent Sessions
    let recentStack  = UIStackView.make(axis: .vertical, spacing: 8)
    let seeAllButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("전체보기 →", for: .normal)
        btn.titleLabel?.font = .appFont(size: 12, weight: .semibold)
        btn.tintColor = AppTheme.Color.primary
        return btn
    }()

    // MARK: - Cat Section
    let catCountBadgeLabel = UILabel.make(text: "0마리", size: 11, weight: .semibold,
                                          color: UIColor(hex: "#785b35"))
    let catAvatarsStack = UIStackView.make(axis: .horizontal, spacing: 20, alignment: .center)
    let addCatButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.backgroundColor    = UIColor(hex: "#FFFBF7")
        btn.layer.cornerRadius = 32
        btn.clipsToBounds      = true
        btn.layer.borderWidth  = 2
        btn.layer.borderColor  = AppTheme.Color.primary.cgColor
        let symCfg = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        btn.setImage(UIImage(systemName: "plus", withConfiguration: symCfg), for: .normal)
        btn.tintColor = AppTheme.Color.primary
        return btn
    }()
    let catEditDoneButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("완료", for: .normal)
        btn.titleLabel?.font   = .appFont(size: 13, weight: .bold)
        btn.setTitleColor(AppTheme.Color.textDark, for: .normal)
        btn.backgroundColor    = AppTheme.Color.primary
        btn.layer.cornerRadius = 14
        btn.clipsToBounds      = true
        btn.contentEdgeInsets  = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
        btn.isHidden = true
        return btn
    }()
    private(set) var catSectionView: UIView?
    private(set) var catBadgeContainer: UIView?

    // MARK: - CTA
    let startButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("사냥 시작하기!", for: .normal)
        btn.setTitleColor(AppTheme.Color.textDark, for: .normal)
        btn.titleLabel?.font = .appFont(size: 17, weight: .black)
        btn.backgroundColor    = AppTheme.Color.primary
        btn.layer.cornerRadius = AppTheme.Radius.xxLarge
        btn.clipsToBounds = true
        AppTheme.applyButtonShadow(to: btn)
        return btn
    }()

    // MARK: - BaseView
    override func setupUI() {
        backgroundColor = AppTheme.Color.background
        setupScrollView()
        buildSections()
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
    private(set) var recentSectionView: UIView?

    private func buildSections() {
        contentStack.addArrangedSubview(makeHeaderSection())

        let banner = makeBannerSection()
        bannerSectionView = banner
        contentStack.addArrangedSubview(banner)

        let progress = makeProgressSection()
        progressSectionView = progress
        contentStack.addArrangedSubview(progress)

        let catSection = makeCatSection()
        catSectionView = catSection
        contentStack.addArrangedSubview(catSection)

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

        editBannerButton.snp.makeConstraints { make in
            make.bottom.trailing.equalToSuperview().inset(12)
            make.width.height.equalTo(32)
        }

        return container.wrapped(insets: UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20))
    }

    private func makeProgressSection() -> UIView {
        return progressPagerView
    }

    private func makeCatSection() -> UIView {
        let titleL = UILabel.make(text: "누구의 기록을 볼까요?", size: 15, weight: .bold,
                                  color: AppTheme.Color.textDark)

        // N마리 배지
        let badgeWrap = UIView()
        badgeWrap.backgroundColor    = UIColor(hex: "#fff5dc")
        badgeWrap.layer.cornerRadius = 12
        badgeWrap.addSubview(catCountBadgeLabel)
        catCountBadgeLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(4)
            make.leading.trailing.equalToSuperview().inset(10)
        }

        catBadgeContainer = badgeWrap

        let headerRow = UIStackView.make(axis: .horizontal, alignment: .center)
        headerRow.addArrangedSubview(titleL)
        headerRow.addArrangedSubview(UIView())   // spacer
        headerRow.addArrangedSubview(badgeWrap)
        headerRow.addArrangedSubview(catEditDoneButton)

        // 아바타 가로 스크롤 (상단 4pt: deleteBadge 오버플로우 수용)
        let scroll = UIScrollView()
        scroll.showsHorizontalScrollIndicator = false
        scroll.contentInset = UIEdgeInsets(top: 4, left: 0, bottom: 0, right: 0)
        scroll.addSubview(catAvatarsStack)
        catAvatarsStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(scroll)
        }
        scroll.snp.makeConstraints { $0.height.equalTo(94) }

        // 추가 버튼 크기 고정 (여기서 한 번만 설정)
        addCatButton.snp.makeConstraints { $0.width.height.equalTo(64) }

        let cardStack = UIStackView.make(axis: .vertical, spacing: 12)
        cardStack.addArrangedSubview(headerRow)
        cardStack.addArrangedSubview(scroll)

        let card = UIView()
        card.backgroundColor    = .white
        card.layer.cornerRadius = 24
        AppTheme.applyCardShadow(to: card, opacity: 0.08, radius: 20)
        card.addSubview(cardStack)
        cardStack.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }

        let wrap = UIView()
        wrap.addSubview(card)
        card.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(20)
        }
        return wrap
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
