import UIKit
import SnapKit

/// 기록 화면 캘린더 그리드 셀
final class DayCell: UICollectionViewCell {

    static let id = "DayCell"

    // MARK: - Subviews

    /// 선택·오늘 배경 — dayLabel.top ~ dotView.bottom 에 compact하게 고정
    private let selectionBg = UIView()
    private let dayLabel    = UILabel()

    /// 원형 마스킹 컨테이너 — clipsToBounds 를 담당, 내부 뷰들은 edges 또는 center 로 배치
    private let imageContainer: UIView = {
        let v = UIView()
        v.clipsToBounds      = true
        v.layer.cornerRadius = 10   // 20pt / 2 = 완전한 원
        v.layer.borderWidth  = 1.5
        v.layer.borderColor  = AppTheme.Color.primaryLight.cgColor
        v.backgroundColor    = AppTheme.Color.primaryLight
        return v
    }()

    /// 실제 사진 이미지 — 비동기 로딩 완료 후 표시
    private let thumbImage: UIImageView = {
        let iv = UIImageView()
        iv.contentMode    = .scaleAspectFill
        iv.clipsToBounds  = true
        iv.isHidden       = true
        return iv
    }()

    /// 상태 심볼 아이콘 (photo = 로딩 중 / exclamationmark.triangle = 사진 없음 or 파일 오류)
    private let symbolIconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    /// 활동 인디케이터 점
    private let dotView = UIView()

    // MARK: - Cell Reuse State

    /// 현재 셀에 요청된 날짜 — 비동기 로딩 완료 시 재사용 여부 판단
    private var currentDay: Int?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)

        selectionBg.layer.cornerRadius = 14
        dayLabel.textAlignment         = .center
        dotView.layer.cornerRadius     = 3

        // ── imageContainer 내부 뷰 배치 ────────────────────────
        imageContainer.addSubview(thumbImage)
        imageContainer.addSubview(symbolIconView)
        thumbImage.snp.makeConstraints { $0.edges.equalToSuperview() }
        symbolIconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.lessThanOrEqualToSuperview().multipliedBy(0.75)
        }

        // ── Z-order: selectionBg → 나머지 ──────────────────────
        contentView.insertSubview(selectionBg, at: 0)
        contentView.addSubview(dayLabel)
        contentView.addSubview(imageContainer)
        contentView.addSubview(dotView)

        // ── 날짜: 셀 상단 ─────────────────────────────────────
        dayLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(3)
            make.centerX.equalToSuperview()
        }

        // ── 이미지 컨테이너: 날짜 바로 아래, 고정 크기 20×20 ────
        imageContainer.snp.makeConstraints { make in
            make.top.equalTo(dayLabel.snp.bottom).offset(3)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(20)
        }

        // ── 점: 이미지 아래 ───────────────────────────────────
        dotView.snp.makeConstraints { make in
            make.top.equalTo(imageContainer.snp.bottom).offset(2)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(6)
        }

        // ── 선택 배경: dayLabel.top ~ dotView.bottom ──────────
        selectionBg.snp.makeConstraints { make in
            make.top.equalTo(dayLabel.snp.top).offset(-3)
            make.bottom.equalTo(dotView.snp.bottom).offset(3)
            make.leading.equalToSuperview().offset(1)
            make.trailing.equalToSuperview().offset(-1)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()
        currentDay             = nil
        thumbImage.image       = nil
        thumbImage.isHidden    = true
        symbolIconView.image   = nil
        symbolIconView.isHidden = true
    }

    // MARK: - Animations

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
        currentDay = day

        guard let day else {
            dayLabel.text               = ""
            selectionBg.backgroundColor = .clear
            imageContainer.isHidden     = true
            dotView.isHidden            = true
            thumbImage.image            = nil
            thumbImage.isHidden         = true
            symbolIconView.isHidden     = true
            return
        }

        dayLabel.text      = "\(day)"
        dayLabel.font      = .appFont(size: 12, weight: isSelected || isToday ? .bold : .regular)
        dayLabel.textColor = isSelected ? .white
                           : isToday    ? AppTheme.Color.primary
                           :              AppTheme.Color.textDark

        selectionBg.backgroundColor = isSelected ? AppTheme.Color.primary
                                    : isToday    ? AppTheme.Color.primaryLight
                                    :              .clear

        imageContainer.isHidden = !hasActivity
        dotView.isHidden        = !hasActivity

        // 이전 이미지 초기화
        thumbImage.image    = nil
        thumbImage.isHidden = true

        if hasActivity {
            let symCfg = UIImage.SymbolConfiguration(pointSize: 9, weight: .medium)

            if let path = imagePath {
                // ── 로딩 중: photo 심볼 먼저 표시 ──────────────────
                symbolIconView.image    = UIImage(systemName: "photo", withConfiguration: symCfg)
                symbolIconView.tintColor = AppTheme.Color.primary.withAlphaComponent(0.55)
                symbolIconView.isHidden = false

                // ── 비동기 로드 ──────────────────────────────────
                let targetDay = day
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    let loadedImage = UIImage(contentsOfFile: path)
                    DispatchQueue.main.async {
                        // 셀이 재사용된 경우 폐기
                        guard let self, self.currentDay == targetDay else { return }
                        if let img = loadedImage {
                            self.thumbImage.image        = img
                            self.thumbImage.contentMode  = .scaleAspectFill
                            self.thumbImage.clipsToBounds = true
                            self.thumbImage.isHidden     = false
                            self.symbolIconView.isHidden = true
                        } else {
                            // 파일 없음 or 손상 — 경고 심볼로 교체
                            self.symbolIconView.image    = UIImage(systemName: "exclamationmark.triangle",
                                                                   withConfiguration: symCfg)
                            self.symbolIconView.tintColor = UIColor(hex: "#E8A0B8")
                        }
                    }
                }
            } else {
                // ── imagePath 없음: 경고 심볼 ────────────────────
                symbolIconView.image    = UIImage(systemName: "exclamationmark.triangle",
                                                  withConfiguration: symCfg)
                symbolIconView.tintColor = UIColor(hex: "#E8A0B8")
                symbolIconView.isHidden = false
            }
        } else {
            symbolIconView.isHidden = true
        }

        dotView.backgroundColor          = isSelected ? .white : AppTheme.Color.primary
        imageContainer.layer.borderColor = isSelected
            ? UIColor.white.cgColor
            : AppTheme.Color.primaryLight.cgColor
    }
}
