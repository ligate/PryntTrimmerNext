// import SwiftUI
// import PhotosUI
// import AVFoundation
// import TrimmerUI
// import TrimmerEngine

// struct ContentView: View {
//     @State private var selection: PhotosPickerItem?
//     @State private var assetURL: URL?
//     @State private var exportURL: URL?
//     @State private var isExporting = false

//     var body: some View {
//         VStack(spacing: 0) {
//             BlueHeader(title: "PryntTrimmerNext") {
//                 Text("Pick, trim, and export with a clean blue style.")
//                     .foregroundStyle(.white.opacity(0.9))
//             }
//             .frame(height: 180)

//             VStack(spacing: 16) {
//                 PhotosPicker(selection: $selection, matching: .videos) {
//                     Text("Pick Video")
//                         .frame(maxWidth: .infinity).padding()
//                         .background(BrandTheme.accent)
//                         .foregroundStyle(.white)
//                         .clipShape(RoundedRectangle(cornerRadius: BrandTheme.radiusLG, style: .continuous))
//                         .padding(.horizontal)
//                 }
//                 .onChange(of: selection) { _, newItem in
//                     Task {
//                         guard let newItem else { return }
//                         if let url = try? await newItem.loadTransferable(type: URL.self) {
//                             assetURL = url
//                         } else if let data = try? await newItem.loadTransferable(type: Data.self) {
//                             assetURL = try? await writeTemp(data: data, name: "picked-\(UUID().uuidString).mov")
//                         }
//                     }
//                 }

//                 if let url = assetURL {
//                     TrimTimelineView(assetURL: url) { _ in }
//                         .frame(height: 80)
//                         .padding(.horizontal)

//                     Button {
//                         Task { await export(assetURL: url) }
//                     } label: {
//                         HStack {
//                             if isExporting { ProgressView().tint(.white) }
//                             Text(isExporting ? "Exporting…" : "Export Trim")
//                         }
//                         .frame(maxWidth: .infinity).padding()
//                         .background(BrandTheme.accentDark)
//                         .foregroundStyle(.white)
//                         .clipShape(RoundedRectangle(cornerRadius: BrandTheme.radiusLG, style: .continuous))
//                     }
//                     .padding(.horizontal)
//                     .disabled(isExporting)
//                 }

//                 if let exportURL {
//                     VStack(spacing: 8) {
//                         Text("Exported to:")
//                         Text(exportURL.lastPathComponent).font(.caption).foregroundStyle(.secondary)
//                         ShareLink("Share", item: exportURL)
//                     }
//                     .padding()
//                 }

//                 Spacer(minLength: 24)
//             }
//             .background(Color(.systemGroupedBackground).ignoresSafeArea())
//         }
//     }

//     func export(assetURL: URL) async {
//         isExporting = true
//         defer { isExporting = false }

//         let vm = try? await TrimViewModel(assetURL: assetURL)
//         guard let vm else { return }

//         let out = FileManager.default.temporaryDirectory.appendingPathComponent("trimmed-\(UUID().uuidString).mp4")
//         do {
//             let req = VideoTrimRequest(assetURL: assetURL, timeRange: vm.range)
//             _ = try await VideoTrimmer().export(req, to: out)
//             exportURL = out
//         } catch {
//             print("Export error:", error)
//         }
//     }

//     func writeTemp(data: Data, name: String) async throws -> URL {
//         let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
//         try? FileManager.default.removeItem(at: url)
//         try data.write(to: url)
//         return url
//     }
// }
