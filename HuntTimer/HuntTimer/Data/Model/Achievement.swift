import Foundation
import RealmSwift

final class Achievement: Object {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var title: String = ""            // "초보 낚시꾼", "전설의 사냥꾼" 등
    @Persisted var unlockedAt: Date = Date()
    @Persisted var condition: String = ""        // 달성 조건 설명 (예: "누적 30시간 달성")
}
