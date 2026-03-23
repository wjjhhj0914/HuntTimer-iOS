import Foundation
import RxSwift
import RxCocoa

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
        // TODO: Realm 연동 — 세션 종료 시 PlaySession 저장
        input.stopTapped
            .subscribe(onNext: { print("[HuntTimer] 타이머 정지 — 세션 저장 예정") })
            .disposed(by: disposeBag)

        return Output(
            sessionSaved: Observable.empty().asDriver(onErrorJustReturn: ())
        )
    }
}
