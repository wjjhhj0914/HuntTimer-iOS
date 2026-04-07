import UIKit
import SnapKit

/// 고양이 목록 행 셀
final class CatListCell: UITableViewCell {
    static let id = "CatListCell"

    var onEditTap: (() -> Void)?

    // MARK: - Subviews
    private let profileImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode    = .scaleAspectFill
        iv.clipsToBounds  = true
        iv.layer.cornerRadius = 32
        iv.backgroundColor = AppTheme.Color.primary.withAlphaComponent(0.12)
        return iv
    }()

    private let defaultIconView: UIImageView = {
        let cfg = UIImage.SymbolConfiguration(pointSize: 22, weight: .light)
        let iv  = UIImageView(image: UIImage(systemName: "pawprint.fill", withConfiguration: cfg))
        iv.tintColor   = AppTheme.Color.primary
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font      = .appFont(size: 16, weight: .bold)
        l.textColor = AppTheme.Color.textDark
        return l
    }()

    private let infoLabel: UILabel = {
        let l = UILabel()
        l.font      = .appFont(size: 13)
        l.textColor = AppTheme.Color.textMuted
        return l
    }()

    private let editButton: UIButton = {
        let btn = UIButton(type: .custom)
        let icon = UIImage(named: "Edit_Pencil_Icon")
        btn.setImage(icon, for: .normal)
        btn.imageView?.contentMode = .scaleAspectFit
        btn.contentEdgeInsets  = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        btn.backgroundColor    = AppTheme.Color.primary.withAlphaComponent(0.12)
        btn.layer.cornerRadius = 20
        return btn
    }()

    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle  = .none
        setupLayout()
        editButton.addTarget(self, action: #selector(editTapped), for: .touchUpInside)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Layout
    private func setupLayout() {
        let card = UIView()
        card.backgroundColor    = .white
        card.layer.cornerRadius = AppTheme.Radius.large
        AppTheme.applyCardShadow(to: card, opacity: 0.06, radius: 8)

        profileImageView.addSubview(defaultIconView)

        let textStack = UIStackView.make(axis: .vertical, spacing: 4)
        textStack.addArrangedSubview(nameLabel)
        textStack.addArrangedSubview(infoLabel)

        card.addSubview(profileImageView)
        card.addSubview(textStack)
        card.addSubview(editButton)
        contentView.addSubview(card)

        card.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.bottom.equalToSuperview().offset(-6)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }
        profileImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(64)
        }
        defaultIconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(28)
        }
        textStack.snp.makeConstraints { make in
            make.leading.equalTo(profileImageView.snp.trailing).offset(14)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(editButton.snp.leading).offset(-8)
        }
        editButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }
    }

    @objc private func editTapped() { onEditTap?() }

    // MARK: - Configure
    func configure(cat: Cat) {
        nameLabel.text = cat.name

        let breedName = CatBreed(rawValue: cat.breed)?.displayName ?? cat.breed
        let agePart: String = {
            guard let birthday = cat.birthday else { return "" }
            let years = Calendar.current.dateComponents([.year], from: birthday, to: Date()).year ?? 0
            return years > 0 ? "\(years)살" : "1살 미만"
        }()

        if agePart.isEmpty && breedName.isEmpty {
            infoLabel.text = ""
        } else if agePart.isEmpty {
            infoLabel.text = breedName
        } else if breedName.isEmpty {
            infoLabel.text = agePart
        } else {
            infoLabel.text = "\(agePart) · \(breedName)"
        }

        if let data = cat.profileImageData, let image = UIImage(data: data) {
            profileImageView.image   = image
            defaultIconView.isHidden = true
        } else {
            profileImageView.image   = nil
            defaultIconView.isHidden = false
        }
    }
}
