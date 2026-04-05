import UIKit
import SnapKit

/// 품종 선택 바텀시트 — UITableView 리스트
final class BreedPickerBottomSheetViewController: BaseViewController {

    // MARK: - Callback
    var onBreedSelected: ((CatBreed) -> Void)?

    // MARK: - State
    private var selectedBreed: CatBreed?

    init(selectedBreed: CatBreed? = nil) {
        self.selectedBreed = selectedBreed
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle   = .crossDissolve
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - UI
    private let dimView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.48)
        v.alpha = 0
        return v
    }()

    private let sheetView: UIView = {
        let v = UIView()
        v.backgroundColor    = .white
        v.layer.cornerRadius = 28
        v.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return v
    }()

    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor         = .clear
        tv.separatorStyle          = .none
        tv.showsVerticalScrollIndicator = false
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "BreedCell")
        return tv
    }()

    private var sheetBottomConstraint: Constraint?
    private let sheetHeight: CGFloat = 480

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateIn()
        scrollToSelected()
    }

    // MARK: - BaseViewController
    override func setupHierarchy() {
        view.addSubview(dimView)
        view.addSubview(sheetView)
        buildSheetContent()
    }

    override func setupConstraints() {
        dimView.snp.makeConstraints { $0.edges.equalToSuperview() }
        sheetView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(sheetHeight)
            sheetBottomConstraint = make.bottom.equalToSuperview().offset(sheetHeight).constraint
        }
    }

    override func setupBind() {
        tableView.delegate   = self
        tableView.dataSource = self
        dimView.onTap(self, action: #selector(dimTapped))
    }

    // MARK: - Build Sheet
    private func buildSheetContent() {
        let handle    = makeHandle()
        let headerRow = makeHeaderRow()
        let sep       = makeSeparator()

        sheetView.addSubview(handle)
        sheetView.addSubview(headerRow)
        sheetView.addSubview(sep)
        sheetView.addSubview(tableView)

        handle.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(24)
        }
        headerRow.snp.makeConstraints { make in
            make.top.equalTo(handle.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(56)
        }
        sep.snp.makeConstraints { make in
            make.top.equalTo(headerRow.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(1)
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(sep.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(sheetView.safeAreaLayoutGuide)
        }
    }

    private func makeHandle() -> UIView {
        let handle = UIView()
        handle.backgroundColor   = AppTheme.Color.purpleLight
        handle.layer.cornerRadius = 2.5

        let area = UIView()
        area.addSubview(handle)
        handle.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(40)
            make.height.equalTo(5)
        }
        return area
    }

    private func makeHeaderRow() -> UIView {
        let titleL  = UILabel.make(text: "품종 선택", size: 17, weight: .bold,
                                   color: AppTheme.Color.textDark)
        let doneBtn = UIButton(type: .system)
        doneBtn.setTitle("완료", for: .normal)
        doneBtn.setTitleColor(.white, for: .normal)
        doneBtn.titleLabel?.font   = .appFont(size: 15, weight: .semibold)
        doneBtn.backgroundColor    = AppTheme.Color.primary
        doneBtn.layer.cornerRadius = 18
        doneBtn.contentEdgeInsets  = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        doneBtn.snp.makeConstraints { $0.height.equalTo(36) }
        doneBtn.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)

        let row = UIView()
        row.addSubview(titleL)
        row.addSubview(doneBtn)
        titleL.snp.makeConstraints { $0.leading.equalToSuperview().offset(20); $0.centerY.equalToSuperview() }
        doneBtn.snp.makeConstraints { $0.trailing.equalToSuperview().offset(-20); $0.centerY.equalToSuperview() }
        return row
    }

    private func makeSeparator() -> UIView {
        let v = UIView()
        v.backgroundColor = AppTheme.Color.separator
        return v
    }

    // MARK: - Scroll to selected
    private func scrollToSelected() {
        guard let breed = selectedBreed,
              let index = CatBreed.allCases.firstIndex(of: breed) else { return }
        tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .middle, animated: false)
    }

    // MARK: - Actions
    @objc private func dimTapped()  { dismissSheet() }

    @objc private func doneTapped() {
        dismissSheet { [weak self] in
            guard let self, let breed = self.selectedBreed else { return }
            self.onBreedSelected?(breed)
        }
    }

    // MARK: - Animation
    private func animateIn() {
        sheetBottomConstraint?.update(offset: 0)
        UIView.animate(withDuration: 0.35, delay: 0,
                       usingSpringWithDamping: 0.85, initialSpringVelocity: 0.2,
                       options: []) {
            self.dimView.alpha = 1
            self.view.layoutIfNeeded()
        }
    }

    func dismissSheet(completion: (() -> Void)? = nil) {
        sheetBottomConstraint?.update(offset: sheetHeight)
        UIView.animate(withDuration: 0.28, delay: 0, options: .curveEaseIn) {
            self.dimView.alpha = 0
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.dismiss(animated: false, completion: completion)
        }
    }
}

// MARK: - UITableViewDataSource & Delegate
extension BreedPickerBottomSheetViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        CatBreed.allCases.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell  = tableView.dequeueReusableCell(withIdentifier: "BreedCell", for: indexPath)
        let breed = CatBreed.allCases[indexPath.row]
        let isSelected = (breed == selectedBreed)

        var config = cell.defaultContentConfiguration()
        config.text                       = breed.displayName
        config.textProperties.font        = .appFont(size: 16, weight: isSelected ? .bold : .regular)
        config.textProperties.color       = isSelected ? AppTheme.Color.primary : AppTheme.Color.textDark
        cell.contentConfiguration         = config
        cell.backgroundColor              = .clear
        cell.selectionStyle               = .none

        // 체크마크
        if isSelected {
            let iv     = UIImageView()
            let cfg    = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)
            iv.image   = UIImage(systemName: "checkmark", withConfiguration: cfg)
            iv.tintColor = AppTheme.Color.primary
            iv.sizeToFit()
            cell.accessoryView = iv
        } else {
            cell.accessoryView = nil
        }

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 52 }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let breed = CatBreed.allCases[indexPath.row]
        guard breed != selectedBreed else { return }
        selectedBreed = breed
        tableView.reloadData()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
