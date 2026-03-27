import UIKit
import SnapKit

/// 기록 화면 캘린더 그리드 셀
final class DayCell: UICollectionViewCell {

    static let id = "DayCell"

    // MARK: - Subviews

    /// 선택·오늘 배경 — dayLabel.top ~ dotView.bottom 에 compact하게 고정
    private let selectionBg = UIView()
    private let dayLabel    = UILabel()

    /// 원형 마스킹 컨테이너 — UIImageView 에 직접 cornerRadius를 적용하면
    /// layoutSubviews 타이밍에 bounds가 0 으로 읽히는 문제가 발생하므로
    /// UIView 래퍼가 clipsToBounds 를 담당하고 이미지는 그 안에서 edges를 채운다
    private let imageContainer: UIView = {
        let v = UIView()
        v.clipsToBounds = true
        v.layer.cornerRadius = 10   // 20pt / 2 = 완전한 원 (고정 사이즈)
        v.layer.borderWidth  = 1.5
        v.layer.borderColor  = AppTheme.Color.primaryLight.cgColor
        v.backgroundColor    = AppTheme.Color.primaryLight
        return v
    }()

    private let thumbImage = AsyncImageView(contentMode: .scaleAspectFill)

    /// 사진 없을 때 기본 아이콘
    private let catIconView: UIImageView = {
        let iv = UIImageView()
        let cfg = UIImage.SymbolConfiguration(pointSize: 9, weight: .medium)
        iv.image = UIImage(systemName: "cat.fill", withConfiguration: cfg)
        iv.tintColor = AppTheme.Color.primary
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    /// 활동 인디케이터 점
    private let dotView = UIView()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)

        selectionBg.layer.cornerRadius = 14
        dayLabel.textAlignment = .center
        dotView.layer.cornerRadius = 3

        // ── 이미지를 컨테이너에 넣기 (원형 클리핑은 컨테이너가 담당) ──
        imageContainer.addSubview(thumbImage)
        imageContainer.addSubview(catIconView)
        thumbImage.snp.makeConstraints { $0.edges.equalToSuperview() }
        catIconView.snp.makeConstraints { $0.center.equalToSuperview() }

        // ── Z-order: selectionBg → 나머지 ──────────────────────
        contentView.insertSubview(selectionBg, at: 0)
        contentView.addSubview(dayLabel)
        contentView.addSubview(imageContainer)
        contentView.addSubview(dotView)

        // ── 날짜: 셀 상단 고정 ────────────────────────────────
        dayLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(3)
            make.centerX.equalToSuperview()
        }

        // ── 이미지 컨테이너: 날짜 바로 아래 ─────────────────────
        imageContainer.snp.makeConstraints { make in
            make.top.equalTo(dayLabel.snp.bottom).offset(3)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(20)
        }

        // ── 점: 이미지 아래 tight 간격 ───────────────────────
        dotView.snp.makeConstraints { make in
            make.top.equalTo(imageContainer.snp.bottom).offset(2)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(6)
        }

        // ── 선택 배경: dayLabel.top ~ dotView.bottom 에 compact하게 ──
        selectionBg.snp.makeConstraints { make in
            make.top.equalTo(dayLabel.snp.top).offset(-3)
            make.bottom.equalTo(dotView.snp.bottom).offset(3)
            make.leading.equalToSuperview().offset(1)
            make.trailing.equalToSuperview().offset(-1)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Animations

    /// 눌림: 빠르게 축소 / 뗌: 원래 크기로 복귀
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(
                withDuration: isHighlighted ? 0.08 : 0.18,
                delay: 0,
                options: [.allowUserInteraction, .beginFromCurrentState]
            ) {
                self.contentView.transform = self.isHighlighted
                    ? CGAffineTransform(scaleX: 0.85, y: 0.85)
                    : .identity
            }
        }
    }

    /// 선택 확정 시 호출 — 현재 transform 위치(눌림 상태)에서 스프링으로 튕겨 돌아옴
    func animateBounce() {
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 0.38,
            initialSpringVelocity: 0.8,
            options: [.allowUserInteraction, .beginFromCurrentState]
        ) {
            self.contentView.transform = .identity
        }
    }

    // MARK: - Configure

    func configure(day: Int?, isSelected: Bool, isToday: Bool, hasActivity: Bool, imagePath: String?) {
        guard let day else {
            dayLabel.text               = ""
            selectionBg.backgroundColor = .clear
            imageContainer.isHidden     = true
            dotView.isHidden            = true
            return
        }

        dayLabel.text = "\(day)"
        dayLabel.font = .appFont(size: 12, weight: isSelected || isToday ? .bold : .regular)
        dayLabel.textColor = isSelected ? .white
                           : isToday    ? AppTheme.Color.primary
                           :              AppTheme.Color.textDark

        selectionBg.backgroundColor = isSelected ? AppTheme.Color.primary
                                    : isToday    ? AppTheme.Color.primaryLight
                                    :              .clear

        imageContainer.isHidden = !hasActivity
        dotView.isHidden        = !hasActivity

        if hasActivity {
            if let path = imagePath, let img = UIImage(contentsOfFile: path) {
                thumbImage.image    = img
                thumbImage.isHidden = false
                catIconView.isHidden = true
            } else {
                thumbImage.image    = nil
                thumbImage.isHidden = true
                catIconView.isHidden = false
            }
        }

        dotView.backgroundColor        = isSelected ? .white : AppTheme.Color.primary
        imageContainer.layer.borderColor = isSelected
            ? UIColor.white.cgColor
            : AppTheme.Color.primaryLight.cgColor
    }
}
