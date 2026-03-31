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
    private var isMemorialMode    = false
    private var timer: Timer?
    private var sessionStartTime: Date?   // 타이머 최초 시작 시각 (일시정지 후 재개 시 유지)

    /// 타이머가 마지막으로 시작·재개된 시각 (백그라운드 시간차 계산 기준)
    private var timerResumedAt: Date?
    /// 마지막 일시정지 이전까지 누적된 경과 초
    private var elapsedBeforePause: Int = 0

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
        setupBackgroundHandlers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let name = fetchFirstCatName()
        contentView.tipLabel.text = "하루 30분 이상 놀아주면 \(name)의 스트레스가 줄어요!"
        isMemorialMode = UserDefaults.standard.bool(forKey: "isMemorialMode")
        applyMemorialMode()
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

    // MARK: - Memorial Mode
    private func applyMemorialMode() {
        if isMemorialMode {
            // 진행 중인 타이머가 있으면 정지
            if isRunning || isPaused { stopTimer() }

            UIView.animate(withDuration: 0.22) {
                self.contentView.statusDot.backgroundColor = AppTheme.Color.purple
                self.contentView.statusLabel.text          = "추모 모드"
                let disabledAlpha: CGFloat = 0.3
                self.contentView.startButton.isEnabled = false
                self.contentView.startButton.alpha     = disabledAlpha
                self.contentView.stopButton.isEnabled  = false
                self.contentView.stopButton.alpha      = disabledAlpha
                self.contentView.moreButton.isEnabled  = false
                self.contentView.moreButton.alpha      = disabledAlpha
                self.contentView.presetButtons.forEach { $0.isEnabled = false; $0.alpha = disabledAlpha }
                self.contentView.toyChipButtons.forEach { $0.isEnabled = false; $0.alpha = disabledAlpha }
            }
        } else {
            contentView.presetButtons.forEach { $0.isEnabled = true }
            contentView.toyChipButtons.forEach { $0.isEnabled = true }
            updateStatusUI()
            updatePresetButtons()
            updateToyUI()
        }
    }

    // MARK: - Timer Actions
    @objc private func startPauseTapped() {
        guard !isMemorialMode else { return }
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
        showSessionSaveModal()
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
        totalSeconds       = sender.tag * 60
        elapsedSeconds     = 0
        elapsedBeforePause = 0
        timerResumedAt     = nil
        sessionStartTime   = nil
        updateDisplay()
        updatePresetButtons()
    }

    // MARK: - Timer Logic
    private func startTimer() {
        guard elapsedSeconds < totalSeconds else { return }
        // 중복 타이머 방지
        timer?.invalidate()
        timer = nil
        if sessionStartTime == nil { sessionStartTime = Date() }  // 최초 시작 시각만 기록 (재개 시 유지)
        timerResumedAt = Date()   // 이번 재개 시각 기록 (백그라운드 시간차 계산 기준)
        isRunning = true
        isPaused  = false

        // 남은 시간에 맞춰 로컬 알림 예약 (백그라운드 중 타이머 종료 안내)
        let remaining = totalSeconds - elapsedSeconds
        NotificationManager.shared.scheduleTimerEndNotification(remainingSeconds: TimeInterval(remaining))

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self, let resumedAt = self.timerResumedAt else { return }
            // 시간차 계산: 재개 시각 기준으로 경과 초를 계산 (화면 꺼짐·백그라운드에 강건)
            self.elapsedSeconds = self.elapsedBeforePause + Int(Date().timeIntervalSince(resumedAt))
            if self.elapsedSeconds >= self.totalSeconds {
                self.elapsedSeconds    = self.totalSeconds
                self.timer?.invalidate()
                self.timer             = nil
                self.isRunning         = false
                self.timerResumedAt    = nil
                self.elapsedBeforePause = 0
                self.huntFinished()
            }
            self.updateDisplay()
        }
        updateStatusUI()
    }

    private func pauseTimer() {
        // 일시정지 시점까지의 경과 초 누적
        if let resumedAt = timerResumedAt {
            elapsedBeforePause += Int(Date().timeIntervalSince(resumedAt))
            elapsedSeconds = elapsedBeforePause
        }
        timerResumedAt = nil
        timer?.invalidate()
        timer    = nil
        isRunning = false
        isPaused  = true
        NotificationManager.shared.cancelTimerEndNotification()
        updateStatusUI()
    }

    /// 기록 삭제 — 세션 데이터와 타이머 상태를 모두 초기 상태로 되돌림
    private func resetSession() {
        sessionStartTime = nil
        selectedToy      = nil
        selectedToyIndex = -1
        stopTimer()
        updateToyUI()
    }

    private func stopTimer() {
        timer?.invalidate()
        timer              = nil
        isRunning          = false
        isPaused           = false
        elapsedSeconds     = 0
        elapsedBeforePause = 0
        timerResumedAt     = nil
        NotificationManager.shared.cancelTimerEndNotification()
        updateDisplay()
        updateStatusUI()
    }

    // MARK: - Background / Foreground Handling

    private func setupBackgroundHandlers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    /// 포그라운드 복귀 시: 중복 알림 제거 → 경과 시간 재계산 → UI 즉시 동기화
    @objc private func handleForeground() {
        // 예약된 알림 전체 제거 후 일일 리마인더 재등록
        NotificationManager.shared.handleForegroundReturn()

        guard isRunning, let resumedAt = timerResumedAt else { return }

        // 백그라운드 체류 시간 포함한 정확한 경과 초 계산
        elapsedSeconds = elapsedBeforePause + Int(Date().timeIntervalSince(resumedAt))

        if elapsedSeconds >= totalSeconds {
            // 백그라운드 중 타이머가 이미 종료된 경우
            elapsedSeconds     = totalSeconds
            timer?.invalidate()
            timer              = nil
            isRunning          = false
            timerResumedAt     = nil
            elapsedBeforePause = 0
            updateDisplay()
            huntFinished()
        } else {
            // UI를 정확한 시점으로 즉시 갱신 (점프)
            updateDisplay()
            // 남은 시간으로 알림 재예약
            let remaining = totalSeconds - elapsedSeconds
            NotificationManager.shared.scheduleTimerEndNotification(remainingSeconds: TimeInterval(remaining))
        }
    }

    private func huntFinished() {
        updateStatusUI()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        showSessionSaveModal()
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

    private func showSessionSaveModal() {
        let modal = SessionSaveModalViewController()
        modal.duration  = elapsedSeconds
        modal.onSave    = { [weak self] memo, photo in
            guard let self else { return }
            self.endAndSaveSession(memo: memo, photo: photo)
            self.stopTimer()
            self.tabBarController?.selectedIndex = 2
        }
        modal.onCancel = { [weak self] in
            self?.resetSession()
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
