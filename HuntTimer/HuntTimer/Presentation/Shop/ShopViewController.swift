import UIKit
import SnapKit

/// 쇼핑 화면 ViewController — 필터 상태 관리 및 상품 그리드 갱신 담당
final class ShopViewController: BaseViewController {

    // MARK: - View
    private let contentView = ShopView()

    // MARK: - State
    private var products = SampleData.products
    private var activeFilter = "전체"
    private var filteredProducts: [ShopProduct] {
        activeFilter == "전체" ? products : products.filter { $0.category == activeFilter }
    }

    // MARK: - loadView
    override func loadView() {
        view = contentView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        refreshGrid()
    }

    // MARK: - BaseViewController
    override func setupBind() {
        contentView.filterButtons.enumerated().forEach { i, btn in
            btn.tag = i
            btn.addTarget(self, action: #selector(filterTapped(_:)), for: .touchUpInside)
        }
        updateAllFilterButtons()
    }

    // MARK: - Filter Actions
    @objc private func filterTapped(_ sender: UIButton) {
        guard sender.tag < contentView.filters.count else { return }
        activeFilter = contentView.filters[sender.tag]
        updateAllFilterButtons()
        refreshGrid()
    }

    private func updateAllFilterButtons() {
        contentView.filterButtons.enumerated().forEach { i, btn in
            contentView.updateFilterButtonStyle(btn, isSelected: contentView.filters[i] == activeFilter)
        }
    }

    // MARK: - Grid Refresh
    private func refreshGrid() {
        contentView.productGridContainer.subviews.forEach { $0.removeFromSuperview() }

        let itemWidth = (UIScreen.main.bounds.width - 40 - 12) / 2
        var rows: [[ShopProduct]] = []
        var temp: [ShopProduct]   = []
        filteredProducts.forEach { p in
            temp.append(p)
            if temp.count == 2 { rows.append(temp); temp = [] }
        }
        if !temp.isEmpty { rows.append(temp) }

        let gridStack = UIStackView.make(axis: .vertical, spacing: 12)
        rows.forEach { rowProducts in
            let rowStack = UIStackView.make(axis: .horizontal, spacing: 12, alignment: .top)
            rowProducts.forEach { product in
                let cell = ShopProductCard(product: product, width: itemWidth)
                cell.onLikeToggled = { [weak self] in self?.toggleLike(productId: product.id) }
                cell.snp.makeConstraints { $0.width.equalTo(itemWidth) }
                rowStack.addArrangedSubview(cell)
            }
            if rowProducts.count == 1 {
                let spacer = UIView()
                spacer.snp.makeConstraints { $0.width.equalTo(itemWidth) }
                rowStack.addArrangedSubview(spacer)
            }
            gridStack.addArrangedSubview(rowStack)
        }

        contentView.productGridContainer.addSubview(gridStack)
        gridStack.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }
    }

    private func toggleLike(productId: Int) {
        guard let idx = products.firstIndex(where: { $0.id == productId }) else { return }
        products[idx].isLiked.toggle()
        refreshGrid()
    }
}
