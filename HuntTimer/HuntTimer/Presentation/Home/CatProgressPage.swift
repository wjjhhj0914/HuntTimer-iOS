import Foundation
import RealmSwift

/// 목표 대시보드 페이저의 단일 페이지 데이터
struct CatProgressPage {
    let catId:           ObjectId?   // nil = 전체 overview 페이지
    let catName:         String
    let profileImageData: Data?
    let todaySeconds:    Int
    let goalMinutes:     Int
    let completedCount:  Int

    var progressRatio: Float {
        let goalSecs = goalMinutes * 60
        guard goalSecs > 0 else { return 0 }
        return min(1.0, Float(todaySeconds) / Float(goalSecs))
    }

    var isOverview: Bool { catId == nil }
}
