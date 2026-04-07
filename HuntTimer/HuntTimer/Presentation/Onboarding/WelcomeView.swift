import UIKit
import SnapKit

/// 온보딩 Welcome 화면 뷰
final class WelcomeView: BaseView {

    // MARK: - Public
    let ctaButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("프로필 만들러 가기", for: .normal)
        btn.setTitleColor(AppTheme.Color.textDark, for: .normal)
        btn.titleLabel?.font = .appFont(size: 17, weight: .bold)
        btn.backgroundColor = AppTheme.Color.primary
        btn.layer.cornerRadius = 28
        return btn
    }()

    // MARK: - Setup
    override func setupUI() {
        backgroundColor = .white

        // Title row: "반가워요, " + "집사님!" (#ff8fab)
        let greetL  = UILabel.make(text: "반가워요, ", size: 26, weight: .semibold, color: AppTheme.Color.textDark)
        let accentL = UILabel.make(text: "집사님!", size: 26, weight: .bold, color: AppTheme.Color.primary)
        let titleRow = UIStackView.make(axis: .horizontal, alignment: .center)
        titleRow.addArrangedSubview(greetL)
        titleRow.addArrangedSubview(accentL)

        let sub1 = UILabel.make(text: "사냥을 기록하기 전에", size: 17,
                                color: AppTheme.Color.textMedium, alignment: .center)
        let sub2 = UILabel.make(text: "아이의 프로필을 먼저 생성해 주세요!", size: 17,
                                color: AppTheme.Color.textMedium, alignment: .center)

        let contentStack = UIStackView.make(axis: .vertical, spacing: 10, alignment: .center)
        [titleRow, sub1, sub2].forEach { contentStack.addArrangedSubview($0) }

        AppTheme.applyButtonShadow(to: ctaButton)

        addSubview(contentStack)
        addSubview(ctaButton)

        ctaButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(120)
            make.width.equalTo(220)
            make.height.equalTo(66)
        }

        contentStack.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(self.snp.centerY).offset(27)
        }
    }
}
