import Foundation
import RealmSwift

final class Cat: Object {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var name: String = ""
    @Persisted var birthday: Date?              // nil = 생일 모름 (unknownBirthdayToggle ON)
    @Persisted var isMale: Bool = false         // true = 남아, false = 여아
    @Persisted var breed: String = ""           // CatBreed.rawValue
    @Persisted var targetTime: Int = 30         // 일일 목표 시간 (분)
    @Persisted var profileImageData: Data?      // JPEG 압축 이미지 데이터
    @Persisted var createdAt: Date = Date()

    // PlaySession.cats의 역방향 참조
    @Persisted(originProperty: "cats") var sessions: LinkingObjects<PlaySession>
}
