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

    func saveSession(startTime: Date, endTime: Date, duration: Int, targetDuration: Int, memo: String? = nil) {
        let session = PlaySession()
        session.startTime = startTime
        session.endTime = endTime
        session.duration = duration
        session.targetDuration = targetDuration
        session.memo = memo

        do {
            let realm = try Realm()
            try realm.write {
                realm.add(session)
            }
            print("[HuntTimer] 세션 저장 완료 — duration: \(duration)초 / target: \(targetDuration)초")
        } catch {
            print("[HuntTimer] 세션 저장 실패:", error)
        }
    }
}
