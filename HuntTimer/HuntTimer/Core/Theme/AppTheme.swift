import UIKit

enum AppTheme {

    // MARK: - Colors
    enum Color {
        static let primary      = UIColor(hex: "#8DC4A7")  // Sage Green
        static let primaryDeep  = UIColor(hex: "#5FA380")  // Mint 500
        static let primaryLight = UIColor(hex: "#EDF7F2")  // Mint 50
        static let yellow       = UIColor(hex: "#FFD4B5")  // Peach
        static let yellowLight  = UIColor(hex: "#F5E3D0")  // Sand
        static let yellowDark   = UIColor(hex: "#8B6A5A")  // Mocha
        static let background   = UIColor(hex: "#FEF8F3")  // Warm White
        static let cardBG       = UIColor.white
        static let textDark     = UIColor(hex: "#2D1B0E")  // Espresso
        static let textMedium   = UIColor(hex: "#8B6A5A")  // Mocha
        static let textMuted    = UIColor(hex: "#C4956A")  // Clay
        static let purple       = UIColor(hex: "#F0C0C8")  // Rose
        static let purpleDeep   = UIColor(hex: "#C4D4E4")  // Mist
        static let purpleLight  = UIColor(hex: "#C9EBD8")  // Mint 100
        static let separator    = UIColor(hex: "#EDF7F2")  // Mint 50
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
