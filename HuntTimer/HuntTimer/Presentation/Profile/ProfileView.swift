import UIKit
import SnapKit

/// 프로필 화면 루트 뷰 — 모든 UI 선언과 SnapKit 레이아웃을 담당
final class ProfileView: BaseView {

    // MARK: - Scroll (private)
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.alwaysBounceVertical = true
        sv.backgroundColor = AppTheme.Color.background
        return sv
    }()
    private let contentStack: UIStackView = {
        let sv = UIStackView.make(axis: .vertical, spacing: 20)
        sv.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 32, right: 0)
        sv.isLayoutMarginsRelativeArrangement = true
        return sv
    }()

    // MARK: - Public UI
    private(set) var catSettingsCard:  UIView = UIView()
    private(set) var appSettingsCard:  UIView = UIView()
    private(set) var reviewCard:       UIView = UIView()

    let avatarImageView: AsyncImageView = {
        let iv = AsyncImageView(contentMode: .scaleAspectFill, cornerRadius: 56)
        AppTheme.applyCardShadow(to: iv, opacity: 0.25, radius: 12)
        return iv
    }()

    let photoEditButton: UIButton = {
        let btn = UIButton(type: .system)
        let cfg = UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
        btn.setImage(UIImage(systemName: "camera.fill", withConfiguration: cfg), for: .normal)
        btn.tintColor = .white
        btn.backgroundColor = AppTheme.Color.primary
        btn.layer.cornerRadius = 13
        btn.clipsToBounds = true
        btn.snp.makeConstraints { $0.width.height.equalTo(26) }
        return btn
    }()

    let memorialToggle: UISwitch = {
        let s = UISwitch()
        s.onTintColor = AppTheme.Color.purple
        return s
    }()

    // MARK: - Cat Info (VC가 Realm 데이터 로드 후 갱신)
    let catNameLabel = UILabel.make(text: "", size: 24, weight: .black,
                                    color: AppTheme.Color.textDark, alignment: .center)
    let catInfoLabel = UILabel.make(text: "", size: 13,
                                    color: AppTheme.Color.textMedium, alignment: .center)

    // MARK: - Stats Card (VC가 Realm 데이터 로드 후 갱신)
    let huntCountLabel  = UILabel.make(text: "—", size: 14, weight: .bold,
                                       color: AppTheme.Color.textDark, alignment: .center)
    let totalTimeLabel  = UILabel.make(text: "—", size: 14, weight: .bold,
                                       color: AppTheme.Color.textDark, alignment: .center)
    let statsBadgeLabel = UILabel.make(text: "—", size: 14, weight: .bold,
                                       color: AppTheme.Color.textDark, alignment: .center)

    // MARK: - Badge Grid (동적 갱신)
    private let badgeGridStack  = UIStackView.make(axis: .vertical, spacing: 8)
    private let badgeCountLabel = UILabel.make(text: "0 / 8 달성", size: 12,
                                               color: AppTheme.Color.textMuted)

    // MARK: - BaseView
    override func setupUI() {
        backgroundColor = AppTheme.Color.background
        memorialToggle.isOn = UserDefaults.standard.bool(forKey: "isMemorialMode")
        setupScrollView()
        buildContent()
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
        contentStack.addArrangedSubview(makeHeroSection())
        contentStack.addArrangedSubview(makeSettingsSection())
        contentStack.addArrangedSubview(makeBadgesSection())
        contentStack.addArrangedSubview(makeAppInfoSection())
    }

    // MARK: - Hero Section
    private func makeHeroSection() -> UIView {
        let heroBG = UIView()
//        heroBG.backgroundColor = AppTheme.Color.primaryLight

        let avatarContainer = UIView()
        avatarContainer.addSubview(avatarImageView)
        avatarContainer.addSubview(photoEditButton)
        avatarImageView.snp.makeConstraints { make in
            make.width.height.equalTo(112)
            make.top.leading.trailing.equalToSuperview()
        }
        photoEditButton.snp.makeConstraints { make in
            make.bottom.equalTo(avatarImageView.snp.bottom).offset(-6)
            make.trailing.equalTo(avatarImageView.snp.trailing).offset(-6)
        }
        avatarContainer.snp.makeConstraints { make in
            make.width.height.equalTo(112)
        }

        let statsDefs: [(String, UILabel, String)] = [
            ("🎯", huntCountLabel,  "총 사냥"),
            ("⏱️", totalTimeLabel,  "총 시간"),
            ("🏅", statsBadgeLabel, "배지"),
        ]
        let statsRow = UIStackView.make(axis: .horizontal, spacing: 12, alignment: .center, distribution: .fillEqually)
        statsDefs.forEach { emoji, valLabel, lbl in
            let card = UIView()
            card.backgroundColor    = AppTheme.Color.primaryLight
            card.layer.cornerRadius = AppTheme.Radius.medium
            let col = UIStackView.make(axis: .vertical, spacing: 2, alignment: .center)
            col.addArrangedSubview(UILabel.make(text: emoji, size: 16, alignment: .center))
            col.addArrangedSubview(valLabel)
            col.addArrangedSubview(UILabel.make(text: lbl, size: 10, color: AppTheme.Color.primary, alignment: .center))
            card.addSubview(col)
            col.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.leading.trailing.equalToSuperview().inset(6)
            }
            statsRow.addArrangedSubview(card)
            card.snp.makeConstraints { $0.height.equalTo(card.snp.width) }
        }

        let mainStack = UIStackView.make(axis: .vertical, spacing: 10, alignment: .center)
        mainStack.addArrangedSubview(avatarContainer)
        mainStack.addArrangedSubview(catNameLabel)
        mainStack.addArrangedSubview(catInfoLabel)
        mainStack.addArrangedSubview(statsRow)
        // statsRow는 mainStack과 동일한 너비로 고정 → fillEqually 분배가 카드 너비를 정확히 계산
        statsRow.snp.makeConstraints { $0.width.equalToSuperview() }

        heroBG.addSubview(mainStack)
        mainStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.bottom.equalToSuperview().offset(-28)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }

        heroBG.layer.cornerRadius  = AppTheme.Radius.xxLarge
        heroBG.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        return heroBG
    }

    // MARK: - Settings Section
    private func makeSettingsSection() -> UIView {
        let wrapper = UIView()
        let title   = UILabel.make(text: "설정", size: 15, weight: .bold, color: AppTheme.Color.textDark)

        struct SettingRow {
            let symbol: String; let label: String; let desc: String
            let bg: UIColor; let fg: UIColor; var hasToggle = false
        }
        let remainingRows: [SettingRow] = [
            SettingRow(symbol: "cloud.rainbow.crop", label: "추모 모드", desc: "소중한 추억 간직하기",
                       bg: AppTheme.Color.purple, fg: AppTheme.Color.pinkLight, hasToggle: true),
        ]

        let listStack = UIStackView.make(axis: .vertical, spacing: 8)

        // 고양이 설정 행 — ViewController에서 탭 이벤트를 연결할 수 있도록 참조 보존
        let catRow = makeSettingRow("cat.fill", "고양이 설정", "프로필 수정",
                                    bg: AppTheme.Color.primaryLight, fg: AppTheme.Color.primary, toggle: false)
        catSettingsCard = catRow
        listStack.addArrangedSubview(catRow)

        remainingRows.forEach { row in
            listStack.addArrangedSubview(makeSettingRow(row.symbol, row.label, row.desc,
                                                        bg: row.bg, fg: row.fg, toggle: row.hasToggle))
        }

        let mainStack = UIStackView.make(axis: .vertical, spacing: 12)
        mainStack.addArrangedSubview(title)
        mainStack.addArrangedSubview(listStack)

        wrapper.addSubview(mainStack)
        mainStack.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }
        return wrapper
    }

    private func makeSettingRow(_ symbol: String, _ label: String, _ desc: String,
                                 bg: UIColor, fg: UIColor, toggle: Bool) -> UIView {
        let card = UIView()
        card.applyCardStyle(cornerRadius: AppTheme.Radius.large)

        let iconView = UIView()
        iconView.backgroundColor   = bg
        iconView.layer.cornerRadius = AppTheme.Radius.medium
        iconView.snp.makeConstraints { $0.width.height.equalTo(44) }
        let symCfg  = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        let iconIV  = UIImageView(image: UIImage(systemName: symbol, withConfiguration: symCfg))
        iconIV.tintColor   = fg
        iconIV.contentMode = .scaleAspectFit
        iconView.addSubview(iconIV)
        iconIV.snp.makeConstraints { $0.center.equalToSuperview() }

        let labelL = UILabel.make(text: label, size: 14, weight: .bold, color: AppTheme.Color.textDark)
        let descL  = UILabel.make(text: desc,  size: 11, color: AppTheme.Color.textMuted)
        let textS  = UIStackView.make(axis: .vertical, spacing: 2)
        textS.addArrangedSubview(labelL)
        textS.addArrangedSubview(descL)

        let accessory: UIView
        if toggle {
            accessory = memorialToggle
        } else {
            let chevronCfg = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
            let chevronIV  = UIImageView(image: UIImage(systemName: "chevron.forward", withConfiguration: chevronCfg))
            chevronIV.tintColor   = AppTheme.Color.textMuted
            chevronIV.contentMode = .scaleAspectFit
            accessory = chevronIV
        }

        textS.setContentHuggingPriority(.defaultLow, for: .horizontal)
        accessory.setContentHuggingPriority(.required, for: .horizontal)
        accessory.setContentCompressionResistancePriority(.required, for: .horizontal)

        let row = UIStackView.make(axis: .horizontal, spacing: 12, alignment: .center)
        row.addArrangedSubview(iconView)
        row.addArrangedSubview(textS)
        row.addArrangedSubview(accessory)
        card.addSubview(row)
        row.snp.makeConstraints { make in
            make.top.bottom.leading.equalToSuperview().inset(12)
            make.trailing.equalToSuperview().inset(14)
        }
        return card
    }

    // MARK: - Badges Section
    private func makeBadgesSection() -> UIView {
        let wrapper   = UIView()
        let titleL    = UILabel.make(text: "획득 배지", size: 15, weight: .bold, color: AppTheme.Color.textDark)
        let headerRow = UIStackView.make(axis: .horizontal, alignment: .center)
        headerRow.addArrangedSubview(titleL)
        headerRow.addArrangedSubview(badgeCountLabel)

        let mainStack = UIStackView.make(axis: .vertical, spacing: 12)
        mainStack.addArrangedSubview(headerRow)
        mainStack.addArrangedSubview(badgeGridStack)

        wrapper.addSubview(mainStack)
        mainStack.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }
        return wrapper
    }

    /// Realm에서 로드한 고양이 정보로 이름/정보 레이블 갱신
    func updateCatInfo(name: String, info: String) {
        catNameLabel.text = name
        catInfoLabel.text = info
    }

    /// BadgeManager가 계산한 배지 배열로 그리드를 재구성
    func reloadBadges(_ badges: [Badge]) {
        badgeGridStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let unlockedCount = badges.filter { $0.unlocked }.count
        badgeCountLabel.text = "\(unlockedCount) / \(badges.count) 달성"

        stride(from: 0, to: badges.count, by: 4).forEach { start in
            let chunk    = Array(badges[start..<min(start + 4, badges.count)])
            let rowStack = UIStackView.make(axis: .horizontal, spacing: 8, distribution: .fillEqually)
            chunk.forEach { rowStack.addArrangedSubview(makeBadgeCell($0)) }
            badgeGridStack.addArrangedSubview(rowStack)
        }
    }

    private func makeBadgeCell(_ badge: Badge) -> UIView {
        let card = UIView()
        card.backgroundColor    = badge.unlocked ? .white : UIColor(white: 0.95, alpha: 1)
        card.layer.cornerRadius = 16
        card.alpha              = badge.unlocked ? 1.0 : 0.5
        AppTheme.applyCardShadow(to: card, opacity: badge.unlocked ? 0.10 : 0)

        let badgeIV          = UIImageView(image: UIImage(named: badge.imageName))
        badgeIV.contentMode  = .scaleAspectFit
        badgeIV.snp.makeConstraints { $0.width.height.equalTo(28) }

        let nameL = UILabel.make(text: badge.label, size: 11, weight: .bold,
                                  color: badge.unlocked ? AppTheme.Color.textDark : .gray,
                                  lines: 2, alignment: .center)
        let descL = UILabel.make(text: badge.desc, size: 9,
                                  color: AppTheme.Color.textMuted, lines: 2, alignment: .center)

        let col = UIStackView.make(axis: .vertical, spacing: 4, alignment: .center)
        [badgeIV, nameL, descL].forEach { col.addArrangedSubview($0) }
        card.addSubview(col)
        col.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(12)
            make.leading.trailing.equalToSuperview().inset(4)
        }
        return card
    }

    // MARK: - App Info Section
    private func makeAppInfoSection() -> UIView {
        let wrapper = UIView()
        let title   = UILabel.make(text: "앱 정보", size: 15, weight: .bold, color: AppTheme.Color.textDark)

        struct AppInfoRow {
            let symbol: String; let label: String; let desc: String
            let bg: UIColor; let fg: UIColor
        }
        let rows: [AppInfoRow] = [
            AppInfoRow(symbol: "gearshape.fill",   label: "앱 설정",          desc: "알림 설정",
                       bg: UIColor(white: 0.92, alpha: 1), fg: AppTheme.Color.textMedium),
            AppInfoRow(symbol: "info.circle.fill",  label: "버전 정보",        desc: "v1.0.0",
                       bg: AppTheme.Color.primaryLight,    fg: AppTheme.Color.primary),
            AppInfoRow(symbol: "star.fill",          label: "리뷰 남기기",      desc: "개발자한테 리뷰를 남겨 주세요!",
                       bg: AppTheme.Color.yellowLight,     fg: AppTheme.Color.yellowDark),
        ]

        let listStack = UIStackView.make(axis: .vertical, spacing: 8)
        rows.enumerated().forEach { index, row in
            let card = UIView()
            card.applyCardStyle(cornerRadius: AppTheme.Radius.large)

            switch index {
            case 0: appSettingsCard = card           // 앱 설정 — ViewController에서 탭 연결
            case 1: card.isUserInteractionEnabled = false  // 버전 정보 — 탭 불가 (정보성 행)
            case 2: reviewCard = card                // 리뷰 남기기 — ViewController에서 탭 연결
            default: break
            }

            let iconBG = UIView()
            iconBG.backgroundColor   = row.bg
            iconBG.layer.cornerRadius = AppTheme.Radius.medium
            iconBG.snp.makeConstraints { $0.width.height.equalTo(44) }

            let symCfg = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
            let iconIV = UIImageView(image: UIImage(systemName: row.symbol, withConfiguration: symCfg))
            iconIV.tintColor   = row.fg
            iconIV.contentMode = .scaleAspectFit
            iconBG.addSubview(iconIV)
            iconIV.snp.makeConstraints { $0.center.equalToSuperview() }

            let labelL = UILabel.make(text: row.label, size: 14, weight: .bold, color: AppTheme.Color.textDark)
            let descL  = UILabel.make(text: row.desc,  size: 11, color: AppTheme.Color.textMuted)
            let textS  = UIStackView.make(axis: .vertical, spacing: 2)
            textS.addArrangedSubview(labelL)
            textS.addArrangedSubview(descL)
            textS.setContentHuggingPriority(.defaultLow, for: .horizontal)

            let rowStack = UIStackView.make(axis: .horizontal, spacing: 12, alignment: .center)
            rowStack.addArrangedSubview(iconBG)
            rowStack.addArrangedSubview(textS)

            // 버전 정보(index 1)는 정보성 행이므로 chevron 없음
            if index != 1 {
                let chevronCfg2 = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
                let chevron = UIImageView(image: UIImage(systemName: "chevron.forward", withConfiguration: chevronCfg2))
                chevron.tintColor   = AppTheme.Color.textMuted
                chevron.contentMode = .scaleAspectFit
                chevron.setContentHuggingPriority(.required, for: .horizontal)
                chevron.setContentCompressionResistancePriority(.required, for: .horizontal)
                rowStack.addArrangedSubview(chevron)
            }

            card.addSubview(rowStack)
            rowStack.snp.makeConstraints { make in
                make.top.bottom.leading.equalToSuperview().inset(12)
                make.trailing.equalToSuperview().inset(14)
            }
            listStack.addArrangedSubview(card)
        }

        let mainStack = UIStackView.make(axis: .vertical, spacing: 12)
        mainStack.addArrangedSubview(title)
        mainStack.addArrangedSubview(listStack)

        wrapper.addSubview(mainStack)
        mainStack.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }
        return wrapper
    }
}
