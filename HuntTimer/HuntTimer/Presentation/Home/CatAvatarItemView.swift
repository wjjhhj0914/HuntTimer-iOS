import UIKit
import SnapKit
import RealmSwift

/// 홈 화면 고양이 섹션 — 개별 아바타 아이템 뷰
/// 일반 모드: 탭 → onTap, 롱프레스 → onLongPress
/// 편집 모드: 흔들림 애니메이션 + 우측 상단 X 배지 표시
final class CatAvatarItemView: UIView {

    // MARK: - Data
    let cat: Cat

    // MARK: - Callbacks
    var onTap: (() -> Void)?
    var onLongPress: (() -> Void)?

    // MARK: - Subviews
    private let circleView  = UIView()
    private let photoView   = UIImageView()
    private let defaultIcon = UIImageView(image: UIImage(named: "RegisterProfile_Cat"))
    private let nameLabel   = UILabel()
    private let checkBadge  = UIView()   // 일반 모드 선택 표시 (우측 하단)
    private let deleteBadge = UIView()   // 편집 모드 X 버튼 (우측 상단)

    // MARK: - Init
    init(cat: Cat) {
        self.cat = cat
        super.init(frame: .zero)
        setupLayout()
        setupGestures()
        configure()
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Layout
    private func setupLayout() {
        clipsToBounds = false

        // ── Circle ────────────────────────────────────────────────────────
        circleView.backgroundColor    = UIColor(hex: "#FFF3E0")
        circleView.layer.cornerRadius = 32
        circleView.layer.borderWidth  = 3
        circleView.layer.borderColor  = AppTheme.Color.primary.cgColor
        circleView.clipsToBounds      = true

        photoView.contentMode = .scaleAspectFill
        photoView.clipsToBounds = true
        defaultIcon.contentMode = .scaleAspectFit

        circleView.addSubview(photoView)
        circleView.addSubview(defaultIcon)
        photoView.snp.makeConstraints { $0.edges.equalToSuperview() }
        defaultIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(28)
        }

        // ── Name label ────────────────────────────────────────────────────
        nameLabel.font          = .appFont(size: 12, weight: .semibold)
        nameLabel.textColor     = AppTheme.Color.textDark
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 1

        // ── Check badge (우측 하단, 20×20) ─────────────────────────────────
        checkBadge.backgroundColor    = AppTheme.Color.primary
        checkBadge.layer.cornerRadius = 10
        checkBadge.isHidden           = true
        let checkIcon = UIImageView(
            image: UIImage(systemName: "checkmark",
                           withConfiguration: UIImage.SymbolConfiguration(pointSize: 8, weight: .bold))
        )
        checkIcon.tintColor   = AppTheme.Color.textDark
        checkIcon.contentMode = .scaleAspectFit
        checkBadge.addSubview(checkIcon)
        checkIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(10)
        }

        // ── Delete badge (우측 상단, 22×22) ────────────────────────────────
        deleteBadge.backgroundColor    = UIColor(hex: "#2d1b0e")
        deleteBadge.layer.cornerRadius = 11
        deleteBadge.isHidden           = true
        let xIcon = UIImageView(
            image: UIImage(systemName: "xmark",
                           withConfiguration: UIImage.SymbolConfiguration(pointSize: 7, weight: .bold))
        )
        xIcon.tintColor   = .white
        xIcon.contentMode = .scaleAspectFit
        deleteBadge.addSubview(xIcon)
        xIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(9)
        }

        // ── Add subviews ──────────────────────────────────────────────────
        addSubview(circleView)
        addSubview(nameLabel)
        addSubview(checkBadge)
        addSubview(deleteBadge)

        // 고정 폭: stackView 내에서 크기 결정
        snp.makeConstraints { $0.width.equalTo(64) }

        circleView.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.width.height.equalTo(64)
        }
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(circleView.snp.bottom).offset(6)
            make.leading.trailing.equalTo(circleView)
            make.bottom.equalToSuperview()
        }
        // Check badge: 원형 우측 하단 모서리
        checkBadge.snp.makeConstraints { make in
            make.width.height.equalTo(20)
            make.trailing.bottom.equalTo(circleView)
        }
        // Delete badge: 원형 우측 상단 모서리 (약간 바깥으로)
        deleteBadge.snp.makeConstraints { make in
            make.width.height.equalTo(22)
            make.trailing.equalTo(circleView.snp.trailing).offset(4)
            make.top.equalTo(circleView.snp.top).offset(-4)
        }
    }

    private func configure() {
        nameLabel.text = cat.name
        if let data = cat.profileImageData, let image = UIImage(data: data) {
            photoView.image      = image
            photoView.isHidden   = false
            defaultIcon.isHidden = true
        } else {
            photoView.isHidden   = true
            defaultIcon.isHidden = false
        }
    }

    // MARK: - Gestures
    private func setupGestures() {
        isUserInteractionEnabled = true

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 1.0
        addGestureRecognizer(longPress)
    }

    @objc private func handleTap() { onTap?() }

    @objc private func handleLongPress(_ gr: UILongPressGestureRecognizer) {
        guard gr.state == .began else { return }
        onLongPress?()
    }

    // MARK: - State Updates

    func setSelected(_ selected: Bool, animated: Bool = true) {
        let update = { self.checkBadge.isHidden = !selected }
        animated ? UIView.animate(withDuration: 0.15, animations: update) : update()
    }

    func setEditing(_ editing: Bool) {
        UIView.animate(withDuration: 0.2) {
            self.deleteBadge.isHidden = !editing
            if editing { self.checkBadge.isHidden = true }
        }
        editing ? startWiggle() : stopWiggle()
    }

    // MARK: - Wiggle Animation

    func startWiggle() {
        guard layer.animation(forKey: "wiggle") == nil else { return }
        let rotation            = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        rotation.values         = [-0.04, 0.04, -0.04]
        rotation.duration       = 0.28
        rotation.repeatCount    = .infinity
        rotation.isAdditive     = true
        // 각 아이콘이 조금씩 다른 타이밍으로 흔들리도록 무작위 오프셋
        rotation.timeOffset     = Double.random(in: 0..<0.28)
        layer.add(rotation, forKey: "wiggle")
    }

    func stopWiggle() {
        layer.removeAnimation(forKey: "wiggle")
    }
}
