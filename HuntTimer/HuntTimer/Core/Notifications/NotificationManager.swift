import Foundation
import UserNotifications
import RealmSwift

// MARK: - NotificationManager

final class NotificationManager: NSObject {

    static let shared = NotificationManager()
    private override init() { super.init() }

    private let center = UNUserNotificationCenter.current()

    private let dateFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd"
        return f
    }()
    private var dateKey: String { dateFmt.string(from: Date()) }

    // MARK: - Setup

    func configure() {
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error { print("[Notification] 권한 요청 오류:", error) }
            print("[Notification] 알림 권한 \(granted ? "허용" : "거부")")
        }
    }

    // MARK: - UserDefaults Settings

    var isAllEnabled: Bool {
        get {
            guard UserDefaults.standard.object(forKey: "nf_allEnabled") != nil else { return true }
            return UserDefaults.standard.bool(forKey: "nf_allEnabled")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "nf_allEnabled")
            if newValue {
                scheduleHuntReminder(hour: reminderHour, minute: reminderMinute)
            } else {
                center.removeAllPendingNotificationRequests()
            }
        }
    }

    var reminderHour: Int {
        get { UserDefaults.standard.object(forKey: "nf_reminderHour") as? Int ?? 19 }
        set { UserDefaults.standard.set(newValue, forKey: "nf_reminderHour") }
    }

    var reminderMinute: Int {
        get { UserDefaults.standard.object(forKey: "nf_reminderMinute") as? Int ?? 0 }
        set { UserDefaults.standard.set(newValue, forKey: "nf_reminderMinute") }
    }

    // MARK: - Scheduled Reminder (오후 7시 기본)

    func scheduleHuntReminder(hour: Int, minute: Int) {
        reminderHour   = hour
        reminderMinute = minute
        center.removePendingNotificationRequests(withIdentifiers: ["huntReminder"])
        guard isAllEnabled else { return }

        let content   = UNMutableNotificationContent()
        content.title = "사냥 시간이에요! 🐱"
        content.body  = "5분만 놀아줘도 좋아요! 시작이 중요해요 😺"
        content.sound = .default

        var dc = DateComponents()
        dc.hour   = hour
        dc.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
        let request = UNNotificationRequest(identifier: "huntReminder", content: content, trigger: trigger)
        center.add(request) { error in
            if let error { print("[Notification] 리마인더 등록 실패:", error) }
        }
    }

    // MARK: - Goal Progress Check (세션 저장 직후 호출)

    func checkGoalProgressAndNotify() {
        guard isAllEnabled else { return }
        guard let realm = try? Realm() else { return }

        let cat      = realm.objects(Cat.self).first
        let catName  = cat?.name.isEmpty == false ? cat!.name : "냥이"
        let goalSecs = (cat?.targetTime ?? 30) * 60

        let calendar  = Calendar.current
        let todaySecs = Array(realm.objects(PlaySession.self))
            .filter { calendar.isDateInToday($0.startTime) }
            .reduce(0) { $0 + $1.duration }

        let state = resolveState(todaySecs: todaySecs, goalSecs: goalSecs)
        fire(state: state, catName: catName, goalMinutes: goalSecs / 60)
    }

    // MARK: - State Resolution

    private enum GoalState {
        case noActivity, underHalf, nearGoal, goalReached, exceeded
    }

    private func resolveState(todaySecs: Int, goalSecs: Int) -> GoalState {
        guard todaySecs > 0 else { return .noActivity }
        if todaySecs > goalSecs  { return .exceeded }
        if todaySecs >= goalSecs { return .goalReached }
        let remaining = goalSecs - todaySecs
        if remaining <= 600      { return .nearGoal }
        return .underHalf
    }

    private func fire(state: GoalState, catName: String, goalMinutes: Int) {
        switch state {
        case .noActivity:
            break // 시간 기반 스케줄 알림으로 처리

        case .underHalf:
            guard !hasFlag("underHalf") else { return }
            setFlag("underHalf")
            let ga = gaPostposition(for: catName)
            send(id: "underHalf_\(dateKey)",
                 title: "아직 사냥이 부족해요 👀",
                 body:  "\(catName)\(ga) 아직 사냥을 더 원하고 있어요 👀 30분만 더 해볼까요?")

        case .nearGoal:
            guard !hasFlag("nearGoal") else { return }
            setFlag("nearGoal")
            send(id: "nearGoal_\(dateKey)",
                 title: "목표 달성이 코앞이에요! 👍",
                 body:  "거의 다 왔어요! 10분만 더 놀아주면 오늘 목표 완료! 👍")

        case .goalReached:
            guard !hasFlag("goalReached") else { return }
            setFlag("goalReached")
            send(id: "goalReached_\(dateKey)",
                 title: "오늘 목표 달성! 🎉",
                 body:  "오늘 목표 달성! 완벽한 집사네요 😻")

        case .exceeded:
            guard !hasFlag("exceeded") else { return }
            setFlag("exceeded")
            let ga = gaPostposition(for: catName)
            send(id: "exceeded_\(dateKey)",
                 title: "초과 달성! 😼🔥",
                 body:  "\(catName)\(ga) 아주 만족했어요! 오늘은 완전 사냥 마스터네요 😼🔥")
        }
    }

    // MARK: - Timer End Notification

    private let timerEndID = "timerEnd"

    /// 타이머 종료 시각에 맞춰 로컬 알림 예약
    func scheduleTimerEndNotification(remainingSeconds: TimeInterval) {
        guard isAllEnabled, remainingSeconds > 0 else { return }
        center.removePendingNotificationRequests(withIdentifiers: [timerEndID])

        let catName = fetchCatName()
        let content = UNMutableNotificationContent()
        content.title = "사냥 완료! 🎉"
        content.body  = "\(catName)와의 사냥 시간이 끝났어요! 기록을 저장해보세요 😺"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(remainingSeconds, 1), repeats: false)
        let request = UNNotificationRequest(identifier: timerEndID, content: content, trigger: trigger)
        center.add(request) { error in
            if let error { print("[Notification] 타이머 종료 알림 등록 실패:", error) }
        }
    }

    /// 타이머 종료 알림 취소 (일시정지·정지 시 호출)
    func cancelTimerEndNotification() {
        center.removePendingNotificationRequests(withIdentifiers: [timerEndID])
    }

    /// 포그라운드 복귀 시 모든 알림 제거 후 일일 리마인더 재예약
    func handleForegroundReturn() {
        center.removeAllPendingNotificationRequests()
        guard isAllEnabled else { return }
        scheduleHuntReminder(hour: reminderHour, minute: reminderMinute)
    }

    private func fetchCatName() -> String {
        guard let realm = try? Realm(),
              let cat   = realm.objects(Cat.self).first,
              !cat.name.isEmpty else { return "냥이" }
        return cat.name
    }

    // MARK: - Immediate Send

    private func send(id: String, title: String, body: String) {
        let content   = UNMutableNotificationContent()
        content.title = title
        content.body  = body
        content.sound = .default
        let request   = UNNotificationRequest(identifier: id, content: content, trigger: nil)
        center.add(request) { error in
            if let error { print("[Notification] 발송 실패 (\(id)):", error) }
        }
    }

    // MARK: - Daily Flags (날짜 포함 키 → 다음 날 자동 만료)

    private func hasFlag(_ key: String) -> Bool {
        UserDefaults.standard.bool(forKey: "nf_\(key)_\(dateKey)")
    }

    private func setFlag(_ key: String) {
        UserDefaults.standard.set(true, forKey: "nf_\(key)_\(dateKey)")
    }

    // MARK: - Korean Postposition "(이)가"
    // 받침 없음 → "가", 받침 있음 → "이가"

    private func gaPostposition(for name: String) -> String {
        guard let last   = name.last,
              let scalar = last.unicodeScalars.first else { return "이가" }
        let code = scalar.value
        guard code >= 0xAC00, code <= 0xD7A3 else { return "이가" }
        return (code - 0xAC00) % 28 == 0 ? "가" : "이가"
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {

    /// 앱이 포그라운드 상태일 때도 알림 배너 + 사운드 표시
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
