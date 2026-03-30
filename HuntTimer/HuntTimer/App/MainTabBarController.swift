import UIKit
import SnapKit

// MARK: - Notification

extension Notification.Name {
    /// 하위 ViewController → MainPageViewController 탭 전환 요청
    static let switchMainTab = Notification.Name("HuntTimer.switchMainTab")
}

// MARK: - MainPageViewController

final class MainPageViewController: UIViewController {

    // MARK: - Tab Model

    private struct TabItem {
        let vc:     UIViewController
        let symbol: String
        let title:  String
    }

    private let tabItems: [TabItem] = [
        TabItem(vc: HomeViewController(),  symbol: "house.fill",    title: "홈"),
        TabItem(vc: TimerViewController(), symbol: "pawprint.fill", title: "사냥"),
        TabItem(vc: LogViewController(),   symbol: "calendar",      title: "캘린더"),
    ]

    /// 각 탭의 NavigationController (한 번만 생성해 재사용)
    private lazy var pages: [UIViewController] = tabItems.map { item in
        let nav = UINavigationController(rootViewController: item.vc)
        nav.setNavigationBarHidden(true, animated: false)
        return nav
    }

    private var currentIndex = 0

    // MARK: - UI

    private let pageVC = UIPageViewController(
        transitionStyle:     .scroll,
        navigationOrientation: .horizontal,
        options: nil
    )

    private let customTabBar = UIView()
    private let tabSeparator = UIView()
    private var tabButtons: [UIButton] = []

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppTheme.Color.background
        setupPageViewController()
        setupTabBar()
        setupNotifications()
    }

    // MARK: - PageViewController Setup

    private func setupPageViewController() {
        addChild(pageVC)
        view.addSubview(pageVC.view)
        pageVC.didMove(toParent: self)
        pageVC.dataSource = self
        pageVC.delegate   = self
        pageVC.setViewControllers([pages[0]], direction: .forward, animated: false)
    }

    // MARK: - Constants

    private enum TabBarMetrics {
        static let height:        CGFloat = 56   // 기존 49 + 7pt
        static let hInset:        CGFloat = 20   // 좌우 여백 (플로팅 형태)
        static let bottomOffset:  CGFloat = 12   // safeArea 기준 하단 여백
        static let cornerRadius:  CGFloat = 22
    }

    // MARK: - Tab Bar Setup

    private func setupTabBar() {
        // 배경·모서리
        customTabBar.backgroundColor    = .white
        customTabBar.layer.cornerRadius = TabBarMetrics.cornerRadius
        customTabBar.clipsToBounds      = false

        // 사방 그림자 (플로팅 느낌)
        customTabBar.layer.shadowColor   = UIColor.black.cgColor
        customTabBar.layer.shadowOpacity = 0.12
        customTabBar.layer.shadowRadius  = 16
        customTabBar.layer.shadowOffset  = CGSize(width: 0, height: 4)

        view.addSubview(customTabBar)

        // 탭바: 좌우 inset + safeArea 기준 하단 여백으로 플로팅
        customTabBar.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(TabBarMetrics.hInset)
            make.trailing.equalToSuperview().offset(-TabBarMetrics.hInset)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-TabBarMetrics.bottomOffset)
            make.height.equalTo(TabBarMetrics.height)
        }

        // pageVC: 화면 상단 ~ 탭바 상단 (탭바만큼 내용 영역 확보)
        pageVC.view.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(customTabBar.snp.top)
        }

        // 탭 버튼 스택 — 상하 패딩 8pt로 아이콘/텍스트 여백 확보
        let stack = UIStackView.make(axis: .horizontal, distribution: .fillEqually)
        customTabBar.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.bottom.equalToSuperview().offset(-8)
            make.leading.trailing.equalToSuperview()
        }

        tabItems.enumerated().forEach { idx, item in
            let btn = makeTabButton(symbol: item.symbol, title: item.title, index: idx)
            tabButtons.append(btn)
            stack.addArrangedSubview(btn)
        }

        updateTabButtons(selectedIndex: 0)
    }

    private func makeTabButton(symbol: String, title: String, index: Int) -> UIButton {
        let btn = UIButton(type: .custom)
        btn.tag = index
        btn.addTarget(self, action: #selector(tabButtonTapped(_:)), for: .touchUpInside)

        var cfg = UIButton.Configuration.plain()
        let symCfg = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        cfg.image               = UIImage(systemName: symbol, withConfiguration: symCfg)
        cfg.title               = title
        cfg.imagePlacement      = .top
        cfg.imagePadding        = 4
        cfg.baseForegroundColor = AppTheme.Color.textMuted
        cfg.contentInsets       = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        cfg.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var attr = incoming
            attr.font = .systemFont(ofSize: 10, weight: .medium)
            return attr
        }
        btn.configuration = cfg
        return btn
    }

    private func updateTabButtons(selectedIndex: Int) {
        tabButtons.enumerated().forEach { idx, btn in
            let color = idx == selectedIndex ? AppTheme.Color.primary : AppTheme.Color.textMuted
            var cfg = btn.configuration
            cfg?.baseForegroundColor = color
            btn.configuration = cfg
        }
    }

    // MARK: - Actions

    @objc private func tabButtonTapped(_ sender: UIButton) {
        switchToPage(sender.tag, animated: false) // 탭 직접 탭 → 애니메이션 없이 즉시 전환
    }

    // MARK: - Page Switch

    func switchToPage(_ index: Int, animated: Bool) {
        guard index >= 0, index < pages.count, index != currentIndex else { return }
        let direction: UIPageViewController.NavigationDirection = index > currentIndex ? .forward : .reverse
        pageVC.setViewControllers([pages[index]], direction: direction, animated: animated)
        currentIndex = index
        updateTabButtons(selectedIndex: index)
    }

    // MARK: - Notifications

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSwitchTab(_:)),
            name: .switchMainTab,
            object: nil
        )
    }

    @objc private func handleSwitchTab(_ notification: Notification) {
        guard let index = notification.object as? Int else { return }
        switchToPage(index, animated: true)
    }
}

// MARK: - UIPageViewControllerDataSource

extension MainPageViewController: UIPageViewControllerDataSource {

    func pageViewController(_ pvc: UIPageViewController,
                             viewControllerBefore vc: UIViewController) -> UIViewController? {
        guard let idx = pages.firstIndex(of: vc), idx > 0 else { return nil }
        return pages[idx - 1]
    }

    func pageViewController(_ pvc: UIPageViewController,
                             viewControllerAfter vc: UIViewController) -> UIViewController? {
        guard let idx = pages.firstIndex(of: vc), idx < pages.count - 1 else { return nil }
        return pages[idx + 1]
    }
}

// MARK: - UIPageViewControllerDelegate

extension MainPageViewController: UIPageViewControllerDelegate {

    func pageViewController(_ pvc: UIPageViewController,
                             didFinishAnimating finished: Bool,
                             previousViewControllers: [UIViewController],
                             transitionCompleted completed: Bool) {
        guard completed,
              let current = pvc.viewControllers?.first,
              let idx     = pages.firstIndex(of: current) else { return }
        currentIndex = idx
        updateTabButtons(selectedIndex: idx)
    }
}
