import Foundation
import RxSwift
import RxCocoa

// MARK: - LogViewModel

final class LogViewModel {

    // MARK: - Input / Output

    struct Input {
        let viewDidLoad:    Observable<Void>
        let daySelected:    Observable<Int>
        let monthChanged:   Observable<Int>   // delta: +1 or -1
    }

    struct Output {
        // TODO: Realm 연동 시 캘린더 활동 데이터 드라이버 추가
        let sessions: Driver<[HuntSession]>
    }

    // MARK: - Private

    private let disposeBag = DisposeBag()

    // MARK: - Transform

    func transform(input: Input) -> Output {
        // TODO: Realm 연동 — 선택 날짜의 PlaySession 조회
        input.daySelected
            .subscribe(onNext: { day in print("[HuntTimer] 날짜 선택: \(day)") })
            .disposed(by: disposeBag)

        return Output(
            sessions: .just(SampleData.sessions)
        )
    }
}
