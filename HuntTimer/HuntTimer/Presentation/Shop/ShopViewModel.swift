import Foundation
import RxSwift
import RxCocoa

// MARK: - ShopViewModel

final class ShopViewModel {

    // MARK: - Input / Output

    struct Input {
        let viewDidLoad:     Observable<Void>
        let filterSelected:  Observable<String>
        let productLiked:    Observable<Int>     // product id
        let cartTapped:      Observable<Int>     // product id
    }

    struct Output {
        // TODO: Naver Shopping API 연동 시 상품 목록 드라이버 추가
        let products: Driver<[ShopProduct]>
    }

    // MARK: - Private

    private let disposeBag = DisposeBag()

    // MARK: - Transform

    func transform(input: Input) -> Output {
        // TODO: Naver Shopping API 연동
        input.cartTapped
            .subscribe(onNext: { id in print("[HuntTimer] 장바구니 추가: \(id)") })
            .disposed(by: disposeBag)

        return Output(
            products: .just(SampleData.products)
        )
    }
}
