import Foundation
import RealmSwift

final class Cat: Object {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var name: String = ""
    @Persisted var birthday: Date = Date()
    @Persisted var gender: String = ""           // "male" | "female"
    @Persisted var weight: Double = 0.0          // kg
    @Persisted var targetTime: Int = 75          // 일일 목표 시간 (분), 기본값 75
    @Persisted var image: String?                // 로컬 파일 경로 또는 Asset 이름

    // PlaySession.cats의 역방향 참조
    @Persisted(originProperty: "cats") var sessions: LinkingObjects<PlaySession>
}
