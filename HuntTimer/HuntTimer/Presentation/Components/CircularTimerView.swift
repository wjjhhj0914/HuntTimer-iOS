import UIKit

/// 타이머 화면 원형 게이지 (경과/잔여 + 발바닥 초침)
final class CircularTimerView: UIView {

    private let trackLayer   = CAShapeLayer()
    private let remainLayer  = CAShapeLayer()
    private let elapsedLayer = CAShapeLayer()
    private let pawLayer     = CATextLayer()
    private let innerCircle  = CAShapeLayer()

    private var currentProgress: Float = 0
    private var currentElapsed: Int    = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        setupLayers()
    }

    private func setupLayers() {
        layer.sublayers?.forEach { $0.removeFromSuperlayer() }

        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius: CGFloat = bounds.width / 2 - 20
        let start  = -CGFloat.pi / 2
        let end    = start + 2 * CGFloat.pi
        let arc    = UIBezierPath(arcCenter: center, radius: radius, startAngle: start, endAngle: end, clockwise: true).cgPath

        // Dashed outer ring
        let outerRing = CAShapeLayer()
        outerRing.path        = UIBezierPath(arcCenter: center, radius: radius + 16, startAngle: start, endAngle: end, clockwise: true).cgPath
        outerRing.fillColor   = UIColor.clear.cgColor
        outerRing.strokeColor = AppTheme.Color.primaryLight.cgColor
        outerRing.lineWidth   = 1
        outerRing.lineDashPattern = [4, 6]
        layer.addSublayer(outerRing)

        // Track
        trackLayer.path        = arc
        trackLayer.fillColor   = UIColor.clear.cgColor
        trackLayer.strokeColor = AppTheme.Color.primaryLight.cgColor
        trackLayer.lineWidth   = 14
        trackLayer.lineCap     = .round
        layer.addSublayer(trackLayer)

        // Remaining (yellow)
        remainLayer.path        = arc
        remainLayer.fillColor   = UIColor.clear.cgColor
        remainLayer.strokeColor = AppTheme.Color.yellow.cgColor
        remainLayer.lineWidth   = 14
        remainLayer.lineCap     = .round
        layer.addSublayer(remainLayer)

        // Elapsed (pink)
        elapsedLayer.path        = arc
        elapsedLayer.fillColor   = UIColor.clear.cgColor
        elapsedLayer.strokeColor = AppTheme.Color.primary.cgColor
        elapsedLayer.lineWidth   = 14
        elapsedLayer.lineCap     = .round
        layer.addSublayer(elapsedLayer)

        // Inner white circle
        let innerPath = UIBezierPath(arcCenter: center, radius: radius - 10, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true).cgPath
        innerCircle.path         = innerPath
        innerCircle.fillColor    = UIColor.white.cgColor
        innerCircle.shadowColor  = AppTheme.Color.primaryLight.cgColor
        innerCircle.shadowOpacity = 1
        innerCircle.shadowRadius = 2
        layer.addSublayer(innerCircle)

        // Paw text layer
        pawLayer.string        = "🐾"
        pawLayer.fontSize      = 16
        pawLayer.alignmentMode = .center
        pawLayer.frame = CGRect(x: 0, y: 0, width: 28, height: 28)
        layer.addSublayer(pawLayer)

        setProgress(currentProgress, animated: false)
        setSecondHand(currentElapsed)   // layoutSubviews 이후에도 올바른 위치 복원
    }

    func setProgress(_ progress: Float, animated: Bool) {
        currentProgress = progress
        let p = CGFloat(progress)
        CATransaction.begin()
        CATransaction.setDisableActions(!animated)
        elapsedLayer.strokeStart = 0
        elapsedLayer.strokeEnd   = p
        remainLayer.strokeStart  = p
        remainLayer.strokeEnd    = 1
        CATransaction.commit()
    }

    func setSecondHand(_ totalElapsed: Int) {
        currentElapsed = totalElapsed
        guard !bounds.isEmpty else { return }
        let center   = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius: CGFloat = bounds.width / 2 - 20
        let fraction = Double(totalElapsed % 60) / 60.0
        let angle    = -Double.pi / 2 + fraction * 2 * Double.pi
        let px = center.x + CGFloat(cos(angle)) * radius
        let py = center.y + CGFloat(sin(angle)) * radius
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        pawLayer.position = CGPoint(x: px, y: py)
        CATransaction.commit()
    }
}
