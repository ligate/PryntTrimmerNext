import Foundation
import AVFoundation
import UIKit

/// Thumbnails are produced on the main actor to avoid crossing non-Sendable images between actors.
@MainActor
public final class ThumbnailGenerator {
    private let asset: AVAsset
    public init(asset: AVAsset) { self.asset = asset }

    public struct Frame {
        public let time: CMTime
        public let image: UIImage
        public init(time: CMTime, image: UIImage) {
            self.time = time; self.image = image
        }
    }

    /// Generates a strip of thumbnails.
    public func generate(every: Double, maxCount: Int = 50, maximumHeight: CGFloat = 72) async throws -> [Frame] {
        let duration = try await asset.load(.duration)
        let timescale: CMTimeScale = 600
        let step = CMTime(seconds: every, preferredTimescale: timescale)

        var values: [NSValue] = []
        var t = CMTime.zero
        while t < duration, values.count < maxCount {
            values.append(NSValue(time: t))
            t = t + step
        }
        if values.isEmpty { values = [NSValue(time: .zero)] }

        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceAfter = .zero
        generator.requestedTimeToleranceBefore = .zero

        if maximumHeight > 0 {
            let tracks = try await asset.loadTracks(withMediaType: .video)
            if let size = try? await tracks.first?.load(.naturalSize), size != .zero {
                let aspect = size.width / max(size.height, 1)
                generator.maximumSize = CGSize(width: aspect * maximumHeight, height: maximumHeight)
            }
        }

        return try await withCheckedThrowingContinuation { cont in
            var frames: [Frame] = []
            generator.generateCGImagesAsynchronously(forTimes: values) { time, cg, _, result, err in
                if let err { cont.resume(throwing: err); return }
                if let cg, result == .succeeded {
                    frames.append(Frame(time: time, image: UIImage(cgImage: cg)))
                }
                if frames.count == values.count {
                    frames.sort { $0.time < $1.time }
                    cont.resume(returning: frames)
                }
            }
        }
    }
}
