import Foundation
import AVFoundation

public enum TrimError: Error { case exportUnavailable, failed, cancelled }

public struct VideoTrimRequest: Sendable {
    public let assetURL: URL
    public let timeRange: CMTimeRange
    public let preset: String
    public let fileType: AVFileType

    public init(
        assetURL: URL,
        timeRange: CMTimeRange,
        preset: String = AVAssetExportPresetHEVCHighestQuality,
        fileType: AVFileType = .mp4
    ) {
        self.assetURL = assetURL
        self.timeRange = timeRange
        self.preset = preset
        self.fileType = fileType
    }
}

public actor VideoTrimmer {
    private var exporter: AVAssetExportSession?

    public init() {}

    @discardableResult
    public func export(_ req: VideoTrimRequest, to url: URL) async throws -> URL {
        let asset = AVURLAsset(url: req.assetURL)

        guard AVAssetExportSession.exportPresets(compatibleWith: asset).contains(req.preset) else {
            throw TrimError.exportUnavailable
        }
        guard let exporter = AVAssetExportSession(asset: asset, presetName: req.preset) else {
            throw TrimError.exportUnavailable
        }
        self.exporter = exporter

        try? FileManager.default.removeItem(at: url)
        exporter.outputURL = url
        exporter.outputFileType = req.fileType
        exporter.timeRange = req.timeRange
        exporter.shouldOptimizeForNetworkUse = true

        try await exporter.exportAsync()
        guard exporter.status == .completed, FileManager.default.fileExists(atPath: url.path) else {
            if exporter.status == .cancelled { throw TrimError.cancelled }
            throw exporter.error ?? TrimError.failed
        }
        self.exporter = nil
        return url
    }

    public func cancel() {
        exporter?.cancelExport()
    }
}

extension AVAssetExportSession {
    fileprivate func exportAsync() async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            self.exportAsynchronously {
                if let e = self.error {
                    cont.resume(throwing: e)
                } else {
                    cont.resume(returning: ())
                }
            }
        }
    }
}
