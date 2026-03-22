import Foundation
import RealmSwift

final class PlaySession: Object {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var cats: List<Cat>               // N:M — 한 세션에 여러 고양이
    @Persisted var toys: List<Toy>               // 해당 세션에서 사용한 장난감 목록
    @Persisted var duration: Int = 0             // 놀이 시간 (초)
    @Persisted var date: Date = Date()           // 세션 시작 시각
    @Persisted var intensity: Int = 3            // 놀이 강도 1(약)~5(강)
    @Persisted var memo: String?

    // PhotoLog.session의 역방향 참조
    @Persisted(originProperty: "session") var photos: LinkingObjects<PhotoLog>
}
