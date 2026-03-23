import UIKit
import SnapKit

/// 기록 화면 캘린더 그리드 셀
final class DayCell: UICollectionViewCell {

    static let id = "DayCell"

    private let dayLabel   = UILabel.make(size: 12, alignment: .center)
    private let thumbImage = AsyncImageView(contentMode: .scaleAspectFill, cornerRadius: 8)
    private let dotView    = UIView()
    private let pillBg     = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        pillBg.layer.cornerRadius = frame.width / 2
        pillBg.clipsToBounds = true
        dotView.layer.cornerRadius = 3
        dotView.snp.makeConstraints { $0.width.height.equalTo(6) }
        thumbImage.layer.borderWidth = 1.5
        thumbImage.layer.borderColor = AppTheme.Color.primaryLight.cgColor

        let stack = UIStackView.make(axis: .vertical, spacing: 2, alignment: .center)
        stack.addArrangedSubview(dayLabel)
        stack.addArrangedSubview(thumbImage)
        stack.addArrangedSubview(dotView)
        thumbImage.snp.makeConstraints { $0.width.height.equalTo(28) }

        contentView.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(day: Int?, isSelected: Bool, isToday: Bool, hasActivity: Bool, imageURL: String?) {
        guard let day else {
            dayLabel.text       = ""
            thumbImage.image    = nil
            thumbImage.isHidden = true
            dotView.isHidden    = true
            backgroundColor     = .clear
            return
        }

        dayLabel.text = "\(day)"
        dayLabel.font = .appFont(size: 12, weight: isSelected || isToday ? .bold : .regular)
        dayLabel.textColor = isSelected ? .white : isToday ? AppTheme.Color.primary : AppTheme.Color.textDark

        backgroundColor = isSelected ? AppTheme.Color.primary : isToday ? AppTheme.Color.primaryLight : .clear
        layer.cornerRadius = 14
        clipsToBounds = true

        thumbImage.isHidden = !hasActivity
        dotView.isHidden    = !hasActivity
        if let url = imageURL { thumbImage.loadImage(from: url) }
        dotView.backgroundColor  = isSelected ? .white : AppTheme.Color.primary
        thumbImage.layer.borderColor = isSelected ? UIColor.white.cgColor : AppTheme.Color.primaryLight.cgColor
    }
}
