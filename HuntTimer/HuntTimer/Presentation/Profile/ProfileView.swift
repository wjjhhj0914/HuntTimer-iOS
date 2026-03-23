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
    let memorialToggle: UISwitch = {
        let s = UISwitch()
        s.onTintColor = AppTheme.Color.purple
        return s
    }()

    // MARK: - BaseView
    override func setupUI() {
        backgroundColor = AppTheme.Color.background
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
        heroBG.backgroundColor = AppTheme.Color.primaryLight

        let circle1 = UIView()
        circle1.backgroundColor  = AppTheme.Color.primary.withAlphaComponent(0.3)
        circle1.layer.cornerRadius = 64
        let circle2 = UIView()
        circle2.backgroundColor  = AppTheme.Color.yellow.withAlphaComponent(0.2)
        circle2.layer.cornerRadius = 48

        heroBG.addSubview(circle1)
        heroBG.addSubview(circle2)
        circle1.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(-32)
            make.trailing.equalToSuperview().offset(32)
            make.width.height.equalTo(128)
        }
        circle2.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(16)
            make.leading.equalToSuperview().offset(-24)
            make.width.height.equalTo(96)
        }

        let avatarContainer = UIView()
        let avatarImageView = AsyncImageView(contentMode: .scaleAspectFill, cornerRadius: 56)
        avatarImageView.loadImage(from: "https://images.unsplash.com/photo-1702914954859-f037fc75b760?w=400")
        avatarImageView.layer.borderWidth = 4
        avatarImageView.layer.borderColor = UIColor.white.cgColor
        AppTheme.applyCardShadow(to: avatarImageView, opacity: 0.25, radius: 12)

        let editButton = UIButton(type: .system)
        editButton.setTitle("✏️", for: .normal)
        editButton.backgroundColor   = AppTheme.Color.primary
        editButton.layer.cornerRadius = 16
        editButton.layer.borderWidth  = 2
        editButton.layer.borderColor  = UIColor.white.cgColor
        editButton.snp.makeConstraints { $0.width.height.equalTo(32) }

        avatarContainer.addSubview(avatarImageView)
        avatarContainer.addSubview(editButton)
        avatarImageView.snp.makeConstraints { make in
            make.width.height.equalTo(112)
            make.top.leading.trailing.equalToSuperview()
        }
        editButton.snp.makeConstraints { make in
            make.bottom.equalTo(avatarImageView.snp.bottom)
            make.trailing.equalTo(avatarImageView.snp.trailing)
        }
        avatarContainer.snp.makeConstraints { make in
            make.width.height.equalTo(112)
        }

        let nameLabel = UILabel.make(text: "뮤기 🐱", size: 24, weight: .black,
                                     color: AppTheme.Color.textDark, alignment: .center)
        let infoLabel = UILabel.make(text: "코숏 · 암컷 · 3살", size: 13,
                                     color: AppTheme.Color.textMedium, alignment: .center)

        let statsData: [(String, String, String)] = [
            ("🎯", "247회", "총 사냥"),
            ("⏱️", "41.5h", "총 시간"),
            ("🏅", "4개",   "배지"),
        ]
        let statsRow = UIStackView.make(axis: .horizontal, spacing: 12, distribution: .fillEqually)
        statsData.forEach { emoji, val, lbl in
            let card = UIView()
            card.backgroundColor   = UIColor(white: 1, alpha: 0.70)
            card.layer.cornerRadius = AppTheme.Radius.medium
            let col = UIStackView.make(axis: .vertical, spacing: 2, alignment: .center)
            col.addArrangedSubview(UILabel.make(text: emoji, size: 16, alignment: .center))
            col.addArrangedSubview(UILabel.make(text: val, size: 14, weight: .bold,
                                                color: AppTheme.Color.textDark, alignment: .center))
            col.addArrangedSubview(UILabel.make(text: lbl, size: 10, color: AppTheme.Color.textMuted, alignment: .center))
            card.addSubview(col)
            col.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview().inset(10)
                make.leading.trailing.equalToSuperview().inset(6)
            }
            statsRow.addArrangedSubview(card)
        }

        let mainStack = UIStackView.make(axis: .vertical, spacing: 10, alignment: .center)
        mainStack.addArrangedSubview(avatarContainer)
        mainStack.addArrangedSubview(nameLabel)
        mainStack.addArrangedSubview(infoLabel)
        mainStack.addArrangedSubview(statsRow)

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
            let emoji: String; let label: String; let desc: String
            let bg: UIColor; let fg: UIColor; var hasToggle = false
        }
        let rows: [SettingRow] = [
            SettingRow(emoji: "🐱", label: "고양이 설정",  desc: "뮤기 프로필 수정",
                       bg: AppTheme.Color.primaryLight, fg: AppTheme.Color.primary),
            SettingRow(emoji: "🎯", label: "목표 설정",    desc: "하루 사냥 목표 시간",
                       bg: AppTheme.Color.yellowLight,  fg: AppTheme.Color.yellowDark),
            SettingRow(emoji: "💜", label: "추모 모드",    desc: "소중한 추억 간직하기",
                       bg: AppTheme.Color.purpleLight,  fg: AppTheme.Color.purple, hasToggle: true),
        ]

        let listStack = UIStackView.make(axis: .vertical, spacing: 8)
        rows.forEach { row in
            listStack.addArrangedSubview(makeSettingRow(row.emoji, row.label, row.desc,
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

    private func makeSettingRow(_ emoji: String, _ label: String, _ desc: String,
                                 bg: UIColor, fg: UIColor, toggle: Bool) -> UIView {
        let card = UIView()
        card.applyCardStyle(cornerRadius: AppTheme.Radius.large)

        let iconView = UIView()
        iconView.backgroundColor  = bg
        iconView.layer.cornerRadius = AppTheme.Radius.medium
        iconView.snp.makeConstraints { $0.width.height.equalTo(44) }
        let iconLabel = UILabel.make(text: emoji, size: 20, alignment: .center)
        iconView.addSubview(iconLabel)
        iconLabel.snp.makeConstraints { $0.center.equalToSuperview() }

        let labelL = UILabel.make(text: label, size: 14, weight: .bold, color: AppTheme.Color.textDark)
        let descL  = UILabel.make(text: desc,  size: 11, color: AppTheme.Color.textMuted)
        let textS  = UIStackView.make(axis: .vertical, spacing: 2)
        textS.addArrangedSubview(labelL)
        textS.addArrangedSubview(descL)

        let accessory: UIView = toggle
            ? memorialToggle
            : UILabel.make(text: "›", size: 20, color: AppTheme.Color.textMuted)

        let row = UIStackView.make(axis: .horizontal, spacing: 12, alignment: .center)
        row.addArrangedSubview(iconView)
        row.addArrangedSubview(textS)
        row.addArrangedSubview(accessory)
        card.addSubview(row)
        row.snp.makeConstraints { $0.edges.equalToSuperview().inset(12) }
        return card
    }

    // MARK: - Badges Section
    private func makeBadgesSection() -> UIView {
        let wrapper   = UIView()
        let titleL    = UILabel.make(text: "🏅 획득 배지", size: 15, weight: .bold, color: AppTheme.Color.textDark)
        let subL      = UILabel.make(text: "4 / 8 달성", size: 12, color: AppTheme.Color.textMuted)
        let headerRow = UIStackView.make(axis: .horizontal, alignment: .center)
        headerRow.addArrangedSubview(titleL)
        headerRow.addArrangedSubview(subL)

        let gridStack = UIStackView.make(axis: .vertical, spacing: 8)
        let chunks = stride(from: 0, to: SampleData.badges.count, by: 4).map {
            Array(SampleData.badges[$0..<min($0 + 4, SampleData.badges.count)])
        }
        chunks.forEach { row in
            let rowStack = UIStackView.make(axis: .horizontal, spacing: 8, distribution: .fillEqually)
            row.forEach { badge in rowStack.addArrangedSubview(makeBadgeCell(badge)) }
            gridStack.addArrangedSubview(rowStack)
        }

        let mainStack = UIStackView.make(axis: .vertical, spacing: 12)
        mainStack.addArrangedSubview(headerRow)
        mainStack.addArrangedSubview(gridStack)

        wrapper.addSubview(mainStack)
        mainStack.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }
        return wrapper
    }

    private func makeBadgeCell(_ badge: Badge) -> UIView {
        let card = UIView()
        card.backgroundColor   = badge.unlocked ? .white : UIColor(white: 0.95, alpha: 1)
        card.layer.cornerRadius = AppTheme.Radius.large
        card.alpha = badge.unlocked ? 1.0 : 0.5
        AppTheme.applyCardShadow(to: card, opacity: badge.unlocked ? 0.10 : 0)

        let emojiL = UILabel.make(text: badge.emoji, size: 24, alignment: .center)
        let nameL  = UILabel.make(text: badge.label, size: 10, weight: .bold,
                                   color: badge.unlocked ? AppTheme.Color.textDark : .gray, lines: 2, alignment: .center)
        let descL  = UILabel.make(text: badge.desc, size: 9, color: AppTheme.Color.textMuted, lines: 2, alignment: .center)

        let col = UIStackView.make(axis: .vertical, spacing: 2, alignment: .center)
        [emojiL, nameL, descL].forEach { col.addArrangedSubview($0) }
        card.addSubview(col)
        col.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(10)
            make.leading.trailing.equalToSuperview().inset(4)
        }
        return card
    }

    // MARK: - App Info Section
    private func makeAppInfoSection() -> UIView {
        let wrapper = UIView()
        let rows: [(String, String)] = [
            ("⚙️", "앱 설정"),
            ("ℹ️", "버전 정보 v1.2.3"),
            ("⭐", "리뷰 남기기"),
        ]
        let stack = UIStackView.make(axis: .vertical, spacing: 8)
        rows.forEach { emoji, label in
            let card = UIView()
            card.applyCardStyle(cornerRadius: AppTheme.Radius.medium)
            let e   = UILabel.make(text: emoji, size: 16)
            let l   = UILabel.make(text: label, size: 13, color: AppTheme.Color.textMedium)
            let a   = UILabel.make(text: "›", size: 20, color: AppTheme.Color.textMuted)
            let row = UIStackView.make(axis: .horizontal, spacing: 10, alignment: .center)
            row.addArrangedSubview(e)
            row.addArrangedSubview(l)
            row.addArrangedSubview(a)
            card.addSubview(row)
            row.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview().inset(13)
                make.leading.trailing.equalToSuperview().inset(16)
            }
            stack.addArrangedSubview(card)
        }
        wrapper.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }
        return wrapper
    }
}
