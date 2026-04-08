import UIKit
import SnapKit
import RealmSwift

/// 타이머 화면 고양이 다중선택 컬렉션셀
final class CatSelectionCell: UICollectionViewCell {
    static let id = "CatSelectionCell"

    // MARK: - Subviews
    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode        = .scaleAspectFill
        iv.clipsToBounds      = true
        iv.layer.cornerRadius = 40
        iv.backgroundColor    = AppTheme.Color.primary.withAlphaComponent(0.15)
        return iv
    }()

    private let defaultIconView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "RegisterProfile_Cat"))
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    /// 선택 시 아바타 위에 오버레이되는 amber 체크 배지
    private let checkBadge: UIView = {
        let v = UIView()
        v.backgroundColor    = AppTheme.Color.primary
        v.layer.cornerRadius = 12
        v.isHidden           = true
        return v
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font          = .appFont(size: 11, weight: .semibold)
        l.textColor     = AppTheme.Color.textDark
        l.textAlignment = .center
        l.numberOfLines = 1
        return l
    }()

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Layout
    private func setupLayout() {
        let cfg       = UIImage.SymbolConfiguration(pointSize: 10, weight: .bold)
        let checkIcon = UIImageView(image: UIImage(systemName: "checkmark",
                                                   withConfiguration: cfg))
        checkIcon.tintColor    = AppTheme.Color.textDark
        checkIcon.contentMode  = .scaleAspectFit

        avatarImageView.addSubview(defaultIconView)
        checkBadge.addSubview(checkIcon)
        contentView.addSubview(avatarImageView)
        contentView.addSubview(checkBadge)
        contentView.addSubview(nameLabel)

        avatarImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)   // 체크 배지 오버플로(4pt) 수용 여백
            make.centerX.equalToSuperview()
            make.width.height.equalTo(80)
        }
        defaultIconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(28)
        }
        checkBadge.snp.makeConstraints { make in
            make.top.equalTo(avatarImageView).offset(-4)
            make.trailing.equalTo(avatarImageView).offset(4)
            make.width.height.equalTo(24)
        }
        checkIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(12)
        }
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarImageView.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }
    }

    // MARK: - Configure
    func configure(cat: Cat) {
        nameLabel.text = cat.name
        if let data = cat.profileImageData, let image = UIImage(data: data) {
            avatarImageView.image    = image
            defaultIconView.isHidden = true
        } else {
            avatarImageView.image    = nil
            defaultIconView.isHidden = false
        }
    }

    func setSelectedState(_ selected: Bool) {
        UIView.animate(withDuration: 0.15) {
            self.contentView.alpha                 = selected ? 1.0 : 0.4
            self.avatarImageView.layer.borderWidth = selected ? 3.0 : 0.0
            self.avatarImageView.layer.borderColor = AppTheme.Color.primary.cgColor
            self.checkBadge.isHidden               = !selected
        }
    }
}
