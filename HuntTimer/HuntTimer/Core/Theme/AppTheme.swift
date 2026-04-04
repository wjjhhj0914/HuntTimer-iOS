import UIKit

enum AppTheme {

    // MARK: - Colors
    enum Color {
        static let primary      = UIColor(hex: "#FF8FAB")
        static let primaryDeep  = UIColor(hex: "#FF6B9A")
        static let primaryLight = UIColor(hex: "#FFE4EE")
        static let yellow       = UIColor(hex: "#FFD966")
        static let yellowLight  = UIColor(hex: "#FFF3D6")
        static let yellowDark   = UIColor(hex: "#C49A00")
        static let background   = UIColor(hex: "#FEF8F3")
        static let cardBG       = UIColor.white
        static let textDark     = UIColor(hex: "#3D2C2C")
        static let textMedium   = UIColor(hex: "#9B6E6E")
        static let textMuted    = UIColor(hex: "#C4A0A0")
        static let purple       = UIColor(hex: "#A78BFA")
        static let purpleDeep   = UIColor(hex: "#8B5CF6")
        static let purpleLight  = UIColor(hex: "#EDE9FE")
        static let separator    = UIColor(hex: "#FFE4EE")
    }

    // MARK: - Corner Radius
    enum Radius {
        static let small:  CGFloat = 12
        static let medium: CGFloat = 16
        static let large:  CGFloat = 20
        static let xLarge: CGFloat = 24
        static let xxLarge: CGFloat = 28
        static let card:   CGFloat = 24
    }

    // MARK: - Spacing
    enum Spacing {
        static let xs:  CGFloat = 4
        static let sm:  CGFloat = 8
        static let md:  CGFloat = 12
        static let lg:  CGFloat = 16
        static let xl:  CGFloat = 20
        static let xxl: CGFloat = 24
    }

    // MARK: - Shadow
    static func applyCardShadow(to view: UIView, opacity: Float = 0.10, radius: CGFloat = 10) {
        view.layer.shadowColor   = AppTheme.Color.primary.cgColor
        view.layer.shadowOffset  = CGSize(width: 0, height: 3)
        view.layer.shadowOpacity = opacity
        view.layer.shadowRadius  = radius
    }

    static func applyButtonShadow(to view: UIView) {
        view.layer.shadowColor   = AppTheme.Color.primaryDeep.cgColor
        view.layer.shadowOffset  = CGSize(width: 0, height: 6)
        view.layer.shadowOpacity = 0.30
        view.layer.shadowRadius  = 14
    }

    // MARK: - Gradient
    static func primaryGradient() -> CAGradientLayer {
        let g = CAGradientLayer()
        g.colors     = [Color.primary.cgColor, Color.primaryDeep.cgColor]
        g.startPoint = CGPoint(x: 0, y: 0)
        g.endPoint   = CGPoint(x: 1, y: 1)
        return g
    }

    static func purpleGradient() -> CAGradientLayer {
        let g = CAGradientLayer()
        g.colors     = [Color.purple.cgColor, Color.purpleDeep.cgColor]
        g.startPoint = CGPoint(x: 0, y: 0)
        g.endPoint   = CGPoint(x: 1, y: 1)
        return g
    }
}
