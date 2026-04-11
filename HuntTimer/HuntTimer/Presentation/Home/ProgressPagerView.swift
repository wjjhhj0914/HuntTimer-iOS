import UIKit
import SnapKit

/// 홈 화면 목표 대시보드 — 좌우 스와이프 페이저
/// 페이지 0 = 전체 overview, 페이지 1~N = 개별 고양이
final class ProgressPagerView: UIView {

    // MARK: - Callback
    /// 페이지가 settle 된 후 호출 (index 0 = 전체, 1~N = 고양이)
    var onPageChanged: ((Int) -> Void)?

    // MARK: - State
    private(set) var currentPage: Int = 0
    private var pageCardViews: [ProgressPageCardView] = []

    // MARK: - Subviews
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.isPagingEnabled = true
        sv.showsHorizontalScrollIndicator = false
        sv.clipsToBounds = true
        return sv
    }()

    private let pageControl: UIPageControl = {
        let pc = UIPageControl()
        pc.currentPageIndicatorTintColor = AppTheme.Color.primary
        pc.pageIndicatorTintColor        = UIColor(hex: "#F0D9C0")
        pc.hidesForSinglePage            = true
        return pc
    }()

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Layout
    private func setupLayout() {
        scrollView.delegate = self
        addSubview(scrollView)
        addSubview(pageControl)

        scrollView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(170)
        }
        pageControl.snp.makeConstraints { make in
            make.top.equalTo(scrollView.snp.bottom).offset(4)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        pageControl.addTarget(self, action: #selector(pageControlTapped), for: .valueChanged)
    }

    // MARK: - Configure

    func configure(pages: [CatProgressPage]) {
        guard !pages.isEmpty else { return }
        pageCardViews.forEach { $0.removeFromSuperview() }
        pageCardViews.removeAll()

        pageControl.numberOfPages = pages.count
        pageControl.currentPage   = 0
        currentPage               = 0

        for page in pages {
            let card = ProgressPageCardView()
            card.configure(page: page)
            scrollView.addSubview(card)
            pageCardViews.append(card)
        }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.relayout()
            self.pageCardViews.first?.animateIn()
        }
    }

    // MARK: - Frame-based layout for paging

    private func relayout() {
        let w = scrollView.bounds.width
        let h = scrollView.bounds.height
        guard w > 0, h > 0 else { return }
        for (idx, card) in pageCardViews.enumerated() {
            card.frame = CGRect(x: CGFloat(idx) * w, y: 0, width: w, height: h)
        }
        scrollView.contentSize = CGSize(width: w * CGFloat(pageCardViews.count), height: h)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard !pageCardViews.isEmpty else { return }
        relayout()
        let w = scrollView.bounds.width
        if w > 0 {
            scrollView.setContentOffset(CGPoint(x: CGFloat(currentPage) * w, y: 0), animated: false)
        }
    }

    // MARK: - External Control

    func setPage(_ index: Int, animated: Bool) {
        guard index >= 0, index < pageCardViews.count else { return }
        let w = scrollView.bounds.width
        guard w > 0 else { return }
        scrollView.setContentOffset(CGPoint(x: CGFloat(index) * w, y: 0), animated: animated)
        pageControl.currentPage = index
        if !animated {
            currentPage = index
            onPageChanged?(index)
            pageCardViews[index].animateIn()
        }
        // animated: scrollViewDidEndScrollingAnimation fires → settledOnCurrentOffset()
    }

    // MARK: - Private

    @objc private func pageControlTapped() {
        setPage(pageControl.currentPage, animated: true)
    }

    private func settledOnCurrentOffset() {
        let w = scrollView.bounds.width
        guard w > 0 else { return }
        let page = max(0, min(Int(round(scrollView.contentOffset.x / w)), pageCardViews.count - 1))
        currentPage             = page
        pageControl.currentPage = page
        onPageChanged?(page)
        pageCardViews[page].animateIn()
    }
}

// MARK: - UIScrollViewDelegate

extension ProgressPagerView: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        settledOnCurrentOffset()
    }
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        settledOnCurrentOffset()
    }
}

// MARK: - ProgressPageCardView (private)

private final class ProgressPageCardView: UIView {

