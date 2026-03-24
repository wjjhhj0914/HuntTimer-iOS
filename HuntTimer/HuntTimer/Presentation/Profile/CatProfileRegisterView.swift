import UIKit
import SnapKit

/// 냥이 프로필 등록 화면 뷰 (NhHhH 디자인 기준)
final class CatProfileRegisterView: BaseView {

    // MARK: - Header
    let headerTitleLabel = UILabel.make(text: "냥이 프로필 등록", size: 18, weight: .black,
                                        color: AppTheme.Color.textDark)

    let backButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        btn.setImage(UIImage(systemName: "chevron.left", withConfiguration: config), for: .normal)
        btn.tintColor = AppTheme.Color.primary
        btn.backgroundColor = AppTheme.Color.primaryLight
        btn.layer.cornerRadius = 18
        return btn
    }()

    let saveButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("저장", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = .appFont(size: 14, weight: .bold)
        btn.backgroundColor = AppTheme.Color.primary
        btn.layer.cornerRadius = 18
        btn.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        return btn
    }()

    // MARK: - Form Fields
    let nameTextField: UITextField = {
        let tf = UITextField()
        tf.font = .appFont(size: 15, weight: .semibold)
        tf.textColor = AppTheme.Color.primary
        tf.attributedPlaceholder = NSAttributedString(
            string: "고양이 이름을 입력하세요",
            attributes: [.foregroundColor: AppTheme.Color.textMuted]
        )
        return tf
    }()

    let birthdateLabel = UILabel.make(text: "생년월일을 선택하세요", size: 15, weight: .semibold,
                                      color: AppTheme.Color.textMuted)

    let unknownBirthdayToggle: UISwitch = {
        let sw = UISwitch()
        sw.onTintColor = AppTheme.Color.primary
        return sw
    }()

    let femaleButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("암컷", for: .normal)
        btn.titleLabel?.font = .appFont(size: 14, weight: .bold)
        btn.backgroundColor = AppTheme.Color.primary
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 10
        return btn
    }()

    let maleButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("수컷", for: .normal)
        btn.titleLabel?.font = .appFont(size: 14, weight: .bold)
        btn.backgroundColor = .clear
        btn.setTitleColor(AppTheme.Color.textMuted, for: .normal)
        btn.layer.cornerRadius = 10
        return btn
    }()

    let registerButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("프로필 등록하기", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = .appFont(size: 17, weight: .bold)
        btn.layer.cornerRadius = 28
        btn.clipsToBounds = true
        return btn
    }()

    // MARK: - Interactive Areas (VC에서 탭 제스처 연결)
    let photoContainerView = UIView()   // 프로필 사진 터치 영역
    let dateFieldView      = UIView()   // 생년월일 입력 필드
    let goalFieldView      = UIView()   // 목표 시간 입력 필드
    let breedFieldView     = UIView()   // 품종 선택 필드

    // MARK: - Updateable Display Labels
    let breedDisplayLabel = UILabel.make(text: "품종을 선택하세요", size: 15, weight: .semibold,
                                          color: AppTheme.Color.textMuted)

    // MARK: - Updateable Labels
    let goalMinuteLabel = UILabel.make(text: "30", size: 20, weight: .bold, color: AppTheme.Color.primary)

    // MARK: - Profile Photo ImageView
    let photoImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 55
        iv.isHidden = true
        return iv
    }()

    // MARK: - Private
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.alwaysBounceVertical = true
        return sv
    }()

    private let contentStack = UIStackView.make(axis: .vertical, spacing: 12)
    private var gradientLayer: CAGradientLayer?

    /// 수정 모드 레이아웃 전환에 필요한 참조
    private var ctaContainer: UIView?
    private var scrollCTAConstraint: Constraint?

    // MARK: - Setup
    override func setupUI() {
        backgroundColor = AppTheme.Color.background

        let headerView = makeHeader()
        let ctaWrap    = makeCTAWrap()
        ctaContainer   = ctaWrap

        addSubview(headerView)
        addSubview(scrollView)
        addSubview(ctaWrap)
        scrollView.addSubview(contentStack)

        [makePhotoSection(),
         makeCard(content: makeNameCardContent()),
         makeCard(content: makeBirthdateCardContent()),
         makeCard(content: makeGenderCardContent()),
         makeCard(content: makeGoalCardContent()),
         makeCard(content: makeBreedCardContent())
        ].forEach { contentStack.addArrangedSubview($0) }

        headerView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(56)
        }
        ctaWrap.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(safeAreaLayoutGuide)
        }
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            scrollCTAConstraint = make.bottom.equalTo(ctaWrap.snp.top).constraint
        }
        contentStack.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.width.equalTo(scrollView).offset(-32)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer?.frame = registerButton.bounds
    }

    // MARK: - Header
    private func makeHeader() -> UIView {
        let header = UIView()

        header.addSubview(backButton)
        header.addSubview(headerTitleLabel)
        header.addSubview(saveButton)

        backButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(36)
        }
        headerTitleLabel.snp.makeConstraints { $0.center.equalToSuperview() }
        saveButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
        }
        return header
    }

    // MARK: - Photo Section
    private func makePhotoSection() -> UIView {
        // photoContainerView: 110×110 tappable circle area
        photoContainerView.backgroundColor = .clear

        let circle = UIView()
        circle.layer.cornerRadius = 55
        circle.clipsToBounds = true

        let grad = CAGradientLayer()
        grad.colors     = [UIColor(hex: "#FFE8EE").cgColor, UIColor(hex: "#FFCDD8").cgColor]
        grad.startPoint = CGPoint(x: 0, y: 0)
        grad.endPoint   = CGPoint(x: 1, y: 1)
        grad.frame      = CGRect(x: 0, y: 0, width: 110, height: 110)
        circle.layer.insertSublayer(grad, at: 0)

        let catIcon = UIImageView()
        let config   = UIImage.SymbolConfiguration(pointSize: 36, weight: .regular)
        catIcon.image       = UIImage(systemName: "pawprint.fill", withConfiguration: config)
        catIcon.tintColor   = AppTheme.Color.primary
        catIcon.contentMode = .scaleAspectFit
        catIcon.tag         = 99  // used to hide it when photo is selected

        circle.addSubview(catIcon)
        circle.addSubview(photoImageView)
        catIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(40)
        }
        photoImageView.snp.makeConstraints { $0.edges.equalToSuperview() }

        let camBtn = UIView()
        camBtn.backgroundColor   = AppTheme.Color.primary
        camBtn.layer.cornerRadius = 15
        let camIcon = UIImageView()
        let camConfig = UIImage.SymbolConfiguration(pointSize: 12, weight: .medium)
        camIcon.image     = UIImage(systemName: "camera.fill", withConfiguration: camConfig)
        camIcon.tintColor = .white
        camIcon.contentMode = .scaleAspectFit
        camBtn.addSubview(camIcon)
        camIcon.snp.makeConstraints { $0.center.equalToSuperview() }

        photoContainerView.addSubview(circle)
        photoContainerView.addSubview(camBtn)
        circle.snp.makeConstraints { $0.width.height.equalTo(110); $0.top.leading.equalToSuperview() }
        camBtn.snp.makeConstraints { make in
            make.width.height.equalTo(30)
            make.trailing.bottom.equalTo(circle)
        }
        photoContainerView.snp.makeConstraints { $0.width.height.equalTo(110) }

        let hintL = UILabel.make(text: "사진을 눌러 등록해주세요", size: 12, weight: .medium,
                                 color: AppTheme.Color.textMuted)

        let stack = UIStackView.make(axis: .vertical, spacing: 6, alignment: .center)
        stack.addArrangedSubview(photoContainerView)
        stack.addArrangedSubview(hintL)

        let container = UIView()
        container.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(4)
            make.bottom.equalToSuperview().offset(-8)
            make.centerX.equalToSuperview()
        }
        return container
    }

    // MARK: - Card Wrapper
    private func makeCard(content: UIView) -> UIView {
        let card = UIView()
        card.backgroundColor   = .white
        card.layer.cornerRadius = AppTheme.Radius.large
        AppTheme.applyCardShadow(to: card, opacity: 0.06, radius: 8)
        card.addSubview(content)
        content.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 16, left: 20, bottom: 16, right: 20))
        }
        return card
    }

    // MARK: - Name Card
    private func makeNameCardContent() -> UIView {
        let label = makeFieldLabel(icon: "heart.fill", text: "고양이 이름")
        let field = makeInputField(content: nameTextField)
        let stack = UIStackView.make(axis: .vertical, spacing: 8)
        stack.addArrangedSubview(label)
        stack.addArrangedSubview(field)
        return stack
    }

    // MARK: - Birthdate Card
    private func makeBirthdateCardContent() -> UIView {
        let label = makeFieldLabel(icon: "birthday.cake.fill", text: "생년월일")

        // dateFieldView: 탭 시 달력 바텀시트 오픈
        dateFieldView.backgroundColor   = AppTheme.Color.background
        dateFieldView.layer.cornerRadius = AppTheme.Radius.small
        dateFieldView.snp.makeConstraints { $0.height.equalTo(44) }

        let calIcon = UIImageView()
        let calConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        calIcon.image     = UIImage(systemName: "calendar", withConfiguration: calConfig)
        calIcon.tintColor = AppTheme.Color.primary
        calIcon.setContentHuggingPriority(.required, for: .horizontal)

        dateFieldView.addSubview(birthdateLabel)
        dateFieldView.addSubview(calIcon)
        birthdateLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.centerY.equalToSuperview()
        }
        calIcon.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-14)
            make.centerY.equalToSuperview()
        }

        let divider = UIView()
        divider.backgroundColor = UIColor(hex: "#F0E4E8")
        divider.snp.makeConstraints { $0.height.equalTo(1) }

        let toggleLabel = UILabel.make(text: "생일을 모르겠어요", size: 13, color: UIColor(hex: "#bfa2a2"))
        let toggleRow   = UIStackView.make(axis: .horizontal, alignment: .center)
        toggleRow.addArrangedSubview(toggleLabel)
        toggleRow.addArrangedSubview(unknownBirthdayToggle)
        toggleRow.snp.makeConstraints { $0.height.equalTo(36) }

        let stack = UIStackView.make(axis: .vertical, spacing: 8)
        [label, dateFieldView, divider, toggleRow].forEach { stack.addArrangedSubview($0) }
        return stack
    }

    // MARK: - Gender Card
    private func makeGenderCardContent() -> UIView {
        let label = makeFieldLabel(icon: "person.fill", text: "성별")

        let segmented = UIView()
        segmented.backgroundColor   = AppTheme.Color.background
        segmented.layer.cornerRadius = AppTheme.Radius.small
        segmented.layer.masksToBounds = true

        let segStack = UIStackView.make(axis: .horizontal, spacing: 4, distribution: .fillEqually)
        segStack.layoutMargins = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        segStack.isLayoutMarginsRelativeArrangement = true
        segStack.addArrangedSubview(femaleButton)
        segStack.addArrangedSubview(maleButton)

        segmented.addSubview(segStack)
        segStack.snp.makeConstraints { $0.edges.equalToSuperview() }
        segmented.snp.makeConstraints { $0.height.equalTo(44) }

        let stack = UIStackView.make(axis: .vertical, spacing: 8)
        stack.addArrangedSubview(label)
        stack.addArrangedSubview(segmented)
        return stack
    }

    // MARK: - Goal Card
    private func makeGoalCardContent() -> UIView {
        // SF Symbol 'bullseye' + 텍스트 레이블 (이모지 제거)
        let bulletIcon = UIImageView()
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 12, weight: .medium)
        bulletIcon.image     = UIImage(systemName: "scope", withConfiguration: iconConfig)
        bulletIcon.tintColor = AppTheme.Color.primary
        bulletIcon.contentMode = .scaleAspectFit
        bulletIcon.snp.makeConstraints { $0.width.height.equalTo(14) }

        let titleText = UILabel.make(text: "하루 사냥 목표 (개별 목표)", size: 12, weight: .semibold,
                                     color: UIColor(hex: "#bfa2a2"))
        let titleRow = UIStackView.make(axis: .horizontal, spacing: 6, alignment: .center)
        titleRow.addArrangedSubview(bulletIcon)
        titleRow.addArrangedSubview(titleText)

        // goalFieldView: 탭 시 목표 시간 바텀시트 오픈
        goalFieldView.backgroundColor   = UIColor(hex: "#FFF5F7")
        goalFieldView.layer.cornerRadius = AppTheme.Radius.small
        goalFieldView.snp.makeConstraints { $0.height.equalTo(44) }

        let unitL = UILabel.make(text: "분 (Minutes)", size: 13, color: UIColor(hex: "#bfa2a2"))
        goalFieldView.addSubview(goalMinuteLabel)
        goalFieldView.addSubview(unitL)
        goalMinuteLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.centerY.equalToSuperview()
        }
        unitL.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-14)
            make.centerY.equalToSuperview()
        }

        let spacer = UIView()
        spacer.snp.makeConstraints { $0.height.equalTo(8) }

        let stack = UIStackView.make(axis: .vertical, spacing: 0)
        [titleRow, spacer, goalFieldView].forEach { stack.addArrangedSubview($0) }
        return stack
    }

    // MARK: - Breed Card
    private func makeBreedCardContent() -> UIView {
        let label = makeFieldLabel(icon: "pawprint.fill", text: "품종")

        let chevron = UIImageView()
        let chevConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        chevron.image     = UIImage(systemName: "chevron.down", withConfiguration: chevConfig)
        chevron.tintColor = AppTheme.Color.primary
        chevron.setContentHuggingPriority(.required, for: .horizontal)

        // breedFieldView: 탭 시 품종 선택 바텀시트 오픈
        breedFieldView.backgroundColor   = AppTheme.Color.background
        breedFieldView.layer.cornerRadius = AppTheme.Radius.small
        breedFieldView.addSubview(breedDisplayLabel)
        breedFieldView.addSubview(chevron)
        breedFieldView.snp.makeConstraints { $0.height.equalTo(44) }
        breedDisplayLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(chevron.snp.leading).offset(-8)
        }
        chevron.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-14)
            make.centerY.equalToSuperview()
        }

        let stack = UIStackView.make(axis: .vertical, spacing: 8)
        stack.addArrangedSubview(label)
        stack.addArrangedSubview(breedFieldView)
        return stack
    }

    // MARK: - CTA Wrap
    private func makeCTAWrap() -> UIView {
        let wrap = UIView()
        wrap.backgroundColor = AppTheme.Color.background

        let grad = CAGradientLayer()
        grad.colors     = [UIColor(hex: "#FF7EA1").cgColor, UIColor(hex: "#FF5C85").cgColor]
        grad.startPoint = CGPoint(x: 0, y: 0)
        grad.endPoint   = CGPoint(x: 0, y: 1)
        registerButton.layer.insertSublayer(grad, at: 0)
        self.gradientLayer = grad

        wrap.addSubview(registerButton)
        registerButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().offset(-16)
            make.height.equalTo(56)
        }
        return wrap
    }

    // MARK: - Helpers
    private func makeFieldLabel(icon systemName: String, text: String) -> UIView {
        let iconView = UIImageView()
        let config   = UIImage.SymbolConfiguration(pointSize: 12, weight: .medium)
        iconView.image       = UIImage(systemName: systemName, withConfiguration: config)
        iconView.tintColor   = AppTheme.Color.primary
        iconView.contentMode = .scaleAspectFit
        iconView.snp.makeConstraints { $0.width.height.equalTo(14) }

        let labelV = UILabel.make(text: text, size: 12, weight: .semibold, color: AppTheme.Color.textMuted)

        let row = UIStackView.make(axis: .horizontal, spacing: 6, alignment: .center)
        row.addArrangedSubview(iconView)
        row.addArrangedSubview(labelV)
        return row
    }

    /// 수정 모드: CTA 영역을 숨기고 scrollView가 safeArea까지 확장되도록 제약을 전환
    func hideCTAForEditMode() {
        ctaContainer?.isHidden = true
        scrollCTAConstraint?.deactivate()
        scrollView.snp.makeConstraints { $0.bottom.equalTo(safeAreaLayoutGuide) }
    }

    private func makeInputField(content: UIView) -> UIView {
        let field = UIView()
        field.backgroundColor   = AppTheme.Color.background
        field.layer.cornerRadius = AppTheme.Radius.small
        field.addSubview(content)
        content.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(14)
            make.centerY.equalToSuperview()
        }
        field.snp.makeConstraints { $0.height.equalTo(44) }
        return field
    }
}
