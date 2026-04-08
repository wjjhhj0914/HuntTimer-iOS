import UIKit
import RealmSwift

/// 타이머 설정 화면 ViewController — 프리셋·장난감·고양이 선택 후 HuntInProgressVC 푸시
final class TimerViewController: BaseViewController {

    // MARK: - View
    private let contentView = TimerView()

    // MARK: - Timer Preset
    private var totalSeconds = 15 * 60

    // MARK: - Toy Selection
    private(set) var selectedToy: String? = nil
    private var selectedToyIndex: Int     = -1
    private let toyNames: [String?]       = ["깃털", "벌레", "레이저", "카샤카샤", "오뎅꼬치", nil]

    // MARK: - Cat Selection
    private var cats:           [Cat]         = []
    private var selectedCatIds: Set<ObjectId> = []

    // MARK: - loadView
    override func loadView() { view = contentView }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureCollectionView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadCats()
        updateTipLabel()
    }

    // MARK: - BaseViewController
    override func setupBind() {
        contentView.startButton.addTarget(self, action: #selector(startTapped), for: .touchUpInside)

        contentView.presetButtons.forEach { btn in
            btn.addTarget(self, action: #selector(presetTapped(_:)), for: .touchUpInside)
        }

        contentView.toyChipButtons.forEach { btn in
            btn.addTarget(self, action: #selector(toyChipTapped(_:)), for: .touchUpInside)
        }

        // 시작 버튼 스프링 애니메이션
        contentView.startButton.addTarget(self, action: #selector(controlPressed(_:)),  for: .touchDown)
        contentView.startButton.addTarget(self, action: #selector(controlReleased(_:)),
                                          for: [.touchUpInside, .touchUpOutside, .touchCancel])

        updatePresetButtons()
    }

    // MARK: - Collection View

    private func configureCollectionView() {
        contentView.catCollectionView.dataSource = self
        contentView.catCollectionView.delegate   = self

        let layout   = contentView.catCollectionView.collectionViewLayout as! UICollectionViewFlowLayout
        let screenW  = UIScreen.main.bounds.width
        // 화면 좌우 여백 20×2 + 카드 내부 패딩 20×2 = 80pt
        let contentW = screenW - 80
        // 3열, 열 간격 20×2 = 40pt
        let itemW    = (contentW - 40) / 3
        let itemH    = CGFloat(107)   // top 여백 6 + 아바타 80 + gap 6 + 이름 15
        layout.itemSize                = CGSize(width: itemW, height: itemH)
        layout.minimumInteritemSpacing = 20
        layout.minimumLineSpacing      = 16
    }

    // MARK: - Data

    private func reloadCats() {
        do {
            let realm = try Realm()
            cats = Array(realm.objects(Cat.self))
        } catch {
            cats = []
        }

        // 삭제된 고양이 선택 해제
        let validIds = Set(cats.map { $0.id })
        selectedCatIds = selectedCatIds.intersection(validIds)

        let isEmpty = cats.isEmpty
        contentView.emptyLabel.isHidden        = !isEmpty
        contentView.catCollectionView.isHidden = isEmpty

        contentView.catCollectionView.reloadData()

        // reloadData() 후 다음 런루프에서 높이 반영
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let h = self.contentView.catCollectionView
                        .collectionViewLayout.collectionViewContentSize.height
            self.contentView.updateCatCollectionHeight(h)
            self.contentView.layoutIfNeeded()
        }

        updateStartButton()
    }

    // MARK: - Button Actions

    @objc private func startTapped() {
        let huntVC = HuntInProgressViewController()
        huntVC.totalSeconds  = totalSeconds
        huntVC.toyName       = selectedToy
        huntVC.selectedCats  = cats.filter { selectedCatIds.contains($0.id) }
        navigationController?.pushViewController(huntVC, animated: true)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    @objc private func toyChipTapped(_ sender: UIButton) {
        selectedToyIndex = sender.tag
        selectedToy      = toyNames[sender.tag]
        updateToyUI()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    @objc private func presetTapped(_ sender: UIButton) {
        totalSeconds = sender.tag * 60
        contentView.timerLabel.text = formatTime(totalSeconds)
        updatePresetButtons()
    }

    @objc private func controlPressed(_ sender: UIButton) {
        UIView.animate(withDuration: 0.12, delay: 0,
                       options: [.curveEaseOut, .allowUserInteraction]) {
            sender.transform = CGAffineTransform(scaleX: 0.88, y: 0.88)
        }
    }

    @objc private func controlReleased(_ sender: UIButton) {
        UIView.animate(withDuration: 0.45, delay: 0,
                       usingSpringWithDamping: 0.45, initialSpringVelocity: 0.8,
                       options: .allowUserInteraction) {
            sender.transform = .identity
        }
    }

    // MARK: - UI Updates

    private func updateStartButton() {
        let hasCats = !selectedCatIds.isEmpty
        contentView.startButton.isEnabled = hasCats
        UIView.animate(withDuration: 0.15) {
            self.contentView.startButton.alpha = hasCats ? 1.0 : 0.5
        }
    }

    private func updateToyUI() {
        contentView.toyChipButtons.enumerated().forEach { idx, btn in
            let isSelected = idx == selectedToyIndex
            let isMuted    = idx == contentView.toyChipButtons.count - 1
            let fgColor: UIColor = isSelected ? AppTheme.Color.textDark
                : (isMuted ? AppTheme.Color.textMuted : AppTheme.Color.primary)
            UIView.animate(withDuration: 0.15) {
                if isSelected {
                    btn.backgroundColor   = AppTheme.Color.primary
                    btn.layer.borderColor = AppTheme.Color.primary.cgColor
                } else if isMuted {
                    btn.backgroundColor   = UIColor(hex: "#F5F0EE")
                    btn.layer.borderColor = UIColor(hex: "#C4B5B5").cgColor
                } else {
                    btn.backgroundColor   = .white
                    btn.layer.borderColor = AppTheme.Color.yellowLight.cgColor
                }
                self.contentView.toyChipIconViews[idx].tintColor = fgColor
                self.contentView.toyChipLabels[idx].textColor    = fgColor
            }
        }
    }

    private func updatePresetButtons() {
        contentView.presetButtons.forEach { btn in
            let isSelected        = btn.tag * 60 == totalSeconds
            btn.backgroundColor   = isSelected ? AppTheme.Color.primary : .white
            btn.setTitleColor(isSelected ? .white : AppTheme.Color.primary, for: .normal)
            btn.layer.borderColor = isSelected
                ? AppTheme.Color.primary.cgColor
                : AppTheme.Color.yellowLight.cgColor
        }
    }

    private func updateTipLabel() {
        if let realm = try? Realm(), let cat = realm.objects(Cat.self).first {
            let name = cat.name.isEmpty ? "냥이" : cat.name
            contentView.tipLabel.text = "하루 30분 이상 놀아주면 \(name)의 스트레스가 줄어요!"
        } else {
            contentView.tipLabel.text = "하루 30분 이상 놀아주면 냥이의 스트레스가 줄어요!"
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

// MARK: - UICollectionViewDataSource

extension TimerViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        cats.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: CatSelectionCell.id, for: indexPath
        ) as! CatSelectionCell
        let cat = cats[indexPath.item]
        cell.configure(cat: cat)
        cell.setSelectedState(selectedCatIds.contains(cat.id))
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension TimerViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        let cat = cats[indexPath.item]
        if selectedCatIds.contains(cat.id) {
            selectedCatIds.remove(cat.id)
        } else {
            selectedCatIds.insert(cat.id)
        }
        if let cell = collectionView.cellForItem(at: indexPath) as? CatSelectionCell {
            cell.setSelectedState(selectedCatIds.contains(cat.id))
        }
        updateStartButton()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
