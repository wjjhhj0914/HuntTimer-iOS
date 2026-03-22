import Foundation
import RealmSwift

final class Toy: Object {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var name: String = ""
    @Persisted var category: String = ""         // "낚싯대" | "터널" | "레이저" 등
    @Persisted var colour: Int = 0               // ToyColour.rawValue

    var toyColour: ToyColour {
        ToyColour(rawValue: colour) ?? .unknown
    }
}

enum ToyColour: Int {
    case unknown = 0
    case red     = 1
    case orange  = 2
    case yellow  = 3
    case green   = 4
    case blue    = 5
    case purple  = 6
    case pink    = 7
    case white   = 8
    case black   = 9
}
