import UIKit

/// URL 기반 비동기 이미지 로딩 UIImageView
final class AsyncImageView: UIImageView {

    private var currentURL: URL?
    private static var cache = NSCache<NSURL, UIImage>()

    private let activityIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .medium)
        ai.color = AppTheme.Color.textMuted
        ai.hidesWhenStopped = true
        return ai
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    convenience init(contentMode: UIView.ContentMode = .scaleAspectFill, cornerRadius: CGFloat = 0) {
        self.init(frame: .zero)
        self.contentMode = contentMode
        if cornerRadius > 0 {
            self.layer.cornerRadius = cornerRadius
            self.clipsToBounds = true
        }
    }

    private func setup() {
        contentMode   = .scaleAspectFill
        clipsToBounds = true
        backgroundColor = AppTheme.Color.primaryLight
        addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    func loadImage(from urlString: String, placeholder: UIColor = AppTheme.Color.primaryLight) {
        backgroundColor = placeholder
        image = nil
        guard let url = URL(string: urlString) else { return }
        currentURL = url

        if let cached = AsyncImageView.cache.object(forKey: url as NSURL) {
            image = cached
            return
        }

        activityIndicator.startAnimating()
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard
                let self,
                let data,
                let loaded = UIImage(data: data),
                self.currentURL == url
            else { return }

            AsyncImageView.cache.setObject(loaded, forKey: url as NSURL)
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                UIView.transition(with: self, duration: 0.25, options: .transitionCrossDissolve) {
                    self.image = loaded
                }
            }
        }.resume()
    }
}
