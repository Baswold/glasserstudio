import SwiftUI

extension Color {
    static let glasserGradient = [Color.blue, Color.purple]
    
    static func glasserPrimary(opacity: Double = 1.0) -> Color {
        Color.blue.opacity(opacity)
    }
}

extension View {
    func glasserCard() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
    }
    
    func glasserButton(isEnabled: Bool = true) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        isEnabled
                        ? LinearGradient(
                            colors: Color.glasserGradient,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        : LinearGradient(
                            colors: [.gray.opacity(0.5), .gray.opacity(0.5)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
    }
}
