import UIKit
import SnapKit

/// 날짜별 놀이시간 바 차트 — 목록 화면 상단에 표시
final class PlayTimeChartView: UIView {

    // MARK: - Constants
    private let goalSeconds    = 1800           // 30분 목표선
    private let maxSeconds     = 3600           // Y축 최대 (60분)
    private let barColor       = AppTheme.Color.primary
    private let goalBarColor   = AppTheme.Color.yellow   // 30분 이상인 날

    // MARK: - State
    private var entries: [(date: Date, totalSeconds: Int)] = []

    // MARK: - Subviews
    private let barsArea    = UIView()           // 막대가 그려지는 영역
    private let goalLine    = UIView()
    private let goalDot     = UIView()
    private let goalLabel   = UILabel()

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Public API
    func configure(entries: [(date: Date, totalSeconds: Int)]) {
        self.entries = entries
        setNeedsLayout()
    }

    // MARK: - Setup
    private func setupUI() {
        backgroundColor     = .white
        layer.cornerRadius  = 14
        layer.shadowColor   = UIColor.black.cgColor
        layer.shadowOpacity = 0.06
        layer.shadowRadius  = 8
        layer.shadowOffset  = CGSize(width: 0, height: 2)

        addSubview(barsArea)
        barsArea.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-28)   // day 레이블용 여백
        }

        goalLine.backgroundColor = AppTheme.Color.primary.withAlphaComponent(0.25)
        goalDot.backgroundColor  = AppTheme.Color.primary.withAlphaComponent(0.5)
        goalDot.layer.cornerRadius = 3

        goalLabel.text      = "30분"
        goalLabel.font      = .systemFont(ofSize: 9, weight: .semibold)
        goalLabel.textColor = AppTheme.Color.primary

        barsArea.addSubview(goalLine)
        barsArea.addSubview(goalDot)
        barsArea.addSubview(goalLabel)
    }

    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        guard barsArea.bounds.width > 0, !entries.isEmpty else { return }
        redraw()
    }

    private func redraw() {
        // 이전 막대·레이블만 제거 (goalLine·goalDot·goalLabel 유지)
        barsArea.subviews
            .filter { $0 !== goalLine && $0 !== goalDot && $0 !== goalLabel }
            .forEach { $0.removeFromSuperview() }

        let count      = entries.count
        let areaW      = barsArea.bounds.width
        let areaH      = barsArea.bounds.height - 18   // 하단 day 레이블 18pt 예약
        let spacing: CGFloat = 6
        let barW       = max(6, (areaW - spacing * CGFloat(count - 1)) / CGFloat(count))

        // 목표선 (30분 비율 위치)
        let goalRatio  = CGFloat(goalSeconds) / CGFloat(maxSeconds)
        let goalY      = areaH * (1 - goalRatio)
        goalLine.frame = CGRect(x: 0, y: goalY, width: areaW, height: 1)
        goalDot.frame  = CGRect(x: -4, y: goalY - 3, width: 6, height: 6)
        goalLabel.sizeToFit()
        goalLabel.frame = CGRect(
            x: areaW - goalLabel.frame.width,
            y: goalY - goalLabel.frame.height - 2,
            width: goalLabel.frame.width,
            height: goalLabel.frame.height
        )

        let dayFmt = DateFormatter()
        dayFmt.locale     = Locale(identifier: "ko_KR")
        dayFmt.dateFormat = "EEE"   // 월·화·수…

        for (i, entry) in entries.enumerated() {
            let x = CGFloat(i) * (barW + spacing)

            // 막대
            let ratio  = min(1.0, CGFloat(entry.totalSeconds) / CGFloat(maxSeconds))
            let barH   = max(2, areaH * ratio)
            let y      = areaH - barH
            let color  = entry.totalSeconds >= goalSeconds ? goalBarColor : barColor

            let bar               = UIView()
            bar.backgroundColor   = color.withAlphaComponent(0.85)
            bar.layer.cornerRadius = min(4, barW / 2)
            bar.frame             = CGRect(x: x, y: y, width: barW, height: barH)
            barsArea.addSubview(bar)

            // 날짜 레이블
            let lbl           = UILabel()
            lbl.text          = dayFmt.string(from: entry.date)
            lbl.font          = .systemFont(ofSize: 9, weight: .medium)
            lbl.textColor     = AppTheme.Color.textMuted
            lbl.textAlignment = .center
            lbl.frame         = CGRect(x: x, y: areaH + 4, width: barW, height: 14)
            barsArea.addSubview(lbl)
        }

        // 목표선·레이블을 최상단으로
        barsArea.bringSubviewToFront(goalLine)
        barsArea.bringSubviewToFront(goalDot)
        barsArea.bringSubviewToFront(goalLabel)
    }
}
