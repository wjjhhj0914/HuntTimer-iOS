import UIKit
import SnapKit

/// 고양이 목록 화면 View — 등록된 고양이가 0마리면 Empty State, 1마리 이상이면 목록 표시
final class CatListView: BaseView {

    // MARK: - Header
    let titleLabel = UILabel.make(
        text: "고양이 목록",
        size: 22,
        weight: .bold,
        color: AppTheme.Color.textDark
    )

    let subtitleLabel: UILabel = {
        let l = UILabel()
        l.font = .appFont(size: 14)
        l.textColor = AppTheme.Color.textMuted
        l.isHidden = true
        return l
    }()

    let addButton: UIButton = {
        let btn = UIButton(type: .system)
        let cfg = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        btn.setImage(UIImage(systemName: "plus", withConfiguration: cfg), for: .normal)
        btn.tintColor = AppTheme.Color.textDark
        btn.backgroundColor = AppTheme.Color.primary
        btn.layer.cornerRadius = 22
        return btn
    }()

    // MARK: - Empty State
    private let emptyContainer: UIView = {
        let v = UIView()
        return v
    }()

    private let catCircle: UIView = {
        let v = UIView()
        v.backgroundColor = AppTheme.Color.primaryLight
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
        l.text = "우측 상단의 플러스 버튼을 눌러서 추가해 주세요"
        l.font = .appFont(size: 15)
        l.textColor = AppTheme.Color.textMuted
        l.textAlignment = .center
        return l
    }()

    // MARK: - List State
    let tableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = .clear
        tv.separatorStyle = .none
        tv.rowHeight = 108
        tv.showsVerticalScrollIndicator = false
        tv.isHidden = true
        return tv
    }()

    // MARK: - Start Button
    let startButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("시작하기", for: .normal)
        btn.setTitleColor(AppTheme.Color.textDark, for: .normal)
        btn.titleLabel?.font = .appFont(size: 17, weight: .bold)
        btn.backgroundColor = AppTheme.Color.primary
        btn.layer.cornerRadius = AppTheme.Radius.large
        btn.isHidden = true
        return btn
    }()

    // MARK: - Setup
    override func setupUI() {
        backgroundColor = AppTheme.Color.background

        catCircle.addSubview(catImageView)

        // 원형 이미지 + 레이블을 하나의 스택으로 묶어 emptyContainer 중앙에 배치
        let emptyStack = UIStackView.make(axis: .vertical, spacing: 0, alignment: .center)
        emptyStack.addArrangedSubview(catCircle)
        emptyStack.setCustomSpacing(52, after: catCircle)
        emptyStack.addArrangedSubview(emptyTitleLabel)
        emptyStack.setCustomSpacing(10, after: emptyTitleLabel)
        emptyStack.addArrangedSubview(emptySubLabel)
        emptyContainer.addSubview(emptyStack)

        [titleLabel, subtitleLabel, addButton,
         emptyContainer, tableView, startButton].forEach { addSubview($0) }

        // Header
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.top.equalTo(safeAreaLayoutGuide).offset(22)
        }
        subtitleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
        }
        addButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalTo(titleLabel)
            make.width.height.equalTo(44)
        }

        // Empty Container — 화면 전체에서 중앙 정렬
        emptyContainer.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.bottom.equalTo(safeAreaLayoutGuide).offset(-20)
        }
        // 스택 전체를 emptyContainer 중앙에 배치
        emptyStack.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.equalToSuperview().offset(-80)
        }
        catCircle.snp.makeConstraints { $0.width.height.equalTo(240) }
        catImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(102)
            make.height.equalTo(94)
        }

        // Start Button — pinned to bottom
        startButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(safeAreaLayoutGuide).offset(-16)
            make.height.equalTo(54)
        }

        // TableView — below subtitle, above startButton
        tableView.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(startButton.snp.top).offset(-12)
        }
    }

    // MARK: - State Toggle
    func updateState(catCount: Int) {
        let hasCats = catCount > 0

        emptyContainer.isHidden = hasCats
        tableView.isHidden      = !hasCats
        subtitleLabel.isHidden  = !hasCats
        startButton.isHidden    = !hasCats

        if hasCats {
            subtitleLabel.text = "\(catCount)마리와 함께하는 중"
        }
    }
}
