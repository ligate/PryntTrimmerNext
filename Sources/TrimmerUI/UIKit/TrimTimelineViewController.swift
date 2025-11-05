// Sources/TrimmerUI/SwiftUI/TrimTimelineView.swift

import SwiftUI
import AVFoundation
import TrimmerEngine

/// View model for the trim timeline.
/// - Sync initializer (no await inside StateObject).
/// - Kicks off async loading via Task on the main actor.

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
        // Alternative pattern if you prefer to trigger loading here instead of in VM.init():
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
                    // If you want live scrubbing callbacks, you can call onScrub here by passing it down.
                }
            )
    }
}
