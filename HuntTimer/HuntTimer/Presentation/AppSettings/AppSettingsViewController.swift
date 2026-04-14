import UIKit

/// 앱 설정 화면 — 알림 권한 토글 + 리마인드 시간 설정
final class AppSettingsViewController: BaseViewController {

    // MARK: - View

    private let contentView = AppSettingsView()

    override func loadView() {
        view = contentView
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "앱 설정"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        navigationController?.interactivePopGestureRecognizer?.delegate  = self
        loadSettings()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }

    // MARK: - BaseViewController

    override func setupBind() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = AppTheme.Color.background
        appearance.shadowColor     = .clear
        appearance.titleTextAttributes = [
            .foregroundColor: AppTheme.Color.textDark,
            .font: UIFont.appFont(size: 17, weight: .bold)
        ]
        let buttonAppearance = UIBarButtonItemAppearance(style: .plain)
        buttonAppearance.normal.titleTextAttributes = [.foregroundColor: AppTheme.Color.textDark]
        appearance.buttonAppearance     = buttonAppearance
        appearance.backButtonAppearance = buttonAppearance
        navigationController?.navigationBar.standardAppearance   = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = AppTheme.Color.textDark

        let backBtn = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain, target: self, action: #selector(backTapped)
        )
        backBtn.tintColor = AppTheme.Color.textDark
        navigationItem.leftBarButtonItem = backBtn

        contentView.allNotifToggle.addTarget(self, action: #selector(allToggleChanged), for: .valueChanged)
        contentView.timePicker.addTarget(self, action: #selector(timePickerChanged), for: .valueChanged)
    }

    // MARK: - Load

    private func loadSettings() {
        let nm = NotificationManager.shared
        contentView.allNotifToggle.setOn(nm.isAllEnabled, animated: false)

        var dc = DateComponents()
        dc.hour   = nm.reminderHour
        dc.minute = nm.reminderMinute
        let date  = Calendar.current.date(from: dc) ?? Date()
        contentView.timePicker.setDate(date, animated: false)
        updateTimeBadge(date: date)
    }

    // MARK: - Actions

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func allToggleChanged() {
        NotificationManager.shared.isAllEnabled = contentView.allNotifToggle.isOn
    }

    @objc private func timePickerChanged() {
        let date     = contentView.timePicker.date
        let calendar = Calendar.current
        let hour     = calendar.component(.hour,   from: date)
        let minute   = calendar.component(.minute, from: date)
        NotificationManager.shared.scheduleHuntReminder(hour: hour, minute: minute)
        updateTimeBadge(date: date)
    }

    // MARK: - Helpers

    private func updateTimeBadge(date: Date) {
        let fmt        = DateFormatter()
        fmt.locale     = Locale(identifier: "ko_KR")
        fmt.dateFormat = "a h:mm"
        contentView.reminderTimeBadge.text = fmt.string(from: date)
    }
}

// MARK: - UIGestureRecognizerDelegate

extension AppSettingsViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        (navigationController?.viewControllers.count ?? 0) > 1
    }
}
