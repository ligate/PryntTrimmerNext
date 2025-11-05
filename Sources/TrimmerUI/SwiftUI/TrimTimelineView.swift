import SwiftUI
import AVFoundation
import TrimmerEngine

@MainActor
public final class TrimViewModel: ObservableObject {
    @Published public var start: CMTime = .zero
    @Published public var end: CMTime
    @Published public var thumbnails: [ThumbnailGenerator.Frame] = []

    public let duration: CMTime
    public let asset: AVAsset
    public let assetURL: URL

    public init(assetURL: URL) async throws {
        self.assetURL = assetURL
        self.asset = AVURLAsset(url: assetURL)
        self.duration = try await asset.load(.duration)
        self.end = duration

        let gen = ThumbnailGenerator(asset: asset)
        self.thumbnails = try await gen.generate(every: max(0.5, duration.seconds/12))
    }

    public var range: CMTimeRange { .init(start: start, end: end) }
}

public struct TrimTimelineView: View {
    @StateObject private var vm: TrimViewModel
    let onScrub: (CMTime) -> Void

    public init(assetURL: URL, onScrub: @escaping (CMTime) -> Void) {
        _vm = StateObject(wrappedValue: try! TrimViewModel(assetURL: assetURL))
        self.onScrub = onScrub
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 2) {
                        ForEach(Array(vm.thumbnails.enumerated()), id: \ .offset) { _, f in
                            Image(uiImage: f.image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: geo.size.height)
                                .clipped()
                        }
                    }
                }
                Handle(position: $vm.start, duration: vm.duration, width: geo.size.width)
                Handle(position: $vm.end, duration: vm.duration, width: geo.size.width)
            }
            .contentShape(Rectangle())
        }
        .frame(height: 72)
    }
}

private struct Handle: View {
    @Binding var position: CMTime
    let duration: CMTime
    let width: CGFloat
    var body: some View {
        let x = CGFloat(position.seconds / max(duration.seconds, 0.0001)) * width
        Rectangle()
            .fill(BrandTheme.accent)
            .frame(width: 4)
            .cornerRadius(2)
            .shadow(radius: 2)
            .position(x: x, y: 36)
            .gesture(DragGesture().onChanged { g in
                let progress = min(max(g.location.x / max(width, 1), 0), 1)
                position = CMTime(seconds: progress * max(duration.seconds, 0.0001), preferredTimescale: 600)
            })
    }
}
