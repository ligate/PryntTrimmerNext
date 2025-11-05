import SwiftUI

public enum BrandTheme {
    public static let bgTop = Color(red: 0.04, green: 0.10, blue: 0.24)
    public static let bgBottom = Color(red: 0.00, green: 0.07, blue: 0.16)
    public static let surface = Color.white
    public static let text = Color(red: 0.06, green: 0.10, blue: 0.20)
    public static let accent = Color(red: 0.15, green: 0.39, blue: 1.00)
    public static let accentDark = Color(red: 0.10, green: 0.27, blue: 0.83)
    public static let border = Color.black.opacity(0.06)
    public static let radiusXL: CGFloat = 28
    public static let radiusLG: CGFloat = 20
}

public struct BlueHeader<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    public init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title; self.content = content()
    }

    public var body: some View {
        ZStack {
            LinearGradient(colors: [BrandTheme.bgTop, BrandTheme.bgBottom],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            VStack(spacing: 16) {
                Text(title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                content
            }
            .padding()
        }
        .frame(maxWidth: .infinity)
    }
}
