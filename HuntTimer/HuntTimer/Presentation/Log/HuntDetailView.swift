import UIKit
import SnapKit

// MARK: - SessionPageView (한 세션의 콘텐츠 페이지)

private final class SessionPageView: UIView {

    // MARK: - Subviews

    private let durationLabel = UILabel.make(text: "0분", size: 28, weight: .black,
                                              color: UIColor(hex: "#E8507A"))

    private let toyPillView: UIView = {
        let v = UIView()
        v.backgroundColor    = UIColor(hex: "#FFF0F4")
        v.layer.cornerRadius = 10
        return v
    }()
    private let toyPillLabel = UILabel.make(text: "", size: 13, weight: .semibold,
                                             color: UIColor(hex: "#E8507A"))
    private let toyEmptyView: UIView = {
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
    private let photoEmptyIcon: UIImageView = {
        let iv = UIImageView()
        let cfg = UIImage.SymbolConfiguration(pointSize: 24, weight: .regular)
        iv.image       = UIImage(systemName: "photo", withConfiguration: cfg)
        iv.tintColor   = UIColor(hex: "#E8A0B8")
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let memoLabel: UILabel = {
        let l = UILabel()
        l.font          = .appFont(size: 13, weight: .regular)
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
        let stack = UIStackView.make(axis: .vertical, spacing: 0)
        stack.layoutMargins = UIEdgeInsets(top: 20, left: 22, bottom: 20, right: 22)
        stack.isLayoutMarginsRelativeArrangement = true

        let timeStack  = makeTimeSection()
        let divider1   = makeDivider()
        let toyStack   = makeToySection()
        let divider2   = makeDivider()
        let photoStack = makePhotoSection()
        let memoStack  = makeMemoSection()

        [timeStack, divider1, toyStack, divider2, photoStack, memoStack]
            .forEach { stack.addArrangedSubview($0) }

        stack.setCustomSpacing(16, after: timeStack)
        stack.setCustomSpacing(16, after: divider1)
        stack.setCustomSpacing(16, after: toyStack)
        stack.setCustomSpacing(16, after: divider2)
        stack.setCustomSpacing(16, after: photoStack)

        addSubview(stack)
        // 상단/좌우만 고정 — 콘텐츠 높이가 자연스럽게 결정되도록 bottom은 고정하지 않음
        stack.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
    }

    // MARK: - Section Builders

    private func makeTimeSection() -> UIStackView {
        let s = UIStackView.make(axis: .vertical, spacing: 8)
        s.addArrangedSubview(makeSectionHeader(icon: "timer", title: "함께 놀아준 시간"))
        s.addArrangedSubview(durationLabel)
        return s
    }

    private func makeToySection() -> UIStackView {
        // Pill
        toyPillView.addSubview(toyPillLabel)
        toyPillLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(7)
            make.leading.trailing.equalToSuperview().inset(14)
        }

        // Empty pill
        let emptyLabel = UILabel.make(text: "선택한 장난감이 없어요!", size: 13, weight: .semibold,
                                      color: UIColor(hex: "#E8A0B8"))
        toyEmptyView.addSubview(emptyLabel)
        emptyLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(7)
            make.leading.trailing.equalToSuperview().inset(14)
        }

        let pillRow = UIStackView.make(axis: .horizontal, spacing: 0)
        pillRow.addArrangedSubview(toyPillView)
        pillRow.addArrangedSubview(toyEmptyView)
        pillRow.addArrangedSubview(UIView())   // 우측 공간 채우기

        let s = UIStackView.make(axis: .vertical, spacing: 10)
        s.addArrangedSubview(makeSectionHeader(icon: "sparkles", title: "놀아준 장난감"))
        s.addArrangedSubview(pillRow)
        return s
    }

    private func makePhotoSection() -> UIStackView {
        photoImageView.addSubview(photoEmptyIcon)
        photoEmptyIcon.snp.makeConstraints { $0.center.equalToSuperview() }
        photoImageView.snp.makeConstraints { $0.height.equalTo(128) }

        let s = UIStackView.make(axis: .vertical, spacing: 10)
        s.addArrangedSubview(makeSectionHeader(icon: "photo", title: "사진"))
        s.addArrangedSubview(photoImageView)
        return s
    }

    private func makeMemoSection() -> UIStackView {
        let memoBox = UIView()
        memoBox.backgroundColor    = UIColor(hex: "#FFF8FA")
        memoBox.layer.cornerRadius = 12
        memoBox.layer.borderWidth  = 1
        memoBox.layer.borderColor  = UIColor(hex: "#F0D8E0").cgColor
        memoBox.addSubview(memoLabel)
        memoLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(12)
            make.leading.trailing.equalToSuperview().inset(14)
        }
        memoBox.snp.makeConstraints { $0.height.equalTo(68) }

