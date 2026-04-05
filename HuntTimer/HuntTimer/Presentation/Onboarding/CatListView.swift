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
        btn.tintColor = .white
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
        btn.titleLabel?.font = .appFont(size: 17, weight: .bold)
        btn.setTitleColor(.white, for: .normal)
        btn.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .disabled)
        btn.backgroundColor = AppTheme.Color.primary
        btn.layer.cornerRadius = AppTheme.Radius.large
        btn.isEnabled = false
        btn.alpha = 0.5
        return btn
    }()

    // MARK: - Setup
    override func setupUI() {
        backgroundColor = AppTheme.Color.background

        catCircle.addSubview(catImageView)
        emptyContainer.addSubview(catCircle)
        emptyContainer.addSubview(emptyTitleLabel)
        emptyContainer.addSubview(emptySubLabel)

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

        // Empty Container — vertically centered in available space
        emptyContainer.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.bottom.equalTo(startButton.snp.top).offset(-20)
        }
        catCircle.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-30)
            make.width.height.equalTo(240)
        }
        catImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(102)
            make.height.equalTo(94)
        }
        emptyTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(catCircle.snp.bottom).offset(36)
            make.leading.trailing.equalToSuperview().inset(40)
        }
        emptySubLabel.snp.makeConstraints { make in
            make.top.equalTo(emptyTitleLabel.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(40)
        }

        // TableView — below header, above start button
        tableView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(startButton.snp.top).offset(-12)
        }

        // Start Button — pinned to bottom
        startButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(safeAreaLayoutGuide).offset(-24)
            make.height.equalTo(58)
        }
    }

    // MARK: - State Toggle
    func updateState(catCount: Int) {
        let hasCats = catCount > 0

        emptyContainer.isHidden = hasCats
        tableView.isHidden      = !hasCats
        subtitleLabel.isHidden  = !hasCats

        if hasCats {
            subtitleLabel.text = "\(catCount)마리와 함께하는 중"
        }

        startButton.isEnabled = hasCats
        UIView.animate(withDuration: 0.2) {
            self.startButton.alpha = hasCats ? 1.0 : 0.5
        }
    }
}
