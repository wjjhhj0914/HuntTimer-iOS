import Foundation
import RealmSwift

final class PhotoLog: Object {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var session: PlaySession?         // ObjectId 대신 링크로 타입 안전성 확보
    @Persisted var imagePath: String = ""        // 로컬 파일 경로 (Documents/...)
    @Persisted var createdAt: Date = Date()
}
