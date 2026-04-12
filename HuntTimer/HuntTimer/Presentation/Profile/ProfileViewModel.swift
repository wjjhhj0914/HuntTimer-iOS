import UIKit
import RxSwift
import RxCocoa

// MARK: - ProfileViewModel

final class ProfileViewModel {

    // MARK: - Input / Output

    struct Input {
        let memorialToggled: Observable<Bool>
    }

    struct Output {
        let backgroundTint: Driver<UIColor>
    }

    // MARK: - Private

    private let disposeBag = DisposeBag()

    // MARK: - Transform

    func transform(input: Input) -> Output {
        let tint = input.memorialToggled
            .map { isOn -> UIColor in
                isOn
                    ? AppTheme.Color.pinkLight.withAlphaComponent(0.3)
                    : AppTheme.Color.background
            }
            .asDriver(onErrorJustReturn: AppTheme.Color.background)

        return Output(backgroundTint: tint)
    }
}
