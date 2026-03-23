import UIKit

/// 타이머 화면 ViewController — 타이머 상태 기계 및 target-action 바인딩 담당
final class TimerViewController: BaseViewController {

    // MARK: - View
    private let contentView = TimerView()

    // MARK: - State
    private var totalSeconds   = 15 * 60
    private var elapsedSeconds = 0
    private var isRunning      = false
    private var isPaused       = false
    private var timer: Timer?

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
        contentView.startButton.addTarget(self, action: #selector(startPauseTapped), for: .touchUpInside)
        contentView.stopButton.addTarget(self,  action: #selector(stopTapped),       for: .touchUpInside)
        contentView.moreButton.addTarget(self,  action: #selector(moreTapped),       for: .touchUpInside)
        contentView.presetButtons.forEach { btn in
            btn.addTarget(self, action: #selector(presetTapped(_:)), for: .touchUpInside)
        }
        updatePresetButtons()
    }

    // MARK: - Timer Actions
    @objc private func startPauseTapped() {
        isRunning ? pauseTimer() : startTimer()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    @objc private func stopTapped() {
        stopTimer()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    @objc private func moreTapped() {}

    @objc private func presetTapped(_ sender: UIButton) {
        guard !isRunning else { return }
        totalSeconds   = sender.tag * 60
        elapsedSeconds = 0
        updateDisplay()
        updatePresetButtons()
    }

    // MARK: - Timer Logic
    private func startTimer() {
        guard elapsedSeconds < totalSeconds else { return }
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
        updateStatusUI()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        showFinishedAlert()
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
                self.contentView.startButton.setTitle("⏸", for: .normal)
            } else if self.isPaused {
                self.contentView.statusDot.backgroundColor = AppTheme.Color.yellow
                self.contentView.statusLabel.text          = "⏸ 일시정지"
                self.contentView.startButton.setTitle("▶", for: .normal)
            } else {
                self.contentView.statusDot.backgroundColor = AppTheme.Color.textMuted
                self.contentView.statusLabel.text          = "사냥 준비"
                self.contentView.startButton.setTitle("▶", for: .normal)
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
