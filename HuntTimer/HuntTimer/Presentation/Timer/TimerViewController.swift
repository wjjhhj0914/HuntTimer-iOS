import UIKit
import RealmSwift

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

    // MARK: - Toy Selection
    /// 선택된 장난감 이름 (nil = 선택 안 함 or 미선택)
    private(set) var selectedToy: String? = nil
    /// 선택된 칩 인덱스 (-1 = 아무것도 선택 안 됨)
    private var selectedToyIndex: Int = -1
    private let toyNames: [String?] = ["깃털", "벌레", "레이저", "카샤카샤", "오뎅꼬치", nil]

    // MARK: - loadView
    override func loadView() {
        view = contentView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        updateDisplay()
        updateStatusUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let name = fetchFirstCatName()
        contentView.tipLabel.text = "하루 30분 이상 놀아주면 \(name)의 스트레스가 줄어요!"
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

        // 장난감 칩 탭
        contentView.toyChipButtons.forEach { btn in
            btn.addTarget(self, action: #selector(toyChipTapped(_:)), for: .touchUpInside)
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
        pauseTimer()
        showSessionSaveModal(resumeOnCancel: true)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    @objc private func moreTapped() {
        guard isRunning else { return }
        pauseTimer()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    @objc private func toyChipTapped(_ sender: UIButton) {
        selectedToyIndex = sender.tag
        selectedToy      = toyNames[sender.tag]
        updateToyUI()
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
        // 중복 타이머 방지: 혹시 살아있는 타이머가 있으면 먼저 정리
        timer?.invalidate()
        timer = nil
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
        updateStatusUI()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        showSessionSaveModal(resumeOnCancel: false)
    }

    private func endAndSaveSession(memo: String? = nil, photo: UIImage? = nil) {
        guard let startTime = sessionStartTime else { return }
        viewModel.saveSession(
            startTime:      startTime,
            endTime:        Date(),
            duration:       elapsedSeconds,
            targetDuration: totalSeconds,
            toyName:        selectedToy,
            memo:           memo,
            photo:          photo
        )
        sessionStartTime = nil
    }

    // MARK: - Custom Modal

    private func showSessionSaveModal(resumeOnCancel: Bool) {
        let modal = SessionSaveModalViewController()
        modal.duration  = elapsedSeconds
        modal.onSave    = { [weak self] memo, photo in
            guard let self else { return }
            self.endAndSaveSession(memo: memo, photo: photo)
            self.stopTimer()
            self.tabBarController?.selectedIndex = 0
        }
        modal.onCancel = { [weak self] in
            if resumeOnCancel { self?.startTimer() }
            else              { self?.stopTimer()  }
        }
        modal.modalPresentationStyle = .overFullScreen
        modal.modalTransitionStyle   = .crossDissolve
        present(modal, animated: true)
    }

    private func fetchFirstCatName() -> String {
        if let realm = try? Realm(),
           let cat = realm.objects(Cat.self).first {
            return cat.name.isEmpty ? "냥이" : cat.name
        }
        return "냥이"
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
                self.contentView.statusLabel.text          = "사냥 중!"
                // 사냥 중: 재생 비활성화 / 일시정지·정지 활성화
                self.contentView.startButton.isEnabled = false
                self.contentView.startButton.alpha     = 0.45
                self.contentView.moreButton.isEnabled  = true
                self.contentView.moreButton.alpha      = 1.0
                self.contentView.stopButton.isEnabled  = true
                self.contentView.stopButton.alpha      = 1.0
            } else if self.isPaused {
                self.contentView.statusDot.backgroundColor = AppTheme.Color.yellow
                self.contentView.statusLabel.text          = "일시정지"
                // 일시정지: 재생·정지 활성화 / 일시정지 비활성화
                self.contentView.startButton.isEnabled = true
                self.contentView.startButton.alpha     = 1.0
                self.contentView.moreButton.isEnabled  = false
                self.contentView.moreButton.alpha      = 0.45
                self.contentView.stopButton.isEnabled  = true
                self.contentView.stopButton.alpha      = 1.0
            } else {
                self.contentView.statusDot.backgroundColor = AppTheme.Color.textMuted
                self.contentView.statusLabel.text          = "사냥 준비"
                // 준비: 재생만 활성화 / 일시정지·정지 비활성화
                self.contentView.startButton.isEnabled = true
                self.contentView.startButton.alpha     = 1.0
                self.contentView.moreButton.isEnabled  = false
                self.contentView.moreButton.alpha      = 0.45
                self.contentView.stopButton.isEnabled  = false
                self.contentView.stopButton.alpha      = 0.45
            }
        }
    }

    private func updateToyUI() {
        contentView.toyChipButtons.enumerated().forEach { idx, btn in
            let isSelected = idx == selectedToyIndex
            let isMuted    = idx == contentView.toyChipButtons.count - 1   // "선택 안 함"
            let fgColor: UIColor = isSelected ? .white
                                              : (isMuted ? AppTheme.Color.textMuted : AppTheme.Color.primary)
            UIView.animate(withDuration: 0.15) {
                btn.backgroundColor = isSelected ? AppTheme.Color.primary : AppTheme.Color.primaryLight
                btn.alpha           = isSelected ? 1.0 : 0.6
                self.contentView.toyChipIconViews[idx].tintColor = fgColor
                self.contentView.toyChipLabels[idx].textColor    = fgColor
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
