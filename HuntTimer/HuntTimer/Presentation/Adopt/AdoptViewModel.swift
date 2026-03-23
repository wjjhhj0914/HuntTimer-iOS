import Foundation
import RxSwift
import RxCocoa

// MARK: - AdoptViewModel

final class AdoptViewModel {

    // MARK: - Input / Output

    struct Input {
        let viewDidLoad:        Observable<Void>
        let locationSelected:   Observable<String>
        let ageSelected:        Observable<String>
        let learnMoreTapped:    Observable<Int>      // cat id
    }

    struct Output {
        // TODO: 유기동물 정보 공공 API 연동 시 실제 데이터 드라이버 추가
        let cats: Driver<[AdoptCat]>
    }

    // MARK: - Private

    private let disposeBag = DisposeBag()

    // MARK: - Transform

    func transform(input: Input) -> Output {
        // TODO: 공공 API 연동
        input.learnMoreTapped
            .subscribe(onNext: { id in print("[HuntTimer] 더 알아보기: 고양이 id=\(id)") })
            .disposed(by: disposeBag)

        return Output(
            cats: .just(SampleData.adoptCats)
        )
    }
}
