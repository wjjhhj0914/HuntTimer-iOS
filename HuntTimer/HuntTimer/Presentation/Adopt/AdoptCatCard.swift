import UIKit
import SnapKit

/// 입양 화면 고양이 카드 컴포넌트
final class AdoptCatCard: UIView {

    var onLikeToggled: (() -> Void)?
    var onLearnMore:   (() -> Void)?

    private var isLiked: Bool
    private let cat: AdoptCat

    private lazy var likeBtn: UIButton = {
        let btn = UIButton(type: .system)
        btn.backgroundColor = UIColor(white: 1, alpha: 0.80)
        btn.layer.cornerRadius = 18
        btn.snp.makeConstraints { $0.width.height.equalTo(36) }
        btn.addTarget(self, action: #selector(likeTapped), for: .touchUpInside)
        return btn
    }()

    private lazy var learnMoreBtn: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("💜 더 알아보기", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = .appFont(size: 14, weight: .bold)
        btn.layer.cornerRadius = 18
        btn.clipsToBounds = true
        let grad = AppTheme.purpleGradient()
        btn.layer.insertSublayer(grad, at: 0)
        DispatchQueue.main.async {
            grad.frame = btn.bounds.isEmpty
                ? CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - 110, height: 48)
                : btn.bounds
        }
        btn.addTarget(self, action: #selector(learnMoreTapped), for: .touchUpInside)
        return btn
    }()

    init(cat: AdoptCat) {
        self.cat     = cat
        self.isLiked = cat.isLiked
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setup() {
        applyCardStyle(cornerRadius: AppTheme.Radius.xxLarge)

        let imageView = AsyncImageView(contentMode: .scaleAspectFill)
        imageView.loadImage(from: cat.imageURL)
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = AppTheme.Radius.xxLarge
        imageView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        imageView.snp.makeConstraints { $0.height.equalTo(200) }

        let gradView = UIView()
        gradView.isUserInteractionEnabled = false
        let gradLayer = CAGradientLayer()
        gradLayer.colors     = [UIColor.clear.cgColor, UIColor(white: 0, alpha: 0.65).cgColor]
        gradLayer.startPoint = CGPoint(x: 0.5, y: 0.35)
        gradLayer.endPoint   = CGPoint(x: 0.5, y: 1.0)
        DispatchQueue.main.async {
            gradLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - 40, height: 200)
            gradView.layer.addSublayer(gradLayer)
        }

        let urgentBadge = UIView()
        urgentBadge.isHidden = !cat.isUrgent
        urgentBadge.backgroundColor = AppTheme.Color.primaryDeep
        urgentBadge.layer.cornerRadius = 12
        let urgentL = UILabel.make(text: "⚡ 긴급 입양 필요", size: 11, weight: .bold, color: .white)
        urgentBadge.addSubview(urgentL)
        urgentL.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(5)
            make.leading.trailing.equalToSuperview().inset(10)
        }

        let catNameL  = UILabel.make(text: cat.name, size: 20, weight: .black, color: .white)
        let catInfoL  = UILabel.make(text: "\(cat.age) · \(cat.gender) · \(cat.breed)", size: 12, color: UIColor(white: 1, alpha: 0.85))
        let locationL = UILabel.make(text: "📍 \(cat.location)", size: 11, color: UIColor(white: 1, alpha: 0.75))
        let overlayStack = UIStackView.make(axis: .vertical, spacing: 2)
        overlayStack.addArrangedSubview(catNameL)
        overlayStack.addArrangedSubview(catInfoL)
        overlayStack.addArrangedSubview(locationL)

        let photoContainer = UIView()
        photoContainer.clipsToBounds = true
        photoContainer.layer.cornerRadius = AppTheme.Radius.xxLarge
        photoContainer.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        [imageView, gradView, urgentBadge, likeBtn, overlayStack].forEach { photoContainer.addSubview($0) }
        imageView.snp.makeConstraints { $0.edges.equalToSuperview() }
        gradView.snp.makeConstraints { $0.edges.equalToSuperview() }
        urgentBadge.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(12)
        }
        likeBtn.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
        }
        overlayStack.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-14)
            make.leading.equalToSuperview().offset(14)
            make.trailing.equalToSuperview().offset(-14)
        }
        photoContainer.snp.makeConstraints { $0.height.equalTo(200) }
        updateLikeButton()

        // Card body
        let shelterL = UILabel.make(text: "🏠 \(cat.shelter)", size: 11, weight: .semibold, color: AppTheme.Color.purple)
        let descL    = UILabel.make(text: cat.desc, size: 13, color: AppTheme.Color.textMedium, lines: 0)

        let tagStack = UIStackView.make(axis: .horizontal, spacing: 6)
        tagStack.alignment = .center
        cat.tags.forEach { tag in
            let pill = UIView()
            pill.backgroundColor  = AppTheme.Color.purpleLight
            pill.layer.cornerRadius = 10
            let l = UILabel.make(text: "#\(tag)", size: 11, weight: .semibold, color: AppTheme.Color.primary)
            pill.addSubview(l)
            l.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview().inset(4)
                make.leading.trailing.equalToSuperview().inset(8)
            }
            tagStack.addArrangedSubview(pill)
        }
        let tagScrollView = UIScrollView()
        tagScrollView.showsHorizontalScrollIndicator = false
        tagScrollView.addSubview(tagStack)
        tagStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalToSuperview()
        }
        tagScrollView.snp.makeConstraints { $0.height.equalTo(30) }

        let callBtn = UIButton(type: .system)
        callBtn.setTitle("📞", for: .normal)
        callBtn.backgroundColor  = AppTheme.Color.primaryLight
        callBtn.layer.cornerRadius = 18
        callBtn.snp.makeConstraints { $0.width.height.equalTo(48) }

        let buttonRow = UIStackView.make(axis: .horizontal, spacing: 10, alignment: .center)
        buttonRow.addArrangedSubview(learnMoreBtn)
        buttonRow.addArrangedSubview(callBtn)
        learnMoreBtn.snp.makeConstraints { $0.height.equalTo(48) }

        let bodyStack = UIStackView.make(axis: .vertical, spacing: 8)
        [shelterL, descL, tagScrollView, buttonRow].forEach { bodyStack.addArrangedSubview($0) }

        let mainStack = UIStackView.make(axis: .vertical, spacing: 0)
        mainStack.addArrangedSubview(photoContainer)
        let bodyPad = UIView()
        bodyPad.addSubview(bodyStack)
        bodyStack.snp.makeConstraints { $0.edges.equalToSuperview().inset(14) }
        mainStack.addArrangedSubview(bodyPad)

        addSubview(mainStack)
        mainStack.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    @objc private func likeTapped() {
        isLiked.toggle()
        updateLikeButton()
        onLikeToggled?()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    @objc private func learnMoreTapped() {
        onLearnMore?()
    }

    private func updateLikeButton() {
        likeBtn.setTitle(isLiked ? "❤️" : "🤍", for: .normal)
    }
}
