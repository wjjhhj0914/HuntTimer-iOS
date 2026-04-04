import UIKit
import SnapKit

/// 고양이 목록 화면 View — 등록된 고양이가 0마리일 때 Empty State 표시
final class CatListView: BaseView {

    // MARK: - Header
    let titleLabel = UILabel.make(
        text: "고양이 목록",
        size: 22,
        weight: .bold,
        color: AppTheme.Color.textDark
    )

    let addButton: UIButton = {
        let btn = UIButton(type: .system)
        let cfg = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        btn.setImage(UIImage(systemName: "plus", withConfiguration: cfg), for: .normal)
        btn.tintColor = .white
        btn.backgroundColor = AppTheme.Color.primary
        btn.layer.cornerRadius = 22
        return btn
    }()

    // MARK: - Empty State
    private let catCircle: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#FEF0E4")
        v.layer.cornerRadius = 120
        return v
    }()

    private let catImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "RegisterProfile_Cat"))
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let emptyTitleLabel: UILabel = {
        let l = UILabel()
        l.text = "아직 등록된 고양이가 없어요!"
        l.font = .appFont(size: 22, weight: .bold)
        l.textColor = AppTheme.Color.textDark
        l.textAlignment = .center
        return l
    }()

    private let emptySubLabel: UILabel = {
        let l = UILabel()
        l.text = "첫 번째 고양이를 등록해 볼까요?"
        l.font = .appFont(size: 15)
        l.textColor = AppTheme.Color.textMuted
        l.textAlignment = .center
        return l
    }()

    // MARK: - Setup
    override func setupUI() {
        backgroundColor = AppTheme.Color.background

        catCircle.addSubview(catImageView)
        [titleLabel, addButton, catCircle, emptyTitleLabel, emptySubLabel].forEach { addSubview($0) }

        // Header
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.top.equalTo(safeAreaLayoutGuide).offset(22)
        }
        addButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalTo(titleLabel)
            make.width.height.equalTo(44)
        }

        // 고양이 원형 일러스트 — 화면 중앙보다 약간 위
        catCircle.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-70)
            make.width.height.equalTo(240)
        }
        catImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(102)
            make.height.equalTo(94)
        }

        // 안내 텍스트
        emptyTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(catCircle.snp.bottom).offset(36)
            make.leading.trailing.equalToSuperview().inset(40)
        }
        emptySubLabel.snp.makeConstraints { make in
            make.top.equalTo(emptyTitleLabel.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(40)
        }
    }
}
