import Foundation
import RealmSwift

final class PlaySession: Object {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var cats: List<Cat>               // N:M — 한 세션에 여러 고양이
    @Persisted var toys: List<Toy>               // 해당 세션에서 사용한 장난감 목록
    @Persisted var startTime: Date = Date()      // 타이머가 실제로 시작된 시각
    @Persisted var endTime: Date?                // 타이머가 종료된 시각
    @Persisted var duration: Int = 0             // 실제 놀아준 시간 (초)
    @Persisted var targetDuration: Int = 0       // 처음에 설정한 목표 시간 (초)
    @Persisted var memo: String?

    // PhotoLog.session의 역방향 참조
    @Persisted(originProperty: "session") var photos: LinkingObjects<PhotoLog>
}
