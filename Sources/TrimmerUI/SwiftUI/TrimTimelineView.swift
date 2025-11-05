// Sources/TrimmerUI/SwiftUI/TrimTimelineView.swift

import SwiftUI
import AVFoundation
import TrimmerEngine

/// View model for the trim timeline.
/// - Sync initializer (no await inside StateObject).
/// - Kicks off async loading via Task on the main actor.
@MainActor
public final class TrimViewModel: ObservableObject {
    // MARK: - Published state
    @Published public var start: CMTime = .zero
    @Published public var end: CMTime = .zero
    @Published public var thumbnails: [ThumbnailGenerator.Frame] = []

    // MARK: - Media
    public private(set) var duration: CMTime = .zero
    public let asset: AVAsset
    public let assetURL: URL

    /// Synchronous initializer. Creates the AVAsset and starts loading.
    public init(assetURL: URL) {
        self.assetURL = assetURL
        self.asset = AVURLAsset(url: assetURL)
        // Start async work after init so StateObject is happy
        Task { await load() }
    }

    /// Asynchronously loads duration and thumbnails.
    public func load() async {
        do {
            let d = try await asset.load(.duration)
            duration = d
            end = d

            let generator = ThumbnailGenerator(asset: asset) // @MainActor
            thumbnails = try await generator.generate(
                every: max(0.5, d.seconds / 12),
                maxCount: 50,
                maximumHeight: 72
            )
        } catch {
            #if DEBUG
            print("TrimViewModel load error:", error)
            #endif
        }
    }

    public var range: CMTimeRange { .init(start: start, end: end) }
}

/// Horizontal, scrollable timeline with draggable start/end handles.
/// Provide `assetURL` and get user-selected `start`/`end` via the view model,
/// or consume `range` when exporting.
public struct TrimTimelineView: View {
    @StateObject private var vm: TrimViewModel
    let onScrub: (CMTime) -> Void

    /// Synchronous init to satisfy StateObject requirements.
    public init(assetURL: URL, onScrub: @escaping (CMTime) -> Void) {
        _vm = StateObject(wrappedValue: TrimViewModel(assetURL: assetURL))
        self.onScrub = onScrub
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 2) {
                        // Fix: correct ForEach id key path
                        ForEach(Array(vm.thumbnails.enumerated()), id: \.offset) { _, frame in
                            Image(uiImage: frame.image)
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
        // If you prefer, you can move the loading trigger here instead:
        // .task { await vm.load() }
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
            .gesture(
                DragGesture().onChanged { g in
                    let progress = min(max(g.location.x / max(width, 1), 0), 1)
                    position = CMTime(
                        seconds: progress * max(duration.seconds, 0.0001),
                        preferredTimescale: 600
                    )
                    // If you want live scrubbing callbacks, thread onScrub down and call it here.
                }
            )
    }
}
