@preconcurrency import AVFoundation

// Declares AVFoundation types as "manually safe to pass" across suspension.
// We still avoid reading/writing them after await (see exportAsync()).
extension AVAssetExportSession: @unchecked Sendable {}
extension AVURLAsset: @unchecked Sendable {}
// (AVAsset itself isn’t stored/used across await in our code path anymore.)

