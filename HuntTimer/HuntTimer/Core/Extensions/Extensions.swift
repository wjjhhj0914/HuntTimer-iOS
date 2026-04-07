import UIKit

// MARK: - UIColor + Hex
extension UIColor {
    convenience init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if s.hasPrefix("#") { s.removeFirst() }
        var rgb: UInt64 = 0
        Scanner(string: s).scanHexInt64(&rgb)
        let r, g, b, a: CGFloat
        if s.count == 8 {
            // RRGGBBAA
            r = CGFloat((rgb >> 24) & 0xFF) / 255.0
            g = CGFloat((rgb >> 16) & 0xFF) / 255.0
            b = CGFloat((rgb >> 8)  & 0xFF) / 255.0
            a = CGFloat(rgb         & 0xFF) / 255.0
        } else {
            // RRGGBB
            r = CGFloat((rgb >> 16) & 0xFF) / 255.0
            g = CGFloat((rgb >> 8)  & 0xFF) / 255.0
            b = CGFloat(rgb         & 0xFF) / 255.0
            a = 1.0
        }
        self.init(red: r, green: g, blue: b, alpha: a)
    }
}

// MARK: - UIFont helpers
extension UIFont {
    static func appFont(size: CGFloat, weight: Weight = .regular) -> UIFont {
        return .systemFont(ofSize: size, weight: weight)
    }
}

// MARK: - UILabel factory
extension UILabel {
    static func make(
        text: String = "",
        size: CGFloat,
        weight: UIFont.Weight = .regular,
        color: UIColor = AppTheme.Color.textDark,
        lines: Int = 1,
        alignment: NSTextAlignment = .natural
    ) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .appFont(size: size, weight: weight)
        label.textColor = color
        label.numberOfLines = lines
        label.textAlignment = alignment
        return label
    }
}

// MARK: - UIButton rounded filled
extension UIButton {
    static func filledRounded(
        title: String,
        color: UIColor,
        titleColor: UIColor = .white,
        cornerRadius: CGFloat = AppTheme.Radius.large
    ) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.setTitleColor(titleColor, for: .normal)
        btn.titleLabel?.font = .appFont(size: 15, weight: .bold)
        btn.backgroundColor = color
        btn.layer.cornerRadius = cornerRadius
        btn.clipsToBounds = true
        return btn
    }
}

// MARK: - UIView card style
extension UIView {
    func applyCardStyle(cornerRadius: CGFloat = AppTheme.Radius.card) {
        backgroundColor    = AppTheme.Color.cardBG
        layer.cornerRadius = cornerRadius
        clipsToBounds      = false
        AppTheme.applyCardShadow(to: self)
    }

    func applyGradient(_ gradient: CAGradientLayer) {
        gradient.frame = bounds
        if layer.sublayers?.first is CAGradientLayer {
            layer.sublayers?.first?.removeFromSuperlayer()
        }
        layer.insertSublayer(gradient, at: 0)
    }

    /// 패딩이 있는 스택뷰 래퍼
    func wrapped(insets: UIEdgeInsets) -> UIView {
        let container = UIView()
        container.addSubview(self)
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: container.topAnchor, constant: insets.top),
            leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: insets.left),
            trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -insets.right),
            bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -insets.bottom)
        ])
        return container
    }
}

// MARK: - UIStackView factory
extension UIStackView {
    static func make(
        axis: NSLayoutConstraint.Axis,
        spacing: CGFloat = 0,
        alignment: UIStackView.Alignment = .fill,
        distribution: UIStackView.Distribution = .fill
    ) -> UIStackView {
        let sv = UIStackView()
        sv.axis         = axis
        sv.spacing      = spacing
        sv.alignment    = alignment
        sv.distribution = distribution
        return sv
    }
}

// MARK: - UIView tap gesture
extension UIView {
    func onTap(_ target: Any?, action: Selector) {
        isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: target, action: action)
        addGestureRecognizer(tap)
    }
}

// MARK: - CALayer round specific corners
extension UIView {
    func roundCorners(_ corners: CACornerMask, radius: CGFloat) {
        layer.cornerRadius  = radius
        layer.maskedCorners = corners
        clipsToBounds = true
    }
}

// MARK: - Number formatter
extension Int {
    var wonFormatted: String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return (f.string(from: NSNumber(value: self)) ?? "\(self)") + "원"
    }
}
