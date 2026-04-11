import UIKit
import SnapKit
import RealmSwift

/// 사냥 진행 중 ViewController
final class HuntInProgressViewController: BaseViewController {

    // MARK: - Configuration (push 전 설정)
    var totalSeconds: Int  = 15 * 60
    var toyName: String?   = nil
    var selectedCats: [Cat] = []

    // MARK: - View / ViewModel
    private let contentView = HuntInProgressView()
    private let viewModel   = TimerViewModel()

    // MARK: - Timer State
    private var elapsedSeconds:     Int    = 0
    private var isRunning:          Bool   = false
    private var isPaused:           Bool   = false
    private var timer:              Timer? = nil
    private var sessionStartTime:   Date?  = nil
    private var timerResumedAt:     Date?  = nil
    private var elapsedBeforePause: Int    = 0

    // MARK: - loadView
    override func loadView() { view = contentView }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureInitialState()
        setupBackgroundHandlers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !isRunning && !isPaused {
            startTimer()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    @MainActor
    deinit {
        timer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - BaseViewController

    override func setupBind() {
        contentView.stopButton.addTarget(self,        action: #selector(stopTapped),        for: .touchUpInside)
        contentView.pauseResumeButton.addTarget(self, action: #selector(pauseResumeTapped), for: .touchUpInside)
    }

    // MARK: - Navigation Bar

    private func configureNavBar() {
        title = "사냥 진행 중"

        let backImg  = UIImage(systemName: "chevron.left")
        let backItem = UIBarButtonItem(image: backImg, style: .plain,
                                       target: self, action: #selector(backTapped))
        backItem.tintColor = UIColor(hex: "#785b35")
        navigationItem.leftBarButtonItem = backItem
    }

    // MARK: - Initial State

    private func configureInitialState() {
        configureNavBar()
        contentView.timerLabel.text       = formatTime(totalSeconds)
        contentView.toyChipLabel.text     = toyName ?? "선택 안 함"
        contentView.catCountBadgeLabel.text = "\(selectedCats.count)마리"
        buildCatAvatars()
    }

    private func buildCatAvatars() {
        contentView.catAvatarsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        selectedCats.forEach { cat in
            contentView.catAvatarsStack.addArrangedSubview(makeCatAvatarView(cat: cat))
        }
    }

    private func makeCatAvatarView(cat: Cat) -> UIView {
        let circle = UIView()
        circle.backgroundColor    = UIColor(hex: "#fff9f0")
        circle.layer.cornerRadius = 40
        circle.layer.borderWidth  = 2
        circle.layer.borderColor  = AppTheme.Color.primary.cgColor
        circle.clipsToBounds      = true
        circle.snp.makeConstraints { $0.width.height.equalTo(80) }

        if let data = cat.profileImageData, let image = UIImage(data: data) {
            let iv = UIImageView(image: image)
            iv.contentMode   = .scaleAspectFill
            iv.clipsToBounds = true
            circle.addSubview(iv)
            iv.snp.makeConstraints { $0.edges.equalToSuperview() }
        } else {
            let iv = UIImageView(image: UIImage(named: "RegisterProfile_Cat"))
            iv.contentMode = .scaleAspectFit
            circle.addSubview(iv)
            iv.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.width.height.equalTo(36)
            }
        }

        let nameLabel = UILabel.make(text: cat.name, size: 12, weight: .semibold,
                                     color: AppTheme.Color.textDark)
        nameLabel.textAlignment = .center

        let stack = UIStackView.make(axis: .vertical, spacing: 8, alignment: .center)
        stack.addArrangedSubview(circle)
        stack.addArrangedSubview(nameLabel)
        return stack
    }

    // MARK: - Button Actions

    @objc private func backTapped() {
        if isRunning || isPaused {
            showExitConfirmation()
        } else {
            navigationController?.popViewController(animated: true)
        }
    }

    @objc private func pauseResumeTapped() {
        if isRunning {
            pauseTimer()
        } else if isPaused {
            resumeTimer()
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    @objc private func stopTapped() {
        guard sessionStartTime != nil, elapsedSeconds > 0 else { return }
        pauseTimer()
        showSessionSaveModal()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    // MARK: - Timer Logic

    private func startTimer() {
        guard elapsedSeconds < totalSeconds else { return }
        timer?.invalidate()
        timer = nil
        if sessionStartTime == nil { sessionStartTime = Date() }
        timerResumedAt = Date()
        isRunning = true
        isPaused  = false

        let remaining = totalSeconds - elapsedSeconds
        NotificationManager.shared.scheduleTimerEndNotification(remainingSeconds: TimeInterval(remaining))

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self, let resumedAt = self.timerResumedAt else { return }
            self.elapsedSeconds = self.elapsedBeforePause + Int(Date().timeIntervalSince(resumedAt))
            if self.elapsedSeconds >= self.totalSeconds {
                self.elapsedSeconds      = self.totalSeconds
                self.timer?.invalidate()
                self.timer               = nil
                self.isRunning           = false
                self.timerResumedAt      = nil
                self.elapsedBeforePause  = 0
                self.huntFinished()
            }
            self.updateDisplay()
        }
        contentView.updatePauseResumeState(isPaused: false)
        updateDisplay()
    }

    private func pauseTimer() {
        if let resumedAt = timerResumedAt {
            elapsedBeforePause += Int(Date().timeIntervalSince(resumedAt))
            elapsedSeconds = elapsedBeforePause
        }
        timerResumedAt = nil
        timer?.invalidate()
        timer     = nil
        isRunning = false
        isPaused  = true
        NotificationManager.shared.cancelTimerEndNotification()
        contentView.updatePauseResumeState(isPaused: true)
    }

    private func resumeTimer() {
        guard isPaused else { return }
        isPaused = false
        startTimer()
    }

    private func stopTimer() {
        timer?.invalidate()
        timer              = nil
        isRunning          = false
        isPaused           = false
        elapsedSeconds     = 0
        elapsedBeforePause = 0
        timerResumedAt     = nil
        sessionStartTime   = nil
        NotificationManager.shared.cancelTimerEndNotification()
    }

    private func huntFinished() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        contentView.updatePauseResumeState(isPaused: true)
        showSessionSaveModal()
    }

    // MARK: - Background Handling

    private func setupBackgroundHandlers() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(handleForeground),
            name: UIApplication.willEnterForegroundNotification, object: nil
        )
    }

    @objc private func handleForeground() {
        NotificationManager.shared.handleForegroundReturn()
        guard isRunning, let resumedAt = timerResumedAt else { return }
        elapsedSeconds = elapsedBeforePause + Int(Date().timeIntervalSince(resumedAt))
        if elapsedSeconds >= totalSeconds {
            elapsedSeconds      = totalSeconds
            timer?.invalidate()
            timer               = nil
            isRunning           = false
            timerResumedAt      = nil
            elapsedBeforePause  = 0
            updateDisplay()
            huntFinished()
        } else {
            updateDisplay()
            let remaining = totalSeconds - elapsedSeconds
            NotificationManager.shared.scheduleTimerEndNotification(remainingSeconds: TimeInterval(remaining))
        }
    }

    // MARK: - Session Save

    private func endAndSaveSession(memo: String? = nil, photo: UIImage? = nil) {
        guard let startTime = sessionStartTime else { return }
        viewModel.saveSession(
            startTime:      startTime,
            endTime:        Date(),
            duration:       elapsedSeconds,
            targetDuration: totalSeconds,
            cats:           selectedCats,
            toyName:        toyName,
            memo:           memo,
            photo:          photo
        )
        sessionStartTime = nil
    }

    private func showSessionSaveModal() {
        let modal      = SessionSaveModalViewController()
        modal.duration = elapsedSeconds
        modal.onSave   = { [weak self] memo, photo in
            guard let self else { return }
            self.endAndSaveSession(memo: memo, photo: photo)
            self.stopTimer()
            let tabBar = self.tabBarController          // pop 전에 캡처 — pop 후엔 parent가 nil이 됨
            self.navigationController?.popViewController(animated: false)
            tabBar?.selectedIndex = 2
        }
        modal.onCancel = { [weak self] in
            guard let self else { return }
            self.stopTimer()
            self.navigationController?.popViewController(animated: true)
        }
        modal.modalPresentationStyle = .overFullScreen
        modal.modalTransitionStyle   = .crossDissolve
        present(modal, animated: true)
    }

    // MARK: - Exit Confirmation

    private func showExitConfirmation() {
        let alert = UIAlertController(
            title: "사냥을 중단하시겠어요?",
            message: "나가면 현재 진행 중인 기록이 저장되지 않아요.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "계속 사냥", style: .cancel))
        alert.addAction(UIAlertAction(title: "나가기", style: .destructive) { [weak self] _ in
            guard let self else { return }
            self.stopTimer()
            self.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }

    // MARK: - UI Updates

    private func updateDisplay() {
        let remaining = max(totalSeconds - elapsedSeconds, 0)
        contentView.timerLabel.text = formatTime(remaining)
    }

    private func formatTime(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
