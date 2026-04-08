import UIKit
import Foundation
import RxSwift
import RxCocoa
import RealmSwift

// MARK: - TimerViewModel

final class TimerViewModel {

    // MARK: - Input / Output

    struct Input {
        let startTapped:  Observable<Void>
        let pauseTapped:  Observable<Void>
        let stopTapped:   Observable<Void>
        let presetTapped: Observable<Int>   // minutes
    }

    struct Output {
        // TODO: Realm 연동 시 세션 저장/통계 드라이버 추가
        let sessionSaved: Driver<Void>
    }

    // MARK: - Private

    private let disposeBag = DisposeBag()

    // MARK: - Transform

    func transform(input: Input) -> Output {
        return Output(
            sessionSaved: Observable.empty().asDriver(onErrorJustReturn: ())
        )
    }

    // MARK: - Session Save

    func saveSession(startTime: Date, endTime: Date, duration: Int, targetDuration: Int,
                     cats: [Cat] = [], toyName: String? = nil,
                     memo: String? = nil, photo: UIImage? = nil) {
        let session = PlaySession()
        session.startTime      = startTime
        session.endTime        = endTime
        session.duration       = duration
        session.targetDuration = targetDuration
        session.memo           = memo

        do {
            let realm = try Realm()
            try realm.write {
                realm.add(session)

                // 선택된 고양이들 저장 (이미 Realm 관리 객체이므로 append 가능)
                session.cats.append(objectsIn: cats)

                // 장난감 저장
                if let name = toyName, !name.isEmpty {
                    let toy = Toy()
                    toy.name     = name
                    toy.category = name
                    realm.add(toy)
                    session.toys.append(toy)
                }

                // 사진 저장
                if let image = photo, let path = Self.saveImageToDocuments(image) {
                    let log = PhotoLog()
                    log.session   = session
                    log.imagePath = path
                    log.createdAt = Date()
                    realm.add(log)
                }
            }
            print("[HuntTimer] 세션 저장 완료 — duration: \(duration)초 / cats: \(cats.map { $0.name }) / toy: \(toyName ?? "없음")")
        } catch {
            print("[HuntTimer] 세션 저장 실패:", error)
            return
        }
        NotificationManager.shared.checkGoalProgressAndNotify()
    }

    // MARK: - Image Storage

    private static func saveImageToDocuments(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        let fileName = UUID().uuidString + ".jpg"
        let dir      = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url      = dir.appendingPathComponent(fileName)
        do {
            try data.write(to: url)
            return url.path
        } catch {
            print("[HuntTimer] 이미지 저장 실패:", error)
            return nil
        }
    }
}
