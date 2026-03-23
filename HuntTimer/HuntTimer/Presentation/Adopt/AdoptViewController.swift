import UIKit
import SnapKit

/// 입양 화면 ViewController — 필터 상태 관리 및 카드 목록 갱신 담당
final class AdoptViewController: BaseViewController {

    // MARK: - View
    private let contentView = AdoptView()

    // MARK: - State
    private var cats           = SampleData.adoptCats
    private var activeLocation = "전체"
    private var activeAge      = "전체"

    // MARK: - loadView
    override func loadView() {
        view = contentView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        refreshCatCards()
    }

    // MARK: - BaseViewController
    override func setupBind() {
        contentView.locationButtons.forEach { btn in
            btn.addTarget(self, action: #selector(locationFilterTapped(_:)), for: .touchUpInside)
        }
        contentView.ageButtons.forEach { btn in
            btn.addTarget(self, action: #selector(ageFilterTapped(_:)), for: .touchUpInside)
        }
    }

    // MARK: - Filter Actions
    @objc private func locationFilterTapped(_ sender: UIButton) {
        guard sender.tag < contentView.locationFilters.count else { return }
        activeLocation = contentView.locationFilters[sender.tag]
        contentView.locationButtons.enumerated().forEach {
            contentView.updateFilterBtn($0.element, isLocation: true, isSelected: $0.offset == sender.tag)
        }
    }

    @objc private func ageFilterTapped(_ sender: UIButton) {
        guard sender.tag < contentView.ageFilters.count else { return }
        activeAge = contentView.ageFilters[sender.tag]
        contentView.ageButtons.enumerated().forEach {
            contentView.updateFilterBtn($0.element, isLocation: false, isSelected: $0.offset == sender.tag)
        }
    }

    // MARK: - Cards Refresh
    private func refreshCatCards() {
        contentView.catCardsContainer.subviews.forEach { $0.removeFromSuperview() }

        let stack = UIStackView.make(axis: .vertical, spacing: 16)
        cats.forEach { cat in
            let card = AdoptCatCard(cat: cat)
            card.onLikeToggled = { [weak self] in self?.toggleLike(catId: cat.id) }
            card.onLearnMore   = { [weak self] in self?.showLearnMore(cat: cat) }
            stack.addArrangedSubview(card)
        }

        contentView.catCardsContainer.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }
    }

    private func toggleLike(catId: Int) {
        guard let idx = cats.firstIndex(where: { $0.id == catId }) else { return }
        cats[idx].isLiked.toggle()
        refreshCatCards()
    }

    private func showLearnMore(cat: AdoptCat) {
        let alert = UIAlertController(
            title: "\(cat.name)에 대해",
            message: cat.desc + "\n\n보호소: \(cat.shelter)",
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "입양 문의하기", style: .default))
        alert.addAction(UIAlertAction(title: "닫기", style: .cancel))
        present(alert, animated: true)
    }
}
