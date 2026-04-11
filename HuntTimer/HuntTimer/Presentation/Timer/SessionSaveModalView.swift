import UIKit
import SnapKit

/// 사냥 기록 저장 커스텀 모달 뷰 — 디자인 Node ID: 7C9WU 기반
final class SessionSaveModalView: UIView {

    // MARK: - Public UI (ViewController에서 접근)

    let backdropView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        return v
    }()

    let closeButton: UIButton = {
        let btn = UIButton(type: .system)
        let cfg = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        btn.setImage(UIImage(systemName: "xmark", withConfiguration: cfg), for: .normal)
        btn.tintColor       = AppTheme.Color.textMuted
        btn.backgroundColor = AppTheme.Color.yellowLight
        btn.layer.cornerRadius = 16
        return btn
    }()

    let durationLabel = UILabel.make(text: "0분", size: 18, weight: .black,
                                     color: AppTheme.Color.primary, alignment: .right)

    let memoTextView: UITextView = {
        let tv = UITextView()
        tv.font               = .appFont(size: 12, weight: .regular)
        tv.textColor          = AppTheme.Color.textMuted
        tv.text               = "냥이의 반응이나 특이사항을 적어주세요..."
        tv.backgroundColor    = AppTheme.Color.background
        tv.layer.cornerRadius = 12
        tv.layer.borderWidth  = 1
        tv.layer.borderColor  = AppTheme.Color.separator.cgColor
        tv.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        return tv
    }()
    var isShowingPlaceholder = true

    let photoSlotView: UIView = {
        let v = UIView()
        v.backgroundColor    = AppTheme.Color.yellowLight
        v.layer.cornerRadius = 16
        v.layer.borderWidth  = 1.5
        v.layer.borderColor  = AppTheme.Color.primaryLight.cgColor
        v.clipsToBounds      = true
        return v
    }()

    let photoImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode   = .scaleAspectFill
        iv.clipsToBounds = true
        iv.isHidden      = true
        return iv
    }()

    private(set) var cameraPlaceholderStack = UIStackView()

    let saveButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("기록 저장하기", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = .appFont(size: 15, weight: .bold)
        btn.backgroundColor    = AppTheme.Color.primary
        btn.layer.cornerRadius = 24
        btn.clipsToBounds      = true
        return btn
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        buildUI()
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Build

    private func buildUI() {
        // Backdrop
        addSubview(backdropView)
        backdropView.snp.makeConstraints { $0.edges.equalToSuperview() }

        // Modal card
        let card = UIView()
        card.backgroundColor     = .white
        card.layer.cornerRadius  = 20
        card.layer.shadowColor   = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.12
        card.layer.shadowRadius  = 32
        card.layer.shadowOffset  = CGSize(width: 0, height: 8)
        addSubview(card)
        card.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(24)
            make.centerY.equalToSuperview()
        }

        // Header
        let headerView = makeHeader()

        // Divider
        let divider = UIView()
        divider.backgroundColor = AppTheme.Color.separator

        // Content
        let contentStack = UIStackView.make(axis: .vertical, spacing: 14)
        contentStack.layoutMargins                  = UIEdgeInsets(top: 14, left: 20, bottom: 20, right: 20)
        contentStack.isLayoutMarginsRelativeArrangement = true
        contentStack.addArrangedSubview(makeResultCard())
        contentStack.addArrangedSubview(makePhotoSection())
        contentStack.addArrangedSubview(makeMemoSection())
        contentStack.addArrangedSubview(makeSaveButtonWrap())

        // Assemble card
        let mainStack = UIStackView.make(axis: .vertical, spacing: 0)
        mainStack.addArrangedSubview(headerView)
        mainStack.addArrangedSubview(divider)
        mainStack.addArrangedSubview(contentStack)

        card.addSubview(mainStack)
        mainStack.snp.makeConstraints { $0.edges.equalToSuperview() }
        divider.snp.makeConstraints { $0.height.equalTo(1) }
    }

    // MARK: - Section Builders

    private func makeHeader() -> UIView {
        let v = UIView()
        let title = UILabel.make(text: "사냥 기록 남기기", size: 17, weight: .bold,
                                  color: AppTheme.Color.textDark)
        closeButton.snp.makeConstraints { $0.width.height.equalTo(32) }

        v.addSubview(title)
        v.addSubview(closeButton)
        v.snp.makeConstraints { $0.height.equalTo(56) }
        title.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.centerY.equalToSuperview()
        }
        closeButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
        }
        return v
    }

    private func makeResultCard() -> UIView {
        let card = UIView()
        card.backgroundColor    = AppTheme.Color.background
        card.layer.cornerRadius = 14

        let leftStack = UIStackView.make(axis: .vertical, spacing: 3)
        leftStack.addArrangedSubview(UILabel.make(text: "오늘 이만큼 놀아줬어요!",
                                                   size: 12, weight: .bold,
                                                   color: AppTheme.Color.textDark))

        let durationSubLabel = UILabel.make(text: "총 사냥 시간", size: 9,
                                             color: AppTheme.Color.textMuted, alignment: .right)
        // 왼쪽은 공간이 부족할 때 먼저 압축되고, 오른쪽(시간)은 항상 온전히 표시
        leftStack.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let rightStack = UIStackView.make(axis: .vertical, spacing: 2, alignment: .trailing)
        rightStack.addArrangedSubview(durationLabel)
        rightStack.addArrangedSubview(durationSubLabel)
        rightStack.setContentHuggingPriority(.required, for: .horizontal)
        rightStack.setContentCompressionResistancePriority(.required, for: .horizontal)

        let row = UIStackView.make(axis: .horizontal, spacing: 12, alignment: .center)
        row.addArrangedSubview(leftStack)
        row.addArrangedSubview(rightStack)

        card.addSubview(row)
        row.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(12)
            make.leading.trailing.equalToSuperview().inset(14)
        }
        return card
    }

    private func makeMemoSection() -> UIStackView {
        let titleL = UILabel.make(text: "오늘은 어땠나요?", size: 13, weight: .bold,
                                   color: UIColor(hex: "#3D2B2B"))
        let optL   = UILabel.make(text: "(선택 사항)", size: 11, color: AppTheme.Color.textMuted)
        titleL.setContentHuggingPriority(.required, for: .horizontal)

        let headerRow = UIStackView.make(axis: .horizontal, spacing: 4, alignment: .center)
        headerRow.addArrangedSubview(titleL)
        headerRow.addArrangedSubview(optL)

        let section = UIStackView.make(axis: .vertical, spacing: 7)
        section.addArrangedSubview(headerRow)
        section.addArrangedSubview(memoTextView)
        memoTextView.snp.makeConstraints { $0.height.equalTo(88) }
        return section
    }

    private func makePhotoSection() -> UIStackView {
        let titleL = UILabel.make(text: "사진 추가", size: 13, weight: .bold,
                                   color: UIColor(hex: "#3D2B2B"))
        let optL   = UILabel.make(text: "(선택 사항)", size: 11, color: AppTheme.Color.textMuted)
        titleL.setContentHuggingPriority(.required, for: .horizontal)

        let headerRow = UIStackView.make(axis: .horizontal, spacing: 4, alignment: .center)
        headerRow.addArrangedSubview(titleL)
        headerRow.addArrangedSubview(optL)

        // Camera placeholder
        let cameraIconCfg = UIImage.SymbolConfiguration(pointSize: 28, weight: .regular)
        let cameraIcon    = UIImageView(image: UIImage(systemName: "camera",
                                                        withConfiguration: cameraIconCfg))
        cameraIcon.tintColor   = AppTheme.Color.primary
        cameraIcon.contentMode = .scaleAspectFit
        cameraIcon.snp.makeConstraints { $0.width.height.equalTo(32) }

        let cameraLabel = UILabel.make(text: "사진을 추가하세요", size: 12, weight: .semibold,
                                        color: AppTheme.Color.primary)

        cameraPlaceholderStack = UIStackView.make(axis: .vertical, spacing: 8, alignment: .center)
        cameraPlaceholderStack.addArrangedSubview(cameraIcon)
        cameraPlaceholderStack.addArrangedSubview(cameraLabel)

        // Slot: image + placeholder inside
        photoSlotView.addSubview(photoImageView)
        photoSlotView.addSubview(cameraPlaceholderStack)
        photoImageView.snp.makeConstraints { $0.edges.equalToSuperview() }
        cameraPlaceholderStack.snp.makeConstraints { $0.center.equalToSuperview() }
        photoSlotView.snp.makeConstraints { $0.width.height.equalTo(150) }

        // Wrapper centers the slot horizontally
        let slotWrapper = UIView()
        slotWrapper.addSubview(photoSlotView)
        photoSlotView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.bottom.equalToSuperview()
        }

        let section = UIStackView.make(axis: .vertical, spacing: 7)
        section.addArrangedSubview(headerRow)
        section.addArrangedSubview(slotWrapper)
        return section
    }

    private func makeSaveButtonWrap() -> UIView {
        saveButton.snp.makeConstraints { $0.height.equalTo(48) }

        let wrapper = UIView()
        wrapper.addSubview(saveButton)
        saveButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(4)
            make.leading.trailing.bottom.equalToSuperview()
        }
        return wrapper
    }
}
