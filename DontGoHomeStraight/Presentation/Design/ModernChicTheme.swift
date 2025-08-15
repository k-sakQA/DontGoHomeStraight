import SwiftUI

// MARK: - Modern Chic Theme Utilities

extension Color {
    static let appPurpleStart = Color(hex: "6366F1")
    static let appPurpleEnd = Color(hex: "8B5CF6")
}

extension LinearGradient {
    static var appHeroGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.appPurpleStart,
                Color.appPurpleEnd
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static var appBackgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "F0F9FF"),
                Color(hex: "E0E7FF")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(
                LinearGradient.appHeroGradient
                    .opacity(configuration.isPressed ? 0.85 : 1.0)
            )
            .cornerRadius(16)
            .shadow(color: .black.opacity(configuration.isPressed ? 0.1 : 0.2), radius: configuration.isPressed ? 6 : 12, x: 0, y: configuration.isPressed ? 3 : 8)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(14)
            .background(
                Color.black.opacity(configuration.isPressed ? 0.35 : 0.25)
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(configuration.isPressed ? 0.06 : 0.12), radius: configuration.isPressed ? 3 : 6, x: 0, y: configuration.isPressed ? 1 : 3)
            .scaleEffect(configuration.isPressed ? 0.99 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.9), value: configuration.isPressed)
    }
}

// MARK: - Card Style

struct AppCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color.white.opacity(0.95))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
    }
}

extension View {
    func appCard() -> some View {
        self.modifier(AppCardModifier())
    }
}

