// import Foundation
// @preconcurrency import AVFoundation   // relax pre-concurrency imports

// public enum TrimError: Error { case exportUnavailable, failed, cancelled }

// // MARK: - Request stores only URL (Sendable)
// public struct VideoTrimRequest: Sendable {
//     public let assetURL: URL
//     public let timeRange: CMTimeRange
//     public let preset: String
//     public let fileType: AVFileType

//     public init(
//         assetURL: URL,
//         timeRange: CMTimeRange,
//         preset: String = AVAssetExportPresetHEVCHighestQuality,
//         fileType: AVFileType = .mp4
//     ) {
//         self.assetURL = assetURL
//         self.timeRange = timeRange
//         self.preset = preset
//         self.fileType = fileType
//     }
// }

// // MARK: - Export actor
// public actor VideoTrimmer {
//     private var exporter: AVAssetExportSession?

//     public init() {}

//     public func export(_ req: VideoTrimRequest, to url: URL) async throws -> URL {
//         let asset = AVURLAsset(url: req.assetURL)

//         // Verify preset and create session
//         guard AVAssetExportSession.exportPresets(compatibleWith: asset).contains(req.preset),
//               let session = AVAssetExportSession(asset: asset, presetName: req.preset) else {
//             throw TrimError.exportUnavailable
//         }
//         self.exporter = session

//         // Configure session
//         try? FileManager.default.removeItem(at: url)
//         session.outputURL = url
//         session.outputFileType = req.fileType
//         session.timeRange = req.timeRange
//         session.shouldOptimizeForNetworkUse = true

//         // Await completion and get a typed result (no reading session after await)
//         let result: ExportResult = try await session.exportAsync()

//         self.exporter = nil

//         switch result {
//         case .completed:
//             return url
//         case .cancelled:
//             throw TrimError.cancelled
//         case .failed(let underlying):
//             throw underlying ?? TrimError.failed
//         }
//     }

//     public func cancel() { exporter?.cancelExport() }
// }

// // MARK: - Result enum to avoid reading the session after suspension
// public enum ExportResult {
//     case completed
//     case cancelled
//     case failed(Error?)
// }

// // MARK: - Async wrapper (no post-await access to the session)
// private extension AVAssetExportSession {
//     /// Exports asynchronously and returns a pure `ExportResult`.
//     /// This avoids reading `status`/`error` after `await`, reducing data-race risk.
//     func exportAsync() async throws -> ExportResult {
//         try await withCheckedThrowingContinuation { (cont: CheckedContinuation<ExportResult, Error>) in
//             self.exportAsynchronously {
//                 // Snapshot state *inside* the callback
//                 let status = self.status
//                 let error  = self.error

//                 switch status {
//                 case .completed:
//                     cont.resume(returning: .completed)
//                 case .cancelled:
//                     cont.resume(returning: .cancelled)
//                 case .failed:
//                     if let e = error { cont.resume(throwing: e) }
//                     else { cont.resume(returning: .failed(nil)) }
//                 default:
//                     // Treat unknown/intermediate statuses as failure guarded by error
//                     if let e = error { cont.resume(throwing: e) }
//                     else { cont.resume(returning: .failed(nil)) }
//                 }
//             }
//         }
//     }
// }
