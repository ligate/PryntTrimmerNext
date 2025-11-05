# PryntTrimmerNext (v2)

Swift Package rewrite for video trimming (modern concurrency, SwiftUI + UIKit timelines) with a blue brand sample app.

**Option A architecture**: requests carry a `URL` (Sendable). `AVAsset` is created inside the `VideoTrimmer` actor to avoid Sendable issues.

- `TrimmerEngine`
  - `VideoTrimRequest` (URL-based)
  - `VideoTrimmer` actor (async export)
  - `ThumbnailGenerator` (UI-thread friendly async generator)
- `TrimmerUI`
  - `BrandTheme` (blue)
  - `TrimTimelineView` (SwiftUI) + `TrimViewModel`
  - `TrimTimelineViewController` (UIKit)

Example app in `Examples/PryntTrimmerNextApp`.
