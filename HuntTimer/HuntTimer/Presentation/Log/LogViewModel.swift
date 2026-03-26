import Foundation
import RxSwift
import RxCocoa

// MARK: - LogViewModel

final class LogViewModel {

    // MARK: - Input / Output

    struct Input {
        let viewDidLoad:  Observable<Void>
        let daySelected:  Observable<Int>
        let monthChanged: Observable<Int>   // delta: +1 or -1
    }

    struct Output {
        let sessions: Driver<[HuntSession]>
    }

    // MARK: - Private

    private let disposeBag = DisposeBag()

    // MARK: - Transform

    func transform(input: Input) -> Output {
        // 세션 데이터는 LogViewController가 Realm에서 직접 조회 후 뷰에 반영
        return Output(sessions: .just([]))
    }
}