        let s = UIStackView.make(axis: .vertical, spacing: 10)
        s.addArrangedSubview(makeSectionHeader(icon: "pencil", title: "메모"))
        s.addArrangedSubview(memoBox)
        return s
    }

    // MARK: - Helpers

    private func makeSectionHeader(icon: String, title: String) -> UIStackView {
        let cfg      = UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
        let iconView = UIImageView(image: UIImage(systemName: icon, withConfiguration: cfg))
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

    private func makeDivider() -> UIView {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#F5ECEF")
        v.snp.makeConstraints { $0.height.equalTo(1) }
        return v
    }

    // MARK: - Configure

    func configure(durationSeconds: Int, toyName: String?, image: UIImage?, memo: String?) {
        durationLabel.text = formatDuration(durationSeconds)

        if let toy = toyName, !toy.isEmpty {
            toyPillLabel.text   = toy
            toyPillView.isHidden  = false
            toyEmptyView.isHidden = true
        } else {
            toyPillView.isHidden  = true
            toyEmptyView.isHidden = false
        }

        if let img = image {
            photoImageView.image    = img
            photoEmptyIcon.isHidden = true
        } else {
            photoImageView.image    = nil
            photoEmptyIcon.isHidden = false
        }

        if let text = memo, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            memoLabel.text      = text
            memoLabel.textColor = UIColor(hex: "#3D2B2B")
        } else {
            memoLabel.text      = "메모가 없습니다"
            memoLabel.textColor = UIColor(hex: "#C8B4BC")
        }
    }

    private func formatDuration(_ seconds: Int) -> String {
        let h    = seconds / 3600
        let mins = (seconds % 3600) / 60
        let secs = seconds % 60
        if h > 0    { return "\(h)시간 \(mins)분" }
        if mins > 0 { return secs > 0 ? "\(mins)분 \(secs)초" : "\(mins)분" }
        return "\(secs)초"
    }
}

// MARK: - HuntDetailView (페이징 모달)

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

    // MARK: - Private

    private let pageControl: UIPageControl = {
        let pc = UIPageControl()
        pc.currentPageIndicatorTintColor = UIColor(hex: "#E8507A")
        pc.pageIndicatorTintColor        = UIColor(hex: "#F0D8E0")
        pc.hidesForSinglePage            = true
        return pc
    }()

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.isPagingEnabled                = true
        sv.showsHorizontalScrollIndicator = false
        sv.clipsToBounds                  = true
        return sv
    }()

    private var pageViews:   [SessionPageView] = []
    private var sessionData: [(durationSeconds: Int, toyName: String?, image: UIImage?, memo: String?)] = []
    private var pagesBuilt = false

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
        let divider = makeDivider()

        scrollView.delegate = self
        scrollView.snp.makeConstraints { $0.height.equalTo(450) }

        pageControl.snp.makeConstraints { $0.height.equalTo(28) }
        pageControl.isHidden = true

        let mainStack = UIStackView.make(axis: .vertical, spacing: 0)
        mainStack.addArrangedSubview(header)
        mainStack.addArrangedSubview(divider)
        mainStack.addArrangedSubview(scrollView)
        mainStack.addArrangedSubview(pageControl)

        card.addSubview(mainStack)
        mainStack.snp.makeConstraints { $0.edges.equalToSuperview() }
        divider.snp.makeConstraints { $0.height.equalTo(1) }
    }

    private func makeHeader() -> UIView {
        let v = UIView()

        let titleStack = UIStackView.make(axis: .horizontal, spacing: 4, alignment: .center)
        let titleLabel = UILabel.make(text: "오늘의 사냥 기록", size: 17, weight: .bold,
                                      color: UIColor(hex: "#3D2B2B"))
        let pawCfg  = UIImage.SymbolConfiguration(pointSize: 15, weight: .medium)
        let pawIcon = UIImageView(image: UIImage(systemName: "pawprint.fill", withConfiguration: pawCfg))
        pawIcon.tintColor   = UIColor(hex: "#E8507A")
        pawIcon.contentMode = .scaleAspectFit
        titleStack.addArrangedSubview(titleLabel)
        titleStack.addArrangedSubview(pawIcon)

        closeButton.snp.makeConstraints { $0.width.height.equalTo(32) }
        v.addSubview(titleStack)
        v.addSubview(closeButton)
        v.snp.makeConstraints { $0.height.equalTo(56) }
        titleStack.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(22)
            make.centerY.equalToSuperview()
        }
        closeButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
        }
        return v
    }

    private func makeDivider() -> UIView {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#F0E4E8")
        return v
    }

    // MARK: - Configure

    func configure(sessions: [(durationSeconds: Int, toyName: String?, image: UIImage?, memo: String?)]) {
        sessionData = sessions
        pageControl.numberOfPages = sessions.count
        pageControl.currentPage   = 0
        pageControl.isHidden      = sessions.count <= 1
        pagesBuilt = false
        setNeedsLayout()
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        guard !pagesBuilt, !sessionData.isEmpty, scrollView.bounds.width > 0 else { return }
        buildPages()
        pagesBuilt = true
    }

    private func buildPages() {
        pageViews.forEach { $0.removeFromSuperview() }
        pageViews.removeAll()

        let pageW = scrollView.bounds.width
        let pageH = scrollView.bounds.height

        for (i, data) in sessionData.enumerated() {
            let page = SessionPageView()
            page.configure(durationSeconds: data.durationSeconds,
                           toyName: data.toyName,
                           image:   data.image,
                           memo:    data.memo)
            page.frame = CGRect(x: CGFloat(i) * pageW, y: 0, width: pageW, height: pageH)
            scrollView.addSubview(page)
            pageViews.append(page)
        }
        scrollView.contentSize = CGSize(width: pageW * CGFloat(sessionData.count), height: pageH)
    }
}

// MARK: - UIScrollViewDelegate

extension HuntDetailView: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let page = Int(round(scrollView.contentOffset.x / max(scrollView.bounds.width, 1)))
        pageControl.currentPage = page
    }
}
