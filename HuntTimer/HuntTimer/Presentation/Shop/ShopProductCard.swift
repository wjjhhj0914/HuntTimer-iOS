import UIKit
import SnapKit

/// 쇼핑 화면 상품 카드 컴포넌트
final class ShopProductCard: UIView {

    var onLikeToggled: (() -> Void)?
    private var isLiked: Bool
    private let product: ShopProduct

    private lazy var likeBtn: UIButton = {
        let btn = UIButton(type: .system)
        btn.backgroundColor = UIColor(white: 1, alpha: 0.85)
        btn.layer.cornerRadius = 14
        btn.addTarget(self, action: #selector(likeTapped), for: .touchUpInside)
        btn.snp.makeConstraints { $0.width.height.equalTo(28) }
        return btn
    }()

    init(product: ShopProduct, width: CGFloat) {
        self.product = product
        self.isLiked = product.isLiked
        super.init(frame: .zero)
        setup(width: width)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setup(width: CGFloat) {
        applyCardStyle(cornerRadius: AppTheme.Radius.large)

        let imageView = AsyncImageView(contentMode: .scaleAspectFill)
        imageView.loadImage(from: product.imageURL)
        imageView.layer.cornerRadius = AppTheme.Radius.large
        imageView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        imageView.clipsToBounds = true

        // Badge
        let badgeLabel = UILabel.make(text: product.badge, size: 10, weight: .bold, color: AppTheme.Color.textDark)
        let badgePill  = UIView()
        badgePill.backgroundColor = UIColor(white: 1, alpha: 0.85)
        badgePill.layer.cornerRadius = 8
        badgePill.isHidden = product.badge.isEmpty
        badgePill.addSubview(badgeLabel)
        badgeLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(3)
            make.leading.trailing.equalToSuperview().inset(6)
        }

        // Recommended overlay
        let recLabel = UILabel.make(text: product.recommendReason ?? "", size: 9, weight: .bold, color: .white, lines: 2)
        let recBG    = UIView()
        recBG.isHidden = !product.recommended
        let recGrad  = CAGradientLayer()
        recGrad.colors     = [UIColor.clear.cgColor, AppTheme.Color.primary.withAlphaComponent(0.9).cgColor]
        recGrad.startPoint = CGPoint(x: 0.5, y: 0)
        recGrad.endPoint   = CGPoint(x: 0.5, y: 1)
        recBG.layer.insertSublayer(recGrad, at: 0)
        DispatchQueue.main.async {
            recGrad.frame = CGRect(x: 0, y: 0, width: width, height: 36)
        }
        recBG.addSubview(recLabel)
        recLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-6)
            make.leading.equalToSuperview().offset(8)
            make.trailing.equalToSuperview().offset(-8)
        }

        let imageContainer = UIView()
        imageContainer.clipsToBounds = true
        imageContainer.layer.cornerRadius = AppTheme.Radius.large
        imageContainer.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        [imageView, badgePill, recBG, likeBtn].forEach { imageContainer.addSubview($0) }
        imageView.snp.makeConstraints { $0.edges.equalToSuperview() }
        imageContainer.snp.makeConstraints { $0.height.equalTo(130) }
        badgePill.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.equalToSuperview().offset(8)
        }
        likeBtn.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.trailing.equalToSuperview().offset(-8)
        }
        recBG.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(36)
        }
        updateLikeButton()

        // Info section
        let brandL  = UILabel.make(text: product.brand, size: 10, color: AppTheme.Color.textMuted)
        let nameL   = UILabel.make(text: product.name,  size: 12, weight: .bold, color: AppTheme.Color.textDark, lines: 2)
        let starL   = UILabel.make(text: "⭐ \(product.rating)  (\(product.reviews))", size: 10, color: AppTheme.Color.textMuted)
        let priceL  = UILabel.make(text: product.price.wonFormatted, size: 14, weight: .black, color: AppTheme.Color.textDark)

        let cartBtn = UIButton(type: .system)
        cartBtn.setTitle("🛒", for: .normal)
        cartBtn.backgroundColor = AppTheme.Color.primary
        cartBtn.layer.cornerRadius = 12
        cartBtn.snp.makeConstraints { $0.width.height.equalTo(28) }

        let priceRow = UIStackView.make(axis: .horizontal, alignment: .center)
        priceRow.addArrangedSubview(priceL)
        priceRow.addArrangedSubview(cartBtn)

        let infoStack = UIStackView.make(axis: .vertical, spacing: 4)
        [brandL, nameL, starL, priceRow].forEach { infoStack.addArrangedSubview($0) }

        let mainStack = UIStackView.make(axis: .vertical, spacing: 0)
        mainStack.addArrangedSubview(imageContainer)
        let infoPadding = UIView()
        infoPadding.addSubview(infoStack)
        infoStack.snp.makeConstraints { $0.edges.equalToSuperview().inset(10) }
        mainStack.addArrangedSubview(infoPadding)

        addSubview(mainStack)
        mainStack.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    @objc private func likeTapped() {
        isLiked.toggle()
        updateLikeButton()
        onLikeToggled?()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func updateLikeButton() {
        likeBtn.setTitle(isLiked ? "❤️" : "🤍", for: .normal)
    }
}
