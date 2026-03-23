import UIKit

/// MVVM 베이스 ViewController.
/// viewDidLoad에서 setupHierarchy → setupConstraints → setupBind 순으로 호출합니다.
class BaseViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupHierarchy()
        setupConstraints()
        setupBind()
    }

    /// 서브뷰 추가 (addSubview)
    func setupHierarchy() {}

    /// Auto Layout 제약 설정
    func setupConstraints() {}

    /// RxSwift 바인딩 및 target-action 연결
    func setupBind() {}
}
