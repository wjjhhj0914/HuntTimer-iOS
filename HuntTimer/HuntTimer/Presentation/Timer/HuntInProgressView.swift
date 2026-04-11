import UIKit
import SnapKit

/// 사냥 진행 중 화면 View
final class HuntInProgressView: BaseView {

    // MARK: - Timer Card
    private let statusPillView: UIView = {
        let v = UIView()
        v.backgroundColor    = AppTheme.Color.yellowLight
        v.layer.cornerRadius = 20
        return v
    }()

    let statusDot: UIView = {
        let v = UIView()
        v.backgroundColor    = AppTheme.Color.primary
        v.layer.cornerRadius = 4
        return v
    }()

    let statusLabel = UILabel.make(text: "사냥 중", size: 12, weight: .semibold,
                                   color: AppTheme.Color.textDark)

    let timerLabel: UILabel = {
        let l = UILabel()
        l.font          = .appFont(size: 64, weight: .black)
        l.textColor     = AppTheme.Color.textDark
        l.textAlignment = .center
        return l
    }()

    let stopButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("중지", for: .normal)
        btn.setTitleColor(AppTheme.Color.textDark, for: .normal)
        btn.titleLabel?.font   = .appFont(size: 14, weight: .bold)
        btn.backgroundColor    = AppTheme.Color.yellowLight
        btn.layer.cornerRadius = 26
        btn.clipsToBounds      = true
        return btn
    }()

    let pauseResumeButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("일시정지", for: .normal)
        btn.setTitleColor(AppTheme.Color.textDark, for: .normal)
        btn.titleLabel?.font   = .appFont(size: 14, weight: .bold)
        btn.backgroundColor    = AppTheme.Color.primary
        btn.layer.cornerRadius = 26
        btn.clipsToBounds      = true
        return btn
    }()

    // MARK: - Toy Card
    let toyChipLabel: UILabel = {
        let l = UILabel()
        l.font          = .appFont(size: 17, weight: .bold)
        l.textColor     = AppTheme.Color.textDark
        l.textAlignment = .left
        return l
    }()

    // MARK: - Cat Card
    let catCountBadgeLabel = UILabel.make(text: "0마리", size: 11, weight: .semibold,
                                          color: AppTheme.Color.textDark)

    let catAvatarsStack: UIStackView = UIStackView.make(
        axis: .horizontal, spacing: 20, alignment: .top
    )

    // MARK: - BaseView
    override func setupUI() {
        backgroundColor = AppTheme.Color.background

        let scrollView   = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide)
            make.leading.trailing.bottom.equalToSuperview()
        }

        let contentStack = UIStackView.make(axis: .vertical, spacing: 0)
        scrollView.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.top.leading.trailing.bottom.equalToSuperview()
            make.width.equalTo(scrollView)
        }

        let timerSection = makeTimerCard()
        let toySection   = makeToyCard()
        let catSection   = makeCatCard()
        let spacer       = makeBottomSpacer()

        [timerSection, toySection, catSection, spacer].forEach {
            contentStack.addArrangedSubview($0)
        }
        contentStack.setCustomSpacing(12, after: timerSection)
        contentStack.setCustomSpacing(12, after: toySection)
        contentStack.setCustomSpacing(0,  after: catSection)
    }

    // MARK: - Card Builders

    private func makeTimerCard() -> UIView {
        // 상태 pill
        let pillRow = UIStackView.make(axis: .horizontal, spacing: 6, alignment: .center)
        pillRow.addArrangedSubview(statusDot)
        pillRow.addArrangedSubview(statusLabel)
        statusDot.snp.makeConstraints { $0.width.height.equalTo(8) }
        statusPillView.addSubview(pillRow)
        pillRow.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(6)
            make.leading.trailing.equalToSuperview().inset(14)
        }

        // 제어 버튼 행
        let ctrlRow = UIStackView.make(axis: .horizontal, spacing: 12, distribution: .fillEqually)
        ctrlRow.addArrangedSubview(stopButton)
        ctrlRow.addArrangedSubview(pauseResumeButton)
        stopButton.snp.makeConstraints       { $0.height.equalTo(52) }
        pauseResumeButton.snp.makeConstraints { $0.height.equalTo(52) }

        let cardStack = UIStackView.make(axis: .vertical, spacing: 12, alignment: .center)
        cardStack.addArrangedSubview(statusPillView)
        cardStack.addArrangedSubview(timerLabel)
        cardStack.addArrangedSubview(ctrlRow)
        ctrlRow.snp.makeConstraints { $0.leading.trailing.equalToSuperview() }

        return wrapInCard(cardStack,
                          padding: UIEdgeInsets(top: 24, left: 20, bottom: 20, right: 20))
    }

    private func makeToyCard() -> UIView {
        let titleL = UILabel.make(text: "선택한 장난감", size: 14, weight: .bold,
                                  color: AppTheme.Color.textDark)

        // amber 칩
        let chip = UIView()
        chip.backgroundColor    = AppTheme.Color.primary
        chip.layer.cornerRadius = 20
        chip.addSubview(toyChipLabel)
        toyChipLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(24)
            make.top.bottom.equalToSuperview()
            make.height.equalTo(52)
        }

        // 칩을 좌측 정렬하는 래퍼
        let chipWrap = UIView()
        chipWrap.addSubview(chip)
        chip.snp.makeConstraints { make in
            make.top.bottom.leading.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
        }

        let cardStack = UIStackView.make(axis: .vertical, spacing: 12)
        cardStack.addArrangedSubview(titleL)
        cardStack.addArrangedSubview(chipWrap)

        return wrapInCard(cardStack)
    }

    private func makeCatCard() -> UIView {
        let titleL = UILabel.make(text: "함께하는 사냥꾼들", size: 14, weight: .bold,
                                  color: AppTheme.Color.textDark)

        // N마리 배지
        let badgeView = UIView()
        badgeView.backgroundColor    = AppTheme.Color.yellowLight
        badgeView.layer.cornerRadius = 12
        badgeView.addSubview(catCountBadgeLabel)
        catCountBadgeLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(4)
            make.leading.trailing.equalToSuperview().inset(10)
        }

        let headerRow = UIStackView.make(axis: .horizontal, spacing: 8, alignment: .center)
        headerRow.addArrangedSubview(titleL)
        headerRow.addArrangedSubview(UIView())   // spacer
        headerRow.addArrangedSubview(badgeView)

        // 수평 스크롤 가능한 아바타 행
        let catScrollView = UIScrollView()
        catScrollView.showsHorizontalScrollIndicator = false
        catScrollView.addSubview(catAvatarsStack)
        catAvatarsStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(catScrollView)
        }
        catScrollView.snp.makeConstraints { $0.height.equalTo(104) }

        let cardStack = UIStackView.make(axis: .vertical, spacing: 16)
        cardStack.addArrangedSubview(headerRow)
        cardStack.addArrangedSubview(catScrollView)

        return wrapInCard(cardStack)
    }

    private func makeBottomSpacer() -> UIView {
        let v = UIView()
        v.snp.makeConstraints { $0.height.equalTo(40) }
        return v
    }

    // MARK: - Card Wrapper

    private func wrapInCard(_ content: UIView,
                             padding: UIEdgeInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)) -> UIView {
        let card = UIView()
        card.backgroundColor    = .white
        card.layer.cornerRadius = 24
        AppTheme.applyCardShadow(to: card, opacity: 0.08, radius: 20)
        card.addSubview(content)
        content.snp.makeConstraints { $0.edges.equalToSuperview().inset(padding) }

        let wrap = UIView()
        wrap.addSubview(card)
        card.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(20)
        }
        return wrap
    }

    // MARK: - State Updates

    func updatePauseResumeState(isPaused: Bool) {
        UIView.animate(withDuration: 0.18) {
            if isPaused {
                self.pauseResumeButton.setTitle("재개하기", for: .normal)
                self.statusDot.backgroundColor = AppTheme.Color.yellow
                self.statusLabel.text          = "일시정지"
            } else {
                self.pauseResumeButton.setTitle("일시정지", for: .normal)
                self.statusDot.backgroundColor = AppTheme.Color.primary
                self.statusLabel.text          = "사냥 중"
            }
        }
    }
}
