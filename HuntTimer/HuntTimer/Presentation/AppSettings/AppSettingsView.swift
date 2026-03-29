import UIKit
import SnapKit

// MARK: - PaddedLabel

/// 내부 패딩을 지원하는 UILabel 서브클래스
final class PaddedLabel: UILabel {
    private let insets: UIEdgeInsets
    init(insets: UIEdgeInsets) {
        self.insets = insets
        super.init(frame: .zero)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }
    override var intrinsicContentSize: CGSize {
        let base = super.intrinsicContentSize
        return CGSize(width:  base.width  + insets.left + insets.right,
                      height: base.height + insets.top  + insets.bottom)
    }
}

// MARK: - AppSettingsView

/// 앱 설정 화면 루트 뷰 — 알림 전체 토글 + 리마인드 시간 피커
final class AppSettingsView: BaseView {

    // MARK: - Public UI

    let allNotifToggle: UISwitch = {
        let s = UISwitch()
        s.onTintColor = AppTheme.Color.primary
        return s
    }()

    let timePicker: UIDatePicker = {
        let dp = UIDatePicker()
        dp.datePickerMode = .time
        dp.preferredDatePickerStyle = .wheels
        dp.locale = Locale(identifier: "ko_KR")
        return dp
    }()

    let reminderTimeBadge: PaddedLabel = {
        let l = PaddedLabel(insets: UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8))
        l.text            = "오후 7:00"
        l.font            = .systemFont(ofSize: 13, weight: .semibold)
        l.textColor       = AppTheme.Color.primary
        l.textAlignment   = .center
        l.backgroundColor = AppTheme.Color.primaryLight
        l.layer.cornerRadius = 6
        l.clipsToBounds   = true
        return l
    }()

    // MARK: - Private

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.alwaysBounceVertical = true
        return sv
    }()

    // MARK: - BaseView

    override func setupUI() {
        backgroundColor = AppTheme.Color.background
        addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }

        let container = UIView()
        scrollView.addSubview(container)
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }

        let card = makeNotificationCard()
        container.addSubview(card)
        card.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.lessThanOrEqualToSuperview().offset(-32)
        }
    }

    // MARK: - Card Builder

    private func makeNotificationCard() -> UIView {
        let card = UIView()
        card.applyCardStyle(cornerRadius: AppTheme.Radius.large)

        // ── Section header: 🔔 알림 ────────────────────────────────────────
        let bellCfg = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        let bellIV  = UIImageView(image: UIImage(systemName: "bell.fill", withConfiguration: bellCfg))
        bellIV.tintColor = AppTheme.Color.primary
        let sectionLabel = UILabel.make(text: "알림", size: 15, weight: .bold, color: AppTheme.Color.textDark)
        let spacer = UIView()

        let sectionRow = UIStackView.make(axis: .horizontal, spacing: 6, alignment: .center)
        [bellIV, sectionLabel, spacer].forEach { sectionRow.addArrangedSubview($0) }

        // ── 전체 알림 toggle row ───────────────────────────────────────────
        let allRow = makeRow(
            title: "전체 알림",
            desc:  "전체 알림을 끄면 모든 알림과 리마인드를 받을 수 없어요",
            accessory: allNotifToggle
        )

        // ── Divider ────────────────────────────────────────────────────────
        let sep = UIView()
        sep.backgroundColor = UIColor(white: 0.92, alpha: 1)
        sep.snp.makeConstraints { $0.height.equalTo(1) }

        // ── 사냥 목표 리마인드 row ─────────────────────────────────────────
        let reminderRow = makeRow(
            title: "사냥 목표 리마인드",
            desc:  "오늘 사냥 기록이 없을 때 알려드려요",
            accessory: reminderTimeBadge
        )

        // ── Stack ─────────────────────────────────────────────────────────
        let stack = UIStackView.make(axis: .vertical, spacing: 14)
        [sectionRow, allRow, sep, reminderRow, timePicker].forEach { stack.addArrangedSubview($0) }

        card.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        return card
    }

    private func makeRow(title: String, desc: String, accessory: UIView) -> UIView {
        let titleL = UILabel.make(text: title, size: 14, weight: .bold, color: AppTheme.Color.textDark)
        let descL  = UILabel.make(text: desc,  size: 11, color: AppTheme.Color.textMuted)

        let textS = UIStackView.make(axis: .vertical, spacing: 2)
        textS.addArrangedSubview(titleL)
        textS.addArrangedSubview(descL)
        textS.setContentHuggingPriority(.defaultLow, for: .horizontal)

        accessory.setContentHuggingPriority(.required, for: .horizontal)
        accessory.setContentCompressionResistancePriority(.required, for: .horizontal)

        let row = UIStackView.make(axis: .horizontal, spacing: 8, alignment: .center)
        row.addArrangedSubview(textS)
        row.addArrangedSubview(accessory)
        return row
    }
}
