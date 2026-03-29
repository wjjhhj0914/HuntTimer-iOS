import UIKit
import RealmSwift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        configureRealm()
        return true
    }

    // MARK: - Realm

    /// 현재 Realm 스키마 버전.
    /// 모델 프로퍼티를 추가·삭제·변경할 때마다 이 값을 1씩 올리고
    /// `migrate(migration:oldSchemaVersion:)` 에 해당 버전 블록을 추가해야 합니다.
    private static let currentSchemaVersion: UInt64 = 2

    private func configureRealm() {
        let config = Realm.Configuration(
            schemaVersion: Self.currentSchemaVersion,
            migrationBlock: migrate
        )
        Realm.Configuration.defaultConfiguration = config

        do {
            _ = try Realm()
            print("[Realm] 초기화 완료 — schema v\(Self.currentSchemaVersion)")
        } catch {
            // 마이그레이션 로직 누락 등 치명적 오류가 발생하면 개발 단계에서 반드시 수정할 것
            print("[Realm] 초기화 실패: \(error)")
        }
    }

    /// 버전별 마이그레이션 블록.
    ///
    /// 새 버전을 추가할 때의 절차:
    ///   1. `currentSchemaVersion` 을 +1 올린다.
    ///   2. 아래에 `if oldSchemaVersion < N { ... }` 블록을 추가한다.
    ///   3. 새 프로퍼티에 기본값이 있으면 Realm이 자동 처리하므로 별도 enumerate 불필요.
    ///      타입 변환·이름 변경·데이터 가공이 필요한 경우에만 enumerate 사용.
    private func migrate(migration: Migration, oldSchemaVersion: UInt64) {
        // ── v0 → v1 ─────────────────────────────────────────────────
        // 초기 스키마 출시 (Cat, PlaySession, Toy, PhotoLog, Achievement)
        // 모든 프로퍼티가 기본값을 가지므로 별도 처리 없음
        if oldSchemaVersion < 1 { }

        // ── v1 → v2 ─────────────────────────────────────────────────
        // • PlaySession.endTime (Date?) 추가 → nil 기본값 자동 적용
        // • Toy.colour (Int)             추가 → 0 (ToyColour.unknown) 자동 적용
        if oldSchemaVersion < 2 { }
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}
