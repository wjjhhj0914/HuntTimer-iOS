import UIKit

/// 홈 화면 진행도 원형 게이지
final class CircularProgressView: UIView {

    private let size: CGFloat
    private let trackLayer     = CAShapeLayer()
    private let remainingLayer = CAShapeLayer()
    private let elapsedLayer   = CAShapeLayer()

    init(size: CGFloat) {
        self.size = size
        super.init(frame: CGRect(origin: .zero, size: CGSize(width: size, height: size)))
        setupLayers()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupLayers() {
        backgroundColor = .clear
        let center = CGPoint(x: size / 2, y: size / 2)
        let radius = size / 2 - 8
        let start  = -CGFloat.pi / 2
        let end    = start + 2 * CGFloat.pi
        let path   = UIBezierPath(
            arcCenter: center, radius: radius,
            startAngle: start, endAngle: end, clockwise: true
        ).cgPath

        trackLayer.path        = path
        trackLayer.fillColor   = UIColor.clear.cgColor
        trackLayer.strokeColor = AppTheme.Color.primaryLight.cgColor
        trackLayer.lineWidth   = 10
        trackLayer.lineCap     = .round
        layer.addSublayer(trackLayer)

        remainingLayer.path        = path
        remainingLayer.fillColor   = UIColor.clear.cgColor
        remainingLayer.strokeColor = AppTheme.Color.yellowLight.cgColor
        remainingLayer.lineWidth   = 10
        remainingLayer.lineCap     = .round
        remainingLayer.strokeStart = 0
        remainingLayer.strokeEnd   = 1.0
        layer.addSublayer(remainingLayer)

        elapsedLayer.path        = path
        elapsedLayer.fillColor   = UIColor.clear.cgColor
        elapsedLayer.strokeColor = AppTheme.Color.primary.cgColor
        elapsedLayer.lineWidth   = 10
        elapsedLayer.lineCap     = .round
        elapsedLayer.strokeStart = 0
        elapsedLayer.strokeEnd   = 0
        layer.addSublayer(elapsedLayer)
    }

    /// progress: 0.0 ~ 1.0 (즉시 반영)
    func updateProgress(_ progress: Float) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let p = CGFloat(max(0, min(1, progress)))
        remainingLayer.strokeStart = p
        remainingLayer.strokeEnd   = 1.0
        elapsedLayer.strokeStart   = 0
        elapsedLayer.strokeEnd     = p
        CATransaction.commit()
    }

    /// progress: 0.0 ~ 1.0 (0 → target 쓱- 채우기 애니메이션)
    func animateProgress(_ progress: Float, duration: CFTimeInterval = 0.85) {
        let p = CGFloat(max(0, min(1, progress)))

        // 모델 레이어 값을 먼저 확정해 애니메이션 종료 후 snap-back 방지
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        elapsedLayer.strokeEnd     = p
        remainingLayer.strokeStart = p
        CATransaction.commit()

        let easing = CAMediaTimingFunction(controlPoints: 0.25, 0.46, 0.45, 0.94)

        let elapsedAnim            = CABasicAnimation(keyPath: "strokeEnd")
        elapsedAnim.fromValue      = 0
        elapsedAnim.toValue        = p
        elapsedAnim.duration       = duration
        elapsedAnim.timingFunction = easing
        elapsedLayer.add(elapsedAnim, forKey: "strokeEndAnim")

        let remainingAnim            = CABasicAnimation(keyPath: "strokeStart")
        remainingAnim.fromValue      = 0
        remainingAnim.toValue        = p
        remainingAnim.duration       = duration
        remainingAnim.timingFunction = easing
        remainingLayer.add(remainingAnim, forKey: "strokeStartAnim")
    }
}
