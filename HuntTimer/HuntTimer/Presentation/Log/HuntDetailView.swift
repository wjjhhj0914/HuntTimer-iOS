import UIKit
import SnapKit

/// 사냥 기록 상세 커스텀 모달 뷰 — 디자인 Node ID: v2cvH 기반
final class HuntDetailView: UIView {

    // MARK: - Public UI

    let backdropView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        return v
    }()

    let closeButton: UIButton = {
        let btn = UIButton(type: .system)
        let cfg = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        btn.setImage(UIImage(systemName: "xmark", withConfiguration: cfg), for: .normal)
        btn.tintColor       = UIColor(hex: "#BFA2A2")
        btn.backgroundColor = UIColor(hex: "#F5ECEF")
        btn.layer.cornerRadius = 16
        return btn
    }()

    // MARK: - Private content subviews

    private let durationLabel = UILabel.make(text: "0분", size: 26, weight: .black,
                                              color: UIColor(hex: "#E8507A"))

    private let toyPillView: UIView = {
        let v = UIView()
        v.backgroundColor    = UIColor(hex: "#FFF0F4")
        v.layer.cornerRadius = 10
        return v
    }()
    private let toyPillLabel = UILabel.make(text: "", size: 12, weight: .semibold,
                                             color: UIColor(hex: "#E8507A"))

    private let toyEmptyStateView: UIView = {
        let v = UIView()
        v.backgroundColor    = UIColor(hex: "#FFF5F7")
        v.layer.cornerRadius = 10
        return v
    }()

    let photoImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode        = .scaleAspectFill
        iv.clipsToBounds      = true
        iv.layer.cornerRadius = 14
        iv.backgroundColor    = UIColor(hex: "#FFF0F4")
        return iv
    }()

    private let photoEmptyIconView: UIImageView = {
        let iv = UIImageView()
        let cfg = UIImage.SymbolConfiguration(pointSize: 28, weight: .regular)
        iv.image       = UIImage(systemName: "photo", withConfiguration: cfg)
        iv.tintColor   = UIColor(hex: "#E8A0B8")
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let memoLabel: UILabel = {
        let l = UILabel()
        l.font          = .appFont(size: 12, weight: .regular)
        l.textColor     = UIColor(hex: "#C8B4BC")
        l.numberOfLines = 0
        return l
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        buildUI()
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Build

    private func buildUI() {
        addSubview(backdropView)
        backdropView.snp.makeConstraints { $0.edges.equalToSuperview() }

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

        let header  = makeHeader()
        let divider = makeDivider(color: UIColor(hex: "#F0E4E8"))

        let contentStack = UIStackView.make(axis: .vertical, spacing: 0)
        contentStack.layoutMargins                       = UIEdgeInsets(top: 4, left: 20, bottom: 20, right: 20)
        contentStack.isLayoutMarginsRelativeArrangement  = true
        contentStack.addArrangedSubview(makeTimeSection())
        contentStack.addArrangedSubview(makeThinDivider())
        contentStack.addArrangedSubview(makeToySection())
        contentStack.addArrangedSubview(makeThinDivider())
        contentStack.addArrangedSubview(makePhotoSection())
        contentStack.addArrangedSubview(makeMemoSection())

        let mainStack = UIStackView.make(axis: .vertical, spacing: 0)
        mainStack.addArrangedSubview(header)
        mainStack.addArrangedSubview(divider)
        mainStack.addArrangedSubview(contentStack)

        card.addSubview(mainStack)
        mainStack.snp.makeConstraints { $0.edges.equalToSuperview() }
        divider.snp.makeConstraints { $0.height.equalTo(1) }
    }

    // MARK: - Header

    private func makeHeader() -> UIView {
        let v = UIView()

        let titleStack = UIStackView.make(axis: .horizontal, spacing: 4, alignment: .center)
        let titleLabel = UILabel.make(text: "오늘의 사냥 기록", size: 17, weight: .bold,
                                      color: UIColor(hex: "#3D2B2B"))
        let pawIcon = UIImageView()
        let pawCfg  = UIImage.SymbolConfiguration(pointSize: 15, weight: .medium)
        pawIcon.image     = UIImage(systemName: "pawprint.fill", withConfiguration: pawCfg)
        pawIcon.tintColor = UIColor(hex: "#E8507A")
        pawIcon.contentMode = .scaleAspectFit
        titleStack.addArrangedSubview(titleLabel)
        titleStack.addArrangedSubview(pawIcon)

        closeButton.snp.makeConstraints { $0.width.height.equalTo(32) }

        v.addSubview(titleStack)
        v.addSubview(closeButton)
        v.snp.makeConstraints { $0.height.equalTo(56) }
        titleStack.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.centerY.equalToSuperview()
        }
        closeButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
        }
        return v
    }

    // MARK: - Time Section

    private func makeTimeSection() -> UIView {
        let wrapper = UIView()

        let headerRow = makeSectionHeader(icon: "timer", title: "함께 놀아준 시간")

        let sectionStack = UIStackView.make(axis: .vertical, spacing: 6)
        sectionStack.addArrangedSubview(headerRow)
        sectionStack.addArrangedSubview(durationLabel)

        wrapper.addSubview(sectionStack)
        sectionStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.leading.trailing.bottom.equalToSuperview()
        }
        return wrapper
    }

    // MARK: - Toy Section

    private func makeToySection() -> UIView {
        let wrapper = UIView()

        let headerRow = makeSectionHeader(icon: "sparkles", title: "놀아준 장난감")

        // Toy pill
        toyPillView.addSubview(toyPillLabel)
        toyPillLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(6)
            make.leading.trailing.equalToSuperview().inset(12)
        }

        // Empty state pill
        let emptyLabel = UILabel.make(text: "선택한 장난감이 없어요!", size: 12, weight: .semibold,
                                      color: UIColor(hex: "#E8A0B8"))
        toyEmptyStateView.addSubview(emptyLabel)
        emptyLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(6)
            make.leading.trailing.equalToSuperview().inset(12)
        }

        // Pills container (only one visible at a time)
        let pillsContainer = UIStackView.make(axis: .horizontal, spacing: 0)
        pillsContainer.addArrangedSubview(toyPillView)
        pillsContainer.addArrangedSubview(toyEmptyStateView)
        pillsContainer.addArrangedSubview(UIView()) // spacer

        let sectionStack = UIStackView.make(axis: .vertical, spacing: 8)
        sectionStack.addArrangedSubview(headerRow)
        sectionStack.addArrangedSubview(pillsContainer)

        wrapper.addSubview(sectionStack)
        sectionStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.leading.trailing.bottom.equalToSuperview()
        }
        return wrapper
    }

    // MARK: - Photo Section

    private func makePhotoSection() -> UIView {
        let wrapper = UIView()

        let headerRow = makeSectionHeader(icon: "photo", title: "사진")

        // Photo image view (with empty icon overlay)
        photoImageView.addSubview(photoEmptyIconView)
        photoEmptyIconView.snp.makeConstraints { $0.center.equalToSuperview() }
        photoImageView.snp.makeConstraints { $0.height.equalTo(180) }

        let sectionStack = UIStackView.make(axis: .vertical, spacing: 8)
        sectionStack.addArrangedSubview(headerRow)
        sectionStack.addArrangedSubview(photoImageView)

        wrapper.addSubview(sectionStack)
        sectionStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.leading.trailing.bottom.equalToSuperview()
        }
        return wrapper
    }

    // MARK: - Memo Section

    private func makeMemoSection() -> UIView {
        let wrapper = UIView()

        let headerRow = makeSectionHeader(icon: "pencil", title: "메모")

        let memoBox = UIView()
        memoBox.backgroundColor    = UIColor(hex: "#FFF8FA")
        memoBox.layer.cornerRadius = 12
        memoBox.layer.borderWidth  = 1
        memoBox.layer.borderColor  = UIColor(hex: "#F0D8E0").cgColor
        memoBox.addSubview(memoLabel)
        memoLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(10)
            make.leading.trailing.equalToSuperview().inset(12)
        }
        memoBox.snp.makeConstraints { $0.height.equalTo(80) }

        let sectionStack = UIStackView.make(axis: .vertical, spacing: 8)
        sectionStack.addArrangedSubview(headerRow)
        sectionStack.addArrangedSubview(memoBox)

        wrapper.addSubview(sectionStack)
        sectionStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.leading.trailing.bottom.equalToSuperview()
        }
        return wrapper
    }

    // MARK: - Helpers

    private func makeSectionHeader(icon: String, title: String) -> UIStackView {
        let iconCfg  = UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
        let iconView = UIImageView(image: UIImage(systemName: icon, withConfiguration: iconCfg))
        iconView.tintColor   = UIColor(hex: "#BFA2A2")
        iconView.contentMode = .scaleAspectFit
        iconView.snp.makeConstraints { $0.width.height.equalTo(14) }

        let label = UILabel.make(text: title, size: 11, weight: .semibold,
                                  color: UIColor(hex: "#BFA2A2"))

        let row = UIStackView.make(axis: .horizontal, spacing: 5, alignment: .center)
        row.addArrangedSubview(iconView)
        row.addArrangedSubview(label)
        return row
    }

    private func makeDivider(color: UIColor) -> UIView {
        let v = UIView()
        v.backgroundColor = color
        return v
    }

    private func makeThinDivider() -> UIView {
        let wrapper = UIView()
        let line    = UIView()
        line.backgroundColor = UIColor(hex: "#F5ECEF")
        wrapper.addSubview(line)
        line.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.height.equalTo(1)
        }
        wrapper.snp.makeConstraints { $0.height.equalTo(20) }
        return wrapper
    }

    // MARK: - Configure

    func configure(durationSeconds: Int, toyName: String?, image: UIImage?, memo: String?) {
        durationLabel.text = formatDuration(durationSeconds)

        if let toy = toyName {
            toyPillLabel.text            = toy
            toyPillView.isHidden         = false
            toyEmptyStateView.isHidden   = true
        } else {
            toyPillView.isHidden         = true
            toyEmptyStateView.isHidden   = false
        }

        if let img = image {
            photoImageView.image          = img
            photoEmptyIconView.isHidden   = true
        } else {
            photoImageView.image          = nil
            photoEmptyIconView.isHidden   = false
        }

        if let text = memo, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            memoLabel.text      = text
            memoLabel.textColor = UIColor(hex: "#3D2B2B")
        } else {
            memoLabel.text      = "메모가 없습니다"
            memoLabel.textColor = UIColor(hex: "#C8B4BC")
        }
    }

    // MARK: - Duration Formatting

    private func formatDuration(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        if mins > 0 { return secs > 0 ? "\(mins)분 \(secs)초" : "\(mins)분" }
        return "\(secs)초"
    }
}
