import UIKit
import SnapKit

/// 쇼핑 화면 루트 뷰 — 모든 UI 선언과 SnapKit 레이아웃을 담당
final class ShopView: BaseView {

    // MARK: - Constants
    let filters = ["전체", "장난감", "깃털", "공", "간식"]

    // MARK: - Scroll (private)
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.alwaysBounceVertical = true
        sv.backgroundColor = AppTheme.Color.background
        return sv
    }()
    private let contentStack: UIStackView = {
        let sv = UIStackView.make(axis: .vertical, spacing: 16)
        sv.layoutMargins = UIEdgeInsets(top: 12, left: 0, bottom: 32, right: 0)
        sv.isLayoutMarginsRelativeArrangement = true
        return sv
    }()

    // MARK: - Public UI
    var filterButtons: [UIButton] = []
    let productGridContainer = UIView()

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
        contentStack.addArrangedSubview(makeHeader())
        contentStack.addArrangedSubview(makePromoBanner())
        contentStack.addArrangedSubview(makeFilterRow())
        contentStack.addArrangedSubview(makeRecommendedHeader())
        contentStack.addArrangedSubview(productGridContainer)
    }

    // MARK: - Sections
    private func makeHeader() -> UIView {
        let v      = UIView()
        let titleL = UILabel.make(text: "냥 쇼핑몰 🛒", size: 22, weight: .black, color: AppTheme.Color.textDark)
        let subL   = UILabel.make(text: "Naver API · 뮤기 맞춤 추천", size: 12, color: AppTheme.Color.textMuted)
        let textS  = UIStackView.make(axis: .vertical, spacing: 2)
        textS.addArrangedSubview(titleL)
        textS.addArrangedSubview(subL)

        let searchBtn = makeIconButton("🔍", bg: .white)
        let cartBtn   = makeIconButton("🛒", bg: AppTheme.Color.primary)
        let cartBadge = UILabel.make(text: "3", size: 9, weight: .bold,
                                     color: AppTheme.Color.textDark, alignment: .center)
        cartBadge.backgroundColor = AppTheme.Color.yellow
        cartBadge.layer.cornerRadius = 7
        cartBadge.clipsToBounds = true
        cartBadge.snp.makeConstraints { $0.width.height.equalTo(14) }

        let cartContainer = UIView()
        cartContainer.addSubview(cartBtn)
        cartContainer.addSubview(cartBadge)
        cartBtn.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(4)
            make.leading.bottom.trailing.equalToSuperview()
            make.width.height.equalTo(40)
        }
        cartBadge.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview()
        }

        let btnRow = UIStackView.make(axis: .horizontal, spacing: 8, alignment: .center)
        btnRow.addArrangedSubview(searchBtn)
        btnRow.addArrangedSubview(cartContainer)

        let row = UIStackView.make(axis: .horizontal, spacing: 8, alignment: .center)
        row.addArrangedSubview(textS)
        row.addArrangedSubview(btnRow)
        v.addSubview(row)
        row.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }
        return v
    }

    private func makeIconButton(_ emoji: String, bg: UIColor) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(emoji, for: .normal)
        btn.backgroundColor = bg
        btn.layer.cornerRadius = 20
        btn.snp.makeConstraints { $0.width.height.equalTo(40) }
        AppTheme.applyCardShadow(to: btn)
        return btn
    }

    private func makePromoBanner() -> UIView {
        let card = UIView()
        card.layer.cornerRadius = AppTheme.Radius.large
        card.clipsToBounds = true
        let grad = AppTheme.primaryGradient()
        card.layer.insertSublayer(grad, at: 0)
        DispatchQueue.main.async {
            grad.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - 40, height: 72)
        }

        let textL = UILabel.make(text: "🎉 오늘만! 첫 구매 20% 할인", size: 15, weight: .black, color: .white)
        let subL  = UILabel.make(text: "무료 배송 + 사은품 증정", size: 11, color: UIColor(white: 1, alpha: 0.7))
        let textS = UIStackView.make(axis: .vertical, spacing: 3)
        textS.addArrangedSubview(textL)
        textS.addArrangedSubview(subL)

        let badge  = UIView()
        badge.backgroundColor   = UIColor(white: 1, alpha: 0.2)
        badge.layer.cornerRadius = 14
        let badgeL = UILabel.make(text: "🚚 무료배송", size: 12, weight: .bold, color: .white)
        badge.addSubview(badgeL)
        badgeL.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(6)
            make.leading.trailing.equalToSuperview().inset(10)
        }

        let row = UIStackView.make(axis: .horizontal, spacing: 8, alignment: .center)
        row.addArrangedSubview(textS)
        row.addArrangedSubview(badge)
        card.addSubview(row)
        row.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(14)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }

        let wrapper = UIView()
        wrapper.addSubview(card)
        card.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.height.equalTo(72)
        }
        return wrapper
    }

    private func makeFilterRow() -> UIScrollView {
        let sv = UIScrollView()
        sv.showsHorizontalScrollIndicator = false
        sv.snp.makeConstraints { $0.height.equalTo(40) }

        let stack = UIStackView.make(axis: .horizontal, spacing: 8)
        stack.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        stack.isLayoutMarginsRelativeArrangement = true

        filters.forEach { f in
            let btn = UIButton(type: .system)
            btn.setTitle(f, for: .normal)
            btn.titleLabel?.font = .appFont(size: 13, weight: .bold)
            btn.layer.cornerRadius = 14
            btn.contentEdgeInsets = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
            filterButtons.append(btn)
            stack.addArrangedSubview(btn)
        }

        sv.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalToSuperview()
        }
        return sv
    }

    private func makeRecommendedHeader() -> UIView {
        let v = UIView()
        let l = UILabel.make(text: "⭐ 뮤기의 사냥 기록 기반 추천", size: 13, weight: .bold,
                             color: AppTheme.Color.yellowDark)
        v.addSubview(l)
        l.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview().offset(20)
        }
        return v
    }

    // MARK: - Filter Button Style
    func updateFilterButtonStyle(_ btn: UIButton, isSelected: Bool) {
        btn.backgroundColor = isSelected ? AppTheme.Color.primary : AppTheme.Color.primaryLight
        btn.setTitleColor(isSelected ? .white : AppTheme.Color.textMedium, for: .normal)
    }
}
