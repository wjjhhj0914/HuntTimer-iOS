import UIKit

/// MVVM 베이스 UIView.
/// 초기화 시 setupUI()를 자동으로 호출합니다.
class BaseView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// 서브뷰 추가 및 SnapKit 레이아웃 설정
    func setupUI() {}
}