    // MARK: - Subviews
    private let gaugeView      = CircularProgressView(size: 130)
    private let centerLabel    = UILabel.make(text: "", size: 20, weight: .black,
                                              color: AppTheme.Color.textDark, alignment: .center)
    private let unitLabel      = UILabel.make(text: "", size: 11,
                                              color: AppTheme.Color.textMuted, alignment: .center)
    private let pctLabel       = UILabel.make(text: "", size: 10, weight: .semibold,
                                              color: AppTheme.Color.primary, alignment: .center)
    private let headerLabel    = UILabel.make(text: "", size: 12, color: AppTheme.Color.textMedium)
    private let valueLabel     = UILabel.make(text: "", size: 17, weight: .black,
                                              color: AppTheme.Color.textDark)
    private let goalBadgeLabel = UILabel.make(text: "", size: 11, weight: .semibold,
                                              color: AppTheme.Color.primary)
    private let timeBadgeLabel = UILabel.make(text: "", size: 11, weight: .semibold,
                                              color: AppTheme.Color.yellowDark)
    private let countLabel     = UILabel.make(text: "", size: 11, color: AppTheme.Color.textMuted)

    private var targetRatio: Float = 0

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupLayout() {
        let card = UIView()
        card.backgroundColor    = .white
        card.layer.cornerRadius = 24
        AppTheme.applyCardShadow(to: card, opacity: 0.08, radius: 20)

        // Gauge 내부 텍스트 스택
        let innerStack = UIStackView.make(axis: .vertical, spacing: 0, alignment: .center)
        [centerLabel, unitLabel, pctLabel].forEach { innerStack.addArrangedSubview($0) }
        gaugeView.addSubview(innerStack)
        innerStack.snp.makeConstraints { $0.center.equalToSuperview() }
        gaugeView.snp.makeConstraints { $0.width.height.equalTo(130) }

        // 배지 칩
        let goalBadge = makePill(goalBadgeLabel, bg: AppTheme.Color.primaryLight)
        let timeBadge = makePill(timeBadgeLabel, bg: AppTheme.Color.yellowLight)
        let badgeRow  = UIStackView.make(axis: .vertical, spacing: 6, alignment: .leading)
        [goalBadge, timeBadge].forEach { badgeRow.addArrangedSubview($0) }

        // 우측 정보 스택
        let infoStack = UIStackView.make(axis: .vertical, spacing: 6)
        [headerLabel, valueLabel, badgeRow, countLabel].forEach { infoStack.addArrangedSubview($0) }

        // 게이지 + 정보 가로 레이아웃
        let row = UIStackView.make(axis: .horizontal, spacing: 16, alignment: .center)
        row.addArrangedSubview(gaugeView)
        row.addArrangedSubview(infoStack)

        card.addSubview(row)
        row.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }

        addSubview(card)
        card.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(20)
        }
    }

    private func makePill(_ label: UILabel, bg: UIColor) -> UIView {
        let pill = UIView()
        pill.backgroundColor    = bg
        pill.layer.cornerRadius = 10
        pill.addSubview(label)
        label.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(4)
            make.leading.trailing.equalToSuperview().inset(8)
        }
        return pill
    }

    // MARK: - Configure

    func configure(page: CatProgressPage) {
        targetRatio = page.progressRatio

        let elapsedText = Self.formatElapsed(seconds: page.todaySeconds)
        let pct         = Int(page.progressRatio * 100)
        let remainSecs  = max(0, page.goalMinutes * 60 - page.todaySeconds)

        headerLabel.text    = page.isOverview ? "전체 사냥 기록" : "\(page.catName)의 기록"
        centerLabel.text    = elapsedText
        unitLabel.text      = "/ \(page.goalMinutes)분"
        pctLabel.text       = "\(pct)%"
        valueLabel.text     = "\(elapsedText) | \(page.goalMinutes)분"
        goalBadgeLabel.text = "목표 \(pct)%"
        timeBadgeLabel.text = Self.formatRemaining(seconds: remainSecs)
        countLabel.text     = "오늘 \(page.completedCount)회 사냥 완료"

        gaugeView.updateProgress(0)
    }

    // MARK: - Animation

    func animateIn() {
        gaugeView.updateProgress(0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self else { return }
            self.gaugeView.animateProgress(self.targetRatio)
        }
    }

    // MARK: - Helpers

    private static func formatElapsed(seconds: Int) -> String {
        if seconds < 60 { return "\(seconds)초" }
        let m = seconds / 60, s = seconds % 60
        return s > 0 ? "\(m)분 \(s)초" : "\(m)분"
    }

    private static func formatRemaining(seconds: Int) -> String {
        if seconds == 0 { return "목표 달성!" }
        if seconds < 60 { return "\(seconds)초 남음" }
        let m = seconds / 60, s = seconds % 60
        return s > 0 ? "\(m)분 \(s)초 남음" : "\(m)분 남음"
    }
}
