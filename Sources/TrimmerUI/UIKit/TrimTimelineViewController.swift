import UIKit
import AVFoundation
import TrimmerEngine

public final class TrimTimelineViewController: UIViewController {
    private let asset: AVAsset
    private var thumbnails: [ThumbnailGenerator.Frame] = []
    private let collection = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    private let startHandle = UIView()
    private let endHandle = UIView()

    public private(set) var start: CMTime = .zero
    public private(set) var end: CMTime

    public init(assetURL: URL) {
        self.asset = AVURLAsset(url: assetURL)
        self.end = self.asset.duration
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        if let flow = collection.collectionViewLayout as? UICollectionViewFlowLayout {
            flow.scrollDirection = .horizontal
            flow.minimumLineSpacing = 2
            flow.itemSize = CGSize(width: 80, height: 72)
        }
        collection.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "c")
        collection.dataSource = self
        collection.backgroundColor = .clear
        view.addSubview(collection)
        collection.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collection.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collection.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collection.topAnchor.constraint(equalTo: view.topAnchor),
            collection.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        configureHandle(startHandle, color: .systemBlue, x: 20)
        configureHandle(endHandle, color: .systemBlue, x: view.bounds.width - 20)

        Task { [weak self] in
            guard let self else { return }
            let gen = ThumbnailGenerator(asset: self.asset)
            self.thumbnails = (try? await gen.generate(every: max(0.5, self.asset.duration.seconds/12))) ?? []
            self.collection.reloadData()
        }
    }

    private func configureHandle(_ v: UIView, color: UIColor, x: CGFloat) {
        v.backgroundColor = color
        v.layer.cornerRadius = 2
        v.translatesAutoresizingMaskIntoConstraints = true
        v.frame = CGRect(x: x, y: 0, width: 4, height: 72)
        view.addSubview(v)
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        v.addGestureRecognizer(pan)
    }

    @objc private func handlePan(_ g: UIPanGestureRecognizer) {
        let x = max(0, min(g.location(in: view).x, view.bounds.width))
        g.view?.center.x = x
        let progress = x / max(view.bounds.width, 1)
        let time = CMTime(seconds: progress * max(asset.duration.seconds, 0.0001), preferredTimescale: 600)
        if g.view === startHandle { start = time } else { end = time }
    }
}

extension TrimTimelineViewController: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { thumbnails.count }
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "c", for: indexPath)
        let iv: UIImageView
        if let existing = cell.contentView.viewWithTag(99) as? UIImageView { iv = existing }
        else {
            iv = UIImageView(frame: cell.contentView.bounds)
            iv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            iv.contentMode = .scaleAspectFill
            iv.clipsToBounds = true
            iv.tag = 99
            cell.contentView.addSubview(iv)
        }
        iv.image = thumbnails[indexPath.item].image
        return cell
    }
}
