import UIKit
import SnapKit

/// 입양 화면 루트 뷰 — 모든 UI 선언과 SnapKit 레이아웃을 담당
final class AdoptView: BaseView {

    // MARK: - Constants
    let locationFilters = ["전체", "서울", "경기", "인천", "부산"]
    let ageFilters      = ["전체", "아기냥", "1~3살", "4~7살", "8살+"]

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
        sv.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 32, right: 0)
        sv.isLayoutMarginsRelativeArrangement = true
        return sv
    }()

    // MARK: - Public UI
    var locationButtons: [UIButton] = []
    var ageButtons:      [UIButton] = []
    let catCardsContainer = UIView()

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
        contentStack.addArrangedSubview(makeFilterSection())
        contentStack.addArrangedSubview(catCardsContainer)
        contentStack.addArrangedSubview(makeFooterCTA())
    }

    // MARK: - Hero
    private func makeHeroSection() -> UIView {
        let heroBG = UIView()
        heroBG.backgroundColor = AppTheme.Color.purpleLight

        let circle1 = UIView()
        circle1.backgroundColor = AppTheme.Color.purple.withAlphaComponent(0.25)
        circle1.layer.cornerRadius = 56
        let circle2 = UIView()
        circle2.backgroundColor = AppTheme.Color.primary.withAlphaComponent(0.20)
        circle2.layer.cornerRadius = 40

        heroBG.addSubview(circle1)
        heroBG.addSubview(circle2)
        circle1.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(-28)
            make.trailing.equalToSuperview().offset(28)
            make.width.height.equalTo(112)
        }
        circle2.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(16)
            make.leading.equalToSuperview().offset(-20)
            make.width.height.equalTo(80)
        }

        let iconView = UIView()
        iconView.backgroundColor   = UIColor(white: 1, alpha: 0.7)
        iconView.layer.cornerRadius = 24
        let iconL = UILabel.make(text: "🐾", size: 24, alignment: .center)
        iconView.addSubview(iconL)
        iconL.snp.makeConstraints { $0.center.equalToSuperview() }
        iconView.snp.makeConstraints { $0.width.height.equalTo(48) }

        let titleL = UILabel.make(text: "새 냥이 만나기 💜", size: 22, weight: .black, color: AppTheme.Color.textDark)
        let subL   = UILabel.make(text: "보호소의 아이들이 기다리고 있어요", size: 13, color: AppTheme.Color.textMedium)
        let textS  = UIStackView.make(axis: .vertical, spacing: 3)
        textS.addArrangedSubview(titleL)
        textS.addArrangedSubview(subL)

        let topRow = UIStackView.make(axis: .horizontal, spacing: 12, alignment: .center)
        topRow.addArrangedSubview(textS)
        topRow.addArrangedSubview(iconView)

        let statsData: [(String, String, String)] = [
            ("🏠", "1,247",  "이번 달 입양"),
            ("🐱", "4,832", "대기 중인 냥이"),
            ("💜", "98%",   "입양 만족도"),
        ]
        let statsRow = UIStackView.make(axis: .horizontal, spacing: 10, distribution: .fillEqually)
        statsData.forEach { emoji, value, lbl in
            let card = UIView()
            card.backgroundColor   = UIColor(white: 1, alpha: 0.70)
            card.layer.cornerRadius = AppTheme.Radius.medium
            let col = UIStackView.make(axis: .vertical, spacing: 2, alignment: .center)
            col.addArrangedSubview(UILabel.make(text: emoji, size: 16, alignment: .center))
            col.addArrangedSubview(UILabel.make(text: value, size: 13, weight: .bold,
                                                color: AppTheme.Color.textDark, alignment: .center))
            col.addArrangedSubview(UILabel.make(text: lbl, size: 9, color: AppTheme.Color.textMedium, alignment: .center))
            card.addSubview(col)
            col.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview().inset(8)
                make.leading.trailing.equalToSuperview().inset(4)
            }
            statsRow.addArrangedSubview(card)
        }

        let mainStack = UIStackView.make(axis: .vertical, spacing: 12)
        mainStack.addArrangedSubview(topRow)
        mainStack.addArrangedSubview(statsRow)
        heroBG.addSubview(mainStack)
        mainStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().offset(-24)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }

        heroBG.layer.cornerRadius  = AppTheme.Radius.xxLarge
        heroBG.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        return heroBG
    }

    // MARK: - Filters
    private func makeFilterSection() -> UIView {
        let wrapper   = UIView()
        let locHeader = UILabel.make(text: "📍 지역", size: 12, color: AppTheme.Color.textMuted)
        let ageHeader = UILabel.make(text: "🐱 나이", size: 12, color: AppTheme.Color.textMuted)

        let locScroll = makeHorizontalFilterScroll(filters: locationFilters, isLocation: true, buttonStore: &locationButtons)
        let ageScroll = makeHorizontalFilterScroll(filters: ageFilters, isLocation: false, buttonStore: &ageButtons)

        let mainStack = UIStackView.make(axis: .vertical, spacing: 8)
        mainStack.addArrangedSubview(locHeader)
        mainStack.addArrangedSubview(locScroll)
        mainStack.addArrangedSubview(ageHeader)
        mainStack.addArrangedSubview(ageScroll)

        wrapper.addSubview(mainStack)
        mainStack.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }
        return wrapper
    }

    private func makeHorizontalFilterScroll(filters: [String], isLocation: Bool, buttonStore: inout [UIButton]) -> UIScrollView {
        let sv = UIScrollView()
        sv.showsHorizontalScrollIndicator = false
        sv.snp.makeConstraints { $0.height.equalTo(34) }

        let stack = UIStackView.make(axis: .horizontal, spacing: 8)
        filters.enumerated().forEach { i, f in
            let btn = UIButton(type: .system)
            btn.setTitle(f, for: .normal)
            btn.titleLabel?.font = .appFont(size: 12, weight: .semibold)
            btn.layer.cornerRadius = 14
            btn.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
            btn.tag = i
            updateFilterBtn(btn, isLocation: isLocation, isSelected: i == 0)
            buttonStore.append(btn)
            stack.addArrangedSubview(btn)
        }
        sv.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalToSuperview()
        }
        return sv
    }

    func updateFilterBtn(_ btn: UIButton, isLocation: Bool, isSelected: Bool) {
        if isLocation {
            btn.backgroundColor = isSelected ? AppTheme.Color.purple : AppTheme.Color.purpleLight
            btn.setTitleColor(isSelected ? .white : AppTheme.Color.primary, for: .normal)
        } else {
            btn.backgroundColor = isSelected ? AppTheme.Color.primary : AppTheme.Color.primaryLight
            btn.setTitleColor(isSelected ? .white : AppTheme.Color.textMedium, for: .normal)
        }
    }

    // MARK: - Footer CTA
    private func makeFooterCTA() -> UIView {
        let card = UIView()
        card.layer.cornerRadius = AppTheme.Radius.large

        let grad = CAGradientLayer()
        grad.colors     = [AppTheme.Color.purpleLight.cgColor, AppTheme.Color.primaryLight.cgColor]
        grad.startPoint = CGPoint(x: 0, y: 0)
        grad.endPoint   = CGPoint(x: 1, y: 1)
        card.layer.insertSublayer(grad, at: 0)
        DispatchQueue.main.async {
            grad.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - 40, height: 120)
        }

        let emojiL  = UILabel.make(text: "💜", size: 24, alignment: .center)
        let titleL  = UILabel.make(text: "더 많은 냥이들이 기다려요", size: 14, weight: .bold,
                                   color: AppTheme.Color.textDark, alignment: .center)
        let subL    = UILabel.make(text: "전국 보호소 1,200개 연계", size: 12,
                                   color: AppTheme.Color.textMedium, alignment: .center)
        let moreBtn = UIButton(type: .system)
        moreBtn.setTitle("더 보기 →", for: .normal)
        moreBtn.setTitleColor(.white, for: .normal)
        moreBtn.titleLabel?.font = .appFont(size: 13, weight: .bold)
        moreBtn.backgroundColor  = AppTheme.Color.purple
        moreBtn.layer.cornerRadius = 14
        moreBtn.contentEdgeInsets = UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 20)

        let col = UIStackView.make(axis: .vertical, spacing: 6, alignment: .center)
        [emojiL, titleL, subL, moreBtn].forEach { col.addArrangedSubview($0) }
        card.addSubview(col)
        col.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        let wrapper = UIView()
        wrapper.addSubview(card)
        card.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.height.greaterThanOrEqualTo(120)
        }
        return wrapper
    }
}
