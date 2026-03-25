import UIKit

/// 타이머 화면 ViewController — 타이머 상태 기계 및 target-action 바인딩 담당
final class TimerViewController: BaseViewController {

    // MARK: - View
    private let contentView = TimerView()

    // MARK: - ViewModel
    private let viewModel = TimerViewModel()

    // MARK: - State
    private var totalSeconds      = 15 * 60
    private var elapsedSeconds    = 0
    private var isRunning         = false
    private var isPaused          = false
    private var timer: Timer?
    private var sessionStartTime: Date?   // 타이머 최초 시작 시각 (일시정지 후 재개 시 유지)

    // MARK: - loadView
    override func loadView() {
        view = contentView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        updateDisplay()
    }

    // MARK: - BaseViewController
    override func setupBind() {
        // 타이머 액션
        contentView.startButton.addTarget(self, action: #selector(startPauseTapped), for: .touchUpInside)
        contentView.stopButton.addTarget(self,  action: #selector(stopTapped),       for: .touchUpInside)
        contentView.moreButton.addTarget(self,  action: #selector(moreTapped),       for: .touchUpInside)
        contentView.presetButtons.forEach { btn in
            btn.addTarget(self, action: #selector(presetTapped(_:)), for: .touchUpInside)
        }

        // 스프링 스케일 애니메이션
        [contentView.startButton, contentView.stopButton, contentView.moreButton].forEach { btn in
            btn.addTarget(self, action: #selector(controlButtonPressed(_:)), for: .touchDown)
            btn.addTarget(self, action: #selector(controlButtonReleased(_:)),
                          for: [.touchUpInside, .touchUpOutside, .touchCancel])
        }

        updatePresetButtons()
    }

    // MARK: - Button Spring Animation
    @objc private func controlButtonPressed(_ sender: UIButton) {
        UIView.animate(withDuration: 0.12, delay: 0,
                       options: [.curveEaseOut, .allowUserInteraction]) {
            sender.transform = CGAffineTransform(scaleX: 0.88, y: 0.88)
        }
    }

    @objc private func controlButtonReleased(_ sender: UIButton) {
        UIView.animate(withDuration: 0.45, delay: 0,
                       usingSpringWithDamping: 0.45, initialSpringVelocity: 0.8,
                       options: .allowUserInteraction) {
            sender.transform = .identity
        }
    }

    // MARK: - Timer Actions
    @objc private func startPauseTapped() {
        guard !isRunning else { return }   // 재생 전용 — 정지는 moreButton이 담당
        startTimer()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    @objc private func stopTapped() {
        guard sessionStartTime != nil, elapsedSeconds > 0 else {
            stopTimer()
            return
        }
        endAndSaveSession()
        stopTimer()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    @objc private func moreTapped() {
        guard isRunning else { return }
        pauseTimer()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    @objc private func presetTapped(_ sender: UIButton) {
        guard !isRunning else { return }
        totalSeconds      = sender.tag * 60
        elapsedSeconds    = 0
        sessionStartTime  = nil
        updateDisplay()
        updatePresetButtons()
    }

    // MARK: - Timer Logic
    private func startTimer() {
        guard elapsedSeconds < totalSeconds else { return }
        if sessionStartTime == nil { sessionStartTime = Date() }  // 최초 시작 시각만 기록 (재개 시 유지)
        isRunning = true
        isPaused  = false
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.elapsedSeconds += 1
            if self.elapsedSeconds >= self.totalSeconds {
                self.elapsedSeconds = self.totalSeconds
                self.timer?.invalidate()
                self.timer = nil
                self.isRunning = false
                self.huntFinished()
            }
            self.updateDisplay()
        }
        updateStatusUI()
    }

    private func pauseTimer() {
        timer?.invalidate()
        timer    = nil
        isRunning = false
        isPaused  = true
        updateStatusUI()
    }

    private func stopTimer() {
        timer?.invalidate()
        timer          = nil
        isRunning      = false
        isPaused       = false
        elapsedSeconds = 0
        updateDisplay()
        updateStatusUI()
    }

    private func huntFinished() {
        endAndSaveSession()
        updateStatusUI()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        showFinishedAlert()
    }

    private func endAndSaveSession() {
        guard let startTime = sessionStartTime else { return }
        viewModel.saveSession(
            startTime: startTime,
            endTime: Date(),
            duration: elapsedSeconds,
            targetDuration: totalSeconds
        )
        sessionStartTime = nil
    }

    private func showFinishedAlert() {
        let alert = UIAlertController(title: "🎉 사냥 완료!", message: "뮤기가 기뻐해요!\n오늘도 수고하셨어요 🐾",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default) { [weak self] _ in
            self?.stopTimer()
        })
        present(alert, animated: true)
    }

    // MARK: - Display Updates
    private func updateDisplay() {
        let elapsed   = elapsedSeconds
        let remaining = max(totalSeconds - elapsedSeconds, 0)
        contentView.elapsedLabel.text   = formatTime(elapsed)
        contentView.remainingLabel.text = formatTime(remaining)

        let progress = totalSeconds > 0 ? Float(elapsedSeconds) / Float(totalSeconds) : 0
        contentView.gaugeView.setProgress(progress, animated: false)
        contentView.gaugeView.setSecondHand(elapsedSeconds)
    }

    private func updateStatusUI() {
        UIView.animate(withDuration: 0.22) {
            if self.isRunning {
                self.contentView.statusDot.backgroundColor = AppTheme.Color.primary
                self.contentView.statusLabel.text          = "🐾 사냥 중!"
            } else if self.isPaused {
                self.contentView.statusDot.backgroundColor = AppTheme.Color.yellow
                self.contentView.statusLabel.text          = "⏸ 일시정지"
            } else {
                self.contentView.statusDot.backgroundColor = AppTheme.Color.textMuted
                self.contentView.statusLabel.text          = "사냥 준비"
            }
        }
    }

    private func updatePresetButtons() {
        contentView.presetButtons.forEach { btn in
            let isSelected = btn.tag * 60 == totalSeconds
            btn.backgroundColor = isSelected ? AppTheme.Color.primary : AppTheme.Color.primaryLight
            btn.setTitleColor(isSelected ? .white : AppTheme.Color.textMedium, for: .normal)
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
