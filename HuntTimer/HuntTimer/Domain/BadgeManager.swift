import Foundation
import RealmSwift

/// 사냥 기록(PlaySession) 기반으로 배지 달성 여부를 평가하는 매니저
enum BadgeManager {

    // MARK: - Public Interface

    /// 현재 Realm 데이터를 기반으로 모든 배지의 달성 여부를 계산하여 반환
    static func evaluateBadges() -> [Badge] {
        guard let realm = try? Realm() else { return locked() }
        let sessions = Array(realm.objects(PlaySession.self))

        let huntingMaster = evaluateHuntingMaster(sessions)
        let featherFan    = evaluateFeatherFan(sessions)
        let sevenDays     = evaluateSevenDays(sessions)
        let lightningCat  = evaluateLightningCat(sessions)
        let nightOwl      = evaluateNightOwl(sessions)
        let perfect       = evaluatePerfect(sessions)
        let diamond       = evaluateDiamond(sessions)
        let superstar     = huntingMaster && featherFan && sevenDays &&
                            lightningCat  && nightOwl   && perfect   && diamond

        return [
            Badge(emoji: "🏆", label: "사냥 마스터", desc: "100회 달성",    unlocked: huntingMaster),
            Badge(emoji: "🪶", label: "깃털 광팬",   desc: "깃털 30회",     unlocked: featherFan),
            Badge(emoji: "🔥", label: "연속 7일",    desc: "7일 연속",      unlocked: sevenDays),
            Badge(emoji: "⚡", label: "번개 냥이",   desc: "5분 이내 10회", unlocked: lightningCat),
            Badge(emoji: "🌙", label: "야행성",      desc: "밤 사냥 20회",  unlocked: nightOwl),
            Badge(emoji: "🎯", label: "퍼펙트",      desc: "목표 30일",     unlocked: perfect),
            Badge(emoji: "💎", label: "다이아",      desc: "총 50시간",     unlocked: diamond),
            Badge(emoji: "🌟", label: "슈퍼스타",    desc: "모든 배지",     unlocked: superstar),
        ]
    }

    // MARK: - Conditions

    /// 총 사냥 횟수 >= 100회
    private static func evaluateHuntingMaster(_ sessions: [PlaySession]) -> Bool {
        sessions.count >= 100
    }

    /// 이름에 "깃털"이 포함된 장난감을 사용한 세션 >= 30회
    private static func evaluateFeatherFan(_ sessions: [PlaySession]) -> Bool {
        sessions.filter { $0.toys.contains { $0.name.contains("깃털") } }.count >= 30
    }

    /// 끊김 없이 7일 연속으로 사냥 기록이 존재하는지
    private static func evaluateSevenDays(_ sessions: [PlaySession]) -> Bool {
        let cal = Calendar.current
        let uniqueDays = Set(sessions.map { cal.startOfDay(for: $0.startTime) })
            .sorted()

        guard uniqueDays.count >= 7 else { return false }

        var streak = 1
        for i in 1..<uniqueDays.count {
            let gap = cal.dateComponents([.day],
                                         from: uniqueDays[i - 1],
                                         to:   uniqueDays[i]).day ?? 0
            if gap == 1 {
                streak += 1
                if streak >= 7 { return true }
            } else {
                streak = 1
            }
        }
        return false
    }

    /// 5분(300초) 이내의 유효한 사냥 기록 >= 10회
    private static func evaluateLightningCat(_ sessions: [PlaySession]) -> Bool {
        sessions.filter { $0.duration > 0 && $0.duration <= 300 }.count >= 10
    }

    /// 밤(22:00 ~ 06:00) 시작 사냥 기록 >= 20회
    private static func evaluateNightOwl(_ sessions: [PlaySession]) -> Bool {
        let cal = Calendar.current
        let count = sessions.filter {
            let h = cal.component(.hour, from: $0.startTime)
            return h >= 22 || h < 6
        }.count
        return count >= 20
    }

    /// 목표 시간 달성(duration >= targetDuration) 고유 날짜 수 >= 30일
    private static func evaluatePerfect(_ sessions: [PlaySession]) -> Bool {
        let cal = Calendar.current
        let achievedDays = Set(
            sessions
                .filter { $0.targetDuration > 0 && $0.duration >= $0.targetDuration }
                .map    { cal.startOfDay(for: $0.startTime) }
        )
        return achievedDays.count >= 30
    }

    /// 총 누적 사냥 시간 >= 180,000초 (50시간)
    private static func evaluateDiamond(_ sessions: [PlaySession]) -> Bool {
        sessions.reduce(0) { $0 + $1.duration } >= 180_000
    }

    // MARK: - Fallback

    private static func locked() -> [Badge] {
        [
            Badge(emoji: "🏆", label: "사냥 마스터", desc: "100회 달성",    unlocked: false),
            Badge(emoji: "🪶", label: "깃털 광팬",   desc: "깃털 30회",     unlocked: false),
            Badge(emoji: "🔥", label: "연속 7일",    desc: "7일 연속",      unlocked: false),
            Badge(emoji: "⚡", label: "번개 냥이",   desc: "5분 이내 10회", unlocked: false),
            Badge(emoji: "🌙", label: "야행성",      desc: "밤 사냥 20회",  unlocked: false),
            Badge(emoji: "🎯", label: "퍼펙트",      desc: "목표 30일",     unlocked: false),
            Badge(emoji: "💎", label: "다이아",      desc: "총 50시간",     unlocked: false),
            Badge(emoji: "🌟", label: "슈퍼스타",    desc: "모든 배지",     unlocked: false),
        ]
    }
}
