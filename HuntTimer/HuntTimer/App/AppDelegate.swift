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
    private func configureRealm() {
        #if DEBUG
        let config = Realm.Configuration(
            schemaVersion: 2,
            deleteRealmIfMigrationNeeded: true
        )
        #else
        let config = Realm.Configuration(
            schemaVersion: 2,
            migrationBlock: { _, _ in }
        )
        #endif
        Realm.Configuration.defaultConfiguration = config

        // SceneDelegate보다 먼저 Realm을 열어 마이그레이션·파일 생성을 완료
        do {
            _ = try Realm()
            print("Realm 초기화 완료: \(config.fileURL?.path ?? "")")
        } catch {
            print("Realm 초기화 실패: \(error)")
            #if DEBUG
            forceResetRealm(config: config)
            #endif
        }
    }

    #if DEBUG
    /// 잔여 보조 파일(lock, management 등)을 정리하고 Realm을 재생성
    private func forceResetRealm(config: Realm.Configuration) {
        guard let url = config.fileURL else { return }
        let fm = FileManager.default
        let targets: [URL] = [
            url,
            URL(fileURLWithPath: url.path + ".lock"),
            URL(fileURLWithPath: url.path + ".note"),
            URL(fileURLWithPath: url.path + ".management")
        ]
        targets.forEach { try? fm.removeItem(at: $0) }

        do {
            _ = try Realm()
            print("📦 Realm 강제 초기화 완료")
        } catch {
            print("❌ Realm 강제 초기화도 실패: \(error)")
        }
    }
    #endif

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}
